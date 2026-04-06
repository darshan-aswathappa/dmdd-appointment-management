-- =====================================================
-- TC#:          TC05
-- Description:  Verify that sp_RescheduleAppointment
--               creates a history record in
--               AppointmentHistory with the correct
--               previous_schedule_id and status values,
--               and that Appointment.schedule_id now
--               points to the new slot.
-- Business Rule: BR3 - Appointment changes must be
--               audited in the history table.
-- REVAMP:       AppointmentHistory schema uses
--               previous_schedule_id (not old/new pair).
--               The new schedule_id lives on the
--               Appointment row itself.
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_test_appt_id          NUMBER := 22;
    v_old_schedule_id       NUMBER := 18;
    v_new_schedule_id       NUMBER := 19;   -- Doctor 2, 2026-04-15, 10:00
    v_count                 NUMBER;
    v_history_count_before  NUMBER;
    v_history_count_after   NUMBER;
    v_hist_prev_sched       NUMBER;
    v_hist_prev_status      VARCHAR2(20);
    v_hist_new_status       VARCHAR2(20);
    v_appt_current_sched    NUMBER;
    v_err_msg               VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC05: Reschedule History Audit Trail ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------
    -- SETUP: confirm the seed appointment state.
    -- -------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM Appointment
    WHERE appointment_id = v_test_appt_id
      AND schedule_id    = v_old_schedule_id
      AND status         = 'Scheduled';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: Appointment 22 with schedule 18 in Scheduled status not found.');
        DBMS_OUTPUT.PUT_LINE('TC05 RESULT: SKIPPED');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM DoctorSchedule
    WHERE schedule_id = v_new_schedule_id
      AND is_available = 1;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: Target schedule slot 19 not found or not available.');
        DBMS_OUTPUT.PUT_LINE('TC05 RESULT: SKIPPED');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_history_count_before
    FROM AppointmentHistory
    WHERE appointment_id = v_test_appt_id;

    DBMS_OUTPUT.PUT_LINE('SETUP: Appointment 22 confirmed. History rows before: ' || v_history_count_before);

    -- -------------------------------------------------
    -- ACTION
    -- -------------------------------------------------
    BEGIN
        sp_RescheduleAppointment(
            p_appointment_id  => v_test_appt_id,
            p_new_schedule_id => v_new_schedule_id,
            p_change_reason   => 'TC05 reschedule test'
        );
        DBMS_OUTPUT.PUT_LINE('ACTION: sp_RescheduleAppointment executed successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('FAIL: sp_RescheduleAppointment raised an unexpected error: ' || v_err_msg);
            DBMS_OUTPUT.PUT_LINE('TC05 RESULT: FAIL');
            RETURN;
    END;

    -- -------------------------------------------------
    -- VERIFY
    -- -------------------------------------------------
    SELECT COUNT(*) INTO v_history_count_after
    FROM AppointmentHistory
    WHERE appointment_id = v_test_appt_id;

    SELECT schedule_id INTO v_appt_current_sched
    FROM Appointment
    WHERE appointment_id = v_test_appt_id;

    DBMS_OUTPUT.PUT_LINE('VERIFY: History rows after: ' || v_history_count_after);
    DBMS_OUTPUT.PUT_LINE('VERIFY: Appointment.schedule_id now: ' || v_appt_current_sched);

    IF v_history_count_after <= v_history_count_before THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: No new history row was created after rescheduling.');
        DBMS_OUTPUT.PUT_LINE('TC05 RESULT: FAIL');
    ELSE
        SELECT previous_schedule_id, previous_status, new_status
        INTO v_hist_prev_sched, v_hist_prev_status, v_hist_new_status
        FROM AppointmentHistory
        WHERE appointment_id = v_test_appt_id
        ORDER BY changed_at DESC
        FETCH FIRST 1 ROW ONLY;

        DBMS_OUTPUT.PUT_LINE('VERIFY: Most recent history record values:');
        DBMS_OUTPUT.PUT_LINE('  previous_schedule_id = ' || NVL(TO_CHAR(v_hist_prev_sched), 'NULL'));
        DBMS_OUTPUT.PUT_LINE('  previous_status      = ' || NVL(v_hist_prev_status, 'NULL'));
        DBMS_OUTPUT.PUT_LINE('  new_status           = ' || NVL(v_hist_new_status, 'NULL'));

        IF v_hist_prev_sched   = v_old_schedule_id
           AND v_hist_prev_status = 'Scheduled'
           AND v_hist_new_status  = 'Scheduled'
           AND v_appt_current_sched = v_new_schedule_id
        THEN
            DBMS_OUTPUT.PUT_LINE('PASS: History record captures previous slot/status and appointment now points to new slot.');
            DBMS_OUTPUT.PUT_LINE('TC05 RESULT: PASS');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: History record values or post-state do not match expected reschedule data.');
            DBMS_OUTPUT.PUT_LINE('TC05 RESULT: FAIL');
        END IF;
    END IF;

    -- -------------------------------------------------
    -- CLEANUP
    -- -------------------------------------------------
    UPDATE Appointment
    SET schedule_id = v_old_schedule_id,
        updated_at  = SYSDATE
    WHERE appointment_id = v_test_appt_id;

    DELETE FROM AppointmentHistory
    WHERE appointment_id = v_test_appt_id
      AND change_reason = 'TC05 reschedule test';

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CLEANUP: Reverted appointment 22 to original schedule slot and removed test history.');
    DBMS_OUTPUT.PUT_LINE('=== TC05 Complete ===');
END;
/
