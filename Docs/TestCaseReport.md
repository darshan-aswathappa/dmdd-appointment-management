# Test Case Report

**Project:** Hospital Management System - Appointment Management Module  
**Course:** DMDD 6210  
**Team:** Darshan Aswathappa, Nireeksha Huns  
**Schema:** HMS  
**RDBMS:** Microsoft SQL Server (T-SQL)

---

## Test Case Summary

| TC# | Name | Business Rule | Script | Status |
|-----|------|---------------|--------|--------|
| TC01 | Duplicate Booking Prevention | BR1 / TV1 | `Tests/TC01_DuplicateBooking.sql` | Planned |
| TC02 | 24-Hour Cancellation Rule | BR2 | `Tests/TC02_CancelBefore24hr.sql` | Planned |
| TC03 | Max Appointments Per Day | BR4 | `Tests/TC03_MaxApptsPerDay.sql` | Planned |
| TC04 | Vacation Blocking | BR5 | `Tests/TC04_VacationBlocking.sql` | Planned |
| TC05 | Reschedule History Preservation | BR3 | `Tests/TC05_RescheduleHistory.sql` | Planned |
| TC06 | Occupied Bed Assignment Fails | TV2 | `Tests/TC06_OccupiedBedFail.sql` | Planned |
| TC07 | Insurance Discount Calculation | TV3 | `Tests/TC07_InsuranceDiscount.sql` | Planned |
| TC08 | Doctor Schedule Overlap Prevention | BR6 | `Tests/TC08_ScheduleOverlap.sql` | Planned |

---

## Detailed Test Cases

### TC01 - Duplicate Booking Prevention

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC01 |
| **Name** | Duplicate Booking Prevention |
| **Business Rule** | BR1 - No duplicate booking (same patient + same schedule slot) |
| **Transaction Validation** | TV1 |
| **Preconditions** | Patient and DoctorSchedule records exist. No prior appointment for this patient-schedule pair. |
| **Setup** | Book an appointment for patient P1 on schedule slot S1 using `sp_BookAppointment`. Confirm it succeeds. |
| **Steps** | 1. Execute `sp_BookAppointment` with the same patient P1 and schedule slot S1. |
| **Expected Result** | The second call raises an error indicating a duplicate booking. No new appointment row is inserted. |
| **Actual Result** | See TC01 output |
| **Status** | Planned |

---

### TC02 - 24-Hour Cancellation Rule

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC02 |
| **Name** | 24-Hour Cancellation Rule |
| **Business Rule** | BR2 - Cancellation allowed only 24 hours before appointment |
| **Preconditions** | An appointment exists with status 'Scheduled' and a schedule datetime less than 24 hours from now. |
| **Setup** | Create or identify an appointment scheduled within the next 24 hours. |
| **Steps** | 1. Execute `sp_CancelAppointment` for the appointment. |
| **Expected Result** | The procedure raises an error stating cancellation is not allowed within 24 hours. The appointment status remains 'Scheduled'. |
| **Actual Result** | See TC02 output |
| **Status** | Planned |

---

### TC03 - Max Appointments Per Day

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC03 |
| **Name** | Maximum Appointments Per Doctor Per Day |
| **Business Rule** | BR4 - Maximum 5 appointments per doctor per day |
| **Preconditions** | A doctor has schedule slots for a given date. The doctor already has 5 scheduled appointments on that date. |
| **Setup** | Book 5 appointments for doctor D1 on date X across different patients. Verify all succeed. |
| **Steps** | 1. Execute `sp_BookAppointment` to book a 6th appointment for doctor D1 on date X with a new patient. |
| **Expected Result** | The procedure raises an error indicating the maximum appointment limit has been reached. No 6th appointment is created. |
| **Actual Result** | See TC03 output |
| **Status** | Planned |

---

### TC04 - Vacation Blocking

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC04 |
| **Name** | Vacation Date Blocking |
| **Business Rule** | BR5 - Appointment cannot be scheduled during doctor vacation |
| **Preconditions** | Doctor D1 has an approved vacation entry covering a specific date range. A schedule slot exists for D1 on a date within that vacation range. |
| **Setup** | Verify the DoctorVacation record is approved and the schedule slot date falls within the vacation period. |
| **Steps** | 1. Execute `sp_BookAppointment` for a patient on the vacation-period schedule slot. |
| **Expected Result** | The procedure raises an error indicating the doctor is on vacation. No appointment is created. |
| **Actual Result** | See TC04 output |
| **Status** | Planned |

---

### TC05 - Reschedule History Preservation

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC05 |
| **Name** | Reschedule History Preservation |
| **Business Rule** | BR3 - Rescheduling keeps full appointment history |
| **Preconditions** | A scheduled appointment exists for patient P1 on schedule slot S1. A new available schedule slot S2 exists. |
| **Setup** | Book appointment A1 for patient P1 on slot S1. Confirm it exists with status 'Scheduled'. |
| **Steps** | 1. Execute `sp_RescheduleAppointment` to move appointment A1 from slot S1 to slot S2. 2. Query `AppointmentHistory` for appointment A1. |
| **Expected Result** | The appointment is updated to reference S2. A record in `AppointmentHistory` captures the previous schedule (S1), previous slot time, change reason, and timestamp. |
| **Actual Result** | See TC05 output |
| **Status** | Planned |

---

### TC06 - Occupied Bed Assignment Fails

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC06 |
| **Name** | Occupied Bed Assignment Fails |
| **Transaction Validation** | TV2 - Assigning occupied bed must fail |
| **Preconditions** | Bed B1 has an active admission (status = 'Active'). |
| **Setup** | Verify an active admission record exists for bed B1. |
| **Steps** | 1. Attempt to INSERT a new admission record assigning bed B1 to a different patient. |
| **Expected Result** | The `trg_PreventOccupiedBed` trigger blocks the insert and raises an error indicating the bed is occupied. No new admission row is inserted. |
| **Actual Result** | See TC06 output |
| **Status** | Planned |

---

### TC07 - Insurance Discount Calculation

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC07 |
| **Name** | Insurance Discount Calculation |
| **Transaction Validation** | TV3 - Bills with insurance must apply correct discount |
| **Preconditions** | Patient P1 has active insurance with a coverage percentage (e.g., 80%). |
| **Setup** | Verify the patient's insurance record is active and has a known coverage percentage. |
| **Steps** | 1. INSERT a billing record for patient P1 with a known total amount. 2. Query the billing record to check the discount applied. |
| **Expected Result** | The `trg_BillingInsuranceDiscount` trigger automatically applies the insurance coverage percentage as a discount on the billing record. For example, an 80% coverage on a $1000 bill results in an $800 discount. |
| **Actual Result** | See TC07 output |
| **Status** | Planned |

---

### TC08 - Doctor Schedule Overlap Prevention

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC08 |
| **Name** | Doctor Schedule Overlap Prevention |
| **Business Rule** | BR6 - Doctor schedule cannot overlap |
| **Preconditions** | Doctor D1 has an existing schedule slot on date X at time T. |
| **Setup** | Verify the DoctorSchedule record exists for D1 on date X at time T. |
| **Steps** | 1. Attempt to INSERT a new DoctorSchedule row for D1 on the same date X and time T. |
| **Expected Result** | The UNIQUE constraint on `(doctor_id, schedule_date, slot_time)` raises a constraint violation error. No duplicate schedule row is inserted. |
| **Actual Result** | See TC08 output |
| **Status** | Planned |
