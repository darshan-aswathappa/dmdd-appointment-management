-- =====================================================
-- FILE: 04_create_indexes.sql
-- PURPOSE: Create additional performance indexes on HMS
--          schema tables, beyond the baseline indexes
--          created alongside the tables in 03_create_tables.sql.
-- NOTE:    Oracle indexes are B-tree by default.
--
-- REVAMP NOTES (v2):
--   - Indexes on the former Doctor/Staff tables were replaced
--     with Employee-centric indexes in 03_create_tables.sql.
--   - Indexes on the former Billing table were dropped;
--     embedded billing_status/billing_date columns on
--     Appointment and Admission get their own indexes here.
-- =====================================================

-- =====================================================
-- APPOINTMENT TABLE INDEXES
-- =====================================================

-- Filter by status: speeds up queries filtering on appointment status
-- (e.g., Scheduled, Completed, Cancelled, No-Show)
CREATE INDEX IX_Appointment_Status
    ON Appointment (status);

-- Appointment billing status lookup (replaces former Billing.status index)
CREATE INDEX IX_Appointment_BillingStatus
    ON Appointment (billing_status);

-- Appointment billing date range (replaces former Billing.billing_date index)
CREATE INDEX IX_Appointment_BillingDate
    ON Appointment (billing_date);

-- =====================================================
-- DOCTOR VACATION TABLE INDEXES
-- =====================================================

-- Vacation overlap check: composite index for detecting whether an
-- employee (doctor) is on vacation during a proposed appointment window
CREATE INDEX IX_DoctorVacation_EmpDates
    ON DoctorVacation (employee_id, start_date, end_date);

-- =====================================================
-- APPOINTMENT HISTORY TABLE INDEXES
-- =====================================================

-- History retrieval: speeds up fetching the full status change history for an appointment
CREATE INDEX IX_ApptHist_Appointment
    ON AppointmentHistory (appointment_id);

-- =====================================================
-- ADMISSION TABLE INDEXES
-- =====================================================

-- Bed occupancy check: composite index for quickly determining which
-- beds are occupied, available, or under maintenance
CREATE INDEX IX_Admission_Bed_Status
    ON Admission (bed_id, status);

-- Admission billing status and date (embedded billing)
CREATE INDEX IX_Admission_BillingStatus
    ON Admission (billing_status);
CREATE INDEX IX_Admission_BillingDate
    ON Admission (billing_date);

-- =====================================================
-- EMPLOYEE TABLE INDEXES
-- =====================================================

-- Doctor specialization lookup: supports filtering doctors by specialization
CREATE INDEX IX_Employee_Specialization
    ON Employee (specialization);

-- =====================================================
-- PATIENT TABLE INDEXES
-- =====================================================

-- Patient name search: supports lookup by last name (most common search pattern)
-- and composite with first name for narrowing results
CREATE INDEX IX_Patient_Name
    ON Patient (last_name, first_name);
