# Part B Implementation Plan -- Hospital Management System

## Appointment Management Module

**Course:** DMDD 6210  
**Team:** Darshan Aswathappa, Nireeksha Huns  
**Target RDBMS:** Microsoft SQL Server (T-SQL)  
**Date:** 2026-04-13

---

## 1. Project Overview

Part B implements the database design from Part A by developing SQL scripts, transactions,
and business logic for the **Appointment Management** module of the Hospital Management
System. The implementation covers the full appointment lifecycle: booking, cancellation,
rescheduling, status tracking, and reporting -- plus all cross-cutting requirements (security,
billing integration, bed management validations).

### 1.1 Module Scope -- Appointment Management

| Functional Requirement    | Description                                          |
|---------------------------|------------------------------------------------------|
| Book Appointments         | Schedule a patient with a doctor on an available slot |
| Cancel Appointments       | Cancel with 24-hour advance rule                     |
| Reschedule Appointments   | Move to new slot, preserve full history               |
| Status Tracking           | Scheduled -> Completed / Cancelled / No-Show          |

### 1.2 Business Rules (from Part A)

| #  | Rule                                                        | Enforcement Method      |
|----|-------------------------------------------------------------|-------------------------|
| BR1 | No duplicate booking (same patient + same schedule slot)   | Stored Procedure + UQ   |
| BR2 | Cancellation allowed only 24 hours before appointment      | Stored Procedure check  |
| BR3 | Rescheduling keeps full appointment history                | Trigger + History table |
| BR4 | Maximum 5 appointments per doctor per day                  | Stored Procedure check  |
| BR5 | Appointment cannot be scheduled during doctor vacation     | Stored Procedure check  |
| BR6 | Doctor schedule cannot overlap                             | UNIQUE constraint       |

### 1.3 Mandatory Transaction Validations (from Part B Requirements)

| #  | Validation                                           | How Demonstrated                      |
|----|------------------------------------------------------|---------------------------------------|
| TV1 | Duplicate Booking Prevention                        | Test case: same patient+slot -> error |
| TV2 | Assigning occupied bed, transaction must fail        | Test case: admit to occupied bed      |
| TV3 | Bills with insurance must apply correct discount     | Test case: billing with coverage %    |

---

## 2. Folder Structure

```
Hospital-Management-System/
|
|-- README.md                          # Project overview, setup instructions, team info
|
|-- P1/                                # Part A deliverables (for reference)
|   |-- PartA.pdf                      # Submitted Part A document
|   |-- ER_Diagram.png                 # Conceptual ER diagram
|   |-- Logical_Design.png             # Relational model diagram
|
|-- DDL/                               # Data Definition Language scripts
|   |-- 01_create_database.sql         # CREATE DATABASE, USE statements (Sys Admin)
|   |-- 02_create_schemas.sql          # CREATE SCHEMA for logical grouping
|   |-- 03_create_tables.sql           # All 15 tables with constraints
|   |-- 04_create_indexes.sql          # Composite and covering indexes
|   |-- 05_create_views.sql            # v_appointment, v_billing, v_bed_status, etc.
|   |-- 06_create_roles_security.sql   # Admin, Operator roles and permissions
|
|-- DML/                               # Data Manipulation Language scripts
|   |-- 01_seed_departments.sql        # Reference data: departments
|   |-- 02_seed_doctors.sql            # 15 doctors + schedules + vacations
|   |-- 03_seed_staff.sql              # Staff members
|   |-- 04_seed_patients.sql           # 200 patients + guardians + insurance
|   |-- 05_seed_rooms_beds.sql         # 25 rooms with 50 beds + 25 rooms with 1 bed
|   |-- 06_seed_appointments.sql       # 50 appointments across various statuses
|   |-- 07_seed_admissions.sql         # 10 admissions
|   |-- 08_seed_prescriptions.sql      # Prescriptions linked to appointments/admissions
|   |-- 09_seed_billing_payments.sql   # Billing records + payments
|
|-- Procedures/                        # Stored Procedures and Functions
|   |-- sp_BookAppointment.sql         # Book with all validations
|   |-- sp_CancelAppointment.sql       # Cancel with 24-hour rule
|   |-- sp_RescheduleAppointment.sql   # Reschedule with history logging
|   |-- sp_GetDoctorAvailability.sql   # Check available slots for a doctor
|   |-- sp_CompleteAppointment.sql     # Mark appointment completed + generate bill
|   |-- fn_GetDoctorDailyCount.sql     # Function: count appointments per doctor per day
|   |-- fn_IsDoctorOnVacation.sql      # Function: check vacation overlap
|
|-- Triggers/                          # Database Triggers
|   |-- trg_AppointmentHistory.sql     # Log every status change to AppointmentHistory
|   |-- trg_PreventOccupiedBed.sql     # Block assigning an occupied bed
|   |-- trg_BillingInsDiscount.sql     # Auto-apply insurance discount on billing insert
|
|-- Reports/                           # Report Queries (5 minimum)
|   |-- rpt_DailyAppointments.sql      # Daily appointments report
|   |-- rpt_DoctorSchedule.sql         # Doctor schedule report
|   |-- rpt_BedOccupancy.sql           # Bed occupancy report
|   |-- rpt_Revenue.sql                # Revenue report
|   |-- rpt_CancellationStats.sql      # Cancellation statistics
|
|-- Tests/                             # Test Case Scripts
|   |-- TC01_DuplicateBooking.sql      # Verify duplicate booking is prevented
|   |-- TC02_CancelBefore24hr.sql      # Verify 24-hour cancellation rule
|   |-- TC03_MaxApptsPerDay.sql        # Verify max 5 appointments per doctor/day
|   |-- TC04_VacationBlocking.sql      # Verify vacation date blocking
|   |-- TC05_RescheduleHistory.sql     # Verify history is preserved on reschedule
|   |-- TC06_OccupiedBedFail.sql       # Verify occupied bed assignment fails
|   |-- TC07_InsuranceDiscount.sql     # Verify insurance discount calculation
|   |-- TC08_ScheduleOverlap.sql       # Verify doctor schedule overlap prevention
|
|-- Docs/                              # Documentation
|   |-- BusinessRules.md               # Business rule documentation
|   |-- TestCaseReport.md              # Test case report with results
|   |-- ExecutionGuide.md              # Step-by-step execution instructions
```

---

## 3. Implementation Phases

### Phase 1: DDL -- Database and Table Creation

**Objective:** Create the database, all 15 tables, constraints, indexes, and views exactly as
designed in Part A.

#### 3.1 Database Creation (`DDL/01_create_database.sql`)

- Use **Sys Admin** (sa) login to create the database
- Set recovery model, collation
- Create a dedicated schema (e.g., `HMS`) for all hospital objects

```
Sys Admin tasks ONLY:
  - CREATE DATABASE HospitalManagementDB
  - CREATE LOGIN / CREATE USER for Admin and Operator
  - ALTER DATABASE settings if needed
```

#### 3.2 Table Creation Order (`DDL/03_create_tables.sql`)

Tables must be created in dependency order to satisfy FK constraints:

| Order | Table              | Dependencies (FK targets)                    |
|-------|--------------------|----------------------------------------------|
| 1     | Insurance          | None                                         |
| 2     | Department         | None (head_doctor_id added later via ALTER)   |
| 3     | Doctor             | Department                                   |
| 4     | --                 | ALTER Department ADD FK to Doctor (head)      |
| 5     | Staff              | Department                                   |
| 6     | Patient            | Insurance                                    |
| 7     | Guardian           | Patient                                      |
| 8     | DoctorSchedule     | Doctor                                       |
| 9     | DoctorVacation     | Doctor, Doctor (approved_by)                  |
| 10    | Appointment        | Patient, DoctorSchedule                      |
| 11    | AppointmentHistory | Appointment, DoctorSchedule, Doctor           |
| 12    | Room               | Department                                   |
| 13    | Bed                | Room                                         |
| 14    | Admission          | Patient, Bed, Doctor, Doctor (icu_approved)   |
| 15    | Prescription       | Appointment, Admission                       |
| 16    | Billing            | Admission, Appointment                       |
| 17    | Payment            | Billing, Staff (processed_by)                |

#### 3.3 Key Constraints per Table (Appointment-Related)

**DoctorSchedule:**
- PK: `schedule_id` (INT IDENTITY)
- FK: `doctor_id` -> Doctor
- UNIQUE: `(doctor_id, schedule_date, slot_time)` -- prevents schedule overlap
- CHECK: `slot_duration_mins IN (15, 30, 45, 60)`
- CHECK: `max_appointments >= 1 AND max_appointments <= 5`
- DEFAULT: `is_available = 1`

**DoctorVacation:**
- PK: `vacation_id` (INT IDENTITY)
- FK: `doctor_id` -> Doctor, `approved_by` -> Doctor
- CHECK: `end_date >= start_date`
- CHECK: `status IN ('Pending', 'Approved', 'Rejected')`

**Appointment:**
- PK: `appointment_id` (INT IDENTITY)
- FK: `patient_id` -> Patient, `schedule_id` -> DoctorSchedule
- UNIQUE: `(patient_id, schedule_id)` -- prevents duplicate booking at DB level
- CHECK: `status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')`
- CHECK: `visit_type IN ('In-Person', 'Teleconsultation')`

**AppointmentHistory:**
- PK: `history_id` (INT IDENTITY)
- FK: `appointment_id` -> Appointment
- FK: `previous_schedule_id` -> DoctorSchedule (nullable)
- FK: `changed_by` -> Doctor (nullable, for system-initiated changes)
- `previous_slot_time` stored as audit snapshot (documented 3NF exception from Part A)

#### 3.4 Indexes (`DDL/04_create_indexes.sql`)

| Index Name                        | Table            | Columns                          | Purpose                          |
|-----------------------------------|------------------|----------------------------------|----------------------------------|
| IX_Appt_Patient                   | Appointment      | patient_id                       | Patient appointment lookup       |
| IX_Appt_Schedule                  | Appointment      | schedule_id                      | Schedule-based lookup            |
| IX_Appt_Status                    | Appointment      | status                           | Filter by status                 |
| IX_DoctorSched_DoctorDate         | DoctorSchedule   | doctor_id, schedule_date         | Daily schedule lookup            |
| IX_DoctorVac_DoctorDates          | DoctorVacation   | doctor_id, start_date, end_date  | Vacation overlap check           |
| IX_ApptHist_Appointment           | AppointmentHistory| appointment_id                  | History retrieval                |
| IX_Billing_Appointment            | Billing          | appointment_id                   | Bill lookup by appointment       |
| IX_Admission_Bed_Status           | Admission        | bed_id, status                   | Bed occupancy check              |

#### 3.5 Views (`DDL/05_create_views.sql`)

As noted in Part A, derived columns removed for 3NF are recovered via views:

| View Name          | Purpose                                                    |
|--------------------|------------------------------------------------------------|
| v_appointment      | Joins Appointment + DoctorSchedule + Patient + Doctor      |
| v_prescription     | Joins Prescription + Patient + Doctor (via FK chains)      |
| v_billing          | Joins Billing + Patient + Insurance (via FK chains)        |
| v_payment          | Joins Payment + Billing + Patient                          |
| v_bed_status       | Derives bed occupancy from Admission status                |
| v_doctor_schedule  | Doctor name + department + schedule slots + vacancy check  |

#### 3.6 Security & Roles (`DDL/06_create_roles_security.sql`)

| Role     | Access Level | Permissions                                              |
|----------|-------------|----------------------------------------------------------|
| Admin    | Full access | ALL on all tables, procedures, views                     |
| Operator | Execute     | EXECUTE on stored procedures, SELECT on views and tables |

Implementation:
```
1. CREATE ROLE HospitalAdmin
2. CREATE ROLE HospitalOperator
3. GRANT ALL on SCHEMA::HMS TO HospitalAdmin
4. GRANT SELECT on SCHEMA::HMS TO HospitalOperator
5. GRANT EXECUTE on SCHEMA::HMS TO HospitalOperator
6. CREATE USER admin_user FOR LOGIN admin_login -> add to HospitalAdmin
7. CREATE USER operator_user FOR LOGIN operator_login -> add to HospitalOperator
```

---

### Phase 2: DML -- Sample Data Seeding

**Objective:** Insert required volumes of realistic sample data.

#### 2.1 Data Volume Requirements

| Entity       | Count  | Script                        | Notes                                   |
|--------------|--------|-------------------------------|-----------------------------------------|
| Departments  | 8      | 01_seed_departments.sql       | Cardiology, Orthopedics, Neurology, etc.|
| Doctors      | 15     | 02_seed_doctors.sql           | Spread across departments               |
| Staff        | 20+    | 03_seed_staff.sql             | Nurses, technicians, admin staff        |
| Patients     | 200    | 04_seed_patients.sql          | Include minors with guardians           |
| Insurance    | 30+    | 04_seed_patients.sql          | Multiple plans, some expired            |
| Guardians    | 20+    | 04_seed_patients.sql          | For minor patients                      |
| Rooms        | 50     | 05_seed_rooms_beds.sql        | 25 rooms x 2 beds + 25 rooms x 1 bed   |
| Beds         | 75     | 05_seed_rooms_beds.sql        | 50 beds (multi) + 25 beds (single)      |
| DoctorSchedule| 150+  | 02_seed_doctors.sql           | Slots across multiple days              |
| DoctorVacation| 5+    | 02_seed_doctors.sql           | Some approved, some pending             |
| Appointments | 50     | 06_seed_appointments.sql      | Mix of statuses                         |
| Admissions   | 10     | 07_seed_admissions.sql        | Active + discharged                     |
| Prescriptions| 30+    | 08_seed_prescriptions.sql     | Linked to appointments and admissions   |
| Billing      | 40+    | 09_seed_billing_payments.sql  | Appointment + admission bills           |
| Payments     | 50+    | 09_seed_billing_payments.sql  | Full, partial, pending payments         |

#### 2.2 Sample Data Design Decisions

- **Appointments** must span multiple statuses: ~30 Scheduled, ~10 Completed, ~7 Cancelled, ~3 No-Show
- **Insurance** policies: mix of active/expired, varying coverage percentages (50%, 70%, 80%, 100%)
- **Doctor schedules**: 30-minute and 60-minute slots, max_appointments = 3-5 per slot type
- **Patients**: include 20+ minors (date_of_birth making them < 18) with guardian records
- **Billing**: include records with and without insurance to test discount logic
- Rooms: types include 'General', 'ICU', 'Private', 'Semi-Private', 'Operation Theatre'
- Beds: types include 'Standard', 'Electric', 'ICU', 'Bariatric'

---

### Phase 3: Stored Procedures and Functions

**Objective:** Implement 5+ procedures/functions encapsulating core Appointment Management
business logic and cross-module transaction validations.

#### 3.1 sp_BookAppointment

**Purpose:** Book a new appointment with full validation.

**Parameters:**
- `@patient_id INT`
- `@schedule_id INT`
- `@visit_type VARCHAR(20)` -- 'In-Person' or 'Teleconsultation'
- `@reason VARCHAR(500)`

**Validation Steps (in order):**
1. Verify patient exists and is active
2. Verify schedule slot exists and `is_available = 1`
3. Check doctor is NOT on vacation for that schedule_date (call `fn_IsDoctorOnVacation`)
4. Check duplicate booking: no existing Appointment with same `patient_id + schedule_id`
   where `status IN ('Scheduled')`
5. Check max appointments per day: count of Scheduled appointments for that doctor on
   that date must be < `DoctorSchedule.max_appointments` (and <= 5 hard cap)
6. If all pass: INSERT into Appointment with `status = 'Scheduled'`
7. Return the new `appointment_id`

**Transaction:** Wrapped in `BEGIN TRAN ... COMMIT/ROLLBACK` with `TRY...CATCH`

#### 3.2 sp_CancelAppointment

**Purpose:** Cancel an appointment enforcing the 24-hour rule.

**Parameters:**
- `@appointment_id INT`
- `@cancellation_reason VARCHAR(500)`

**Validation Steps:**
1. Verify appointment exists and `status = 'Scheduled'`
2. Get the appointment's schedule_date + slot_time from DoctorSchedule
3. Check: `DATEDIFF(HOUR, GETDATE(), schedule_datetime) >= 24`
   - If < 24 hours, RAISERROR and ROLLBACK
4. UPDATE Appointment SET `status = 'Cancelled'`, `cancelled_at = GETDATE()`
5. History is logged automatically by `trg_AppointmentHistory`

#### 3.3 sp_RescheduleAppointment

**Purpose:** Move appointment to a new slot, preserving history.

**Parameters:**
- `@appointment_id INT`
- `@new_schedule_id INT`
- `@change_reason VARCHAR(500)`

**Validation Steps:**
1. Verify appointment exists and `status = 'Scheduled'`
2. Verify new schedule slot exists and is available
3. Verify new slot is not during doctor vacation
4. Verify no duplicate at new slot for this patient
5. Verify max appointments per day not exceeded at new slot
6. Store old `schedule_id` and old `status` for history
7. UPDATE Appointment SET `schedule_id = @new_schedule_id`
8. INSERT into AppointmentHistory (old schedule, old status, new status, reason, timestamp)
   - Note: trigger can also handle this, but explicit insert gives more control for reschedule

#### 3.4 sp_GetDoctorAvailability

**Purpose:** Return available schedule slots for a given doctor within a date range.

**Parameters:**
- `@doctor_id INT`
- `@start_date DATE`
- `@end_date DATE`

**Logic:**
1. SELECT from DoctorSchedule WHERE `doctor_id = @doctor_id`
   AND `schedule_date BETWEEN @start_date AND @end_date`
   AND `is_available = 1`
2. LEFT JOIN with Appointment (status = 'Scheduled') to get current booking count
3. EXCLUDE dates that fall within any approved DoctorVacation range
4. Return: schedule_id, schedule_date, slot_time, slots_remaining

#### 3.5 sp_CompleteAppointment

**Purpose:** Mark appointment as completed and generate a billing record.

**Parameters:**
- `@appointment_id INT`
- `@notes VARCHAR(2000)` (optional clinical notes)
- `@bill_amount DECIMAL(10,2)`

**Logic:**
1. Verify appointment exists and `status = 'Scheduled'`
2. UPDATE Appointment SET `status = 'Completed'`, `notes = @notes`
3. Determine patient's active insurance via FK chain:
   `Appointment -> Patient -> Insurance (WHERE is_active = 1 AND valid_until >= GETDATE())`
4. Calculate insurance coverage: `@bill_amount * (coverage_percentage / 100.0)`
   - Cap at `max_coverage_amount`
5. INSERT into Billing: `total_amount`, `insurance_coverage_amt`, `status = 'Pending'`,
   `billing_date = GETDATE()`, `due_date = DATEADD(DAY, 30, GETDATE())`
6. Return bill_id

#### 3.6 fn_GetDoctorDailyCount (Scalar Function)

**Purpose:** Return the number of scheduled appointments for a doctor on a given date.

**Parameters:** `@doctor_id INT`, `@target_date DATE`  
**Returns:** INT

**Logic:**
```
SELECT COUNT(*) FROM Appointment a
JOIN DoctorSchedule ds ON a.schedule_id = ds.schedule_id
WHERE ds.doctor_id = @doctor_id
  AND ds.schedule_date = @target_date
  AND a.status = 'Scheduled'
```

#### 3.7 fn_IsDoctorOnVacation (Scalar Function)

**Purpose:** Check if a doctor has an approved vacation overlapping a given date.

**Parameters:** `@doctor_id INT`, `@check_date DATE`  
**Returns:** BIT (1 = on vacation, 0 = available)

**Logic:**
```
IF EXISTS (
  SELECT 1 FROM DoctorVacation
  WHERE doctor_id = @doctor_id
    AND status = 'Approved'
    AND @check_date BETWEEN start_date AND end_date
) RETURN 1
ELSE RETURN 0
```

---

### Phase 4: Triggers

**Objective:** Implement triggers for automated enforcement and audit logging.

#### 4.1 trg_AppointmentHistory (AFTER UPDATE on Appointment)

**Fires:** After any UPDATE on the Appointment table  
**Action:** If `status` or `schedule_id` changed, INSERT a row into AppointmentHistory capturing:
- `appointment_id`
- `previous_schedule_id` (from DELETED)
- `previous_status` (from DELETED)
- `new_status` (from INSERTED)
- `previous_slot_time` (snapshot from DoctorSchedule via old schedule_id)
- `changed_at = GETDATE()`

#### 4.2 trg_PreventOccupiedBed (INSTEAD OF INSERT on Admission)

**Fires:** Before INSERT into Admission  
**Action:**
1. Check if the target `bed_id` already has an active admission (`status = 'Active'`)
2. If occupied -> RAISERROR('Bed is currently occupied. Transaction failed.') and do NOT insert
3. If available -> proceed with INSERT
4. This satisfies **TV2: Assigning occupied bed, transaction must fail**

#### 4.3 trg_BillingInsuranceDiscount (AFTER INSERT on Billing)

**Fires:** After INSERT into Billing  
**Action:**
1. For the new billing row, trace to the patient's active insurance
2. Calculate: `discount = total_amount * (coverage_percentage / 100.0)`
3. Cap at `max_coverage_amount`
4. UPDATE the billing row: `insurance_coverage_amt = discount`
5. This satisfies **TV3: Bills with insurance must apply correct discount**

---

### Phase 5: Reports

**Objective:** Create 5 reporting queries as required.

#### 5.1 rpt_DailyAppointments -- Daily Appointments Report

**Description:** List all appointments for a given date with patient name, doctor name,
department, time slot, visit type, and status.

**Key Joins:** Appointment -> DoctorSchedule -> Doctor -> Department; Appointment -> Patient

**Parameters:** `@report_date DATE`

**Output Columns:**
- Appointment ID, Patient Name, Doctor Name, Department, Schedule Date, Slot Time,
  Visit Type, Status, Reason

#### 5.2 rpt_DoctorSchedule -- Doctor Schedule Report

**Description:** Show each doctor's schedule for a given date range with slot availability and
booked patient info.

**Key Joins:** Doctor -> DoctorSchedule LEFT JOIN Appointment LEFT JOIN Patient

**Parameters:** `@doctor_id INT (optional)`, `@start_date DATE`, `@end_date DATE`

**Output Columns:**
- Doctor Name, Specialization, Date, Slot Time, Duration, Max Appointments,
  Current Bookings, Slots Remaining, On Vacation (Y/N)

#### 5.3 rpt_BedOccupancy -- Bed Occupancy Report

**Description:** Show all rooms and beds with current occupancy status, patient info for
occupied beds, and overall occupancy percentage.

**Key Joins:** Room -> Bed LEFT JOIN Admission (active) LEFT JOIN Patient

**Output Columns:**
- Room Number, Room Type, Floor, Bed Number, Bed Type, Status (Available/Occupied/Maintenance),
  Patient Name (if occupied), Admission Date
- Summary row: Total Beds, Occupied, Available, Occupancy %

#### 5.4 rpt_Revenue -- Revenue Report

**Description:** Summarize revenue by date range, broken down by source (appointment vs.
admission), insurance vs. self-pay, and payment status.

**Key Joins:** Billing LEFT JOIN Payment, Billing -> Appointment/Admission

**Parameters:** `@start_date DATE`, `@end_date DATE`

**Output Columns:**
- Period, Total Billed, Insurance Coverage Applied, Net Patient Liability,
  Total Collected, Outstanding Balance
- Breakdown by: Appointment Revenue vs. Admission Revenue

#### 5.5 rpt_CancellationStats -- Cancellation Statistics

**Description:** Analyze appointment cancellations by doctor, department, time period, and
reason patterns.

**Key Joins:** Appointment (Cancelled) -> DoctorSchedule -> Doctor -> Department;
AppointmentHistory for cancellation reasons

**Parameters:** `@start_date DATE`, `@end_date DATE`

**Output Columns:**
- Doctor Name, Department, Total Appointments, Cancelled Count, Cancellation Rate %,
  Most Common Reason, Avg Days Before Appointment When Cancelled

---

### Phase 6: Test Cases

**Objective:** Minimum 5 test cases covering business rules and transaction validations.

#### Test Case Matrix

| TC# | Test Case                          | Type                | Expected Result                                    | Business Rule |
|-----|------------------------------------|---------------------|----------------------------------------------------|---------------|
| TC01 | Book duplicate appointment        | Transaction (TV1)   | Error: Duplicate booking prevented                 | BR1           |
| TC02 | Cancel within 24 hours            | Business Rule       | Error: Cancellation denied (< 24 hrs)              | BR2           |
| TC03 | Exceed 5 appointments per day     | Business Rule       | Error: Maximum daily limit reached                 | BR4           |
| TC04 | Book during doctor vacation       | Business Rule       | Error: Doctor on approved vacation                 | BR5           |
| TC05 | Reschedule and verify history     | Audit               | History row created with old slot + status          | BR3           |
| TC06 | Assign occupied bed               | Transaction (TV2)   | Error: Bed occupied, transaction rolled back        | Admission rule|
| TC07 | Bill with insurance discount      | Transaction (TV3)   | Insurance coverage_amt = total * coverage%          | Billing rule  |
| TC08 | Book overlapping doctor schedule  | Constraint          | Error: Unique constraint violation on schedule      | BR6           |

#### Test Case Script Structure

Each test case file follows this template:
```sql
-- =====================================================
-- Test Case: TC01 - Duplicate Booking Prevention
-- Business Rule: BR1
-- Expected: Error raised, no duplicate row inserted
-- =====================================================

-- SETUP: Ensure a known appointment exists
-- ACTION: Attempt to book same patient + same slot
-- VERIFY: Check error message and row count unchanged
-- CLEANUP: (optional) remove test data
```

---

### Phase 7: Business Rule Documentation

**Location:** `Docs/BusinessRules.md`

Document each rule with:
1. **Rule ID** and description
2. **Source** (Part A requirement reference)
3. **Enforcement mechanism** (constraint, procedure, trigger)
4. **Where implemented** (file path)
5. **How tested** (test case reference)

---

## 4. Table Schemas (Quick Reference from Part A)

### 4.1 Core Appointment Tables

```
Appointment
-----------
  appointment_id    INT IDENTITY PRIMARY KEY
  patient_id        INT NOT NULL  -> FK Patient
  schedule_id       INT NOT NULL  -> FK DoctorSchedule
  status            VARCHAR(20) NOT NULL CHECK (IN Scheduled/Completed/Cancelled/No-Show)
  visit_type        VARCHAR(20) NOT NULL CHECK (IN In-Person/Teleconsultation)
  reason            VARCHAR(500)
  notes             VARCHAR(2000)
  cancelled_at      DATETIME NULL
  created_at        DATETIME DEFAULT GETDATE()
  updated_at        DATETIME DEFAULT GETDATE()
  UNIQUE(patient_id, schedule_id)

DoctorSchedule
--------------
  schedule_id         INT IDENTITY PRIMARY KEY
  doctor_id           INT NOT NULL  -> FK Doctor
  schedule_date       DATE NOT NULL
  slot_time           TIME NOT NULL
  slot_duration_mins  INT NOT NULL CHECK (IN 15/30/45/60)
  max_appointments    INT NOT NULL DEFAULT 5 CHECK (BETWEEN 1 AND 5)
  is_available        BIT DEFAULT 1
  created_at          DATETIME DEFAULT GETDATE()
  UNIQUE(doctor_id, schedule_date, slot_time)

DoctorVacation
--------------
  vacation_id   INT IDENTITY PRIMARY KEY
  doctor_id     INT NOT NULL  -> FK Doctor
  approved_by   INT NULL      -> FK Doctor
  start_date    DATE NOT NULL
  end_date      DATE NOT NULL CHECK (>= start_date)
  reason        VARCHAR(500)
  status        VARCHAR(20) DEFAULT 'Pending' CHECK (IN Pending/Approved/Rejected)
  created_at    DATETIME DEFAULT GETDATE()

AppointmentHistory
------------------
  history_id            INT IDENTITY PRIMARY KEY
  appointment_id        INT NOT NULL -> FK Appointment
  previous_schedule_id  INT NULL     -> FK DoctorSchedule
  changed_by            INT NULL     -> FK Doctor
  previous_status       VARCHAR(20)
  new_status            VARCHAR(20)
  previous_slot_time    TIME         -- audit snapshot (documented 3NF exception)
  change_reason         VARCHAR(500)
  changed_at            DATETIME DEFAULT GETDATE()
```

### 4.2 Supporting Tables (Required for FK Integrity)

All 15 tables from Part A are created in `DDL/03_create_tables.sql`. The full schema is
defined in Part A Section 6 (Relational Model). Key supporting tables:

- **Patient**: patient_id, insurance_id (FK), first_name, last_name, date_of_birth, gender,
  blood_type, phone, email, address, guardian_name, guardian_phone, guardian_relationship
- **Doctor**: doctor_id, department_id (FK), first_name, last_name, specialization,
  license_number, phone, email, status, hire_date
- **Department**: department_id, head_doctor_id (FK), name, location, phone
- **Insurance**: insurance_id, provider_name, policy_number, plan_type, coverage_percentage,
  max_coverage_amount, valid_from, valid_until, is_active
- **Room**: room_id, department_id (FK), room_number, room_type, floor, is_active
- **Bed**: bed_id, room_id (FK), bed_number, bed_type, is_maintenance
- **Admission**: admission_id, patient_id (FK), bed_id (FK), admitting_doctor_id (FK),
  icu_approved_by (FK), admission_type, diagnosis, status, discharge_notes,
  admission_datetime, discharge_datetime
- **Billing**: bill_id, admission_id (FK), appointment_id (FK), total_amount,
  insurance_coverage_amt, status, billing_date, due_date
- **Payment**: payment_id, bill_id (FK), processed_by (FK), amount, payment_method,
  transaction_ref, status, payment_date
- **Prescription**: prescription_id, appointment_id (FK), admission_id (FK), medication_name,
  dosage, frequency, duration_days, instructions, prescribed_at
- **Staff**: staff_id, department_id (FK), first_name, last_name, role, phone, email,
  employment_status, hire_date
- **Guardian**: (embedded in Patient per Part A design -- guardian_name, guardian_phone,
  guardian_relationship columns)

---

## 5. Git Commit Strategy

The project requires **multiple commits over time** with proper structure. Follow this commit
plan to demonstrate incremental development:

| Commit # | Description                                  | Files Changed                          |
|----------|----------------------------------------------|----------------------------------------|
| 1        | Initial project structure and README         | README.md, folder structure            |
| 2        | Add Part A deliverables                      | P1/PartA.pdf, diagrams                 |
| 3        | DDL: Database and schema creation            | DDL/01, DDL/02                         |
| 4        | DDL: Core table creation (all 15 tables)     | DDL/03                                 |
| 5        | DDL: Indexes and views                       | DDL/04, DDL/05                         |
| 6        | DDL: Security roles and permissions          | DDL/06                                 |
| 7        | DML: Seed departments, doctors, staff        | DML/01, DML/02, DML/03                |
| 8        | DML: Seed patients, rooms, beds              | DML/04, DML/05                         |
| 9        | DML: Seed appointments and admissions        | DML/06, DML/07                         |
| 10       | DML: Seed prescriptions, billing, payments   | DML/08, DML/09                         |
| 11       | Stored procedures: Book, Cancel, Reschedule  | Procedures/sp_Book, sp_Cancel, sp_Resch|
| 12       | Stored procedures: Availability, Complete    | Procedures/sp_GetDoctor, sp_Complete   |
| 13       | Functions: Daily count, vacation check       | Procedures/fn_*                        |
| 14       | Triggers: History, occupied bed, insurance   | Triggers/trg_*                         |
| 15       | Reports: All 5 report queries               | Reports/rpt_*                          |
| 16       | Test cases: All 8 test scripts               | Tests/TC*                              |
| 17       | Documentation: Business rules, test report   | Docs/*                                 |
| 18       | Final review and cleanup                     | Various                                |

**Commit message format:** `<type>: <description>` (e.g., `feat: add appointment booking stored procedure`)

---

## 6. Execution Order

When running the entire project from scratch on a fresh SQL Server instance:

```
Step 1:  DDL/01_create_database.sql        (run as Sys Admin / sa)
Step 2:  DDL/02_create_schemas.sql         (run as Sys Admin / sa)
Step 3:  DDL/03_create_tables.sql          (run as Admin)
Step 4:  DDL/04_create_indexes.sql         (run as Admin)
Step 5:  DDL/05_create_views.sql           (run as Admin)
Step 6:  DDL/06_create_roles_security.sql  (run as Sys Admin / sa)
Step 7:  DML/01 through DML/09            (run as Admin, in order)
Step 8:  Procedures/sp_* and fn_*          (run as Admin)
Step 9:  Triggers/trg_*                    (run as Admin)
Step 10: Reports/rpt_*                     (run as Admin or Operator)
Step 11: Tests/TC*                         (run as Operator to verify permissions)
```

---

## 7. Checklist -- Part B Requirements Coverage

| Requirement                         | Covered In                             | Status   |
|-------------------------------------|----------------------------------------|----------|
| DDL Scripts (Sys Admin where needed)| DDL/01-06                              | Planned  |
| Stored Procedures (min 3-5)         | 5 procedures + 2 functions = 7 total   | Planned  |
| Triggers (Optional)                 | 3 triggers                             | Planned  |
| Sample Data Scripts                 | DML/01-09                              | Planned  |
| Business Rule Documentation         | Docs/BusinessRules.md                  | Planned  |
| Test Case Report (min 5)            | 8 test cases in Tests/ + Docs/TestCaseReport.md | Planned |
| Security: Admin (Full access)       | DDL/06                                 | Planned  |
| Security: Operator (Execute access) | DDL/06                                 | Planned  |
| Report: Daily appointments          | Reports/rpt_DailyAppointments.sql      | Planned  |
| Report: Doctor schedule             | Reports/rpt_DoctorSchedule.sql         | Planned  |
| Report: Bed occupancy               | Reports/rpt_BedOccupancy.sql           | Planned  |
| Report: Revenue                     | Reports/rpt_Revenue.sql                | Planned  |
| Report: Cancellation statistics     | Reports/rpt_CancellationStats.sql      | Planned  |
| TV1: Duplicate Booking Prevention   | sp_BookAppointment + TC01              | Planned  |
| TV2: Occupied bed must fail         | trg_PreventOccupiedBed + TC06          | Planned  |
| TV3: Insurance discount on billing  | trg_BillingInsDiscount + TC07          | Planned  |
| Data: 200 patients                  | DML/04                                 | Planned  |
| Data: 15 doctors                    | DML/02                                 | Planned  |
| Data: 50 appointments               | DML/06                                 | Planned  |
| Data: 10 admissions                 | DML/07                                 | Planned  |
| Data: 25 rooms with 50 beds         | DML/05                                 | Planned  |
| Data: 25 rooms with 1 bed           | DML/05                                 | Planned  |
| GitHub: Multiple commits over time  | Git Commit Strategy (Section 5)        | Planned  |
| GitHub: Proper structure            | Folder Structure (Section 2)           | Planned  |
| Module fully implemented            | Appointment Management                 | Planned  |

---

## 8. Notes and Assumptions

1. **RDBMS**: SQL Server is assumed based on "Sys Admin" terminology in Part B requirements.
   If PostgreSQL is required instead, stored procedures use PL/pgSQL syntax, triggers use
   `CREATE OR REPLACE FUNCTION` + `CREATE TRIGGER`, and Sys Admin maps to the
   `postgres` superuser.

2. **Guardian**: Per Part A design, guardian info is stored as columns on Patient table
   (guardian_name, guardian_phone, guardian_relationship) rather than a separate Guardian
   table. This is a simplification that satisfies the requirement while maintaining 1NF.

3. **3NF Views**: Since Part A removed derived columns for strict 3NF, the views
   (v_appointment, v_billing, etc.) are critical for usability. Stored procedures and reports
   will join through these views or replicate the join logic directly.

4. **AppointmentHistory.previous_slot_time**: Stored as an intentional audit snapshot,
   documented as a 3NF exception in Part A. This is not a normalization violation -- it is
   standard practice for immutable audit tables where source data may change.

5. **Billing Context**: Each billing record links to either an appointment_id OR an admission_id
   (not both). This "dual-context" model from Part A is preserved.

6. **Insurance Discount Calculation**: `discount = MIN(total_amount * coverage_percentage / 100, max_coverage_amount)`.
   Only applied when the patient has an active, non-expired insurance policy.
