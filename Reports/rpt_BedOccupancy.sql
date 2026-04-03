-- =====================================================
-- FILE: rpt_BedOccupancy.sql
-- PURPOSE: Show all rooms and beds with current
--          occupancy status and a summary rollup
-- DATABASE: HospitalManagementDB (Oracle)
-- =====================================================

-- =====================================================
-- Query 1: Detailed Bed Occupancy
-- Lists every bed with its room, department, current
-- status, and patient information when occupied.
-- =====================================================
SELECT
    r.room_number                                       AS RoomNumber,
    r.room_type                                         AS RoomType,
    r.floor_number                                       AS Floor,
    dept.name                                           AS DepartmentName,
    b.bed_number                                        AS BedNumber,
    b.bed_type                                          AS BedType,
    CASE
        WHEN b.is_maintenance = 1       THEN 'Maintenance'
        WHEN adm.admission_id IS NOT NULL THEN 'Occupied'
        ELSE 'Available'
    END                                                 AS Status,
    CASE
        WHEN adm.admission_id IS NOT NULL
        THEN p.first_name || ' ' || p.last_name
        ELSE NULL
    END                                                 AS PatientName,
    adm.admission_datetime                              AS AdmissionDate
FROM Room r
    INNER JOIN Department dept
        ON r.department_id = dept.department_id
    INNER JOIN Bed b
        ON r.room_id = b.room_id
    LEFT JOIN Admission adm
        ON b.bed_id = adm.bed_id
       AND adm.status = 'Active'
    LEFT JOIN Patient p
        ON adm.patient_id = p.patient_id
WHERE
    r.is_active = 1
ORDER BY
    r.floor_number ASC,
    r.room_number ASC,
    b.bed_number ASC;

-- =====================================================
-- Query 2: Occupancy Summary
-- Aggregated counts and occupancy percentage across
-- all active beds in the hospital.
-- =====================================================
SELECT
    COUNT(*)                                            AS TotalBeds,
    SUM(CASE
        WHEN b.is_maintenance = 0
         AND adm.admission_id IS NOT NULL
        THEN 1 ELSE 0
    END)                                                AS OccupiedCount,
    SUM(CASE
        WHEN b.is_maintenance = 0
         AND adm.admission_id IS NULL
        THEN 1 ELSE 0
    END)                                                AS AvailableCount,
    SUM(CASE
        WHEN b.is_maintenance = 1
        THEN 1 ELSE 0
    END)                                                AS MaintenanceCount,
    ROUND(
        SUM(CASE
            WHEN b.is_maintenance = 0
             AND adm.admission_id IS NOT NULL
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*),
    2)                                                  AS OccupancyPercent
FROM Bed b
    INNER JOIN Room r
        ON b.room_id = r.room_id
    LEFT JOIN Admission adm
        ON b.bed_id = adm.bed_id
       AND adm.status = 'Active'
WHERE
    r.is_active = 1;
