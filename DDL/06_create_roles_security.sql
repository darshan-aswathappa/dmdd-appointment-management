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

create role hospitaladmin;
create role hospitaloperator;

-- =====================================================
-- 2. GRANT PERMISSIONS TO HospitalAdmin
-- Full CRUD on all HMS-owned tables
-- =====================================================
grant select,insert,update,delete on hms.insurance to hospitaladmin;
grant select,insert,update,delete on hms.department to hospitaladmin;
grant select,insert,update,delete on hms.employee to hospitaladmin;
grant select,insert,update,delete on hms.patient to hospitaladmin;
grant select,insert,update,delete on hms.doctorschedule to hospitaladmin;
grant select,insert,update,delete on hms.doctorvacation to hospitaladmin;
grant select,insert,update,delete on hms.appointment to hospitaladmin;
grant select,insert,update,delete on hms.appointmenthistory to hospitaladmin;
grant select,insert,update,delete on hms.room to hospitaladmin;
grant select,insert,update,delete on hms.bed to hospitaladmin;
grant select,insert,update,delete on hms.admission to hospitaladmin;
grant select,insert,update,delete on hms.prescription to hospitaladmin;
grant select,insert,update,delete on hms.payment to hospitaladmin;

-- Grant SELECT on HMS-owned views to HospitalAdmin
grant select on hms.v_appointment to hospitaladmin;
grant select on hms.v_doctor_schedule to hospitaladmin;
grant select on hms.v_prescription to hospitaladmin;
grant select on hms.v_billing to hospitaladmin;
grant select on hms.v_payment to hospitaladmin;
grant select on hms.v_bed_status to hospitaladmin;

-- Grant EXECUTE on appointment procedures + helper function to HospitalAdmin
-- (operator_user intentionally does NOT receive these, so EXECUTE from the
--  operator role raises ORA-01031 / ORA-00942 and demonstrates the
--  read-only boundary in the UI).
grant execute on hms.sp_bookappointment to hospitaladmin;
grant execute on hms.sp_cancelappointment to hospitaladmin;
grant execute on hms.sp_rescheduleappointment to hospitaladmin;
grant execute on hms.sp_completeappointment to hospitaladmin;
grant execute on hms.sp_getdoctoravailability to hospitaladmin;
grant execute on hms.fn_isdoctoronvacation to hospitaladmin;

-- =====================================================
-- 3. GRANT PERMISSIONS TO HospitalOperator
-- Read-only access to tables + views, execute on procedures
-- =====================================================
grant select on hms.insurance to hospitaloperator;
grant select on hms.department to hospitaloperator;
grant select on hms.employee to hospitaloperator;
grant select on hms.patient to hospitaloperator;
grant select on hms.doctorschedule to hospitaloperator;
grant select on hms.doctorvacation to hospitaloperator;
grant select on hms.appointment to hospitaloperator;
grant select on hms.appointmenthistory to hospitaloperator;
grant select on hms.room to hospitaloperator;
grant select on hms.bed to hospitaloperator;
grant select on hms.admission to hospitaloperator;
grant select on hms.prescription to hospitaloperator;
grant select on hms.payment to hospitaloperator;

-- Grant SELECT on HMS-owned views to HospitalOperator
grant select on hms.v_appointment to hospitaloperator;
grant select on hms.v_doctor_schedule to hospitaloperator;
grant select on hms.v_prescription to hospitaloperator;
grant select on hms.v_billing to hospitaloperator;
grant select on hms.v_payment to hospitaloperator;
grant select on hms.v_bed_status to hospitaloperator;

-- Grant EXECUTE on appointment procedures + helper function to HospitalOperator
-- so the operator role has "Execute access" (procedure-only write path).
grant execute on hms.sp_bookappointment to hospitaloperator;
grant execute on hms.sp_cancelappointment to hospitaloperator;
grant execute on hms.sp_rescheduleappointment to hospitaloperator;
grant execute on hms.sp_completeappointment to hospitaloperator;
grant execute on hms.sp_getdoctoravailability to hospitaloperator;
grant execute on hms.fn_isdoctoronvacation to hospitaloperator;

-- =====================================================
-- 4. ASSIGN ROLES TO APPLICATION USERS
-- =====================================================

grant hospitaladmin to admin_user;
alter user admin_user default role hospitaladmin;

grant hospitaloperator to operator_user;
alter user operator_user default role hospitaloperator;

-- =====================================================
-- 5. VERIFICATION QUERIES (uncomment to run)
-- =====================================================

select grantee,
       granted_role
  from dba_role_privs
 where granted_role in ( 'HOSPITALADMIN',
                         'HOSPITALOPERATOR' );

select grantee,
       table_name,
       privilege
  from dba_tab_privs
 where grantee in ( 'HOSPITALADMIN',
                    'HOSPITALOPERATOR' )
 order by grantee,
          table_name;