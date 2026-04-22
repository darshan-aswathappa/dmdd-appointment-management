-- ============================================================================
-- Negative flow: Book during doctor vacation
-- Mirrors: ui/app.py :: _run_negative_scenario('book-vacation')
-- Rule:     BR5 (vacation blocking)
-- Expected: ORA-20003: Doctor ... is on approved vacation on 2026-04-22.
--
-- Uses seeded slot 174 (Dr. David Kim, 2026-04-22 09:00) which falls
-- inside his approved 2026-04-21 .. 2026-04-23 vacation.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_out NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_BookAppointment(65, 174, ''In-Person'', ' ||
        '''negative flow demo'', OUT)  -- slot 174 is during vacation');

    sp_BookAppointment(65, 174, 'In-Person',
                       'negative flow demo', v_out);

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS: appt ' || v_out);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
