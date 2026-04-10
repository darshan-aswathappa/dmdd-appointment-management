-- ============================================================================
-- Function:    fn_IsDoctorOnVacation
-- Description: Checks whether a doctor (Employee of type 'Doctor') has an
--              approved vacation on a given date.
--
-- REVAMP: doctor_id column was renamed to employee_id on DoctorVacation.
--
-- Parameters:  p_employee_id - The employee (doctor) to check
--              p_check_date  - The date to verify against vacation records
-- Returns:     NUMBER(1) - 1 if on vacation, 0 otherwise
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_IsDoctorOnVacation
(
    p_employee_id IN NUMBER,
    p_check_date  IN DATE
)
RETURN NUMBER
AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM DoctorVacation
    WHERE employee_id = p_employee_id
      AND status      = 'Approved'
      AND p_check_date BETWEEN start_date AND end_date;

    IF v_count > 0 THEN
        RETURN 1;
    END IF;

    RETURN 0;
END fn_IsDoctorOnVacation;
/
