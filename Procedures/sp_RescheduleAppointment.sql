-- ============================================================================
-- Procedure:   sp_RescheduleAppointment
-- Description: Reschedules an existing appointment to a new schedule slot.
--              Validates both old and new slots, checks vacation, and
--              explicitly logs the change in AppointmentHistory.
--
-- REVAMP:
--   - BR4 (max appointments per doctor per day) retired.
--   - DoctorSchedule.doctor_id renamed to employee_id.
--
-- Parameters:  p_appointment_id   - The appointment to reschedule
--              p_new_schedule_id  - The new schedule slot
--              p_change_reason    - Reason for rescheduling
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_RescheduleAppointment
(
    p_appointment_id  IN NUMBER,
    p_new_schedule_id IN NUMBER,
    p_change_reason   IN VARCHAR2
)
AS
    v_old_schedule_id   NUMBER;
    v_patient_id        NUMBER;
    v_new_employee_id   NUMBER;
    v_new_schedule_date DATE;
    v_count             NUMBER;
BEGIN
    -- ================================================================
    -- Validation 1: Verify appointment exists and is Scheduled
    -- ================================================================
    BEGIN
        SELECT schedule_id, patient_id
        INTO v_old_schedule_id, v_patient_id
        FROM Appointment
        WHERE appointment_id = p_appointment_id
          AND status = 'Scheduled';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Appointment with ID ' || p_appointment_id || ' does not exist or is not in Scheduled status.');
    END;

    -- ================================================================
    -- Validation 2: Verify new schedule slot exists and is available
    -- ================================================================
    BEGIN
        SELECT employee_id, schedule_date
        INTO v_new_employee_id, v_new_schedule_date
        FROM DoctorSchedule
        WHERE schedule_id = p_new_schedule_id
          AND is_available = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'New schedule slot with ID ' || p_new_schedule_id || ' does not exist or is not available.');
    END;

    -- ================================================================
    -- Validation 3: Verify new slot is NOT during doctor vacation
    -- ================================================================
    IF fn_IsDoctorOnVacation(v_new_employee_id, v_new_schedule_date) = 1 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Doctor (Employee ID: ' || v_new_employee_id || ') is on approved vacation on ' || TO_CHAR(v_new_schedule_date, 'YYYY-MM-DD') || '. Cannot reschedule to this date.');
    END IF;

    -- ================================================================
    -- Validation 4: No duplicate appointment at new slot for this patient
    -- ================================================================
    SELECT COUNT(*) INTO v_count
    FROM Appointment
    WHERE patient_id  = v_patient_id
      AND schedule_id = p_new_schedule_id
      AND status      = 'Scheduled';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Patient ' || v_patient_id || ' already has a scheduled appointment at new schedule slot ' || p_new_schedule_id || '.');
    END IF;

    -- ================================================================
    -- Update the appointment with the new schedule slot
    -- ================================================================
    UPDATE Appointment
    SET schedule_id = p_new_schedule_id,
        updated_at  = SYSDATE
    WHERE appointment_id = p_appointment_id;

    -- ================================================================
    -- Explicitly log the reschedule in AppointmentHistory
    -- ================================================================
    INSERT INTO AppointmentHistory
        (appointment_id, previous_schedule_id, previous_status, new_status, change_reason, changed_at)
    VALUES
        (p_appointment_id, v_old_schedule_id, 'Scheduled', 'Scheduled', p_change_reason, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_RescheduleAppointment;
/