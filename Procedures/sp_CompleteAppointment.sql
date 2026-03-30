-- ============================================================================
-- Procedure:   sp_CompleteAppointment
-- Description: Marks a scheduled appointment as completed and writes billing
--              details onto the Appointment row itself.
--
-- REVAMP:
--   - Billing is now embedded on Appointment. Instead of INSERTing into
--     Billing, we UPDATE the Appointment with bill_amount, billing_status,
--     billing_date, due_date. The trg_AppointmentInsDiscount trigger then
--     fires and computes insurance_coverage_amt automatically.
--
-- Parameters:  p_appointment_id - The appointment to complete
--              p_notes          - Optional clinical notes
--              p_bill_amount    - Total bill amount for the visit
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_CompleteAppointment
(
    p_appointment_id IN  NUMBER,
    p_notes          IN  VARCHAR2 DEFAULT NULL,
    p_bill_amount    IN  NUMBER
)
AS
    v_count NUMBER;
BEGIN
    -- ================================================================
    -- Validation 1: Verify appointment exists and is Scheduled
    -- ================================================================
    SELECT COUNT(*) INTO v_count
    FROM Appointment
    WHERE appointment_id = p_appointment_id
      AND status         = 'Scheduled';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Appointment with ID ' || p_appointment_id || ' does not exist or is not in Scheduled status.');
    END IF;

    -- ================================================================
    -- Complete the appointment AND set embedded billing fields in a
    -- single UPDATE. The insurance_coverage_amt is computed by the
    -- trg_AppointmentInsDiscount trigger.
    -- ================================================================
    UPDATE Appointment
    SET status          = 'Completed',
        notes           = p_notes,
        bill_amount     = p_bill_amount,
        billing_status  = 'Pending',
        billing_date    = TRUNC(SYSDATE),
        due_date        = TRUNC(SYSDATE) + 30,
        updated_at      = SYSDATE
    WHERE appointment_id = p_appointment_id;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_CompleteAppointment;
/
