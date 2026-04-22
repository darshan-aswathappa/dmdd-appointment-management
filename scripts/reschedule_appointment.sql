-- ============================================================================
-- Flow: Reschedule appointment (happy path)
-- Mirrors: ui/app.py :: flow_reschedule()
-- Procedure: sp_RescheduleAppointment(appointment_id, new_schedule_id, reason)
--
-- Auto-picks the earliest live Scheduled appointment and the earliest
-- free unbooked slot that is different from its current slot.
-- trg_AppointmentHistory logs the status change with the supplied reason.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_appt_id      NUMBER;
    v_current_sid  NUMBER;
    v_new_sid      NUMBER;
    v_reason       VARCHAR2(200) := 'script-driven reschedule';
BEGIN
    SELECT appointment_id, schedule_id
      INTO v_appt_id, v_current_sid
    FROM (
        SELECT appointment_id, schedule_id
          FROM Appointment
         WHERE status = 'Scheduled'
         ORDER BY appointment_id
    )
    WHERE ROWNUM = 1;

    SELECT schedule_id INTO v_new_sid
    FROM (
        SELECT ds.schedule_id
          FROM DoctorSchedule ds
         WHERE ds.is_available = 1
           AND ds.schedule_id <> v_current_sid
           AND NOT EXISTS (
               SELECT 1 FROM Appointment a
                WHERE a.schedule_id = ds.schedule_id
                  AND a.status = 'Scheduled'
           )
         ORDER BY ds.schedule_date, ds.slot_time
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('Rescheduling appointment ' || v_appt_id ||
                         ' from slot ' || v_current_sid ||
                         ' to slot ' || v_new_sid || '...');

    sp_RescheduleAppointment(
        p_appointment_id   => v_appt_id,
        p_new_schedule_id  => v_new_sid,
        p_reason           => v_reason
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: rescheduled appointment ' || v_appt_id ||
                         ' to slot ' || v_new_sid);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'Could not find either a Scheduled appointment or a free ' ||
            'unbooked slot; nothing to do.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/
