-- ============================================================================
-- Negative flow: Book on a non-existent / unavailable slot
-- Mirrors: ui/app.py :: _run_negative_scenario('book-invalid-slot')
-- Rule:     Schedule existence
-- Expected: ORA-20002: Schedule slot with ID 99999 does not exist or is not available.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_out NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_BookAppointment(21, 99999, ''In-Person'', ' ||
        '''negative flow demo'', OUT) ...');

    sp_BookAppointment(21, 99999, 'In-Person',
                       'negative flow demo', v_out);

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS: appt ' || v_out);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
