-- =====================================================
-- TC#:          TC01
-- Description:  Verify that sp_BookAppointment rejects a
--               duplicate booking for the same patient
--               and schedule slot that already has a
--               'Scheduled' appointment.
-- Business Rule: BR1 - No duplicate appointments allowed
--               for the same patient + schedule slot.
-- Test Vector:  TV1
-- Expected:     Error raised containing
--               "A scheduled appointment already exists"
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_test_patient_id   NUMBER := 21;
    v_test_schedule_id  NUMBER := 6;
    v_appointment_id    NUMBER;
    v_err_msg           VARCHAR2(4000);
    v_count             NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC01: Duplicate Booking Prevention ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------
    -- SETUP
    -- Patient 21 already has a Scheduled appointment
    -- at schedule_id = 6 (seed data, appointment_id = 21)
    -- -------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM Appointment
    WHERE patient_id  = v_test_patient_id
      AND schedule_id = v_test_schedule_id
      AND status      = 'Scheduled';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: Expected seed appointment for patient 21 / schedule 6 not found.');
        DBMS_OUTPUT.PUT_LINE('TC01 RESULT: SKIPPED');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('SETUP: Confirmed existing Scheduled appointment for patient 21 at schedule slot 6.');

    -- -------------------------------------------------
    -- ACTION & VERIFY
    -- Attempt to book the same patient + slot again.
    -- -------------------------------------------------
    BEGIN
        sp_BookAppointment(
            p_patient_id  => v_test_patient_id,
            p_schedule_id => v_test_schedule_id,
            p_visit_type  => 'In-Person',
            p_reason      => 'TC01 duplicate test',
            p_appointment_id => v_appointment_id
        );

        -- If we reach here, the procedure did NOT raise an error
        DBMS_OUTPUT.PUT_LINE('FAIL: sp_BookAppointment succeeded when it should have rejected a duplicate booking.');
        DBMS_OUTPUT.PUT_LINE('TC01 RESULT: FAIL');
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('Caught expected error: ' || v_err_msg);

            IF v_err_msg LIKE '%scheduled appointment already exists%' THEN
                DBMS_OUTPUT.PUT_LINE('PASS: Duplicate booking was correctly rejected.');
                DBMS_OUTPUT.PUT_LINE('TC01 RESULT: PASS');
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAIL: An error was raised, but the message did not match the expected duplicate-booking text.');
                DBMS_OUTPUT.PUT_LINE('TC01 RESULT: FAIL');
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TC01 Complete ===');
END;
/
