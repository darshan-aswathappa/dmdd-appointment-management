-- ============================================================================
-- Procedure:   sp_CancelAppointment
-- Description: Cancels a scheduled appointment if it is at least 24 hours
--              before the appointment time. History is logged by trigger.
-- Parameters:  p_appointment_id      - The appointment to cancel
--              p_cancellation_reason  - Reason for cancellation
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_CancelAppointment
(
    p_appointment_id     IN NUMBER,
    p_cancellation_reason IN VARCHAR2
)
AS
    v_schedule_id    NUMBER;
    v_schedule_date  DATE;
    v_slot_time      VARCHAR2(5);
    v_appt_datetime  DATE;
    v_hours_until    NUMBER;
BEGIN
    -- ================================================================
    -- Validation 1: Verify appointment exists and is in Scheduled status
    -- ================================================================
    BEGIN
        SELECT schedule_id
        INTO v_schedule_id
        FROM Appointment
        WHERE appointment_id = p_appointment_id
          AND status = 'Scheduled';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Appointment with ID ' || p_appointment_id || ' does not exist or is not in Scheduled status.');
    END;

    -- ================================================================
    -- Validation 2: Get schedule date and slot time
    -- ================================================================
    SELECT schedule_date, slot_time
    INTO v_schedule_date, v_slot_time
    FROM DoctorSchedule
    WHERE schedule_id = v_schedule_id;

    -- ================================================================
    -- Validation 3: Ensure cancellation is at least 24 hours in advance
    -- ================================================================
    v_appt_datetime := TO_DATE(TO_CHAR(v_schedule_date, 'YYYY-MM-DD') || ' ' || v_slot_time, 'YYYY-MM-DD HH24:MI');
    v_hours_until := (v_appt_datetime - SYSDATE) * 24;

    IF v_hours_until < 24 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cannot cancel appointment ' || p_appointment_id || '. Cancellations must be made at least 24 hours in advance. Current lead time: ' || TRUNC(v_hours_until) || ' hours.');
    END IF;

    -- ================================================================
    -- Update the appointment status to Cancelled
    -- History is logged automatically by the trigger
    -- ================================================================
    UPDATE Appointment
    SET status       = 'Cancelled',
        cancelled_at = SYSDATE,
        notes        = p_cancellation_reason,
        updated_at   = SYSDATE
    WHERE appointment_id = p_appointment_id;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_CancelAppointment;
/
