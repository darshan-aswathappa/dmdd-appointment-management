-- =====================================================
-- TC#:          TC08
-- Description:  Verify that the UNIQUE constraint on
--               DoctorSchedule (employee_id, schedule_date,
--               slot_time) prevents duplicate schedule
--               entries for the same doctor, date, and time.
-- Business Rule: BR6 - A doctor cannot have overlapping
--               schedule slots on the same date/time.
-- REVAMP:       doctor_id renamed to employee_id;
--               max_appointments removed.
-- Expected:     UNIQUE constraint violation error.
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_test_employee_id    NUMBER := 1;
    v_test_schedule_date  DATE   := DATE '2026-04-14';
    v_test_slot_time      VARCHAR2(5) := '09:00';
    v_count               NUMBER;
    v_err_msg             VARCHAR2(4000);
    v_err_code            NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC08: Schedule Overlap Prevention ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- SETUP: confirm existing seed row (schedule_id = 1)
    SELECT COUNT(*) INTO v_count
    FROM DoctorSchedule
    WHERE employee_id   = v_test_employee_id
      AND schedule_date = v_test_schedule_date
      AND slot_time     = v_test_slot_time;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: Expected schedule record for employee 1 on 2026-04-14 at 09:00 not found.');
        DBMS_OUTPUT.PUT_LINE('TC08 RESULT: SKIPPED');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('SETUP: Confirmed existing schedule for employee 1 on 2026-04-14 at 09:00.');

    -- ACTION: attempt duplicate insert
    BEGIN
        INSERT INTO DoctorSchedule (employee_id, schedule_date, slot_time, slot_duration_mins, is_available)
        VALUES (v_test_employee_id, v_test_schedule_date, v_test_slot_time, 30, 1);

        DBMS_OUTPUT.PUT_LINE('FAIL: INSERT succeeded when the UNIQUE constraint should have prevented it.');
        DBMS_OUTPUT.PUT_LINE('TC08 RESULT: FAIL');

        -- Cleanup: remove the accidental duplicate
        DELETE FROM DoctorSchedule
        WHERE employee_id   = v_test_employee_id
          AND schedule_date = v_test_schedule_date
          AND slot_time     = v_test_slot_time
          AND schedule_id <> 1
          AND ROWNUM = 1;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg  := SQLERRM;
            v_err_code := SQLCODE;
            DBMS_OUTPUT.PUT_LINE('Caught expected error (code ' || v_err_code || '): ' || v_err_msg);

            -- ORA-00001 = UNIQUE constraint violation
            IF v_err_code = -1 THEN
                DBMS_OUTPUT.PUT_LINE('PASS: UNIQUE constraint correctly prevented duplicate schedule entry.');
                DBMS_OUTPUT.PUT_LINE('TC08 RESULT: PASS');
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAIL: An error was raised, but it was not a UNIQUE constraint violation.');
                DBMS_OUTPUT.PUT_LINE('  Error Code: ' || v_err_code);
                DBMS_OUTPUT.PUT_LINE('  Error Message: ' || v_err_msg);
                DBMS_OUTPUT.PUT_LINE('TC08 RESULT: FAIL');
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TC08 Complete ===');
END;
/
