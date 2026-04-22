-- ============================================================================
-- Negative flow: Reschedule to a non-existent slot
-- Mirrors: ui/app.py :: _run_negative_scenario('reschedule-invalid-slot')
-- Rule:     Schedule existence
-- Expected: ORA-20002: New schedule slot with ID 999999 does not exist
--           or is not available.
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
        ', 999999, ''negative flow demo'') ...');

    sp_RescheduleAppointment(v_appt_id, 999999, 'negative flow demo');

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'PRECONDITION MISSING: no Scheduled appointments exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
