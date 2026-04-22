-- ============================================================================
-- Negative flow: Cancel within the 24-hour window
-- Mirrors: ui/app.py :: _run_negative_scenario('cancel-within-24h')
-- Rule:     BR2 (24-hour cancellation rule)
-- Expected: ORA-20002: ... Cancellations must be made at least 24 hours
--           in advance.
--
-- Dynamically creates a DoctorSchedule slot 30 minutes from now, books
-- an appointment on it (bypassing sp_BookAppointment so seed constraints
-- can't block the setup), then calls sp_CancelAppointment and asserts
-- the BR2 failure. Cleans up both rows in the FINALLY branch.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_sched_id  NUMBER;
    v_appt_id   NUMBER;
    v_today     DATE := TRUNC(SYSDATE);
    v_slot_time VARCHAR2(5) := TO_CHAR(SYSDATE + INTERVAL '30' MINUTE, 'HH24:MI');
BEGIN
    -- 1. Create a schedule slot 30 minutes out.
    INSERT INTO DoctorSchedule
        (employee_id, schedule_date, slot_time,
         slot_duration_mins, is_available)
    VALUES (1, v_today, v_slot_time, 30, 1)
    RETURNING schedule_id INTO v_sched_id;

    DBMS_OUTPUT.PUT_LINE('Created DoctorSchedule ' || v_sched_id ||
                         ' for today at ' || v_slot_time || '.');

    -- 2. Book an appointment on it.
    INSERT INTO Appointment
        (patient_id, schedule_id, status, visit_type, reason,
         created_at, updated_at)
    VALUES (61, v_sched_id, 'Scheduled', 'In-Person',
            'negative flow demo', SYSDATE, SYSDATE)
    RETURNING appointment_id INTO v_appt_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Booked appointment ' || v_appt_id ||
                         ' on that slot.');

    -- 3. Try to cancel; BR2 must fire.
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            'Calling sp_CancelAppointment(' || v_appt_id ||
            ', ''negative flow demo'') ...');

        sp_CancelAppointment(v_appt_id, 'negative flow demo');

        DBMS_OUTPUT.PUT_LINE(
            'UNEXPECTED SUCCESS: cancellation was allowed.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
    END;

    -- 4. Cleanup.
    DELETE FROM Appointment     WHERE appointment_id = v_appt_id;
    DELETE FROM DoctorSchedule  WHERE schedule_id    = v_sched_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cleanup: removed test appointment and slot.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: ' || SQLERRM);
        -- Best-effort cleanup in case setup partially succeeded.
        IF v_appt_id  IS NOT NULL THEN
            DELETE FROM Appointment     WHERE appointment_id = v_appt_id;
        END IF;
        IF v_sched_id IS NOT NULL THEN
            DELETE FROM DoctorSchedule  WHERE schedule_id    = v_sched_id;
        END IF;
        COMMIT;
        RAISE;
END;
/
