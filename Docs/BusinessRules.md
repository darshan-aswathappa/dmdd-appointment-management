# Business Rules Documentation

**Project:** Hospital Management System - Appointment Management Module  
**Course:** DMDD 6210  
**Team:** Darshan Aswathappa, Nireeksha Huns  
**Schema:** HMS  
**RDBMS:** Microsoft SQL Server (T-SQL)

---

## 1. Business Rules

These rules originate from the Part A design and are enforced programmatically in Part B.

| Rule ID | Description | Source | Enforcement Mechanism | Implementation File | Test Case |
|---------|-------------|--------|----------------------|---------------------|-----------|
| BR1 | No duplicate booking (same patient + same schedule slot) | Part A | Stored Procedure validation + UNIQUE constraint on `(patient_id, schedule_id)` | `Procedures/sp_BookAppointment.sql`, `DDL/03_create_tables.sql` | TC01 |
| BR2 | Cancellation allowed only 24 hours before appointment | Part A | Stored Procedure `DATEDIFF(HOUR, GETDATE(), schedule_datetime) >= 24` check | `Procedures/sp_CancelAppointment.sql` | TC02 |
| BR3 | Rescheduling keeps full appointment history | Part A | Explicit INSERT to `AppointmentHistory` table + `trg_AppointmentHistory` trigger on status change | `Procedures/sp_RescheduleAppointment.sql`, `Triggers/trg_AppointmentHistory.sql` | TC05 |
| BR4 | Maximum 5 appointments per doctor per day | Part A | Stored Procedure check using `fn_GetDoctorDailyCount`; rejects booking when count >= `max_appointments` or hard cap of 5 | `Procedures/sp_BookAppointment.sql`, `Procedures/fn_GetDoctorDailyCount.sql` | TC03 |
| BR5 | Appointment cannot be scheduled during doctor vacation | Part A | Stored Procedure check using `fn_IsDoctorOnVacation`; verifies schedule_date does not fall within any approved vacation range | `Procedures/sp_BookAppointment.sql`, `Procedures/fn_IsDoctorOnVacation.sql` | TC04 |
| BR6 | Doctor schedule cannot overlap | Part A | UNIQUE constraint on `(doctor_id, schedule_date, slot_time)` in `DoctorSchedule` table | `DDL/03_create_tables.sql` | TC08 |

### BR1 - No Duplicate Booking

- **What:** A patient cannot book two appointments for the same schedule slot.
- **Database Level:** UNIQUE constraint on `Appointment(patient_id, schedule_id)` prevents duplicates even if the stored procedure check is bypassed.
- **Procedure Level:** `sp_BookAppointment` checks for an existing appointment with `status IN ('Scheduled')` for the same patient and schedule before inserting.

### BR2 - 24-Hour Cancellation Rule

- **What:** Appointments can only be cancelled if the scheduled time is at least 24 hours in the future.
- **Enforcement:** `sp_CancelAppointment` retrieves the schedule date and slot time from `DoctorSchedule`, combines them into a datetime, and uses `DATEDIFF(HOUR, GETDATE(), schedule_datetime)` to verify the 24-hour window.
- **On Violation:** The procedure raises an error and rolls back the transaction.

### BR3 - Rescheduling Preserves History

- **What:** When an appointment is rescheduled, the previous schedule information is preserved.
- **Enforcement:** `sp_RescheduleAppointment` explicitly inserts a record into `AppointmentHistory` capturing the previous schedule ID, slot time, and change reason. Additionally, `trg_AppointmentHistory` fires on any appointment status change to log audit records.

### BR4 - Maximum 5 Appointments Per Doctor Per Day

- **What:** A doctor cannot have more than 5 scheduled appointments on a single day.
- **Enforcement:** `fn_GetDoctorDailyCount` returns the count of scheduled appointments for a given doctor and date. `sp_BookAppointment` calls this function and rejects the booking if the count meets or exceeds the `max_appointments` value from `DoctorSchedule` (capped at 5).

### BR5 - Vacation Blocking

- **What:** Appointments cannot be scheduled on dates when the doctor is on an approved vacation.
- **Enforcement:** `fn_IsDoctorOnVacation` checks whether the schedule date falls within any approved vacation period for the doctor. `sp_BookAppointment` calls this function and rejects the booking if a vacation conflict exists.

### BR6 - Doctor Schedule Overlap Prevention

- **What:** A doctor cannot have two schedule slots at the same date and time.
- **Enforcement:** The UNIQUE constraint on `DoctorSchedule(doctor_id, schedule_date, slot_time)` prevents overlapping entries at the database level. Any attempt to insert a duplicate schedule slot raises a constraint violation error.

---

## 2. Transaction Validations

These validations demonstrate transaction integrity for cross-module operations as required by Part B.

| TV ID | Description | Source | Enforcement Mechanism | Implementation File | Test Case |
|-------|-------------|--------|----------------------|---------------------|-----------|
| TV1 | Duplicate Booking Prevention | Part B Requirement | Stored Procedure check within `BEGIN TRAN...COMMIT/ROLLBACK` + UNIQUE constraint on `(patient_id, schedule_id)` | `Procedures/sp_BookAppointment.sql`, `DDL/03_create_tables.sql` | TC01 |
| TV2 | Assigning occupied bed must fail | Part B Requirement | `INSTEAD OF INSERT` trigger on Admission table checks bed occupancy; rolls back if bed is occupied | `Triggers/trg_PreventOccupiedBed.sql` | TC06 |
| TV3 | Bills with insurance must apply correct discount | Part B Requirement | `AFTER INSERT` trigger on Billing table checks patient insurance coverage and applies discount percentage automatically | `Triggers/trg_BillingInsDiscount.sql` | TC07 |

### TV1 - Duplicate Booking Prevention (Transaction)

- **Scenario:** Two concurrent sessions attempt to book the same patient for the same schedule slot.
- **Defense Layer 1:** `sp_BookAppointment` checks for existing appointments within a transaction.
- **Defense Layer 2:** The UNIQUE constraint on `Appointment(patient_id, schedule_id)` catches any race condition that bypasses the procedure check.
- **Expected Outcome:** The second booking attempt fails with an error; the database remains consistent.

### TV2 - Occupied Bed Assignment Prevention

- **Scenario:** An admission record is inserted assigning a bed that is already occupied by an active admission.
- **Enforcement:** `trg_PreventOccupiedBed` is an `INSTEAD OF INSERT` trigger that queries the Admission table for any active admission on the same bed. If found, the insert is rejected with `RAISERROR`.
- **Expected Outcome:** The INSERT is blocked; no data is written; an error message is returned.

### TV3 - Insurance Discount on Billing

- **Scenario:** A billing record is inserted for a patient who has active insurance.
- **Enforcement:** `trg_BillingInsuranceDiscount` is an `AFTER INSERT` trigger that looks up the patient's insurance coverage percentage and applies it as a discount to the billing amount.
- **Expected Outcome:** The billing record's discount field is automatically updated to reflect the correct insurance coverage percentage.

---

## 3. Rule-to-Test Mapping Summary

| Rule/TV | Test Case | Test Script |
|---------|-----------|-------------|
| BR1 / TV1 | TC01 - Duplicate Booking Prevention | `Tests/TC01_DuplicateBooking.sql` |
| BR2 | TC02 - 24-Hour Cancellation Rule | `Tests/TC02_CancelBefore24hr.sql` |
| BR4 | TC03 - Max Appointments Per Day | `Tests/TC03_MaxApptsPerDay.sql` |
| BR5 | TC04 - Vacation Blocking | `Tests/TC04_VacationBlocking.sql` |
| BR3 | TC05 - Reschedule History | `Tests/TC05_RescheduleHistory.sql` |
| TV2 | TC06 - Occupied Bed Fails | `Tests/TC06_OccupiedBedFail.sql` |
| TV3 | TC07 - Insurance Discount | `Tests/TC07_InsuranceDiscount.sql` |
| BR6 | TC08 - Schedule Overlap | `Tests/TC08_ScheduleOverlap.sql` |
