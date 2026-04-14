-- =====================================================
-- TC#:          TC04
-- Description:  Verify that sp_BookAppointment rejects
--               bookings for a doctor who has an Approved
--               vacation on the requested date.
-- Business Rule: BR5 - Appointments cannot be booked
--               during a doctor's approved vacation.
-- Expected:     Error raised containing
--               "on approved vacation"
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_test_employee_id  NUMBER := 5;
    v_test_schedule_id  NUMBER := 174;   -- 2026-04-22, 09:00
    v_test_patient_id   NUMBER := 65;    -- A patient not used elsewhere
    v_vacation_date     DATE   := DATE '2026-04-22';
    v_count             NUMBER;
    v_is_on_vacation    NUMBER;
    v_appointment_id    NUMBER;
    v_err_msg           VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC04: Vacation Blocking ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------
    -- SETUP
    -- Doctor 5 (Dr. David Kim) has an Approved vacation
    -- from 2026-04-21 to 2026-04-23 (vacation_id = 6).
    -- Schedule slot 174 (doctor 5, 2026-04-22, 09:00)
    -- falls within this vacation period.
    -- -------------------------------------------------

    -- Verify vacation exists and is Approved
    SELECT COUNT(*) INTO v_count
    FROM DoctorVacation
    WHERE employee_id = v_test_employee_id
      AND status = 'Approved'
      AND v_vacation_date BETWEEN start_date AND end_date;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: No approved vacation found for doctor 5 covering 2026-04-22.');
        DBMS_OUTPUT.PUT_LINE('TC04 RESULT: SKIPPED');
        RETURN;
    END IF;

    -- Verify schedule slot exists
    SELECT COUNT(*) INTO v_count
    FROM DoctorSchedule
    WHERE schedule_id = v_test_schedule_id
      AND employee_id = v_test_employee_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: Schedule slot 174 for doctor 5 not found.');
        DBMS_OUTPUT.PUT_LINE('TC04 RESULT: SKIPPED');
        RETURN;
    END IF;

    -- Verify the function returns 1 (on vacation)
    v_is_on_vacation := fn_IsDoctorOnVacation(v_test_employee_id, v_vacation_date);
    DBMS_OUTPUT.PUT_LINE('SETUP: fn_IsDoctorOnVacation(5, 2026-04-22) = ' || v_is_on_vacation);

    -- -------------------------------------------------
    -- ACTION & VERIFY
    -- Attempt to book during vacation period
    -- -------------------------------------------------
    BEGIN
        sp_BookAppointment(
            p_patient_id  => v_test_patient_id,
            p_schedule_id => v_test_schedule_id,
            p_visit_type  => 'In-Person',
            p_reason      => 'TC04 vacation test',
            p_appointment_id => v_appointment_id
        );

        DBMS_OUTPUT.PUT_LINE('FAIL: sp_BookAppointment succeeded when it should have rejected (doctor on vacation).');
        DBMS_OUTPUT.PUT_LINE('TC04 RESULT: FAIL');
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('Caught expected error: ' || v_err_msg);

            IF v_err_msg LIKE '%vacation%' THEN
                DBMS_OUTPUT.PUT_LINE('PASS: Booking during approved vacation was correctly rejected.');
                DBMS_OUTPUT.PUT_LINE('TC04 RESULT: PASS');
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAIL: An error was raised, but the message did not match the expected vacation-blocking text.');
                DBMS_OUTPUT.PUT_LINE('TC04 RESULT: FAIL');
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TC04 Complete ===');
END;
/
