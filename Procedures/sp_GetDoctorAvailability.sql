-- ============================================================================
-- Procedure:   sp_GetDoctorAvailability
-- Description: Returns schedule slots for a doctor within a date range,
--              excluding vacation dates and slots already booked by a
--              Scheduled appointment.
--
-- REVAMP:
--   - max_appointments was removed from DoctorSchedule. A slot is considered
--     available if (a) is_available = 1, (b) the doctor is not on approved
--     vacation that day, and (c) no Scheduled appointment exists on it.
--   - doctor_id column renamed to employee_id.
--
-- Parameters:  p_employee_id - The employee (doctor) to query
--              p_start_date  - Beginning of the date range
--              p_end_date    - End of the date range
--              p_cursor      - (OUT) SYS_REFCURSOR with available slots
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_GetDoctorAvailability
(
    p_employee_id IN  NUMBER,
    p_start_date  IN  DATE,
    p_end_date    IN  DATE,
    p_cursor      OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
        SELECT
            ds.schedule_id,
            ds.schedule_date,
            ds.slot_time,
            ds.slot_duration_mins,
            COUNT(a.appointment_id) AS current_bookings
        FROM DoctorSchedule ds
        LEFT JOIN Appointment a
            ON ds.schedule_id = a.schedule_id
            AND a.status = 'Scheduled'
        WHERE ds.employee_id = p_employee_id
          AND ds.schedule_date BETWEEN p_start_date AND p_end_date
          AND ds.is_available = 1
          -- Exclude dates that overlap with an approved vacation
          AND NOT EXISTS (
              SELECT 1
              FROM DoctorVacation dv
              WHERE dv.employee_id = ds.employee_id
                AND dv.status      = 'Approved'
                AND ds.schedule_date BETWEEN dv.start_date AND dv.end_date
          )
        GROUP BY
            ds.schedule_id,
            ds.schedule_date,
            ds.slot_time,
            ds.slot_duration_mins
        -- Only unbooked slots
        HAVING COUNT(a.appointment_id) = 0
        ORDER BY
            ds.schedule_date,
            ds.slot_time;
END sp_GetDoctorAvailability;
/
