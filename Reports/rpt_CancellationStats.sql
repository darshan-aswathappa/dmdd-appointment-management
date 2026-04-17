-- =====================================================
-- FILE: rpt_CancellationStats.sql
-- PURPOSE: Cancellation analysis per doctor showing
--          rate, most common reason, and lead time.
-- REVAMP: Doctor table replaced with Employee (filtered
--         to employee_type = 'Doctor').
-- =====================================================

-- Parameters: start_date = DATE '2026-01-01'
--             end_date   = DATE '2026-04-30'

WITH DoctorAppointments AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        dept.name                                       AS department_name,
        COUNT(a.appointment_id)                         AS total_appointments,
        SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END)
                                                        AS cancelled_count,
        AVG(
            CASE
                WHEN a.status = 'Cancelled' AND a.cancelled_at IS NOT NULL
                THEN (ds.schedule_date - TRUNC(a.cancelled_at))
                ELSE NULL
            END
        )                                               AS avg_days_before_appt
    FROM Employee e
        INNER JOIN Department dept
            ON e.department_id = dept.department_id
        INNER JOIN DoctorSchedule ds
            ON e.employee_id = ds.employee_id
        INNER JOIN Appointment a
            ON ds.schedule_id = a.schedule_id
    WHERE
        e.employee_type = 'Doctor'
        AND ds.schedule_date BETWEEN DATE '2026-01-01' AND DATE '2026-04-30'
    GROUP BY
        e.employee_id,
        e.first_name,
        e.last_name,
        dept.name
),

CancellationReasons AS (
    SELECT
        e.employee_id,
        ah.change_reason,
        COUNT(*)                                        AS reason_count,
        ROW_NUMBER() OVER (
            PARTITION BY e.employee_id
            ORDER BY COUNT(*) DESC
        )                                               AS rn
    FROM Employee e
        INNER JOIN DoctorSchedule ds
            ON e.employee_id = ds.employee_id
        INNER JOIN Appointment a
            ON ds.schedule_id = a.schedule_id
        INNER JOIN AppointmentHistory ah
            ON a.appointment_id = ah.appointment_id
           AND ah.new_status = 'Cancelled'
    WHERE
        e.employee_type = 'Doctor'
        AND ds.schedule_date BETWEEN DATE '2026-01-01' AND DATE '2026-04-30'
        AND ah.change_reason IS NOT NULL
    GROUP BY
        e.employee_id,
        ah.change_reason
)

SELECT
    da.first_name || ' ' || da.last_name                AS DoctorName,
    da.department_name                                   AS Department,
    da.total_appointments                                AS TotalAppointments,
    da.cancelled_count                                   AS CancelledCount,
    ROUND(
        CASE
            WHEN da.total_appointments > 0
            THEN da.cancelled_count * 100.0 / da.total_appointments
            ELSE 0
        END,
    2)                                                   AS CancellationRatePct,
    NVL(cr.change_reason, 'No reason recorded')          AS MostCommonReason,
    ROUND(NVL(da.avg_days_before_appt, 0), 1)            AS AvgDaysBeforeAppt
FROM DoctorAppointments da
    LEFT JOIN CancellationReasons cr
        ON da.employee_id = cr.employee_id
       AND cr.rn = 1
ORDER BY
    CancellationRatePct DESC,
    da.last_name ASC;
