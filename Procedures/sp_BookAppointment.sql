-- ============================================================================
-- Procedure:   sp_BookAppointment
-- Description: Books a new appointment for a patient at a given schedule slot.
--              Validates patient existence, slot availability, vacation
--              status, and duplicate appointments before inserting the row.
--
-- REVAMP:
--   - BR4 (max appointments per doctor per day) retired: the daily-count
--     and max-per-slot checks have been removed.
--   - DoctorSchedule.doctor_id renamed to employee_id.
--
-- Parameters:  p_patient_id      - The patient requesting the appointment
--              p_schedule_id     - The doctor schedule slot to book
--              p_visit_type      - 'In-Person' or 'Teleconsultation'
--              p_reason          - Reason for the appointment
--              p_appointment_id  - (OUT) The new appointment_id on success
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_BookAppointment
(
    p_patient_id     IN  NUMBER,
    p_schedule_id    IN  NUMBER,
    p_visit_type     IN  VARCHAR2,
    p_reason         IN  VARCHAR2,
    p_appointment_id OUT NUMBER
)
AS
    v_employee_id    NUMBER;
    v_schedule_date  DATE;
    v_count          NUMBER;
BEGIN
    -- ================================================================
    -- Validation 1: Verify the patient exists
    -- ================================================================
    SELECT COUNT(*) INTO v_count
    FROM Patient
    WHERE patient_id = p_patient_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Patient with ID ' || p_patient_id || ' does not exist.');
    END IF;

    -- ================================================================
    -- Validation 2: Verify schedule slot exists and is available
    -- ================================================================
    BEGIN
        SELECT employee_id, schedule_date
        INTO v_employee_id, v_schedule_date
        FROM DoctorSchedule
        WHERE schedule_id = p_schedule_id
          AND is_available = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Schedule slot with ID ' || p_schedule_id || ' does not exist or is not available.');
    END;

    -- ================================================================
    -- Validation 3: Check doctor is NOT on vacation for that date
    -- ================================================================
    IF fn_IsDoctorOnVacation(v_employee_id, v_schedule_date) = 1 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Doctor (Employee ID: ' || v_employee_id || ') is on approved vacation on ' || TO_CHAR(v_schedule_date, 'YYYY-MM-DD') || '. Cannot book appointment.');
    END IF;

    -- ================================================================
    -- Validation 4: No duplicate (same patient + same slot, Scheduled)
    -- ================================================================
    SELECT COUNT(*) INTO v_count
    FROM Appointment
    WHERE patient_id  = p_patient_id
      AND schedule_id = p_schedule_id
      AND status      = 'Scheduled';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'A scheduled appointment already exists for patient ' || p_patient_id || ' at schedule slot ' || p_schedule_id || '.');
    END IF;

    -- ================================================================
    -- Insert the new appointment
    -- ================================================================
    INSERT INTO Appointment (patient_id, schedule_id, visit_type, reason, status, created_at, updated_at)
    VALUES (p_patient_id, p_schedule_id, p_visit_type, p_reason, 'Scheduled', SYSDATE, SYSDATE)
    RETURNING appointment_id INTO p_appointment_id;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_BookAppointment;
/
