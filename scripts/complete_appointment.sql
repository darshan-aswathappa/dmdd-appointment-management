-- ============================================================================
-- Flow: Complete + bill appointment (happy path)
-- Mirrors: ui/app.py :: flow_complete()
-- Procedure: sp_CompleteAppointment(appointment_id, notes, bill_amount)
--
-- Marks a Scheduled appointment Completed and sets bill_amount.
-- trg_AppointmentInsDiscount fires on UPDATE and populates
-- insurance_coverage_amt based on the patient's insurance plan.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_appt_id      NUMBER;
    v_notes        VARCHAR2(500) := 'script-driven completion';
    v_bill_amount  NUMBER := 350.00;
    v_status       VARCHAR2(20);
    v_bill         NUMBER;
    v_ins_cover    NUMBER;
    v_bill_status  VARCHAR2(20);
BEGIN
    SELECT appointment_id INTO v_appt_id
    FROM (
        SELECT appointment_id
          FROM Appointment
         WHERE status = 'Scheduled'
         ORDER BY appointment_id
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('Completing appointment ' || v_appt_id ||
                         ' with bill $' || v_bill_amount || '...');

    sp_CompleteAppointment(
        p_appointment_id => v_appt_id,
        p_notes          => v_notes,
        p_bill_amount    => v_bill_amount
    );

    SELECT status, bill_amount, insurance_coverage_amt, billing_status
      INTO v_status, v_bill, v_ins_cover, v_bill_status
      FROM Appointment
     WHERE appointment_id = v_appt_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: appointment ' || v_appt_id ||
                         ' status=' || v_status ||
                         ' bill=' || v_bill ||
                         ' insurance_coverage=' || v_ins_cover ||
                         ' billing_status=' || v_bill_status);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'No Scheduled appointment to complete; book one first.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/
