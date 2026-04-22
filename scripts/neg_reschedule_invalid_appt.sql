-- ============================================================================
-- Negative flow: Reschedule a non-existent appointment
-- Mirrors: ui/app.py :: _run_negative_scenario('reschedule-invalid-appt')
-- Rule:     Appointment existence
-- Expected: ORA-20001: Appointment with ID 999999 does not exist or is
--           not in Scheduled status.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_RescheduleAppointment(999999, 10, ' ||
        '''negative flow demo'') ...');

    sp_RescheduleAppointment(999999, 10, 'negative flow demo');

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
