-- =====================================================
-- TC#:          TC06
-- Description:  Verify that the trg_PreventOccupiedBed
--               trigger blocks admission of a patient to
--               a bed that already has an Active admission.
-- Business Rule: TV2 - A bed cannot be assigned to two
--               patients simultaneously.
-- Expected:     Error raised containing
--               "Bed is currently occupied"
-- =====================================================
SET SERVEROUTPUT ON;

DECLARE
    v_occupied_bed_id          NUMBER := 51;
    v_test_patient_id          NUMBER := 66;    -- A different patient
    v_test_employee_id         NUMBER := 1;     -- Dr. Robert Chen (Employee)
    v_count                    NUMBER;
    v_admission_count_before   NUMBER;
    v_admission_count_after    NUMBER;
    v_err_msg                  VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TC06: Occupied Bed Prevention ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------
    -- SETUP
    -- Bed 51 has an Active admission (admission_id = 1,
    -- patient 51, doctor 1) from seed data.
    -- -------------------------------------------------

    -- Verify that bed 51 has an Active admission
    SELECT COUNT(*) INTO v_count
    FROM Admission
    WHERE bed_id = v_occupied_bed_id
      AND status = 'Active';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SETUP ERROR: No Active admission found for bed 51.');
        DBMS_OUTPUT.PUT_LINE('TC06 RESULT: SKIPPED');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('SETUP: Confirmed bed 51 has an Active admission.');

    -- Record the current admission count for this bed
    SELECT COUNT(*) INTO v_admission_count_before
    FROM Admission
    WHERE bed_id = v_occupied_bed_id;

    -- -------------------------------------------------
    -- ACTION & VERIFY
    -- Attempt to insert a new admission for the same bed
    -- -------------------------------------------------
    BEGIN
        INSERT INTO Admission (patient_id, bed_id, admitting_employee_id, admission_type, diagnosis, status, admission_datetime)
        VALUES (v_test_patient_id, v_occupied_bed_id, v_test_employee_id, 'Emergency', 'TC06 test - should be blocked', 'Active', SYSDATE);

        -- If we reach here, the trigger did NOT prevent the insert
        DBMS_OUTPUT.PUT_LINE('FAIL: INSERT succeeded when trigger should have blocked it (bed occupied).');
        DBMS_OUTPUT.PUT_LINE('TC06 RESULT: FAIL');

        -- Cleanup the accidental insert
        DELETE FROM Admission
        WHERE patient_id = v_test_patient_id
          AND bed_id     = v_occupied_bed_id
          AND diagnosis  = 'TC06 test - should be blocked';
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_err_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('Caught expected error: ' || v_err_msg);

            -- Verify no new admission row was inserted
            SELECT COUNT(*) INTO v_admission_count_after
            FROM Admission
            WHERE bed_id = v_occupied_bed_id;

            IF v_err_msg LIKE '%occupied%' AND v_admission_count_after = v_admission_count_before THEN
                DBMS_OUTPUT.PUT_LINE('PASS: Trigger correctly prevented admission to an occupied bed. No new row inserted.');
                DBMS_OUTPUT.PUT_LINE('TC06 RESULT: PASS');
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAIL: Error message or post-state did not match expectations.');
                DBMS_OUTPUT.PUT_LINE('  Error: ' || v_err_msg);
                DBMS_OUTPUT.PUT_LINE('  Admissions before: ' || v_admission_count_before);
                DBMS_OUTPUT.PUT_LINE('  Admissions after:  ' || v_admission_count_after);
                DBMS_OUTPUT.PUT_LINE('TC06 RESULT: FAIL');
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TC06 Complete ===');
END;
/
