-- =====================================================
-- FILE: rpt_DoctorSchedule.sql
-- PURPOSE: Show doctor schedule with current bookings and
--          vacation status for a date range.
-- REVAMP:
--   - Doctor table replaced with Employee (filtered by
--     employee_type = 'Doctor').
--   - max_appointments removed: slots are uncapped;
--     MaxAppointments and SlotsRemaining columns dropped
--     in favor of just CurrentBookings.
-- =====================================================

-- Parameters: start_date = DATE '2026-04-01'
--             end_date   = DATE '2026-04-30'

SELECT
    e.first_name || ' ' || e.last_name                 AS DoctorName,
    e.specialization                                    AS Specialization,
    dept.name                                           AS Department,
    ds.schedule_date                                    AS ScheduleDate,
    ds.slot_time                                        AS SlotTime,
    ds.slot_duration_mins                               AS DurationMins,
    COUNT(a.appointment_id)                             AS CurrentBookings,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM DoctorVacation dv
            WHERE dv.employee_id  = e.employee_id
              AND dv.status       = 'Approved'
              AND ds.schedule_date BETWEEN dv.start_date AND dv.end_date
        )
        THEN 'Y'
        ELSE 'N'
    END                                                 AS OnVacation
FROM Employee e
    INNER JOIN Department dept
        ON e.department_id = dept.department_id
    INNER JOIN DoctorSchedule ds
        ON e.employee_id = ds.employee_id
    LEFT JOIN Appointment a
        ON a.schedule_id = ds.schedule_id
       AND a.status = 'Scheduled'
WHERE
    e.employee_type = 'Doctor'
    AND ds.schedule_date BETWEEN DATE '2026-04-01' AND DATE '2026-04-30'
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    e.specialization,
    dept.name,
    ds.schedule_id,
    ds.schedule_date,
    ds.slot_time,
    ds.slot_duration_mins
ORDER BY
    e.last_name ASC,
    e.first_name ASC,
    ds.schedule_date ASC,
    ds.slot_time ASC;
