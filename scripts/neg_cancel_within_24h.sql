-- Negative: Cancel within the 24h window  -> expect ORA-20002 (BR2)
-- Sets up a slot 30 minutes out + an appointment, calls the procedure,
-- then cleans up. Cannot be expressed as a pure EXEC because the
-- precondition must be created at runtime.
SET SERVEROUTPUT ON

DECLARE
    v_sched_id  NUMBER;
    v_appt_id   NUMBER;
    v_slot_time VARCHAR2(5) := TO_CHAR(SYSDATE + INTERVAL '30' MINUTE, 'HH24:MI');
BEGIN
    INSERT INTO DoctorSchedule
        (employee_id, schedule_date, slot_time, slot_duration_mins, is_available)
    VALUES (1, TRUNC(SYSDATE), v_slot_time, 30, 1)
    RETURNING schedule_id INTO v_sched_id;

    INSERT INTO Appointment
        (patient_id, schedule_id, status, visit_type, reason,
         created_at, updated_at)
    VALUES (61, v_sched_id, 'Scheduled', 'In-Person',
            'negative flow demo', SYSDATE, SYSDATE)
    RETURNING appointment_id INTO v_appt_id;
    COMMIT;

    BEGIN
        sp_CancelAppointment(v_appt_id, 'negative flow demo');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
    END;

    DELETE FROM Appointment    WHERE appointment_id = v_appt_id;
    DELETE FROM DoctorSchedule WHERE schedule_id    = v_sched_id;
    COMMIT;
END;
/
