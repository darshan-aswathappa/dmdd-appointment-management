-- ============================================================================
-- Flow: Check doctor availability (read-only, happy path)
-- Mirrors: ui/app.py :: flow_availability()
-- Procedure: sp_GetDoctorAvailability(employee_id, start_date, end_date, OUT ref_cursor)
--
-- Lists open slots for a doctor in a date range. Vacation days and
-- slots that already have a Scheduled appointment are excluded.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

VARIABLE rc REFCURSOR

DECLARE
    v_employee_id NUMBER := 1;                         -- edit as needed
    v_start_date  DATE   := TO_DATE('2026-04-01', 'YYYY-MM-DD');
    v_end_date    DATE   := TO_DATE('2026-04-30', 'YYYY-MM-DD');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Availability for employee ' || v_employee_id ||
                         ' from ' || TO_CHAR(v_start_date, 'YYYY-MM-DD') ||
                         ' to '   || TO_CHAR(v_end_date,   'YYYY-MM-DD'));

    sp_GetDoctorAvailability(
        p_employee_id => v_employee_id,
        p_start_date  => v_start_date,
        p_end_date    => v_end_date,
        p_result      => :rc
    );
END;
/

PRINT rc
