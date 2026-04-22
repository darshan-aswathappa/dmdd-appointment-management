-- ============================================================================
-- Negative flow: Complete a non-existent appointment
-- Mirrors: ui/app.py :: _run_negative_scenario('complete-invalid')
-- Rule:     Appointment existence
-- Expected: ORA-20001: Appointment with ID 999999 does not exist or is
--           not in Scheduled status.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_CompleteAppointment(999999, ' ||
        '''negative flow demo'', 100) ...');

    sp_CompleteAppointment(999999, 'negative flow demo', 100);

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
