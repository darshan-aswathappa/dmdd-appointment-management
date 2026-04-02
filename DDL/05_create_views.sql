-- =====================================================
-- FILE: 05_create_views.sql
-- PURPOSE: Create views to simplify common query
--          patterns and reporting
-- NOTE:    Oracle uses CREATE OR REPLACE VIEW.
--          String concatenation uses || instead of +.
--          ISNULL() is replaced with NVL().
--
-- REVAMP NOTES (v2):
--   - Doctor + Staff merged into Employee; views filter
--     employees by employee_type = 'Doctor' where the
--     former Doctor table was meant.
--   - DoctorSchedule.max_appointments was removed; the
--     v_doctor_schedule view now just reports current
--     bookings with no cap.
--   - Billing was folded into Appointment/Admission;
--     v_billing is now a UNION of the two sources.
--   - v_payment now joins Payment to Appointment OR
--     Admission directly.
-- =====================================================

-- =====================================================
-- 1. v_appointment
-- PURPOSE: Consolidated appointment view joining
--          Appointment, DoctorSchedule, Patient,
--          Employee, and Department information.
-- =====================================================
CREATE OR REPLACE VIEW v_appointment
AS
SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name          AS patient_name,
    e.first_name || ' ' || e.last_name          AS doctor_name,
    dept.name                                    AS department_name,
    e.specialization,
    ds.schedule_date,
    ds.slot_time,
    ds.slot_duration_mins,
    a.visit_type,
    a.status                                     AS appointment_status,
    a.reason,
    a.notes
FROM Appointment a
    INNER JOIN DoctorSchedule ds ON a.schedule_id = ds.schedule_id
    INNER JOIN Patient p         ON a.patient_id  = p.patient_id
    INNER JOIN Employee e        ON ds.employee_id = e.employee_id
    INNER JOIN Department dept   ON e.department_id = dept.department_id;

-- =====================================================
-- 2. v_doctor_schedule
-- PURPOSE: Doctor schedule availability view showing
--          current bookings and vacation-based
--          availability. The removed max_appointments
--          cap means every available slot is bookable.
-- =====================================================
CREATE OR REPLACE VIEW v_doctor_schedule
AS
SELECT
    ds.schedule_id,
    e.first_name || ' ' || e.last_name          AS doctor_name,
    e.specialization,
    dept.name                                    AS department_name,
    ds.schedule_date,
    ds.slot_time,
    ds.slot_duration_mins,
    COUNT(a.appointment_id)                      AS current_bookings,
    CASE
        WHEN ds.is_available = 0 THEN 0
        WHEN EXISTS (
            SELECT 1
            FROM DoctorVacation dv
            WHERE dv.employee_id = e.employee_id
              AND dv.status      = 'Approved'
              AND ds.schedule_date BETWEEN dv.start_date AND dv.end_date
        ) THEN 0
        ELSE 1
    END                                          AS is_available
FROM DoctorSchedule ds
    INNER JOIN Employee e      ON ds.employee_id  = e.employee_id
    INNER JOIN Department dept ON e.department_id = dept.department_id
    LEFT JOIN  Appointment a   ON a.schedule_id   = ds.schedule_id
                               AND a.status       = 'Scheduled'
WHERE
    e.employee_type = 'Doctor'
GROUP BY
    ds.schedule_id,
    e.employee_id,
    e.first_name, e.last_name,
    e.specialization,
    dept.name,
    ds.schedule_date,
    ds.slot_time,
    ds.slot_duration_mins,
    ds.is_available;

-- =====================================================
-- 3. v_prescription
-- PURPOSE: Prescription details with patient and doctor
--          information, sourced from either Appointment
--          or Admission chains.
-- =====================================================
CREATE OR REPLACE VIEW v_prescription
AS
SELECT
    pr.prescription_id,
    p.first_name || ' ' || p.last_name           AS patient_name,
    e.first_name || ' ' || e.last_name           AS doctor_name,
    pr.medication_name,
    pr.dosage,
    pr.frequency,
    pr.duration_days,
    pr.instructions,
    pr.prescribed_at,
    CASE
        WHEN pr.appointment_id IS NOT NULL THEN 'Appointment'
        WHEN pr.admission_id   IS NOT NULL THEN 'Admission'
        ELSE 'Unknown'
    END                                           AS source
FROM Prescription pr
    -- Appointment path
    LEFT JOIN Appointment a        ON pr.appointment_id = a.appointment_id
    LEFT JOIN DoctorSchedule ds_a  ON a.schedule_id     = ds_a.schedule_id
    -- Admission path
    LEFT JOIN Admission adm        ON pr.admission_id   = adm.admission_id
    -- Resolve Patient: from Appointment or Admission
    LEFT JOIN Patient p            ON p.patient_id = COALESCE(a.patient_id, adm.patient_id)
    -- Resolve Doctor (Employee) from either chain
    LEFT JOIN Employee e           ON e.employee_id = COALESCE(ds_a.employee_id, adm.admitting_employee_id);

-- =====================================================
-- 4. v_billing
-- PURPOSE: Unified billing view. Since Billing was
--          folded into Appointment and Admission, this
--          view UNIONs the two sources so reports and
--          queries can still treat billing as one stream.
-- =====================================================
CREATE OR REPLACE VIEW v_billing
AS
SELECT
    'A-' || a.appointment_id                      AS bill_ref,
    a.appointment_id                              AS appointment_id,
    CAST(NULL AS NUMBER(10))                      AS admission_id,
    'Appointment'                                 AS source,
    p.first_name || ' ' || p.last_name            AS patient_name,
    a.bill_amount                                 AS total_amount,
    a.insurance_coverage_amt                      AS insurance_coverage_amt,
    a.bill_amount - a.insurance_coverage_amt      AS net_amount,
    i.provider_name                               AS insurance_provider,
    i.policy_number,
    a.billing_date,
    a.due_date,
    a.billing_status                              AS billing_status
FROM Appointment a
    INNER JOIN Patient p   ON a.patient_id = p.patient_id
    LEFT JOIN  Insurance i ON i.insurance_id = p.insurance_id
WHERE a.bill_amount IS NOT NULL
UNION ALL
SELECT
    'D-' || adm.admission_id                      AS bill_ref,
    CAST(NULL AS NUMBER(10))                      AS appointment_id,
    adm.admission_id                              AS admission_id,
    'Admission'                                   AS source,
    p.first_name || ' ' || p.last_name            AS patient_name,
    adm.bill_amount                               AS total_amount,
    adm.insurance_coverage_amt                    AS insurance_coverage_amt,
    adm.bill_amount - adm.insurance_coverage_amt  AS net_amount,
    i.provider_name                               AS insurance_provider,
    i.policy_number,
    adm.billing_date,
    adm.due_date,
    adm.billing_status                            AS billing_status
FROM Admission adm
    INNER JOIN Patient p   ON adm.patient_id = p.patient_id
    LEFT JOIN  Insurance i ON i.insurance_id = p.insurance_id
WHERE adm.bill_amount IS NOT NULL;

-- =====================================================
-- 5. v_payment
-- PURPOSE: Payment details with billing and patient
--          information. Payments now hang off Appointment
--          or Admission directly.
-- =====================================================
CREATE OR REPLACE VIEW v_payment
AS
SELECT
    pay.payment_id,
    CASE
        WHEN pay.appointment_id IS NOT NULL THEN 'Appointment'
        WHEN pay.admission_id   IS NOT NULL THEN 'Admission'
        ELSE 'Unknown'
    END                                           AS source,
    pay.appointment_id,
    pay.admission_id,
    p.first_name || ' ' || p.last_name            AS patient_name,
    pay.amount,
    pay.payment_method,
    pay.transaction_ref,
    pay.status                                    AS payment_status,
    pay.payment_date
FROM Payment pay
    LEFT JOIN Appointment a    ON pay.appointment_id = a.appointment_id
    LEFT JOIN Admission adm    ON pay.admission_id   = adm.admission_id
    LEFT JOIN Patient p        ON p.patient_id = COALESCE(a.patient_id, adm.patient_id);

-- =====================================================
-- 6. v_bed_status
-- PURPOSE: Real-time bed occupancy view showing room
--          and bed details with current patient info.
-- =====================================================
CREATE OR REPLACE VIEW v_bed_status
AS
SELECT
    r.room_id,
    r.room_number,
    r.room_type,
    r.floor_number,
    bd.bed_id,
    bd.bed_number,
    bd.bed_type,
    CASE
        WHEN bd.is_maintenance = 1                   THEN 'Maintenance'
        WHEN adm.admission_id IS NOT NULL            THEN 'Occupied'
        ELSE 'Available'
    END                                           AS occupancy_status,
    CASE
        WHEN adm.admission_id IS NOT NULL
        THEN p.first_name || ' ' || p.last_name
        ELSE NULL
    END                                           AS patient_name,
    adm.admission_datetime
FROM Room r
    INNER JOIN Bed bd              ON bd.room_id = r.room_id
    LEFT JOIN  Admission adm       ON adm.bed_id = bd.bed_id
                                   AND adm.status = 'Active'
    LEFT JOIN  Patient p           ON p.patient_id = adm.patient_id;
