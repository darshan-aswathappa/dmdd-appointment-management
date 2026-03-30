-- =====================================================
-- FILE: rpt_DailyAppointments.sql
-- PURPOSE: List all appointments for a given date with
--          patient, doctor (Employee), department, and
--          slot details.
-- REVAMP: Doctor table joined via Employee (type='Doctor').
-- =====================================================

-- Parameter: report_date = DATE '2026-04-14'

SELECT
    a.appointment_id                                    AS AppointmentID,
    p.first_name || ' ' || p.last_name                 AS PatientName,
    e.first_name || ' ' || e.last_name                 AS DoctorName,
    dept.name                                           AS DepartmentName,
    ds.schedule_date                                    AS ScheduleDate,
    ds.slot_time                                        AS SlotTime,
    ds.slot_duration_mins                               AS SlotDurationMins,
    a.visit_type                                        AS VisitType,
    a.status                                            AS Status,
    NVL(a.reason, 'N/A')                               AS Reason
FROM Appointment a
    INNER JOIN DoctorSchedule ds
        ON a.schedule_id = ds.schedule_id
    INNER JOIN Employee e
        ON ds.employee_id = e.employee_id
    INNER JOIN Department dept
        ON e.department_id = dept.department_id
    INNER JOIN Patient p
        ON a.patient_id = p.patient_id
WHERE
    ds.schedule_date = DATE '2026-04-14'
ORDER BY
    ds.slot_time ASC,
    e.last_name ASC,
    e.first_name ASC;
