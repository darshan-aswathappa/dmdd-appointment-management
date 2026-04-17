# HMS UI

Minimal Flask UI over the revamped Hospital Management System schema.
Gives you:

- **Dashboard** with row counts and quick links.
- **CRUD on all 13 tables** (Insurance, Department, Employee, Patient,
  DoctorSchedule, DoctorVacation, Appointment, AppointmentHistory, Room,
  Bed, Admission, Prescription, Payment). Forms are auto-generated from
  Oracle metadata — nullable / NOT NULL / types all detected at startup.
- **6 demo flow pages** that exercise the revamped stored procedures
  and triggers:
  - Book appointment → `sp_BookAppointment`
  - Cancel appointment → `sp_CancelAppointment` (BR2 24-hour rule)
  - Reschedule → `sp_RescheduleAppointment` (BR3 history)
  - Complete + bill → `sp_CompleteAppointment` (fires `trg_AppointmentInsDiscount`)
  - Admit patient → INSERT Admission (fires `trg_PreventOccupiedBed`)
  - Record payment → INSERT Payment (XOR appointment/admission)
- **View browser** for `v_appointment`, `v_doctor_schedule`,
  `v_prescription`, `v_billing`, `v_payment`, `v_bed_status`.

No login, no session management, no user accounts. Intended for local
use only to poke at the database.

## Requirements

- Python 3.10+
- Oracle Database 12.2+ reachable at `localhost:1521/XEPDB1`
- The HMS schema fully created and seeded (see
  `../MASTER_EXECUTION_GUIDE.sql`).

## Setup

```bash
cd ui
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

If your HMS password or DSN is different from the default in
`config.py`, edit that file before running.

## Run

```bash
python app.py
```

Then open <http://127.0.0.1:5050/>.

## Notes

- Uses `python-oracledb` in **thin mode** — no Oracle Instant Client
  install required.
- Each HTTP request opens a fresh connection (no pool). Fine for local
  use; not for production.
- Identity columns (`employee_id`, `appointment_id`, etc.) are hidden
  in insert forms so Oracle can auto-generate them. For this to work
  the identity columns must be `GENERATED ALWAYS AS IDENTITY` after the
  initial seed — see the `START WITH LIMIT VALUE` step in the master
  guide.
- Oracle errors (unique constraint violations, check constraint
  failures, raised `ORA-20xxx` from procedures) are caught and shown as
  red flash banners at the top of the page.

## File map

```
ui/
├── app.py              # Flask routes
├── db.py               # Connection + metadata helpers
├── config.py           # DB credentials (edit for your environment)
├── requirements.txt
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── table_list.html
│   ├── table_form.html
│   ├── view_list.html
│   └── flows/
│       ├── book.html
│       ├── cancel.html
│       ├── reschedule.html
│       ├── complete.html
│       ├── admit.html
│       └── pay.html
└── static/
    └── style.css
```
