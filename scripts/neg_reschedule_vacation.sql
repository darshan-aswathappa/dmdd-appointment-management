-- ============================================================================
-- Negative flow: Reschedule into doctor vacation
-- Mirrors: ui/app.py :: _run_negative_scenario('reschedule-vacation')
-- Rule:     BR5 (vacation blocking)
-- Expected: ORA-20003: Doctor ... is on approved vacation on 2026-04-22.
--
-- Tries to reschedule a live Scheduled appointment onto slot 174,
-- which lies inside Dr. David Kim's approved vacation window.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_appt_id NUMBER;
BEGIN
    SELECT appointment_id INTO v_appt_id
    FROM (
        SELECT appointment_id
          FROM Appointment
         WHERE status = 'Scheduled'
         ORDER BY appointment_id
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_RescheduleAppointment(' || v_appt_id ||
        ', 174, ''negative flow demo'')  -- slot 174 is during vacation');

    sp_RescheduleAppointment(v_appt_id, 174, 'negative flow demo');

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'PRECONDITION MISSING: no Scheduled appointments exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
