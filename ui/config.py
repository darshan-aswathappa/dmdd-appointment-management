"""Database configuration for the HMS  UI.

Connects to Oracle Autonomous Database via wallet (mTLS) using
python-oracledb's thin mode — no Instant Client required.

If you move the wallet or rotate credentials, change the values below.
"""

# DB user credentials live in db.DB_USERS now (supports multi-user toggle).

# -- Autonomous DB connection ------------------------------------------------
# TNS alias from tnsnames.ora inside the wallet.
#   _tp        -> Transaction Processing (recommended for OLTP apps)
#   _tpurgent  -> TP with highest priority (pricier connection slots)
#   _high / _medium / _low -> Analytics-style, parallel query
DB_DSN = "rsc9f2o9gywzt7xi_tp"

# -- Wallet location ---------------------------------------------------------
# Directory containing the extracted wallet files
# (tnsnames.ora, sqlnet.ora, cwallet.sso, ewallet.pem, ewallet.p12, ...).
WALLET_DIR = "/Users/nireekshahuns/Desktop/Wallet_RSC9F2O9GYWZT7XI"

# Password you set when you downloaded the wallet from OCI.
WALLET_PASSWORD = "Darshan5579!@#"
