-- =====================================================
-- FILE: rpt_Revenue.sql
-- PURPOSE: Revenue summary, breakdown by source, and
--          payment status analysis for a date range.
-- REVAMP:
--   - Billing table dropped. Billing now lives on
--     Appointment and Admission. Queries below use
--     the v_billing view (a UNION of both sources).
--   - Payments aggregated per source-entity via
--     (appointment_id, admission_id) keys rather than
--     bill_id.
-- =====================================================

-- Parameters: start_date = DATE '2026-01-01'
--             end_date   = DATE '2026-04-30'

-- =====================================================
-- Query 1: Overall Revenue Summary
-- =====================================================
WITH appt_pay AS (
    SELECT appointment_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND appointment_id IS NOT NULL
    GROUP BY appointment_id
),
adm_pay AS (
    SELECT admission_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND admission_id IS NOT NULL
    GROUP BY admission_id
)
SELECT
    SUM(bl.total_amount)                                      AS TotalBilled,
    SUM(bl.insurance_coverage_amt)                            AS TotalInsuranceCoverage,
    SUM(bl.total_amount) - SUM(bl.insurance_coverage_amt)     AS NetPatientLiability,
    NVL(SUM(CASE WHEN bl.source = 'Appointment' THEN ap.completed_amount
                 WHEN bl.source = 'Admission'   THEN dp.completed_amount END), 0)
                                                              AS TotalCollected,
    SUM(bl.total_amount)
        - SUM(bl.insurance_coverage_amt)
        - NVL(SUM(CASE WHEN bl.source = 'Appointment' THEN ap.completed_amount
                       WHEN bl.source = 'Admission'   THEN dp.completed_amount END), 0)
                                                              AS OutstandingBalance
FROM v_billing bl
    LEFT JOIN appt_pay ap ON bl.appointment_id = ap.appointment_id
    LEFT JOIN adm_pay  dp ON bl.admission_id   = dp.admission_id
WHERE
    bl.billing_date BETWEEN DATE '2026-01-01' AND DATE '2026-04-30';

-- =====================================================
-- Query 2: Revenue By Source (Appointment vs Admission)
-- =====================================================
WITH appt_pay AS (
    SELECT appointment_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND appointment_id IS NOT NULL
    GROUP BY appointment_id
),
adm_pay AS (
    SELECT admission_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND admission_id IS NOT NULL
    GROUP BY admission_id
)
SELECT
    bl.source                                                 AS RevenueSource,
    COUNT(*)                                                  AS BillCount,
    SUM(bl.total_amount)                                      AS TotalBilled,
    SUM(bl.insurance_coverage_amt)                            AS InsuranceCoverage,
    SUM(bl.total_amount) - SUM(bl.insurance_coverage_amt)     AS NetPatientLiability,
    NVL(SUM(CASE WHEN bl.source = 'Appointment' THEN ap.completed_amount
                 WHEN bl.source = 'Admission'   THEN dp.completed_amount END), 0)
                                                              AS TotalCollected
FROM v_billing bl
    LEFT JOIN appt_pay ap ON bl.appointment_id = ap.appointment_id
    LEFT JOIN adm_pay  dp ON bl.admission_id   = dp.admission_id
WHERE
    bl.billing_date BETWEEN DATE '2026-01-01' AND DATE '2026-04-30'
GROUP BY bl.source
ORDER BY bl.source;

-- =====================================================
-- Query 3: Revenue By Billing Status
-- =====================================================
WITH appt_pay AS (
    SELECT appointment_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND appointment_id IS NOT NULL
    GROUP BY appointment_id
),
adm_pay AS (
    SELECT admission_id, SUM(amount) AS completed_amount
    FROM Payment
    WHERE status = 'Completed' AND admission_id IS NOT NULL
    GROUP BY admission_id
)
SELECT
    bl.billing_status                                         AS BillingStatus,
    COUNT(*)                                                  AS BillCount,
    SUM(bl.total_amount)                                      AS TotalAmount,
    SUM(bl.insurance_coverage_amt)                            AS InsuranceCoverage,
    SUM(bl.total_amount) - SUM(bl.insurance_coverage_amt)     AS NetPatientLiability,
    NVL(SUM(CASE WHEN bl.source = 'Appointment' THEN ap.completed_amount
                 WHEN bl.source = 'Admission'   THEN dp.completed_amount END), 0)
                                                              AS TotalCollected
FROM v_billing bl
    LEFT JOIN appt_pay ap ON bl.appointment_id = ap.appointment_id
    LEFT JOIN adm_pay  dp ON bl.admission_id   = dp.admission_id
WHERE
    bl.billing_date BETWEEN DATE '2026-01-01' AND DATE '2026-04-30'
GROUP BY bl.billing_status
ORDER BY
    CASE bl.billing_status
        WHEN 'Pending'        THEN 1
        WHEN 'Partially Paid' THEN 2
        WHEN 'Overdue'        THEN 3
        WHEN 'Paid'           THEN 4
    END;
