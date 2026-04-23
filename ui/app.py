"""Flask UI for the HMS schema.

Routes:
  /                              Dashboard with row counts for all tables.
  /tables/<name>                 List / CRUD forms for a table.
  /views/<name>                  Read-only display of a view.
  /reports, /reports/<name>      Execute saved SQL reports.
  /flows                         Appointment-module demo flows (pos + neg).
  /flows/book|cancel|reschedule|complete|availability
                                 Positive-path flows.
  /flows/negative/<scenario>     Canned negative flow that triggers a
                                 specific validation error.
  /docs, /rules, /tests          Reference documentation pages.
"""
import os
import re

from flask import (
    Flask, render_template, request, redirect, url_for, flash, abort,
    session,
)
import oracledb

from db import (
    TABLES, VIEWS, TABLE_META, load_metadata,
    get_conn, html_input_for, coerce_value,
    DB_USERS, DEFAULT_USER_KEY,
)


def current_user_key() -> str:
    """Pick the DB user for this request from the Flask session."""
    key = session.get("db_user", DEFAULT_USER_KEY)
    return key if key in DB_USERS else DEFAULT_USER_KEY


def current_conn():
    """Return an Oracle connection as the user selected in the session."""
    return get_conn(current_user_key())


app = Flask(__name__)
app.secret_key = "hms-ui-dev-secret"


# Load schema metadata once at startup. If the DB isn't reachable yet, we
# still boot the app and surface a helpful error on the first request.
try:
    load_metadata()
except oracledb.DatabaseError as e:
    app.logger.warning("Could not load metadata at startup: %s", e)


PERMISSION_ORA_CODES = {1031, 942, 4043, 6550, 1039}


@app.errorhandler(oracledb.DatabaseError)
def handle_oracle_error(e):
    """Render Oracle errors as a flash message and send the user back.

    Permission-related codes get a dedicated 'Permission denied as
    <user>' framing so the demo toggle's effect is obvious.
    """
    (err,) = e.args
    msg = getattr(err, "message", str(err)).strip()
    code = abs(int(getattr(err, "code", 0) or 0))
    user_label = DB_USERS[current_user_key()]["label"]
    if code in PERMISSION_ORA_CODES:
        flash(f"Permission denied as {user_label} - {msg}", "error")
    else:
        flash(f"Oracle error (as {user_label}): {msg}", "error")
    return redirect(request.referrer or url_for("index"))


@app.context_processor
def inject_user_context():
    """Make current_user + all_users available to every template."""
    key = current_user_key()
    return {
        "current_user": DB_USERS[key],
        "current_user_key": key,
        "all_users": DB_USERS,
    }


@app.route("/set-user", methods=["POST"])
def set_user():
    key = request.form.get("user")
    if key in DB_USERS:
        session["db_user"] = key
        flash(
            f"Now connected as {DB_USERS[key]['label']} "
            f"(role: {DB_USERS[key]['role']}).",
            "success",
        )
    else:
        flash("Unknown user selection.", "error")
    return redirect(request.referrer or url_for("index"))


@app.route("/users")
def users_page():
    return render_template("users.html")


@app.route("/whoami")
def whoami():
    """Diagnostic: prove which Oracle user is actually running queries.

    Queries run here use current_conn(), so they reflect whatever the
    user toggle says. If the session-level Oracle USER does not match
    the selected toggle label, the session isn't actually switching.
    If operator_user has EXECUTE on procedures, the DB grants deviate
    from DDL/06_create_roles_security.sql and need to be resynced.
    """
    diagnostic = {
        "session_key": current_user_key(),
        "session_user_meta": DB_USERS[current_user_key()],
        "oracle_user": None,
        "current_schema": None,
        "roles": [],
        "procedure_privs": [],
        "table_priv_sample": [],
        "error": None,
    }
    try:
        with current_conn() as conn:
            cur = conn.cursor()
            cur.execute("SELECT USER FROM DUAL")
            diagnostic["oracle_user"] = cur.fetchone()[0]

            cur.execute(
                "SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM DUAL"
            )
            diagnostic["current_schema"] = cur.fetchone()[0]

            cur.execute("SELECT role FROM SESSION_ROLES ORDER BY role")
            diagnostic["roles"] = [r[0] for r in cur.fetchall()]

            # Which procedures/functions is this session allowed to EXECUTE?
            cur.execute(
                """
                SELECT table_name, privilege, grantor
                  FROM user_tab_privs
                 WHERE privilege = 'EXECUTE'
                   AND table_name IN (
                       'SP_BOOKAPPOINTMENT',
                       'SP_CANCELAPPOINTMENT',
                       'SP_RESCHEDULEAPPOINTMENT',
                       'SP_COMPLETEAPPOINTMENT',
                       'SP_GETDOCTORAVAILABILITY',
                       'FN_ISDOCTORONVACATION'
                   )
                 ORDER BY table_name
                """
            )
            diagnostic["procedure_privs"] = [
                {"name": r[0], "priv": r[1], "grantor": r[2]}
                for r in cur.fetchall()
            ]

            # Sample of table-level privileges (first 15 rows).
            cur.execute(
                """
                SELECT table_name, privilege, grantor
                  FROM user_tab_privs
                 WHERE privilege IN
                       ('SELECT','INSERT','UPDATE','DELETE','EXECUTE')
                 ORDER BY table_name, privilege
                 FETCH FIRST 40 ROWS ONLY
                """
            )
            diagnostic["table_priv_sample"] = [
                {"name": r[0], "priv": r[1], "grantor": r[2]}
                for r in cur.fetchall()
            ]
    except oracledb.DatabaseError as e:
        (err,) = e.args
        diagnostic["error"] = getattr(err, "message", str(err)).strip()

    return render_template("whoami.html", d=diagnostic)


# ---------------------------------------------------------------------------
# View metadata (title + description for each VIEWS entry)
# ---------------------------------------------------------------------------
VIEWS_META = [
    {
        "name": "V_APPOINTMENT",
        "title": "Appointment (consolidated)",
        "description": (
            "Consolidated appointment view joining Appointment, "
            "DoctorSchedule, Patient, Employee, and Department. Use it to "
            "read a full appointment record without hand-writing the joins."
        ),
    },
    {
        "name": "V_DOCTOR_SCHEDULE",
        "title": "Doctor Schedule",
        "description": (
            "Doctor schedule availability with current booking counts and "
            "vacation flags per slot. One row per DoctorSchedule slot."
        ),
    },
    {
        "name": "V_PRESCRIPTION",
        "title": "Prescription",
        "description": (
            "Prescription details enriched with patient and doctor info, "
            "sourced from either the Appointment or Admission chain."
        ),
    },
    {
        "name": "V_BILLING",
        "title": "Billing (unified)",
        "description": (
            "Unified billing stream. UNIONs billing data from Appointment "
            "and Admission so reports can treat billing as one source."
        ),
    },
    {
        "name": "V_PAYMENT",
        "title": "Payment",
        "description": (
            "Payment records joined to their originating Appointment or "
            "Admission plus the patient, with billing context."
        ),
    },
    {
        "name": "V_BED_STATUS",
        "title": "Bed Status",
        "description": (
            "Real-time bed occupancy. Every bed with its room, status "
            "(Available / Occupied / Maintenance), and current patient."
        ),
    },
]

VIEWS_META_BY_NAME = {v["name"]: v for v in VIEWS_META}


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
@app.route("/")
def index():
    counts = {}
    errors = []
    with current_conn() as conn:
        cur = conn.cursor()
        for t in TABLES:
            try:
                cur.execute(f"SELECT COUNT(*) FROM {t}")
                counts[t] = cur.fetchone()[0]
            except oracledb.DatabaseError as e:
                counts[t] = "-"
                errors.append(f"{t}: {e}")
    return render_template(
        "index.html", counts=counts, tables=TABLES, views=VIEWS,
        views_meta=VIEWS_META, errors=errors,
    )


# ---------------------------------------------------------------------------
# Generic CRUD
# ---------------------------------------------------------------------------
@app.route("/tables")
def tables_index():
    return redirect(url_for("index") + "#crud")


def _require_table(name: str) -> dict:
    name = name.upper()
    if name not in TABLE_META:
        abort(404)
    return TABLE_META[name]


@app.route("/tables/<name>")
def table_list(name):
    name = name.upper()
    meta = _require_table(name)
    cols = [c["name"] for c in meta["columns"]]
    pk_col = meta["pk"][0] if meta["pk"] else None

    limit = int(request.args.get("limit", 200))
    with current_conn() as conn:
        cur = conn.cursor()
        order_clause = f"ORDER BY {pk_col} DESC" if pk_col else ""
        cur.execute(
            f"SELECT {','.join(cols)} FROM {name} {order_clause} "
            f"FETCH FIRST {int(limit)} ROWS ONLY"
        )
        raw_rows = cur.fetchall()

    rows = [
        [_display_cell(v) for v in r] for r in raw_rows
    ]
    return render_template(
        "table_list.html",
        name=name, cols=cols, rows=rows, meta=meta, pk_col=pk_col,
    )


def _display_cell(v):
    """Cheap renderer for table cells."""
    if v is None:
        return ""
    # oracledb returns LOBs as LOB objects; read them
    if hasattr(v, "read"):
        try:
            return v.read()
        except Exception:
            return "<LOB>"
    import datetime as _dt
    if isinstance(v, _dt.datetime):
        return v.strftime("%Y-%m-%d %H:%M")
    return str(v)


@app.route("/tables/<name>/new", methods=["GET", "POST"])
def table_new(name):
    name = name.upper()
    meta = _require_table(name)
    editable_cols = [
        c for c in meta["columns"] if c["name"] not in meta["identity"]
    ]

    if request.method == "POST":
        col_names = []
        values = {}
        for c in editable_cols:
            raw = request.form.get(c["name"])
            val = coerce_value(raw, c)
            if val is None and not c["nullable"] and c["default"] is None:
                flash(f"{c['name']} is required", "error")
                return render_template(
                    "table_form.html", name=name, meta=meta,
                    editable_cols=editable_cols, values=request.form,
                    hint_fn=html_input_for, mode="new",
                )
            col_names.append(c["name"])
            values[c["name"]] = val

        placeholders = ",".join(f":{c}" for c in col_names)
        sql = (
            f"INSERT INTO {name} ({','.join(col_names)}) "
            f"VALUES ({placeholders})"
        )
        with current_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, values)
            conn.commit()
        flash(f"Inserted into {name}.", "success")
        return redirect(url_for("table_list", name=name))

    return render_template(
        "table_form.html", name=name, meta=meta,
        editable_cols=editable_cols, values={},
        hint_fn=html_input_for, mode="new",
    )


@app.route("/tables/<name>/<pk>/edit", methods=["GET", "POST"])
def table_edit(name, pk):
    name = name.upper()
    meta = _require_table(name)
    if not meta["pk"]:
        flash(f"No primary key on {name}; edit unsupported", "error")
        return redirect(url_for("table_list", name=name))
    pk_col = meta["pk"][0]
    editable_cols = [
        c for c in meta["columns"] if c["name"] not in meta["identity"]
    ]

    if request.method == "POST":
        assignments = []
        values = {"__pk__": _coerce_pk(pk, meta)}
        for c in editable_cols:
            raw = request.form.get(c["name"])
            val = coerce_value(raw, c)
            assignments.append(f"{c['name']} = :{c['name']}")
            values[c["name"]] = val
        sql = (
            f"UPDATE {name} SET {', '.join(assignments)} "
            f"WHERE {pk_col} = :__pk__"
        )
        with current_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, values)
            conn.commit()
        flash(f"Updated {name} #{pk}.", "success")
        return redirect(url_for("table_list", name=name))

    # Load existing row
    col_names = [c["name"] for c in meta["columns"]]
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            f"SELECT {','.join(col_names)} FROM {name} "
            f"WHERE {pk_col} = :p",
            p=_coerce_pk(pk, meta),
        )
        row = cur.fetchone()
    if row is None:
        abort(404)
    values = {}
    for c, v in zip(meta["columns"], row):
        if v is None:
            values[c["name"]] = ""
        elif c["type"] == "DATE":
            values[c["name"]] = v.strftime("%Y-%m-%d") if v else ""
        else:
            values[c["name"]] = _display_cell(v)

    return render_template(
        "table_form.html", name=name, meta=meta,
        editable_cols=editable_cols, values=values,
        hint_fn=html_input_for, mode="edit", pk=pk, pk_col=pk_col,
    )


def _coerce_pk(pk, meta):
    pk_col_name = meta["pk"][0]
    col = next(c for c in meta["columns"] if c["name"] == pk_col_name)
    return coerce_value(pk, col)


@app.route("/tables/<name>/<pk>/delete", methods=["POST"])
def table_delete(name, pk):
    name = name.upper()
    meta = _require_table(name)
    if not meta["pk"]:
        flash(f"No primary key on {name}; delete unsupported", "error")
        return redirect(url_for("table_list", name=name))
    pk_col = meta["pk"][0]
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            f"DELETE FROM {name} WHERE {pk_col} = :p",
            p=_coerce_pk(pk, meta),
        )
        conn.commit()
    flash(f"Deleted {name} #{pk}.", "success")
    return redirect(url_for("table_list", name=name))


# ---------------------------------------------------------------------------
# Views (read-only)
# ---------------------------------------------------------------------------
@app.route("/views/<name>")
def view_show(name):
    name = name.upper()
    if name not in VIEWS:
        abort(404)
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {name} FETCH FIRST 500 ROWS ONLY")
        cols = [d[0] for d in cur.description]
        rows = [[_display_cell(v) for v in r] for r in cur.fetchall()]
    meta = VIEWS_META_BY_NAME.get(name)
    return render_template(
        "view_list.html", name=name, cols=cols, rows=rows, views=VIEWS,
        meta=meta, views_meta=VIEWS_META_BY_NAME,
    )


# ---------------------------------------------------------------------------
# Appointment-module flows (the demo story)
# ---------------------------------------------------------------------------

# Positive flows: link cards on the flows index page.
POSITIVE_FLOWS = [
    {
        "endpoint": "flow_book",
        "title": "Book appointment",
        "procedure": "sp_BookAppointment",
        "blurb": "Happy-path booking. Runs all four validations and inserts "
                 "a new Scheduled appointment.",
    },
    {
        "endpoint": "flow_reschedule",
        "title": "Reschedule appointment",
        "procedure": "sp_RescheduleAppointment",
        "blurb": "Move a Scheduled appointment to a new slot. Writes an "
                 "AppointmentHistory row with the caller-supplied reason.",
    },
    {
        "endpoint": "flow_cancel",
        "title": "Cancel appointment",
        "procedure": "sp_CancelAppointment",
        "blurb": "Cancel a Scheduled appointment at least 24 hours out. "
                 "trg_AppointmentHistory logs the status change.",
    },
    {
        "endpoint": "flow_complete",
        "title": "Complete + bill",
        "procedure": "sp_CompleteAppointment",
        "blurb": "Mark a Scheduled appointment Completed and set bill_amount. "
                 "trg_AppointmentInsDiscount computes insurance coverage.",
    },
    {
        "endpoint": "flow_availability",
        "title": "Check doctor availability",
        "procedure": "sp_GetDoctorAvailability",
        "blurb": "Read-only: list open slots for a doctor in a date range. "
                 "Excludes vacations and already-booked slots.",
    },
]

# Negative scenarios: each is a pre-canned call that triggers a specific
# validation error. Keys are the URL slug; descriptions drive the UI.
NEGATIVE_SCENARIOS = [
    {
        "key": "book-invalid-patient",
        "title": "Book with a non-existent patient",
        "procedure": "sp_BookAppointment",
        "rule": "Patient existence",
        "expected": "ORA-20001: Patient with ID 99999 does not exist.",
        "blurb": "Passes a patient_id that is not in the Patient table.",
    },
    {
        "key": "book-invalid-slot",
        "title": "Book on a non-existent / unavailable slot",
        "procedure": "sp_BookAppointment",
        "rule": "Schedule existence",
        "expected": "ORA-20002: Schedule slot with ID 99999 does not exist "
                    "or is not available.",
        "blurb": "Passes a schedule_id that does not exist in DoctorSchedule.",
    },
    {
        "key": "book-vacation",
        "title": "Book during doctor vacation",
        "procedure": "sp_BookAppointment",
        "rule": "BR5 (vacation blocking)",
        "expected": "ORA-20003: Doctor ... is on approved vacation on "
                    "2026-04-22.",
        "blurb": "Uses schedule slot 174 (Dr. David Kim, 2026-04-22 09:00), "
                 "which falls inside his approved 2026-04-21 to 2026-04-23 "
                 "vacation.",
    },
    {
        "key": "book-duplicate",
        "title": "Book a duplicate appointment",
        "procedure": "sp_BookAppointment",
        "rule": "BR1 / TV1 (duplicate booking)",
        "expected": "ORA-20004: A scheduled appointment already exists for "
                    "patient 21 at schedule slot 6.",
        "blurb": "Patient 21 already has a Scheduled appointment on "
                 "schedule slot 6 (seed data). Calling the procedure again "
                 "with the same pair triggers the duplicate check.",
    },
    {
        "key": "cancel-invalid",
        "title": "Cancel a non-existent appointment",
        "procedure": "sp_CancelAppointment",
        "rule": "Appointment existence",
        "expected": "ORA-20001: Appointment with ID 999999 does not exist "
                    "or is not in Scheduled status.",
        "blurb": "Passes an appointment_id that does not exist.",
    },
    {
        "key": "cancel-within-24h",
        "title": "Cancel within the 24-hour window",
        "procedure": "sp_CancelAppointment",
        "rule": "BR2 (24-hour cancellation rule)",
        "expected": "ORA-20002: ... Cancellations must be made at least "
                    "24 hours in advance.",
        "blurb": "Dynamically creates a schedule slot 30 minutes from now, "
                 "books an appointment on it, then tries to cancel - which "
                 "must fail. Cleanup removes both the appointment and slot.",
    },
    {
        "key": "reschedule-invalid-appt",
        "title": "Reschedule a non-existent appointment",
        "procedure": "sp_RescheduleAppointment",
        "rule": "Appointment existence",
        "expected": "ORA-20001: Appointment with ID 999999 does not exist "
                    "or is not in Scheduled status.",
        "blurb": "Passes an appointment_id that does not exist.",
    },
    {
        "key": "reschedule-invalid-slot",
        "title": "Reschedule to a non-existent slot",
        "procedure": "sp_RescheduleAppointment",
        "rule": "Schedule existence",
        "expected": "ORA-20002: New schedule slot with ID 999999 does not "
                    "exist or is not available.",
        "blurb": "Picks a live Scheduled appointment and tries to move it "
                 "to a schedule_id that does not exist.",
    },
    {
        "key": "reschedule-vacation",
        "title": "Reschedule into doctor vacation",
        "procedure": "sp_RescheduleAppointment",
        "rule": "BR5 (vacation blocking)",
        "expected": "ORA-20003: Doctor ... is on approved vacation on "
                    "2026-04-22.",
        "blurb": "Tries to reschedule a live Scheduled appointment onto "
                 "slot 174, which is inside Dr. David Kim's approved "
                 "vacation.",
    },
    {
        "key": "complete-invalid",
        "title": "Complete a non-existent appointment",
        "procedure": "sp_CompleteAppointment",
        "rule": "Appointment existence",
        "expected": "ORA-20001: Appointment with ID 999999 does not exist "
                    "or is not in Scheduled status.",
        "blurb": "Passes an appointment_id that does not exist.",
    },
]

NEGATIVE_SCENARIOS_BY_KEY = {s["key"]: s for s in NEGATIVE_SCENARIOS}


def _find_scheduled_appointment_id():
    """Return a currently-Scheduled appointment ID, or None."""
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT appointment_id FROM Appointment "
            "WHERE status = 'Scheduled' "
            "ORDER BY appointment_id FETCH FIRST 1 ROWS ONLY"
        )
        row = cur.fetchone()
        return int(row[0]) if row else None


def _find_free_scheduled_slot():
    """Any available, unbooked DoctorSchedule slot."""
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT ds.schedule_id
              FROM DoctorSchedule ds
             WHERE ds.is_available = 1
               AND NOT EXISTS (
                   SELECT 1 FROM Appointment a
                    WHERE a.schedule_id = ds.schedule_id
                      AND a.status = 'Scheduled'
               )
             ORDER BY ds.schedule_date, ds.slot_time
             FETCH FIRST 1 ROWS ONLY
            """
        )
        row = cur.fetchone()
        return int(row[0]) if row else None


def _exec_proc(name, params, call_str, notes):
    """Execute a procedure and capture error-or-success shape."""
    try:
        with current_conn() as conn:
            cur = conn.cursor()
            cur.callproc(name, params)
        return {
            "call": call_str,
            "outcome": "unexpected_success",
            "error_code": None,
            "error_message": None,
            "notes": notes,
        }
    except oracledb.DatabaseError as e:
        (err,) = e.args
        return {
            "call": call_str,
            "outcome": "error",
            "error_code": getattr(err, "code", None),
            "error_message": getattr(err, "message", str(err)).strip(),
            "notes": notes,
        }


def _run_negative_scenario(key):
    notes = []

    if key == "book-invalid-patient":
        slot = _find_free_scheduled_slot() or 1
        notes.append(f"Using free slot {slot} for the call.")
        with current_conn() as conn:
            out = conn.cursor().var(oracledb.NUMBER)
        return _exec_proc(
            "sp_BookAppointment",
            [99999, slot, "In-Person", "negative flow demo", out],
            f"sp_BookAppointment(99999, {slot}, 'In-Person', "
            f"'negative flow demo', OUT);",
            notes,
        )

    if key == "book-invalid-slot":
        with current_conn() as conn:
            out = conn.cursor().var(oracledb.NUMBER)
        return _exec_proc(
            "sp_BookAppointment",
            [21, 99999, "In-Person", "negative flow demo", out],
            "sp_BookAppointment(21, 99999, 'In-Person', "
            "'negative flow demo', OUT);",
            notes,
        )

    if key == "book-vacation":
        with current_conn() as conn:
            out = conn.cursor().var(oracledb.NUMBER)
        return _exec_proc(
            "sp_BookAppointment",
            [65, 174, "In-Person", "negative flow demo", out],
            "sp_BookAppointment(65, 174, 'In-Person', "
            "'negative flow demo', OUT);  -- slot 174 is during vacation",
            notes,
        )

    if key == "book-duplicate":
        with current_conn() as conn:
            cur = conn.cursor()
            cur.execute(
                "SELECT COUNT(*) FROM Appointment "
                "WHERE patient_id = 21 AND schedule_id = 6 "
                "AND status = 'Scheduled'"
            )
            if cur.fetchone()[0] == 0:
                notes.append(
                    "Precondition missing: no Scheduled appointment for "
                    "patient 21 on schedule slot 6 (seed data absent)."
                )
                return {
                    "call": "sp_BookAppointment(21, 6, ..., OUT);",
                    "outcome": "precondition_missing",
                    "error_code": None,
                    "error_message": None,
                    "notes": notes,
                }
            out = cur.var(oracledb.NUMBER)
        notes.append(
            "Precondition: patient 21 already has a Scheduled appointment "
            "on schedule slot 6 (confirmed)."
        )
        return _exec_proc(
            "sp_BookAppointment",
            [21, 6, "In-Person", "negative flow demo", out],
            "sp_BookAppointment(21, 6, 'In-Person', "
            "'negative flow demo', OUT);  -- duplicate",
            notes,
        )

    if key == "cancel-invalid":
        return _exec_proc(
            "sp_CancelAppointment",
            [999999, "negative flow demo"],
            "sp_CancelAppointment(999999, 'negative flow demo');",
            notes,
        )

    if key == "cancel-within-24h":
        import datetime as _dt
        schedule_id = None
        appt_id = None
        try:
            with current_conn() as conn:
                cur = conn.cursor()
                today = _dt.datetime.now().replace(
                    hour=0, minute=0, second=0, microsecond=0
                )
                slot_time = (
                    _dt.datetime.now() + _dt.timedelta(minutes=30)
                ).strftime("%H:%M")
                sched_var = cur.var(oracledb.NUMBER)
                cur.execute(
                    """
                    INSERT INTO DoctorSchedule
                        (employee_id, schedule_date, slot_time,
                         slot_duration_mins, is_available)
                    VALUES (1, :d, :t, 30, 1)
                    RETURNING schedule_id INTO :id
                    """,
                    d=today, t=slot_time, id=sched_var,
                )
                schedule_id = int(sched_var.getvalue())
                notes.append(
                    f"Created DoctorSchedule {schedule_id} for today at "
                    f"{slot_time} (30 min in the future)."
                )

                appt_var = cur.var(oracledb.NUMBER)
                cur.execute(
                    """
                    INSERT INTO Appointment
                        (patient_id, schedule_id, status, visit_type,
                         reason, created_at, updated_at)
                    VALUES (61, :s, 'Scheduled', 'In-Person',
                            'negative flow demo', SYSDATE, SYSDATE)
                    RETURNING appointment_id INTO :id
                    """,
                    s=schedule_id, id=appt_var,
                )
                appt_id = int(appt_var.getvalue())
                conn.commit()
                notes.append(f"Booked appointment {appt_id} on that slot.")

            return _exec_proc(
                "sp_CancelAppointment",
                [appt_id, "negative flow demo"],
                f"sp_CancelAppointment({appt_id}, 'negative flow demo');",
                notes,
            )
        finally:
            with current_conn() as conn:
                cur = conn.cursor()
                if appt_id is not None:
                    cur.execute(
                        "DELETE FROM Appointment "
                        "WHERE appointment_id = :a",
                        a=appt_id,
                    )
                if schedule_id is not None:
                    cur.execute(
                        "DELETE FROM DoctorSchedule "
                        "WHERE schedule_id = :s",
                        s=schedule_id,
                    )
                conn.commit()
            notes.append("Cleanup: removed test appointment and slot.")

    if key == "reschedule-invalid-appt":
        return _exec_proc(
            "sp_RescheduleAppointment",
            [999999, 10, "negative flow demo"],
            "sp_RescheduleAppointment(999999, 10, 'negative flow demo');",
            notes,
        )

    if key == "reschedule-invalid-slot":
        appt_id = _find_scheduled_appointment_id()
        if appt_id is None:
            notes.append(
                "No Scheduled appointments exist; cannot run this scenario."
            )
            return {
                "call": "sp_RescheduleAppointment(?, 999999, ...);",
                "outcome": "precondition_missing",
                "error_code": None,
                "error_message": None,
                "notes": notes,
            }
        notes.append(f"Using live Scheduled appointment {appt_id}.")
        return _exec_proc(
            "sp_RescheduleAppointment",
            [appt_id, 999999, "negative flow demo"],
            f"sp_RescheduleAppointment({appt_id}, 999999, "
            f"'negative flow demo');",
            notes,
        )

    if key == "reschedule-vacation":
        appt_id = _find_scheduled_appointment_id()
        if appt_id is None:
            notes.append(
                "No Scheduled appointments exist; cannot run this scenario."
            )
            return {
                "call": "sp_RescheduleAppointment(?, 174, ...);",
                "outcome": "precondition_missing",
                "error_code": None,
                "error_message": None,
                "notes": notes,
            }
        notes.append(
            f"Using live Scheduled appointment {appt_id}. Target slot 174 "
            f"is during Dr. David Kim's approved vacation."
        )
        return _exec_proc(
            "sp_RescheduleAppointment",
            [appt_id, 174, "negative flow demo"],
            f"sp_RescheduleAppointment({appt_id}, 174, "
            f"'negative flow demo');",
            notes,
        )

    if key == "complete-invalid":
        return _exec_proc(
            "sp_CompleteAppointment",
            [999999, "negative flow demo", 100],
            "sp_CompleteAppointment(999999, 'negative flow demo', 100);",
            notes,
        )

    abort(404)


def _list_patients():
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT patient_id, first_name || ' ' || last_name "
            "FROM Patient ORDER BY patient_id"
        )
        return cur.fetchall()


def _list_doctors():
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT employee_id, first_name || ' ' || last_name "
            "FROM Employee WHERE employee_type = 'Doctor' ORDER BY employee_id"
        )
        return cur.fetchall()


def _list_unbooked_schedule_slots(limit=200):
    """Future slots (is_available=1) with no Scheduled appointment yet."""
    with current_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            f"""
            SELECT ds.schedule_id,
                   e.first_name || ' ' || e.last_name AS doctor_name,
                   TO_CHAR(ds.schedule_date, 'YYYY-MM-DD') AS d,
                   ds.slot_time
              FROM DoctorSchedule ds
              JOIN Employee e ON e.employee_id = ds.employee_id
             WHERE ds.is_available = 1
               AND NOT EXISTS (
                   SELECT 1 FROM Appointment a
                    WHERE a.schedule_id = ds.schedule_id
                      AND a.status = 'Scheduled'
               )
             ORDER BY ds.schedule_date, ds.slot_time
             FETCH FIRST {int(limit)} ROWS ONLY
            """
        )
        return cur.fetchall()


# -- Flows index -------------------------------------------------------------
@app.route("/flows")
def flows_index():
    return render_template(
        "flows/index.html",
        positive=POSITIVE_FLOWS,
        negative=NEGATIVE_SCENARIOS,
    )


# -- Book appointment --------------------------------------------------------
@app.route("/flows/book", methods=["GET", "POST"])
def flow_book():
    if request.method == "POST":
        patient_id = int(request.form["patient_id"])
        schedule_id = int(request.form["schedule_id"])
        visit_type = request.form["visit_type"]
        reason = request.form.get("reason") or None

        with current_conn() as conn:
            cur = conn.cursor()
            appt_var = cur.var(oracledb.NUMBER)
            cur.callproc(
                "sp_BookAppointment",
                [patient_id, schedule_id, visit_type, reason, appt_var],
            )
            new_id = int(appt_var.getvalue())
        flash(f"Booked appointment {new_id}.", "success")
        return redirect(url_for("table_list", name="APPOINTMENT"))

    return render_template(
        "flows/book.html",
        patients=_list_patients(),
        slots=_list_unbooked_schedule_slots(),
    )


# -- Cancel ------------------------------------------------------------------
@app.route("/flows/cancel", methods=["GET", "POST"])
def flow_cancel():
    if request.method == "POST":
        appt_id = int(request.form["appointment_id"])
        reason = request.form.get("reason") or ""
        with current_conn() as conn:
            cur = conn.cursor()
            cur.callproc("sp_CancelAppointment", [appt_id, reason])
        flash(f"Cancelled appointment {appt_id}.", "success")
        return redirect(url_for("table_list", name="APPOINTMENT"))

    return render_template("flows/cancel.html")


# -- Reschedule --------------------------------------------------------------
@app.route("/flows/reschedule", methods=["GET", "POST"])
def flow_reschedule():
    if request.method == "POST":
        appt_id = int(request.form["appointment_id"])
        new_sched = int(request.form["new_schedule_id"])
        reason = request.form.get("reason") or ""
        with current_conn() as conn:
            cur = conn.cursor()
            cur.callproc(
                "sp_RescheduleAppointment", [appt_id, new_sched, reason]
            )
        flash(
            f"Rescheduled appointment {appt_id} to slot {new_sched}.",
            "success",
        )
        return redirect(url_for("table_list", name="APPOINTMENT"))

    return render_template(
        "flows/reschedule.html", slots=_list_unbooked_schedule_slots()
    )


# -- Complete (demonstrates insurance-discount trigger) ---------------------
@app.route("/flows/complete", methods=["GET", "POST"])
def flow_complete():
    result = None
    if request.method == "POST":
        appt_id = int(request.form["appointment_id"])
        notes = request.form.get("notes") or None
        bill_amount = float(request.form["bill_amount"])
        with current_conn() as conn:
            cur = conn.cursor()
            cur.callproc(
                "sp_CompleteAppointment", [appt_id, notes, bill_amount]
            )
            cur.execute(
                """
                SELECT appointment_id, status, bill_amount,
                       insurance_coverage_amt, billing_status,
                       billing_date, due_date
                  FROM Appointment WHERE appointment_id = :a
                """,
                a=appt_id,
            )
            r = cur.fetchone()
        if r:
            result = {
                "appointment_id": r[0],
                "status": r[1],
                "bill_amount": r[2],
                "insurance_coverage_amt": r[3],
                "billing_status": r[4],
                "billing_date": r[5].strftime("%Y-%m-%d") if r[5] else "",
                "due_date": r[6].strftime("%Y-%m-%d") if r[6] else "",
            }
        flash(
            f"Completed appointment {appt_id}. "
            f"Trigger computed insurance coverage = "
            f"${result['insurance_coverage_amt'] if result else '?'}.",
            "success",
        )

    return render_template("flows/complete.html", result=result)


# -- Check doctor availability (positive, read-only) ------------------------
@app.route("/flows/availability", methods=["GET", "POST"])
def flow_availability():
    result_rows = None
    form = {"employee_id": "", "start_date": "", "end_date": ""}

    if request.method == "POST":
        form["employee_id"] = request.form["employee_id"]
        form["start_date"] = request.form["start_date"]
        form["end_date"] = request.form["end_date"]

        import datetime as _dt
        emp_id = int(form["employee_id"])
        start_date = _dt.datetime.strptime(form["start_date"], "%Y-%m-%d")
        end_date = _dt.datetime.strptime(form["end_date"], "%Y-%m-%d")

        with current_conn() as conn:
            cur = conn.cursor()
            ref_cur = cur.var(oracledb.CURSOR)
            cur.callproc(
                "sp_GetDoctorAvailability",
                [emp_id, start_date, end_date, ref_cur],
            )
            inner = ref_cur.getvalue()
            raw = inner.fetchall()
            cols = [d[0] for d in inner.description]
            result_rows = {"cols": cols, "rows": [
                [_display_cell(v) for v in r] for r in raw
            ]}

    return render_template(
        "flows/availability.html",
        doctors=_list_doctors(),
        result=result_rows,
        form=form,
    )


# -- Negative scenarios (one-click demos of every validation error) ---------
@app.route("/flows/negative/<scenario>", methods=["GET", "POST"])
def flow_negative(scenario):
    meta = NEGATIVE_SCENARIOS_BY_KEY.get(scenario)
    if meta is None:
        abort(404)
    result = None
    if request.method == "POST":
        result = _run_negative_scenario(scenario)
    return render_template(
        "flows/negative.html", meta=meta, result=result, scenario=scenario,
    )


# ---------------------------------------------------------------------------
# Docs (read-only reference page for procs/functions/triggers/reports)
# ---------------------------------------------------------------------------
@app.route("/docs")
def docs():
    tab = request.args.get("tab", "procedures").lower()
    if tab not in {"procedures", "functions", "triggers", "reports"}:
        tab = "procedures"
    return render_template("docs.html", tab=tab)


@app.route("/rules")
def rules():
    return render_template("rules.html")


@app.route("/tests")
def tests():
    return render_template("tests.html")


# ---------------------------------------------------------------------------
# Reports (execute saved SQL files and render results)
# ---------------------------------------------------------------------------
REPORTS_DIR = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "Reports")
)

REPORTS = [
    {
        "name": "rpt_DailyAppointments",
        "title": "Daily Appointments",
        "description": (
            "All appointments on a given date with patient, doctor, "
            "department, and slot details."
        ),
        "parameters": "report_date (default 2026-04-14)",
    },
    {
        "name": "rpt_DoctorSchedule",
        "title": "Doctor Schedule",
        "description": (
            "Per-doctor slots in a date range with current booking counts "
            "and vacation flags."
        ),
        "parameters": "start_date, end_date (default 2026-04-01 → 2026-04-30)",
    },
    {
        "name": "rpt_BedOccupancy",
        "title": "Bed Occupancy",
        "description": (
            "Every bed with its current status and patient, plus a "
            "hospital-wide occupancy rollup."
        ),
        "parameters": "none",
    },
    {
        "name": "rpt_Revenue",
        "title": "Revenue",
        "description": (
            "Total billed, insurance coverage, collections, and "
            "outstanding balance — overall, by source, and by "
            "billing status."
        ),
        "parameters": "start_date, end_date (default 2026-01-01 → 2026-04-30)",
    },
    {
        "name": "rpt_CancellationStats",
        "title": "Cancellation Stats",
        "description": (
            "Per-doctor cancellation rate, most common reason, and "
            "average lead time."
        ),
        "parameters": "start_date, end_date (default 2026-01-01 → 2026-04-30)",
    },
]

REPORTS_BY_NAME = {r["name"]: r for r in REPORTS}


def _split_report_sql(text: str) -> list:
    """Strip SQL line comments and split into individual statements by ';'.

    Returns a list of (label, sql) tuples. The label is extracted from a
    comment of the form '-- Query N: Title' that appears above the statement;
    if no label is found, 'Result N' is used.
    """
    statements: list[tuple[str, str]] = []
    current_label: str | None = None
    pending_label: str | None = None
    buffer: list[str] = []

    # Match labels like: "-- Query 1: Overall Revenue Summary"
    label_re = re.compile(
        r"^\s*--+\s*(Query\s+\d+\s*[:\-]\s*.+|Detailed .+|Occupancy .+)\s*$",
        re.IGNORECASE,
    )

    def flush():
        nonlocal current_label, buffer
        stmt = "".join(buffer).strip()
        if stmt:
            label = current_label or f"Result {len(statements) + 1}"
            statements.append((label, stmt))
        buffer = []

    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        if not stripped:
            if buffer:
                buffer.append(line)
            continue

        if stripped.startswith("--"):
            m = label_re.match(stripped)
            if m:
                pending_label = m.group(1).strip().rstrip(".")
            continue

        if pending_label is not None and not buffer:
            current_label = pending_label
            pending_label = None

        buffer.append(line)
        # If the statement terminates on this line, flush
        if ";" in line:
            sql_joined = "".join(buffer)
            idx = sql_joined.rfind(";")
            stmt = sql_joined[:idx].strip()
            if stmt:
                label = current_label or f"Result {len(statements) + 1}"
                statements.append((label, stmt))
            buffer = []
            current_label = None

    flush()
    return statements


def _run_report(name: str) -> list:
    path = os.path.join(REPORTS_DIR, f"{name}.sql")
    if not os.path.isfile(path):
        abort(404)
    with open(path, encoding="utf-8") as f:
        raw_sql = f.read()

    queries = _split_report_sql(raw_sql)
    results = []
    with current_conn() as conn:
        cur = conn.cursor()
        for label, stmt in queries:
            try:
                cur.execute(stmt)
                cols = [d[0] for d in cur.description] if cur.description else []
                rows = [
                    [_display_cell(v) for v in r] for r in cur.fetchall()
                ]
                results.append({
                    "label": label,
                    "cols": cols,
                    "rows": rows,
                    "error": None,
                    "sql": stmt,
                })
            except oracledb.DatabaseError as e:
                (err,) = e.args
                results.append({
                    "label": label,
                    "cols": [],
                    "rows": [],
                    "error": getattr(err, "message", str(err)),
                    "sql": stmt,
                })
    return results


@app.route("/reports")
def reports_index():
    return render_template("reports_index.html", reports=REPORTS)


@app.route("/reports/<name>")
def reports_show(name):
    meta = REPORTS_BY_NAME.get(name)
    if meta is None:
        abort(404)
    results = _run_report(name)
    return render_template(
        "reports_show.html", meta=meta, results=results, reports=REPORTS,
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050, debug=True)
