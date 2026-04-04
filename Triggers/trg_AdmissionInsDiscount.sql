-- ============================================================================
-- Trigger:     trg_AdmissionInsDiscount
-- Table:       Admission
-- Fires:       BEFORE UPDATE OF bill_amount (row-level)
-- Purpose:     Automatically calculates and applies the insurance coverage
--              amount when an Admission row's bill_amount is set or changed.
--              Mirror of trg_AppointmentInsDiscount for the admission side
--              of the billing fold-in.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_AdmissionInsDiscount
BEFORE UPDATE OF bill_amount ON Admission
FOR EACH ROW
WHEN (NEW.bill_amount IS NOT NULL)
DECLARE
    v_coverage_percentage NUMBER(5,2);
    v_max_coverage_amount NUMBER(10,2);
    v_is_active           NUMBER(1);
    v_valid_until         DATE;
    v_coverage_amt        NUMBER(10,2) := 0;
BEGIN
    IF :OLD.bill_amount IS NULL
       OR :OLD.bill_amount <> :NEW.bill_amount THEN

        BEGIN
            SELECT ins.coverage_percentage, ins.max_coverage_amount,
                   ins.is_active, ins.valid_until
            INTO v_coverage_percentage, v_max_coverage_amount,
                 v_is_active, v_valid_until
            FROM Patient p
            JOIN Insurance ins ON p.insurance_id = ins.insurance_id
            WHERE p.patient_id = :NEW.patient_id;

            IF v_is_active = 1 AND v_valid_until >= TRUNC(SYSDATE) THEN
                v_coverage_amt := :NEW.bill_amount * v_coverage_percentage / 100.0;
                IF v_coverage_amt > v_max_coverage_amount THEN
                    v_coverage_amt := v_max_coverage_amount;
                END IF;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_coverage_amt := 0;
        END;

        :NEW.insurance_coverage_amt := v_coverage_amt;
    END IF;
END trg_AdmissionInsDiscount;
/
