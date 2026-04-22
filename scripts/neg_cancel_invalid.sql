-- ============================================================================
-- Negative flow: Cancel a non-existent appointment
-- Mirrors: ui/app.py :: _run_negative_scenario('cancel-invalid')
-- Rule:     Appointment existence
-- Expected: ORA-20001: Appointment with ID 999999 does not exist or is
--           not in Scheduled status.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_CancelAppointment(999999, ''negative flow demo'') ...');

    sp_CancelAppointment(999999, 'negative flow demo');

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS: cancelled 999999');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
