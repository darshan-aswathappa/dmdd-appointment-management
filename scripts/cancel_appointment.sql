-- ============================================================================
-- Flow: Cancel appointment (happy path)
-- Mirrors: ui/app.py :: flow_cancel()
-- Procedure: sp_CancelAppointment(appointment_id, reason)
--
-- Pre-condition: a Scheduled appointment exists whose slot is more than
-- 24 hours in the future (otherwise BR2 will reject the cancellation).
-- The block below auto-picks the earliest such appointment.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_appt_id NUMBER;
    v_reason  VARCHAR2(200) := 'script-driven cancellation';
BEGIN
    SELECT appointment_id INTO v_appt_id
    FROM (
        SELECT a.appointment_id
          FROM Appointment a
          JOIN DoctorSchedule ds ON ds.schedule_id = a.schedule_id
         WHERE a.status = 'Scheduled'
           AND (ds.schedule_date
                + NUMTODSINTERVAL(
                    TO_NUMBER(SUBSTR(ds.slot_time, 1, 2)), 'HOUR')
                + NUMTODSINTERVAL(
                    TO_NUMBER(SUBSTR(ds.slot_time, 4, 2)), 'MINUTE'))
                > SYSDATE + 1
         ORDER BY a.appointment_id
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('Cancelling appointment ' || v_appt_id || '...');

    sp_CancelAppointment(
        p_appointment_id => v_appt_id,
        p_reason         => v_reason
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: cancelled appointment ' || v_appt_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'No Scheduled appointment with slot >24h in future; ' ||
            'nothing to cancel. Seed or book one first.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/
