-- =====================================================
-- TC#:          TC02
-- Description:  Verify that sp_CancelAppointment rejects
--               cancellation when the appointment is
--               less than 24 hours away.
-- Business Rule: BR2 - Cancellations must be made at
--               least 24 hours in advance.
-- Expected:     Error raised containing
--               "Cancellations must be made at least 24 hours"
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_test_employee_id  NUMBER := 1;    -- Dr. Robert Chen (Employee)
    v_test_patient_id   NUMBER := 61;   -- A patient not used in other tests
    v_today             DATE   := TRUNC(SYSDATE);
    v_slot_time_ts      TIMESTAMP := SYSTIMESTAMP + INTERVAL '30' MINUTE;
    v_slot_time_str     VARCHAR2(5) := TO_CHAR(SYSTIMESTAMP + INTERVAL '30' MINUTE, 'HH24:MI');
    v_test_schedule_id  NUMBER;
    v_test_appt_id      NUMBER;
    v_original_status   VARCHAR2(20);
    v_err_msg           VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC02: Cancel Before 24-Hour Window ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------
    -- SETUP
    -- Create a doctor schedule slot for TODAY with a
    -- near-future time so that < 24 hours remain.
    -- Then book an appointment on that slot.
    -- -------------------------------------------------

    -- Insert a schedule slot for today (near-future, < 24 hours away).
    -- DoctorSchedule.slot_time is VARCHAR2(5) in 'HH24:MI' format.
    INSERT INTO DoctorSchedule (employee_id, schedule_date, slot_time, slot_duration_mins, is_available)
    VALUES (v_test_employee_id, v_today, v_slot_time_str, 30, 1)
    RETURNING schedule_id INTO v_test_schedule_id;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('SETUP: Created schedule slot (ID: ' || v_test_schedule_id || ') for today at ' || v_slot_time_str);

    -- Book an appointment on that slot
    INSERT INTO Appointment (patient_id, schedule_id, status, visit_type, reason, created_at, updated_at)
    VALUES (v_test_patient_id, v_test_schedule_id, 'Scheduled', 'In-Person', 'TC02 test appointment', SYSDATE, SYSDATE)
    RETURNING appointment_id INTO v_test_appt_id;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('SETUP: Created appointment (ID: ' || v_test_appt_id || ') for patient ' || v_test_patient_id);

    -- -------------------------------------------------
    -- ACTION & VERIFY
    -- Attempt to cancel this appointment (< 24 hours away)
    -- -------------------------------------------------
    BEGIN
        sp_CancelAppointment(
            p_appointment_id      => v_test_appt_id,
            p_cancellation_reason => 'TC02 test cancellation'
        );

        -- If we reach here, the procedure did NOT raise an error
        DBMS_OUTPUT.PUT_LINE('FAIL: sp_CancelAppointment succeeded when it should have been rejected (< 24 hours).');
        DBMS_OUTPUT.PUT_LINE('TC02 RESULT: FAIL');
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('Caught expected error: ' || v_err_msg);

            -- Confirm appointment status is still Scheduled (unchanged)
            SELECT status INTO v_original_status
            FROM Appointment
            WHERE appointment_id = v_test_appt_id;

            IF v_err_msg LIKE '%24 hours%' AND v_original_status = 'Scheduled' THEN
                DBMS_OUTPUT.PUT_LINE('PASS: Cancellation within 24-hour window was correctly rejected. Status remains Scheduled.');
                DBMS_OUTPUT.PUT_LINE('TC02 RESULT: PASS');
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAIL: Error message or post-state did not match expectations.');
                DBMS_OUTPUT.PUT_LINE('  Error: ' || v_err_msg);
                DBMS_OUTPUT.PUT_LINE('  Status after attempt: ' || NVL(v_original_status, 'NULL'));
                DBMS_OUTPUT.PUT_LINE('TC02 RESULT: FAIL');
            END IF;
    END;

    -- -------------------------------------------------
    -- CLEANUP
    -- Remove test-specific data
    -- -------------------------------------------------
    DELETE FROM Appointment WHERE appointment_id = v_test_appt_id;
    DELETE FROM DoctorSchedule WHERE schedule_id = v_test_schedule_id;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CLEANUP: Removed test appointment and schedule slot.');
    DBMS_OUTPUT.PUT_LINE('=== TC02 Complete ===');
END;
/
