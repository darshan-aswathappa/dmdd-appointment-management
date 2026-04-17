-- =====================================================
-- FILE: 06_create_roles_security.sql
-- PURPOSE: Create database roles and assign granular
--          permissions on HMS schema objects
-- NOTE:    Run as ADMIN or SYS (a DBA-level user).
--          Tables are owned by the HMS user, so all
--          references must use the HMS. prefix.
--
-- REVAMP NOTES (v2):
--   - Doctor and Staff grants collapsed into Employee.
--   - Billing grants dropped; billing is now embedded in
--     Appointment and Admission.
-- =====================================================

-- =====================================================
-- 1. CREATE DATABASE ROLES
-- =====================================================

CREATE ROLE HospitalAdmin;
CREATE ROLE HospitalOperator;

-- =====================================================
-- 2. GRANT PERMISSIONS TO HospitalAdmin
-- Full CRUD on all HMS-owned tables
-- =====================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Insurance          TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Department         TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Employee           TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Patient            TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.DoctorSchedule     TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.DoctorVacation     TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Appointment        TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.AppointmentHistory TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Room               TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Bed                TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Admission          TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Prescription       TO HospitalAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON HMS.Payment            TO HospitalAdmin;

-- Grant SELECT on HMS-owned views to HospitalAdmin
GRANT SELECT ON HMS.v_appointment      TO HospitalAdmin;
GRANT SELECT ON HMS.v_doctor_schedule  TO HospitalAdmin;
GRANT SELECT ON HMS.v_prescription     TO HospitalAdmin;
GRANT SELECT ON HMS.v_billing          TO HospitalAdmin;
GRANT SELECT ON HMS.v_payment          TO HospitalAdmin;
GRANT SELECT ON HMS.v_bed_status       TO HospitalAdmin;

-- Grant EXECUTE on appointment procedures + helper function to HospitalAdmin
-- (operator_user intentionally does NOT receive these, so EXECUTE from the
--  operator role raises ORA-01031 / ORA-00942 and demonstrates the
--  read-only boundary in the UI).
GRANT EXECUTE ON HMS.sp_BookAppointment       TO HospitalAdmin;
GRANT EXECUTE ON HMS.sp_CancelAppointment     TO HospitalAdmin;
GRANT EXECUTE ON HMS.sp_RescheduleAppointment TO HospitalAdmin;
GRANT EXECUTE ON HMS.sp_CompleteAppointment   TO HospitalAdmin;
GRANT EXECUTE ON HMS.sp_GetDoctorAvailability TO HospitalAdmin;
GRANT EXECUTE ON HMS.fn_IsDoctorOnVacation    TO HospitalAdmin;

-- =====================================================
-- 3. GRANT PERMISSIONS TO HospitalOperator
-- Read-only access to tables + views, execute on procedures
-- =====================================================
GRANT SELECT ON HMS.Insurance          TO HospitalOperator;
GRANT SELECT ON HMS.Department         TO HospitalOperator;
GRANT SELECT ON HMS.Employee           TO HospitalOperator;
GRANT SELECT ON HMS.Patient            TO HospitalOperator;
GRANT SELECT ON HMS.DoctorSchedule     TO HospitalOperator;
GRANT SELECT ON HMS.DoctorVacation     TO HospitalOperator;
GRANT SELECT ON HMS.Appointment        TO HospitalOperator;
GRANT SELECT ON HMS.AppointmentHistory TO HospitalOperator;
GRANT SELECT ON HMS.Room               TO HospitalOperator;
GRANT SELECT ON HMS.Bed                TO HospitalOperator;
GRANT SELECT ON HMS.Admission          TO HospitalOperator;
GRANT SELECT ON HMS.Prescription       TO HospitalOperator;
GRANT SELECT ON HMS.Payment            TO HospitalOperator;

-- Grant SELECT on HMS-owned views to HospitalOperator
GRANT SELECT ON HMS.v_appointment      TO HospitalOperator;
GRANT SELECT ON HMS.v_doctor_schedule  TO HospitalOperator;
GRANT SELECT ON HMS.v_prescription     TO HospitalOperator;
GRANT SELECT ON HMS.v_billing          TO HospitalOperator;
GRANT SELECT ON HMS.v_payment          TO HospitalOperator;
GRANT SELECT ON HMS.v_bed_status       TO HospitalOperator;

-- =====================================================
-- 4. ASSIGN ROLES TO APPLICATION USERS
-- =====================================================

GRANT HospitalAdmin TO admin_user;
ALTER USER admin_user DEFAULT ROLE HospitalAdmin;

GRANT HospitalOperator TO operator_user;
ALTER USER operator_user DEFAULT ROLE HospitalOperator;

-- =====================================================
-- 5. VERIFICATION QUERIES (uncomment to run)
-- =====================================================

SELECT grantee, granted_role
FROM dba_role_privs
WHERE granted_role IN ('HOSPITALADMIN', 'HOSPITALOPERATOR');

SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE grantee IN ('HOSPITALADMIN', 'HOSPITALOPERATOR')
ORDER BY grantee, table_name;
