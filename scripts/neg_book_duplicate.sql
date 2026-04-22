-- ============================================================================
-- Negative flow: Book a duplicate appointment
-- Mirrors: ui/app.py :: _run_negative_scenario('book-duplicate')
-- Rule:     BR1 / TV1 (duplicate booking)
-- Expected: ORA-20004: A scheduled appointment already exists for
--           patient 21 at schedule slot 6.
--
-- Pre-condition (from seed data): patient 21 already has a Scheduled
-- appointment on schedule slot 6. If the seed is missing, the block
-- reports precondition_missing instead of calling the procedure.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_cnt NUMBER;
    v_out NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM Appointment
     WHERE patient_id = 21
       AND schedule_id = 6
       AND status = 'Scheduled';

    IF v_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE(
            'PRECONDITION MISSING: no Scheduled appointment for ' ||
            'patient 21 on slot 6 (seed data absent). Skipping call.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Precondition confirmed. Calling ' ||
        'sp_BookAppointment(21, 6, ''In-Person'', ' ||
        '''negative flow demo'', OUT)  -- duplicate');

    sp_BookAppointment(21, 6, 'In-Person',
                       'negative flow demo', v_out);

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS: appt ' || v_out);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
