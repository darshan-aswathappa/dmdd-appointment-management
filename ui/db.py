"""Oracle connection helper and table metadata loader.

Uses python-oracledb in thin mode (no Oracle Instant Client required).
Connects to Oracle Autonomous Database via wallet (mTLS).

The UI supports switching the connecting user at runtime via a registry
of known DB users. Each user maps to a role with different privileges,
so the demo can show permission errors without having to recompile.
"""
import oracledb
from config import DB_DSN, WALLET_DIR, WALLET_PASSWORD


# Registered DB users the UI knows how to connect as. The keys are
# URL-safe slugs used in the session and form POSTs; the values carry
# Oracle credentials plus metadata shown on the /users page.
DB_USERS = {
    "hms": {
        "label": "HMS (schema owner)",
        "user": "HMS",
        "password": "HospitalMS@Pass123",
        "role": "OWNER",
        "kind": "owner",
        "description": (
            "The schema owner. Owns every table, view, procedure, and "
            "trigger in the HMS schema and can perform any DDL or DML. "
            "Used for migrations, seeding, and admin setup - not a "
            "real application user."
        ),
    },
    "admin_user": {
        "label": "admin_user",
        "user": "admin_user",
        "password": "AdminPass123",
        "role": "HospitalAdmin",
        "kind": "admin",
        "description": (
            "The application-tier admin. Holds the HospitalAdmin role: "
            "full CRUD on all tables and views, plus EXECUTE on the "
            "appointment procedures. Does not own any objects."
        ),
    },
    "operator_user": {
        "label": "operator_user",
        "user": "operator_user",
        "password": "OperatorPass456",
        "role": "HospitalOperator",
        "kind": "operator",
        "description": (
            "The read-only operator. Holds the HospitalOperator role: "
            "SELECT on every table and view, nothing else. Cannot "
            "INSERT/UPDATE/DELETE and cannot EXECUTE procedures - the "
            "UI surfaces the ORA-01031 error when it tries."
        ),
    },
}

DEFAULT_USER_KEY = "hms"


# Tables we expose in the generic CRUD interface, in a sensible display order.
TABLES = [
    "INSURANCE",
    "DEPARTMENT",
    "EMPLOYEE",
    "PATIENT",
    "DOCTORSCHEDULE",
    "DOCTORVACATION",
    "APPOINTMENT",
    "APPOINTMENTHISTORY",
    "ROOM",
    "BED",
    "ADMISSION",
    "PRESCRIPTION",
    "PAYMENT",
]

# Views exposed for read-only browsing.
VIEWS = [
    "V_APPOINTMENT",
    "V_DOCTOR_SCHEDULE",
    "V_PRESCRIPTION",
    "V_BILLING",
    "V_PAYMENT",
    "V_BED_STATUS",
]

# Populated by load_metadata() at app startup.
# Shape: {table_name: {"columns": [...], "identity": {...}, "pk": [...]}}
TABLE_META: dict = {}


def get_conn(user_key: str = DEFAULT_USER_KEY):
    """Return a fresh Oracle connection as the requested user.

    `user_key` selects a row from DB_USERS. Unknown keys fall back to the
    default (schema owner). For non-owner users we set CURRENT_SCHEMA=HMS
    so unqualified table/view names resolve to HMS-owned objects instead
    of failing with ORA-00942.
    """
    cfg = DB_USERS.get(user_key) or DB_USERS[DEFAULT_USER_KEY]
    conn = oracledb.connect(
        user=cfg["user"],
        password=cfg["password"],
        dsn=DB_DSN,
        config_dir=WALLET_DIR,
        wallet_location=WALLET_DIR,
        wallet_password=WALLET_PASSWORD,
    )
    if cfg["user"].upper() != "HMS":
        cur = conn.cursor()
        try:
            cur.execute("ALTER SESSION SET CURRENT_SCHEMA = HMS")
        finally:
            cur.close()
    return conn


def load_metadata() -> dict:
    """Load column info, identity columns, and primary keys for all CRUD tables.

    Cached in the module-level TABLE_META dict for the life of the process.
    """
    TABLE_META.clear()
    with get_conn() as conn:
        cur = conn.cursor()
        for t in TABLES:
            cur.execute(
                """
                SELECT column_name, data_type, data_length, nullable,
                       data_default, char_length
                  FROM user_tab_columns
                 WHERE table_name = :t
              ORDER BY column_id
                """,
                t=t,
            )
            cols = []
            for row in cur.fetchall():
                cols.append(
                    {
                        "name": row[0],
                        "type": row[1],
                        "length": row[2],
                        "nullable": row[3] == "Y",
                        "default": row[4],
                        "char_length": row[5],
                    }
                )

            cur.execute(
                "SELECT column_name FROM user_tab_identity_cols WHERE table_name = :t",
                t=t,
            )
            identity = {r[0] for r in cur.fetchall()}

            cur.execute(
                """
                SELECT cc.column_name
                  FROM user_constraints c
                  JOIN user_cons_columns cc ON c.constraint_name = cc.constraint_name
                 WHERE c.table_name = :t
                   AND c.constraint_type = 'P'
              ORDER BY cc.position
                """,
                t=t,
            )
            pk = [r[0] for r in cur.fetchall()]

            TABLE_META[t] = {"columns": cols, "identity": identity, "pk": pk}
    return TABLE_META


def html_input_for(col: dict) -> dict:
    """Map an Oracle column descriptor to HTML form input hints."""
    t = col["type"]
    if t == "DATE":
        return {"type": "date", "html_type": "date"}
    if t == "NUMBER":
        return {"type": "number", "step": "any"}
    if t in ("CHAR", "VARCHAR2", "NVARCHAR2"):
        length = col["char_length"] or col["length"] or 100
        if length > 500:
            return {"type": "textarea"}
        return {"type": "text", "maxlength": length}
    if t == "CLOB":
        return {"type": "textarea"}
    return {"type": "text"}


def coerce_value(raw: str, col: dict):
    """Convert a form-submitted string into a Python value suitable for oracledb."""
    if raw is None or raw == "":
        return None
    t = col["type"]
    if t == "NUMBER":
        # Let the driver sort int vs float
        if "." in raw:
            return float(raw)
        try:
            return int(raw)
        except ValueError:
            return float(raw)
    if t == "DATE":
        # HTML date input => 'YYYY-MM-DD'
        import datetime as _dt
        return _dt.datetime.strptime(raw, "%Y-%m-%d")
    return raw
