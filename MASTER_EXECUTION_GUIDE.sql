-- ============================================================================
--
--  HOSPITAL MANAGEMENT SYSTEM — MASTER EXECUTION GUIDE
--  Target: Oracle Database 12c+ (12.2 or later)
--  Course: DMDD 6210
--  Team:   Darshan Aswathappa, Nireeksha Huns
--
--  This file is NOT meant to be run as a single script.
--  Follow each step manually in SQL Developer or SQL*Plus.
--
-- ============================================================================


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗     ██████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ██╔═████╗
-- ██████╔╝███████║███████║███████╗█████╗      ██║██╔██║
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ████╔╝██║
-- ██║     ██║  ██║██║  ██║███████║███████╗     ╚██████╔╝
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═════╝
-- PHASE 0: CONNECT AS DBA (SYS or SYSTEM)
-- ============================================================================

-- STEP 0.1: Open SQL Developer (or SQL*Plus)
-- STEP 0.2: Create a new connection:
--     Connection Name: SYS_DBA
--     Username:        SYS
--     Password:        <your SYS password>
--     Role:            SYSDBA
--     Hostname:        localhost (or your server)
--     Port:            1521
--     Service Name:    XEPDB1 (or ORCL, or your PDB name)
--
-- If using SQL*Plus from terminal:
--     sqlplus sys/<password>@localhost:1521/XEPDB1 as sysdba


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗     ██╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ███║
-- ██████╔╝███████║███████║███████╗█████╗      ╚██║
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝       ██║
-- ██║     ██║  ██║██║  ██║███████║███████╗      ██║
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═╝
-- PHASE 1: CREATE USERS AND ROLES (Run as SYS/SYSTEM DBA)
-- ============================================================================

-- -------------------------------------------
-- STEP 1.1: Create the HMS schema owner user
-- -------------------------------------------
-- This user OWNS all hospital tables, views, procedures, triggers.
-- Think of HMS as the "database" — in Oracle, a user IS a schema.

CREATE USER HMS IDENTIFIED BY "HospitalMS@Pass123"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;

-- Grant privileges so HMS can create objects
GRANT CREATE SESSION   TO HMS;
GRANT CREATE TABLE     TO HMS;
GRANT CREATE VIEW      TO HMS;
GRANT CREATE PROCEDURE TO HMS;
GRANT CREATE TRIGGER   TO HMS;
GRANT CREATE SEQUENCE  TO HMS;
GRANT UNLIMITED TABLESPACE TO HMS;

-- -------------------------------------------
-- STEP 1.2: Create application users
-- -------------------------------------------
-- admin_user:    Will get full CRUD access (HospitalAdmin role)
-- operator_user: Will get SELECT + EXECUTE access (HospitalOperator role)

CREATE USER admin_user IDENTIFIED BY "AdminPass123"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO admin_user;

CREATE USER operator_user IDENTIFIED BY "OperatorPass456"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO operator_user;

-- -------------------------------------------
-- STEP 1.3: Verify users were created
-- -------------------------------------------
SELECT username, account_status, created
FROM dba_users
WHERE username IN ('HMS', 'ADMIN_USER', 'OPERATOR_USER')
ORDER BY username;
-- Expected: 3 rows, all OPEN status

-- ============================================================================
-- NOTE: You can also just run the script file:
--   @DDL/01_create_database.sql
--   @DDL/02_create_schemas.sql
-- But change passwords to match what you set above.
-- ============================================================================


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗    ██████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ╚════██╗
-- ██████╔╝███████║███████║███████╗█████╗       █████╔╝
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ╚═══██╗
-- ██║     ██║  ██║██║  ██║███████║███████╗    ██████╔╝
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝
-- PHASE 2: CREATE TABLES (Run as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 2.0: DISCONNECT from SYS. Reconnect as HMS.
-- -------------------------------------------
-- In SQL Developer: Create new connection:
--     Connection Name: HMS
--     Username:        HMS
--     Password:        HmsPass123
--     Hostname:        localhost
--     Port:            1521
--     Service Name:    XEPDB1
--
-- In SQL*Plus:
--     CONNECT HMS/"HmsPass123"@localhost:1521/XEPDB1

-- -------------------------------------------
-- STEP 2.1: Run the table creation script
-- -------------------------------------------
-- Open and run: DDL/03_create_tables.sql
-- This creates all 15+ tables in dependency order.
--
-- In SQL*Plus you can run:
--     @DDL/03_create_tables.sql

-- -------------------------------------------
-- STEP 2.2: Verify tables
-- -------------------------------------------
SELECT table_name FROM user_tables ORDER BY table_name;
-- Expected output (15+ tables):
--   ADMISSION
--   APPOINTMENT
--   APPOINTMENTHISTORY
--   BED
--   BILLING
--   DEPARTMENT
--   DOCTOR
--   DOCTORSCHEDULE
--   DOCTORVACATION
--   INSURANCE
--   PATIENT
--   PAYMENT
--   PRESCRIPTION
--   ROOM
--   STAFF

-- -------------------------------------------
-- STEP 2.3: Verify constraints
-- -------------------------------------------
SELECT constraint_name, constraint_type, table_name
FROM user_constraints
WHERE constraint_type IN ('P', 'R', 'U', 'C')
ORDER BY table_name, constraint_type;
-- P = Primary Key, R = Foreign Key, U = Unique, C = Check


-- ============================================================================
-- PHASE 2B: CREATE INDEXES (Still as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 2.4: Run the index creation script
-- -------------------------------------------
-- Open and run: DDL/04_create_indexes.sql

-- Verify:
SELECT index_name, table_name, uniqueness
FROM user_indexes
WHERE index_name LIKE 'IX_%'
ORDER BY table_name, index_name;


-- ============================================================================
-- PHASE 2C: CREATE VIEWS (Still as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 2.5: Run the views creation script
-- -------------------------------------------
-- Open and run: DDL/05_create_views.sql

-- Verify:
SELECT view_name FROM user_views ORDER BY view_name;
-- Expected: V_APPOINTMENT, V_BED_STATUS, V_BILLING,
--           V_DOCTOR_SCHEDULE, V_PAYMENT, V_PRESCRIPTION


-- ============================================================================
-- PHASE 2D: CREATE ROLES AND GRANT PERMISSIONS
-- ============================================================================

-- -------------------------------------------
-- STEP 2.6: DISCONNECT from HMS. Reconnect as SYS (DBA).
-- -------------------------------------------
-- The GRANT statements reference HMS-owned tables, so we need
-- to prefix them or run as HMS with GRANT OPTION.
--
-- IMPORTANT: The security script grants on bare table names.
-- These grants must be run AS the HMS user (who owns the tables)
-- OR the DBA must prefix: GRANT SELECT ON HMS.Insurance TO ...
--
-- RECOMMENDED: Run as HMS user instead, since HMS owns the objects.

-- -------------------------------------------
-- STEP 2.7: Reconnect as HMS, then run security script
-- -------------------------------------------
-- Open and run: DDL/06_create_roles_security.sql
--
-- NOTE: If you get "insufficient privileges" on CREATE ROLE,
-- reconnect as SYS and run just the CREATE ROLE lines:
--     CREATE ROLE HospitalAdmin;
--     CREATE ROLE HospitalOperator;
-- Then reconnect as HMS and run the GRANT lines.
-- Then as SYS run the ALTER USER and GRANT role TO user lines.

-- ALTERNATIVE: Run the entire file as SYS but prefix table names:
-- (The provided script already handles this correctly)

-- -------------------------------------------
-- STEP 2.8: Verify roles and grants
-- -------------------------------------------
-- Run as SYS/DBA:
SELECT grantee, granted_role
FROM dba_role_privs
WHERE granted_role IN ('HOSPITALADMIN', 'HOSPITALOPERATOR')
ORDER BY grantee;
-- Expected:
--   ADMIN_USER     HOSPITALADMIN
--   OPERATOR_USER  HOSPITALOPERATOR

SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE grantee IN ('HOSPITALADMIN', 'HOSPITALOPERATOR')
ORDER BY grantee, table_name, privilege;


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗    ██████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ╚════██╗
-- ██████╔╝███████║███████║███████╗█████╗       █████╔╝
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝       ╚═══██╗
-- ██║     ██║  ██║██║  ██║███████║███████╗    ██████╔╝
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝
-- PHASE 3: SEED DATA (Run as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 3.0: Connect as HMS user
-- -------------------------------------------

-- -------------------------------------------
-- STEP 3.1: CRITICAL — Alter identity columns for seeding
-- -------------------------------------------
-- Our seed scripts insert EXPLICIT IDs (e.g., department_id = 1, 2, 3...).
-- Oracle's GENERATED ALWAYS AS IDENTITY rejects explicit values.
-- We must temporarily switch to GENERATED BY DEFAULT.

ALTER TABLE Insurance         MODIFY (insurance_id     GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Department        MODIFY (department_id    GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Employee          MODIFY (employee_id      GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Patient           MODIFY (patient_id       GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE DoctorSchedule    MODIFY (schedule_id      GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE DoctorVacation    MODIFY (vacation_id      GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Appointment       MODIFY (appointment_id   GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE AppointmentHistory MODIFY (history_id      GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Room              MODIFY (room_id          GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Bed               MODIFY (bed_id           GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Admission         MODIFY (admission_id     GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Prescription      MODIFY (prescription_id  GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE Payment           MODIFY (payment_id       GENERATED BY DEFAULT ON NULL AS IDENTITY);

-- -------------------------------------------
-- STEP 3.2: Run seed scripts IN THIS EXACT ORDER
-- -------------------------------------------
-- Each script depends on data from the previous one (FK references).
-- Run each file one at a time and verify before moving to the next.

-- SCRIPT 1: Departments (8 rows)
-- @DML/01_seed_departments.sql
-- Verify:
SELECT COUNT(*) AS dept_count FROM Department;  -- Expected: 8

-- SCRIPT 2: Employees (Doctors + Staff) + Schedules + Vacations
--           15 doctors + 24 staff, 205 schedules, 6 vacations
-- @DML/02_seed_employees.sql
-- Verify:
SELECT employee_type, COUNT(*) FROM Employee GROUP BY employee_type ORDER BY 1;
-- Expected: Administrative Assistant=4, Doctor=15, Lab Technician=4,
--           Nurse=8, Pharmacist=4, Receptionist=4
SELECT COUNT(*) AS schedule_count FROM DoctorSchedule;  -- Expected: 205
SELECT COUNT(*) AS vacation_count FROM DoctorVacation;  -- Expected: 6

-- (Former SCRIPT 3 / 03_seed_staff.sql has been merged into
--  02_seed_employees.sql as part of the revamp and no longer exists.)

-- SCRIPT 4: Insurance + Patients (35 insurance, 200 patients)
-- @DML/04_seed_patients.sql
-- Verify:
SELECT COUNT(*) AS insurance_count FROM Insurance;  -- Expected: 35
SELECT COUNT(*) AS patient_count FROM Patient;      -- Expected: 200

-- SCRIPT 5: Rooms + Beds (50 rooms, 75 beds)
-- @DML/05_seed_rooms_beds.sql
-- Verify:
SELECT COUNT(*) AS room_count FROM Room;  -- Expected: 50
SELECT COUNT(*) AS bed_count FROM Bed;    -- Expected: 75

-- SCRIPT 6: Appointments (50 rows)
-- @DML/06_seed_appointments.sql
-- Verify:
SELECT status, COUNT(*) AS cnt FROM Appointment GROUP BY status ORDER BY status;
-- Expected: Cancelled=7, Completed=10, No-Show=3, Scheduled=30

-- SCRIPT 7: Admissions (10 rows)
-- @DML/07_seed_admissions.sql
-- Verify:
SELECT status, COUNT(*) AS cnt FROM Admission GROUP BY status;
-- Expected: Active=6, Discharged=4

-- SCRIPT 8: Prescriptions (35 rows)
-- @DML/08_seed_prescriptions.sql
-- Verify:
SELECT COUNT(*) AS rx_count FROM Prescription;  -- Expected: 35

-- SCRIPT 9: Payments (52 rows). Billing is now embedded in Appointment
--           and Admission; bill counts come from v_billing.
-- @DML/09_seed_payments.sql
-- Verify:
SELECT COUNT(*) AS bill_count FROM v_billing;   -- Expected: ~30 (appt bills + admission bills)
SELECT COUNT(*) AS payment_count FROM Payment;  -- Expected: 52

-- -------------------------------------------
-- STEP 3.3: Restore identity columns to ALWAYS
-- -------------------------------------------
-- Now that seeding is done, lock down identity columns so future
-- inserts auto-generate IDs (stored procedures use RETURNING INTO).

ALTER TABLE Insurance         MODIFY (insurance_id     GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Department        MODIFY (department_id    GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Employee          MODIFY (employee_id      GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Patient           MODIFY (patient_id       GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE DoctorSchedule    MODIFY (schedule_id      GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE DoctorVacation    MODIFY (vacation_id      GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Appointment       MODIFY (appointment_id   GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE AppointmentHistory MODIFY (history_id      GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Room              MODIFY (room_id          GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Bed               MODIFY (bed_id           GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Admission         MODIFY (admission_id     GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Prescription      MODIFY (prescription_id  GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);
ALTER TABLE Payment           MODIFY (payment_id       GENERATED ALWAYS AS IDENTITY START WITH LIMIT VALUE);

-- -------------------------------------------
-- STEP 3.4: Full data verification
-- -------------------------------------------
SELECT 'Department'     AS entity, COUNT(*) AS cnt FROM Department      UNION ALL
SELECT 'Employee',      COUNT(*) FROM Employee                          UNION ALL
SELECT 'Insurance',     COUNT(*) FROM Insurance                         UNION ALL
SELECT 'Patient',       COUNT(*) FROM Patient                           UNION ALL
SELECT 'DoctorSchedule', COUNT(*) FROM DoctorSchedule                   UNION ALL
SELECT 'DoctorVacation', COUNT(*) FROM DoctorVacation                   UNION ALL
SELECT 'Room',          COUNT(*) FROM Room                              UNION ALL
SELECT 'Bed',           COUNT(*) FROM Bed                               UNION ALL
SELECT 'Appointment',   COUNT(*) FROM Appointment                       UNION ALL
SELECT 'Admission',     COUNT(*) FROM Admission                         UNION ALL
SELECT 'Prescription',  COUNT(*) FROM Prescription                      UNION ALL
SELECT 'Payment',       COUNT(*) FROM Payment
ORDER BY 1;


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗    ██╗  ██╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ██║  ██║
-- ██████╔╝███████║███████║███████╗█████╗      ███████║
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ╚════██║
-- ██║     ██║  ██║██║  ██║███████║███████╗          ██║
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝          ╚═╝
-- PHASE 4: FUNCTIONS AND STORED PROCEDURES (Run as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 4.1: Create FUNCTIONS first (procedures depend on these)
-- -------------------------------------------

-- @Procedures/fn_IsDoctorOnVacation.sql
-- (fn_GetDoctorDailyCount was removed in the revamp along with BR4.)

-- Verify functions compiled:
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type = 'FUNCTION'
ORDER BY object_name;
-- Expected: FN_ISDOCTORONVACATION (VALID)
-- If status = INVALID, check errors:
--   SHOW ERRORS FUNCTION fn_IsDoctorOnVacation;

-- -------------------------------------------
-- STEP 4.2: Create STORED PROCEDURES
-- -------------------------------------------

-- @Procedures/sp_BookAppointment.sql
-- @Procedures/sp_CancelAppointment.sql
-- @Procedures/sp_RescheduleAppointment.sql
-- @Procedures/sp_GetDoctorAvailability.sql
-- @Procedures/sp_CompleteAppointment.sql

-- Verify procedures compiled:
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
ORDER BY object_name;
-- Expected: 5 procedures, all VALID
-- If any are INVALID:
--   SHOW ERRORS PROCEDURE sp_BookAppointment;

-- -------------------------------------------
-- STEP 4.3: Quick test — book an appointment
-- -------------------------------------------
SET SERVEROUTPUT ON;

DECLARE
    v_appt_id NUMBER;
BEGIN
    sp_BookAppointment(
        p_patient_id     => 51,       -- patient not already booked
        p_schedule_id    => 10,       -- a valid future schedule slot
        p_visit_type     => 'In-Person',
        p_reason         => 'Test booking from master guide',
        p_appointment_id => v_appt_id
    );
    DBMS_OUTPUT.PUT_LINE('Booking successful! Appointment ID: ' || v_appt_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- If successful, clean up the test row:
-- DELETE FROM Appointment WHERE reason = 'Test booking from master guide';
-- COMMIT;


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗    ███████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ██╔════╝
-- ██████╔╝███████║███████║███████╗█████╗      ███████╗
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ╚════██║
-- ██║     ██║  ██║██║  ██║███████║███████╗    ███████║
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝
-- PHASE 5: TRIGGERS (Run as HMS user)
-- ============================================================================

-- -------------------------------------------
-- STEP 5.1: Create all 3 triggers
-- -------------------------------------------

-- @Triggers/trg_AppointmentHistory.sql        (AFTER UPDATE on Appointment)
-- @Triggers/trg_PreventOccupiedBed.sql        (BEFORE INSERT on Admission)
-- @Triggers/trg_AppointmentInsDiscount.sql    (BEFORE UPDATE OF bill_amount on Appointment)
-- @Triggers/trg_AdmissionInsDiscount.sql      (BEFORE UPDATE OF bill_amount on Admission)

-- Verify:
SELECT trigger_name, table_name, triggering_event, status
FROM user_triggers
ORDER BY trigger_name;
-- Expected: 4 triggers, all ENABLED
-- If INVALID:
--   SHOW ERRORS TRIGGER trg_AppointmentHistory;


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗     ██████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ██╔════╝
-- ██████╔╝███████║███████║███████╗█████╗      ███████╗
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ██╔═══██╗
-- ██║     ██║  ██║██║  ██║███████║███████╗    ╚██████╔╝
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝
-- PHASE 6: GRANT EXECUTE ON PROCEDURES TO ROLES (Run as HMS user)
-- ============================================================================

-- Procedures need explicit EXECUTE grants. Admin gets them; operator
-- does NOT - operator is intentionally read-only so that attempting to
-- run an appointment flow as operator raises ORA-06550 / ORA-00942 and
-- the UI can demonstrate the permission boundary.

GRANT EXECUTE ON sp_BookAppointment       TO HospitalAdmin;
GRANT EXECUTE ON sp_CancelAppointment     TO HospitalAdmin;
GRANT EXECUTE ON sp_RescheduleAppointment TO HospitalAdmin;
GRANT EXECUTE ON sp_GetDoctorAvailability TO HospitalAdmin;
GRANT EXECUTE ON sp_CompleteAppointment   TO HospitalAdmin;
GRANT EXECUTE ON fn_IsDoctorOnVacation    TO HospitalAdmin;

-- Clean up any EXECUTE grants that an earlier version of this script may
-- have leaked to HospitalOperator / operator_user. Safe to run multiple
-- times - REVOKE on a non-existent grant is a no-op error in Oracle, so
-- wrap each in its own block when running against a pristine DB.
-- (Comment these out on first-time setup.)
REVOKE EXECUTE ON sp_BookAppointment       FROM HospitalOperator;
REVOKE EXECUTE ON sp_CancelAppointment     FROM HospitalOperator;
REVOKE EXECUTE ON sp_RescheduleAppointment FROM HospitalOperator;
REVOKE EXECUTE ON sp_GetDoctorAvailability FROM HospitalOperator;
REVOKE EXECUTE ON sp_CompleteAppointment   FROM HospitalOperator;
REVOKE EXECUTE ON fn_IsDoctorOnVacation    FROM HospitalOperator;

REVOKE EXECUTE ON sp_BookAppointment       FROM operator_user;
REVOKE EXECUTE ON sp_CancelAppointment     FROM operator_user;
REVOKE EXECUTE ON sp_RescheduleAppointment FROM operator_user;
REVOKE EXECUTE ON sp_GetDoctorAvailability FROM operator_user;
REVOKE EXECUTE ON sp_CompleteAppointment   FROM operator_user;
REVOKE EXECUTE ON fn_IsDoctorOnVacation    FROM operator_user;


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗    ███████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ╚════██║
-- ██████╔╝███████║███████║███████╗█████╗          ██╔╝
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝        ██╔╝
-- ██║     ██║  ██║██║  ██║███████║███████╗      ██║
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═╝
-- PHASE 7: RUN REPORTS (Run as HMS or operator_user)
-- ============================================================================

-- -------------------------------------------
-- STEP 7.1: Run each report script
-- -------------------------------------------
-- These are standalone SELECT queries with sample parameters.
-- Open each file and run it:

-- @Reports/rpt_DailyAppointments.sql     — appointments for a specific date
-- @Reports/rpt_DoctorSchedule.sql        — doctor schedule with availability
-- @Reports/rpt_BedOccupancy.sql          — bed status + summary
-- @Reports/rpt_Revenue.sql               — revenue breakdown
-- @Reports/rpt_CancellationStats.sql     — cancellation analysis

-- TIP: Modify the date parameters at the top of each report to match
-- your seed data dates (2026-04-14 through 2026-04-25).


-- ============================================================================
-- ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗     █████╗
-- ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ██╔══██╗
-- ██████╔╝███████║███████║███████╗█████╗      ╚█████╔╝
-- ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝      ██╔══██╗
-- ██║     ██║  ██║██║  ██║███████║███████╗    ╚█████╔╝
-- ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚════╝
-- PHASE 8: RUN TEST CASES (Run as operator_user)
-- ============================================================================

-- -------------------------------------------
-- STEP 8.0: DISCONNECT from HMS. Reconnect as operator_user.
-- -------------------------------------------
-- Connection:
--     Username: operator_user
--     Password: OperatorPass456
--
-- In SQL*Plus:
--     CONNECT operator_user/"OperatorPass456"@localhost:1521/XEPDB1
--
-- IMPORTANT: Since operator_user doesn't own the tables, they must
-- reference them with the HMS. prefix, or create synonyms.

-- -------------------------------------------
-- STEP 8.1: Create public synonyms (run as SYS or HMS)
-- -------------------------------------------
-- So operator_user can reference tables without HMS. prefix:
-- (Reconnect as SYS first)

CREATE OR REPLACE PUBLIC SYNONYM Insurance          FOR HMS.Insurance;
CREATE OR REPLACE PUBLIC SYNONYM Department         FOR HMS.Department;
CREATE OR REPLACE PUBLIC SYNONYM Employee           FOR HMS.Employee;
CREATE OR REPLACE PUBLIC SYNONYM Patient            FOR HMS.Patient;
CREATE OR REPLACE PUBLIC SYNONYM DoctorSchedule     FOR HMS.DoctorSchedule;
CREATE OR REPLACE PUBLIC SYNONYM DoctorVacation     FOR HMS.DoctorVacation;
CREATE OR REPLACE PUBLIC SYNONYM Appointment        FOR HMS.Appointment;
CREATE OR REPLACE PUBLIC SYNONYM AppointmentHistory FOR HMS.AppointmentHistory;
CREATE OR REPLACE PUBLIC SYNONYM Room               FOR HMS.Room;
CREATE OR REPLACE PUBLIC SYNONYM Bed                FOR HMS.Bed;
CREATE OR REPLACE PUBLIC SYNONYM Admission          FOR HMS.Admission;
CREATE OR REPLACE PUBLIC SYNONYM Prescription       FOR HMS.Prescription;
CREATE OR REPLACE PUBLIC SYNONYM Payment            FOR HMS.Payment;

-- Synonyms for views
CREATE OR REPLACE PUBLIC SYNONYM v_appointment      FOR HMS.v_appointment;
CREATE OR REPLACE PUBLIC SYNONYM v_doctor_schedule  FOR HMS.v_doctor_schedule;
CREATE OR REPLACE PUBLIC SYNONYM v_prescription     FOR HMS.v_prescription;
CREATE OR REPLACE PUBLIC SYNONYM v_billing          FOR HMS.v_billing;
CREATE OR REPLACE PUBLIC SYNONYM v_payment          FOR HMS.v_payment;
CREATE OR REPLACE PUBLIC SYNONYM v_bed_status       FOR HMS.v_bed_status;

-- Synonyms for procedures and functions
CREATE OR REPLACE PUBLIC SYNONYM sp_BookAppointment       FOR HMS.sp_BookAppointment;
CREATE OR REPLACE PUBLIC SYNONYM sp_CancelAppointment     FOR HMS.sp_CancelAppointment;
CREATE OR REPLACE PUBLIC SYNONYM sp_RescheduleAppointment FOR HMS.sp_RescheduleAppointment;
CREATE OR REPLACE PUBLIC SYNONYM sp_GetDoctorAvailability FOR HMS.sp_GetDoctorAvailability;
CREATE OR REPLACE PUBLIC SYNONYM sp_CompleteAppointment   FOR HMS.sp_CompleteAppointment;
CREATE OR REPLACE PUBLIC SYNONYM fn_IsDoctorOnVacation    FOR HMS.fn_IsDoctorOnVacation;

-- -------------------------------------------
-- STEP 8.2: Reconnect as operator_user and run tests
-- -------------------------------------------
-- CONNECT operator_user/"OperatorPass456"@localhost:1521/XEPDB1

SET SERVEROUTPUT ON;

-- Run each test case. Each prints [PASS] or [FAIL]:

-- @Tests/TC01_DuplicateBooking.sql      — expects error on duplicate booking
-- @Tests/TC02_CancelBefore24hr.sql      — expects error on late cancellation
-- @Tests/TC04_VacationBlocking.sql      — expects error booking during vacation
-- @Tests/TC05_RescheduleHistory.sql     — expects history row after reschedule
-- @Tests/TC06_OccupiedBedFail.sql       — expects error on occupied bed
-- @Tests/TC07_InsuranceDiscount.sql     — expects correct discount calculation
-- @Tests/TC08_ScheduleOverlap.sql       — expects unique constraint violation
-- (TC03 was removed in the revamp — BR4 max-per-day rule retired.)

-- -------------------------------------------
-- STEP 8.3: Expected output in Messages panel
-- -------------------------------------------
-- [PASS] TC01: Duplicate booking prevented - ORA-20004: ...
-- [PASS] TC02: 24-hour cancellation rule enforced - ORA-20002: ...
-- [PASS] TC04: Vacation blocking works - ORA-20003: ...
-- [PASS] TC05: History row created with correct previous schedule and status
-- [PASS] TC06: Occupied bed blocked - ORA-20002: ...
-- [PASS] TC07: Insurance discount correctly applied (expected: $800, actual: $800)
-- [PASS] TC08: Schedule overlap prevented - ORA-00001: unique constraint violated


-- ============================================================================
-- FINAL VERIFICATION SUMMARY
-- ============================================================================

-- Run as HMS user to check everything:

-- 1. All objects exist:
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
WHERE object_type IN ('TABLE', 'VIEW', 'INDEX', 'PROCEDURE', 'FUNCTION', 'TRIGGER')
GROUP BY object_type
ORDER BY object_type;
-- Expected:
--   FUNCTION   1
--   INDEX      18+ (includes PK indexes)
--   PROCEDURE  5
--   TABLE      13   (former Doctor+Staff -> Employee, Billing dropped)
--   TRIGGER    4
--   VIEW       6

-- 2. All objects are valid (no compilation errors):
SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID';
-- Expected: 0 rows (no invalid objects)

-- 3. Row counts:
SELECT 'Department'     AS entity, COUNT(*) AS cnt FROM Department      UNION ALL
SELECT 'Employee',      COUNT(*) FROM Employee                          UNION ALL
SELECT 'Insurance',     COUNT(*) FROM Insurance                         UNION ALL
SELECT 'Patient',       COUNT(*) FROM Patient                           UNION ALL
SELECT 'DoctorSchedule', COUNT(*) FROM DoctorSchedule                   UNION ALL
SELECT 'DoctorVacation', COUNT(*) FROM DoctorVacation                   UNION ALL
SELECT 'Room',          COUNT(*) FROM Room                              UNION ALL
SELECT 'Bed',           COUNT(*) FROM Bed                               UNION ALL
SELECT 'Appointment',   COUNT(*) FROM Appointment                       UNION ALL
SELECT 'Admission',     COUNT(*) FROM Admission                         UNION ALL
SELECT 'Prescription',  COUNT(*) FROM Prescription                      UNION ALL
SELECT 'Payment',       COUNT(*) FROM Payment
ORDER BY entity;


-- ============================================================================
-- CLEANUP (Only if you need to start over)
-- ============================================================================

-- To drop everything and start fresh, connect as SYS and run:
--
-- DROP USER HMS CASCADE;          -- Drops ALL tables, views, procedures, triggers
-- DROP USER admin_user CASCADE;
-- DROP USER operator_user CASCADE;
-- DROP ROLE HospitalAdmin;
-- DROP ROLE HospitalOperator;
--
-- Then start again from Phase 0.

-- ============================================================================
-- END OF MASTER EXECUTION GUIDE
-- ============================================================================
