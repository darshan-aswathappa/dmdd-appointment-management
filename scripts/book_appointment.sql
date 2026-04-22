-- ============================================================================
-- Flow: Book appointment (happy path)
-- Mirrors: ui/app.py :: flow_book()
-- Procedure: sp_BookAppointment(patient_id, schedule_id, visit_type, reason, OUT)
--
-- Edit the values below to match a real patient and an available slot,
-- or let the discovery block pick the first free Scheduled slot for you.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_patient_id    NUMBER := 21;                 -- edit as needed
    v_schedule_id   NUMBER;                       -- auto-picked below
    v_visit_type    VARCHAR2(20) := 'In-Person';
    v_reason        VARCHAR2(200) := 'script-driven booking';
    v_appt_id       NUMBER;
BEGIN
    -- Pick the earliest available, unbooked slot (same logic as UI helper
    -- _find_free_scheduled_slot).
    SELECT schedule_id INTO v_schedule_id
    FROM (
        SELECT ds.schedule_id
          FROM DoctorSchedule ds
         WHERE ds.is_available = 1
           AND NOT EXISTS (
               SELECT 1 FROM Appointment a
                WHERE a.schedule_id = ds.schedule_id
                  AND a.status = 'Scheduled'
           )
         ORDER BY ds.schedule_date, ds.slot_time
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('Booking patient ' || v_patient_id ||
                         ' into slot ' || v_schedule_id || '...');

    sp_BookAppointment(
        p_patient_id     => v_patient_id,
        p_schedule_id    => v_schedule_id,
        p_visit_type     => v_visit_type,
        p_reason         => v_reason,
        p_appointment_id => v_appt_id
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: booked appointment ' || v_appt_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No free DoctorSchedule slot available.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/
