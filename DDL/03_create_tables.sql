-- =====================================================
-- FILE: 03_create_tables.sql
-- PURPOSE: Create all HMS schema tables in dependency
--          order with proper constraints and indexes
-- NOTE:    Run as the HMS user. All tables belong to
--          the connected user's schema.
--
-- REVAMP NOTES (v2):
--   1. Guardian columns are embedded in Patient (no separate Guardian table).
--   2. Doctor and Staff are merged into a single Employee table with an
--      employee_type discriminator.
--   3. DoctorSchedule and DoctorVacation now reference Employee via
--      employee_id. Schedules no longer carry a max_appointments cap
--      (BR4 has been retired).
--   4. Billing has been folded into Appointment and Admission as
--      embedded billing columns (bill_amount, insurance_coverage_amt,
--      billing_status, billing_date, due_date). Payment now references
--      Appointment or Admission directly.
-- =====================================================

-- =====================================================
-- 1. Insurance
-- Stores insurance provider and policy information
-- =====================================================
CREATE TABLE Insurance (
    insurance_id        NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    provider_name       VARCHAR2(200)       NOT NULL,
    policy_number       VARCHAR2(100)       NOT NULL,
    plan_type           VARCHAR2(50)        NOT NULL,
    coverage_percentage NUMBER(5,2)         NOT NULL,
    max_coverage_amount NUMBER(10,2)        NOT NULL,
    valid_from          DATE                NOT NULL,
    valid_until         DATE                NOT NULL,
    is_active           NUMBER(1)           DEFAULT 1 NOT NULL,

    CONSTRAINT PK_Insurance PRIMARY KEY (insurance_id),
    CONSTRAINT UQ_Insurance_PolicyNumber UNIQUE (policy_number),
    CONSTRAINT CK_Insurance_CoveragePercentage CHECK (coverage_percentage BETWEEN 0 AND 100),
    CONSTRAINT CK_Insurance_ValidDates CHECK (valid_until >= valid_from),
    CONSTRAINT CK_Insurance_IsActive CHECK (is_active IN (0, 1))
);

-- =====================================================
-- 2. Department
-- Hospital departments; head_employee_id FK added after
-- Employee table exists (circular dependency)
-- =====================================================
CREATE TABLE Department (
    department_id       NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    head_employee_id    NUMBER(10)          NULL,
    name                VARCHAR2(100)       NOT NULL,
    location            VARCHAR2(200)       NULL,
    phone               VARCHAR2(20)        NULL,

    CONSTRAINT PK_Department PRIMARY KEY (department_id)
);

-- =====================================================
-- 3. Employee
-- Unified staff table. Replaces the former Doctor and
-- Staff tables. The employee_type column discriminates
-- Doctor from non-clinical staff (Nurse, Lab Technician,
-- Receptionist, Pharmacist, Administrative Assistant).
--
-- Doctors must provide specialization and license_number;
-- non-doctors must provide role. This is enforced via a
-- CHECK constraint so that the single table can cover
-- both populations without losing the domain rules.
-- =====================================================
CREATE TABLE Employee (
    employee_id     NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    department_id   NUMBER(10)          NOT NULL,
    employee_type   VARCHAR2(30)        NOT NULL,
    first_name      VARCHAR2(100)       NOT NULL,
    last_name       VARCHAR2(100)       NOT NULL,
    specialization  VARCHAR2(100)       NULL,
    license_number  VARCHAR2(50)        NULL,
    role            VARCHAR2(50)        NULL,
    phone           VARCHAR2(20)        NULL,
    email           VARCHAR2(200)       NULL,
    status          VARCHAR2(20)        DEFAULT 'Active' NOT NULL,
    hire_date       DATE                NOT NULL,

    CONSTRAINT PK_Employee PRIMARY KEY (employee_id),
    CONSTRAINT FK_Employee_Department FOREIGN KEY (department_id)
        REFERENCES Department(department_id),
    CONSTRAINT UQ_Employee_LicenseNumber UNIQUE (license_number),
    CONSTRAINT CK_Employee_Type CHECK (employee_type IN (
        'Doctor', 'Nurse', 'Lab Technician', 'Receptionist',
        'Pharmacist', 'Administrative Assistant'
    )),
    CONSTRAINT CK_Employee_Status CHECK (status IN (
        'Active', 'On Leave', 'Retired', 'Terminated'
    )),
    -- Doctors must carry specialization + license_number and have NO role;
    -- non-doctors must carry a role label and NO specialization/license.
    -- This prevents cross-attribute contamination (e.g., a Doctor row with
    -- role='Nurse', or a Nurse row with specialization set).
    CONSTRAINT CK_Employee_DoctorAttrs CHECK (
        (employee_type = 'Doctor'
            AND specialization IS NOT NULL
            AND license_number IS NOT NULL
            AND role IS NULL)
        OR
        (employee_type <> 'Doctor'
            AND specialization IS NULL
            AND license_number IS NULL
            AND role IS NOT NULL)
    )
);

-- =====================================================
-- 4. Add deferred FK: Department.head_employee_id -> Employee
-- =====================================================
ALTER TABLE Department
    ADD CONSTRAINT FK_Department_Head_Employee
    FOREIGN KEY (head_employee_id) REFERENCES Employee(employee_id);

-- =====================================================
-- 5. Patient
-- Patient demographics, contact info, and guardian
-- details (guardian info denormalized per Part A design)
-- =====================================================
CREATE TABLE Patient (
    patient_id              NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    insurance_id            NUMBER(10)          NULL,
    first_name              VARCHAR2(100)       NOT NULL,
    last_name               VARCHAR2(100)       NOT NULL,
    date_of_birth           DATE                NOT NULL,
    gender                  VARCHAR2(10)        NOT NULL,
    blood_type              VARCHAR2(5)         NULL,
    phone                   VARCHAR2(20)        NULL,
    email                   VARCHAR2(200)       NULL,
    address                 VARCHAR2(500)       NULL,
    guardian_name           VARCHAR2(100)       NULL,
    guardian_phone          VARCHAR2(20)        NULL,
    guardian_relationship   VARCHAR2(50)        NULL,
    created_at              DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_Patient PRIMARY KEY (patient_id),
    CONSTRAINT FK_Patient_Insurance FOREIGN KEY (insurance_id)
        REFERENCES Insurance(insurance_id),
    CONSTRAINT CK_Patient_Gender CHECK (gender IN ('Male', 'Female', 'Other'))
);

-- =====================================================
-- 6. DoctorSchedule
-- Available appointment slots per doctor per day.
-- max_appointments has been removed (BR4 retired).
-- Each slot row represents one bookable timeslot.
-- =====================================================
CREATE TABLE DoctorSchedule (
    schedule_id         NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    employee_id         NUMBER(10)          NOT NULL,
    schedule_date       DATE                NOT NULL,
    slot_time           VARCHAR2(5)         NOT NULL,
    slot_duration_mins  NUMBER(10)          NOT NULL,
    is_available        NUMBER(1)           DEFAULT 1 NOT NULL,
    created_at          DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_DoctorSchedule PRIMARY KEY (schedule_id),
    CONSTRAINT FK_DoctorSchedule_Employee FOREIGN KEY (employee_id)
        REFERENCES Employee(employee_id),
    CONSTRAINT UQ_DoctorSchedule_EmployeeDateTime UNIQUE (employee_id, schedule_date, slot_time),
    CONSTRAINT CK_DoctorSchedule_SlotDuration CHECK (slot_duration_mins IN (15, 30, 45, 60)),
    CONSTRAINT CK_DoctorSchedule_IsAvailable CHECK (is_available IN (0, 1)),
    -- Enforce HH:MM format (24-hour) on slot_time so stored values
    -- can be parsed/ordered without surprises.
    CONSTRAINT CK_DoctorSchedule_SlotTimeFormat CHECK (
        REGEXP_LIKE(slot_time, '^([01][0-9]|2[0-3]):[0-5][0-9]$')
    )
);

-- =====================================================
-- 7. DoctorVacation
-- Vacation requests and approval tracking
-- =====================================================
CREATE TABLE DoctorVacation (
    vacation_id     NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    employee_id     NUMBER(10)          NOT NULL,
    approved_by     NUMBER(10)          NULL,
    start_date      DATE                NOT NULL,
    end_date        DATE                NOT NULL,
    reason          VARCHAR2(500)       NULL,
    status          VARCHAR2(20)        DEFAULT 'Pending' NOT NULL,
    created_at      DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_DoctorVacation PRIMARY KEY (vacation_id),
    CONSTRAINT FK_DoctorVacation_Employee FOREIGN KEY (employee_id)
        REFERENCES Employee(employee_id),
    CONSTRAINT FK_DoctorVacation_ApprovedBy FOREIGN KEY (approved_by)
        REFERENCES Employee(employee_id),
    CONSTRAINT CK_DoctorVacation_Dates CHECK (end_date >= start_date),
    CONSTRAINT CK_DoctorVacation_Status CHECK (status IN ('Pending', 'Approved', 'Rejected'))
);

-- =====================================================
-- 8. Appointment
-- Patient visits linked to a doctor schedule slot.
-- Billing columns are embedded here (1:1 merge).
--   - bill_amount is NULL until the appointment is
--     completed; once set, trg_AppointmentInsDiscount
--     fires and populates insurance_coverage_amt.
-- =====================================================
CREATE TABLE Appointment (
    appointment_id          NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    patient_id              NUMBER(10)          NOT NULL,
    schedule_id             NUMBER(10)          NOT NULL,
    status                  VARCHAR2(20)        DEFAULT 'Scheduled' NOT NULL,
    visit_type              VARCHAR2(20)        NOT NULL,
    reason                  VARCHAR2(500)       NULL,
    notes                   VARCHAR2(2000)      NULL,
    cancelled_at            DATE                NULL,
    -- Embedded billing (replaces former Billing.appointment_id rows)
    bill_amount             NUMBER(10,2)        NULL,
    insurance_coverage_amt  NUMBER(10,2)        DEFAULT 0 NOT NULL,
    billing_status          VARCHAR2(20)        NULL,
    billing_date            DATE                NULL,
    due_date                DATE                NULL,
    created_at              DATE                DEFAULT SYSDATE NOT NULL,
    updated_at              DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_Appointment PRIMARY KEY (appointment_id),
    CONSTRAINT FK_Appointment_Patient FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id),
    CONSTRAINT FK_Appointment_DoctorSchedule FOREIGN KEY (schedule_id)
        REFERENCES DoctorSchedule(schedule_id),
    CONSTRAINT UQ_Appointment_PatientSchedule UNIQUE (patient_id, schedule_id),
    CONSTRAINT CK_Appointment_Status CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')),
    CONSTRAINT CK_Appointment_VisitType CHECK (visit_type IN ('In-Person', 'Teleconsultation')),
    CONSTRAINT CK_Appointment_BillAmount CHECK (bill_amount IS NULL OR bill_amount >= 0),
    CONSTRAINT CK_Appointment_InsCoverage CHECK (insurance_coverage_amt >= 0),
    CONSTRAINT CK_Appointment_BillingStatus CHECK (
        billing_status IS NULL
        OR billing_status IN ('Pending', 'Paid', 'Partially Paid', 'Overdue')
    )
);

-- =====================================================
-- 9. AppointmentHistory
-- Audit trail for appointment changes
-- NOTE: previous_slot_time stored as VARCHAR2(5) in 'HH:MM' format
-- =====================================================
CREATE TABLE AppointmentHistory (
    history_id              NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    appointment_id          NUMBER(10)          NOT NULL,
    previous_schedule_id    NUMBER(10)          NULL,
    changed_by              NUMBER(10)          NULL,
    previous_status         VARCHAR2(20)        NULL,
    new_status              VARCHAR2(20)        NULL,
    previous_slot_time      VARCHAR2(5)         NULL,
    change_reason           VARCHAR2(500)       NULL,
    changed_at              DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_AppointmentHistory PRIMARY KEY (history_id),
    CONSTRAINT FK_AppointmentHistory_Appointment FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id),
    CONSTRAINT FK_AppointmentHistory_PrevSchedule FOREIGN KEY (previous_schedule_id)
        REFERENCES DoctorSchedule(schedule_id),
    CONSTRAINT FK_AppointmentHistory_ChangedBy FOREIGN KEY (changed_by)
        REFERENCES Employee(employee_id)
);

-- =====================================================
-- 10. Room
-- Physical rooms within hospital departments
-- =====================================================
CREATE TABLE Room (
    room_id         NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    department_id   NUMBER(10)          NOT NULL,
    room_number     VARCHAR2(20)        NOT NULL,
    room_type       VARCHAR2(50)        NOT NULL,
    floor_number    NUMBER(10)          NOT NULL,
    is_active       NUMBER(1)           DEFAULT 1 NOT NULL,

    CONSTRAINT PK_Room PRIMARY KEY (room_id),
    CONSTRAINT FK_Room_Department FOREIGN KEY (department_id)
        REFERENCES Department(department_id),
    CONSTRAINT UQ_Room_RoomNumber UNIQUE (room_number),
    CONSTRAINT CK_Room_RoomType CHECK (room_type IN ('General', 'ICU', 'Private', 'Semi-Private', 'Operation Theatre')),
    CONSTRAINT CK_Room_IsActive CHECK (is_active IN (0, 1))
);

-- =====================================================
-- 11. Bed
-- Individual beds within rooms
-- =====================================================
CREATE TABLE Bed (
    bed_id          NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    room_id         NUMBER(10)          NOT NULL,
    bed_number      VARCHAR2(20)        NOT NULL,
    bed_type        VARCHAR2(50)        NOT NULL,
    is_maintenance  NUMBER(1)           DEFAULT 0 NOT NULL,

    CONSTRAINT PK_Bed PRIMARY KEY (bed_id),
    CONSTRAINT FK_Bed_Room FOREIGN KEY (room_id)
        REFERENCES Room(room_id),
    CONSTRAINT UQ_Bed_RoomBedNumber UNIQUE (room_id, bed_number),
    CONSTRAINT CK_Bed_BedType CHECK (bed_type IN ('Standard', 'Electric', 'ICU', 'Bariatric')),
    CONSTRAINT CK_Bed_IsMaintenance CHECK (is_maintenance IN (0, 1))
);

-- =====================================================
-- 12. Admission
-- Inpatient admissions linking patients to beds/doctors.
-- Billing columns are embedded here (1:1 merge with the
-- former Billing table on the admission side).
-- =====================================================
CREATE TABLE Admission (
    admission_id            NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    patient_id              NUMBER(10)          NOT NULL,
    bed_id                  NUMBER(10)          NOT NULL,
    admitting_employee_id   NUMBER(10)          NOT NULL,
    icu_approved_by         NUMBER(10)          NULL,
    admission_type          VARCHAR2(50)        NOT NULL,
    diagnosis               VARCHAR2(1000)      NULL,
    status                  VARCHAR2(20)        DEFAULT 'Active' NOT NULL,
    discharge_notes         VARCHAR2(2000)      NULL,
    admission_datetime      DATE                DEFAULT SYSDATE NOT NULL,
    discharge_datetime      DATE                NULL,
    -- Embedded billing (replaces former Billing.admission_id rows)
    bill_amount             NUMBER(10,2)        NULL,
    insurance_coverage_amt  NUMBER(10,2)        DEFAULT 0 NOT NULL,
    billing_status          VARCHAR2(20)        NULL,
    billing_date            DATE                NULL,
    due_date                DATE                NULL,

    CONSTRAINT PK_Admission PRIMARY KEY (admission_id),
    CONSTRAINT FK_Admission_Patient FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id),
    CONSTRAINT FK_Admission_Bed FOREIGN KEY (bed_id)
        REFERENCES Bed(bed_id),
    CONSTRAINT FK_Admission_AdmittingEmployee FOREIGN KEY (admitting_employee_id)
        REFERENCES Employee(employee_id),
    CONSTRAINT FK_Admission_ICUApprovedBy FOREIGN KEY (icu_approved_by)
        REFERENCES Employee(employee_id),
    CONSTRAINT CK_Admission_Type CHECK (admission_type IN ('Emergency', 'Elective', 'Transfer')),
    CONSTRAINT CK_Admission_Status CHECK (status IN ('Active', 'Discharged', 'Transferred')),
    CONSTRAINT CK_Admission_BillAmount CHECK (bill_amount IS NULL OR bill_amount >= 0),
    CONSTRAINT CK_Admission_InsCoverage CHECK (insurance_coverage_amt >= 0),
    CONSTRAINT CK_Admission_BillingStatus CHECK (
        billing_status IS NULL
        OR billing_status IN ('Pending', 'Paid', 'Partially Paid', 'Overdue')
    )
);

-- =====================================================
-- 13. Prescription
-- Medications prescribed during appointments or admissions
-- =====================================================
CREATE TABLE Prescription (
    prescription_id NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    appointment_id  NUMBER(10)          NULL,
    admission_id    NUMBER(10)          NULL,
    medication_name VARCHAR2(200)       NOT NULL,
    dosage          VARCHAR2(100)       NOT NULL,
    frequency       VARCHAR2(100)       NOT NULL,
    duration_days   NUMBER(10)          NOT NULL,
    instructions    VARCHAR2(500)       NULL,
    prescribed_at   DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_Prescription PRIMARY KEY (prescription_id),
    CONSTRAINT FK_Prescription_Appointment FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id),
    CONSTRAINT FK_Prescription_Admission FOREIGN KEY (admission_id)
        REFERENCES Admission(admission_id),
    CONSTRAINT CK_Prescription_DurationDays CHECK (duration_days > 0),
    CONSTRAINT CK_Prescription_Source CHECK (
        (appointment_id IS NOT NULL AND admission_id IS NULL)
        OR (appointment_id IS NULL AND admission_id IS NOT NULL)
    )
);

-- =====================================================
-- 14. Payment
-- Payments applied to an Appointment or Admission.
-- The former Billing.bill_id link has been replaced with
-- direct FKs to the billable entity. Exactly one of
-- (appointment_id, admission_id) must be set.
-- =====================================================
CREATE TABLE Payment (
    payment_id      NUMBER(10) GENERATED ALWAYS AS IDENTITY   NOT NULL,
    appointment_id  NUMBER(10)          NULL,
    admission_id    NUMBER(10)          NULL,
    processed_by    NUMBER(10)          NULL,
    amount          NUMBER(10,2)        NOT NULL,
    payment_method  VARCHAR2(50)        NOT NULL,
    transaction_ref VARCHAR2(100)       NULL,
    status          VARCHAR2(20)        DEFAULT 'Completed' NOT NULL,
    payment_date    DATE                DEFAULT SYSDATE NOT NULL,

    CONSTRAINT PK_Payment PRIMARY KEY (payment_id),
    CONSTRAINT FK_Payment_Appointment FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id),
    CONSTRAINT FK_Payment_Admission FOREIGN KEY (admission_id)
        REFERENCES Admission(admission_id),
    CONSTRAINT FK_Payment_Employee FOREIGN KEY (processed_by)
        REFERENCES Employee(employee_id),
    CONSTRAINT CK_Payment_Method CHECK (payment_method IN ('Cash', 'Credit Card', 'Debit Card', 'Insurance', 'Bank Transfer')),
    CONSTRAINT CK_Payment_Status CHECK (status IN ('Completed', 'Pending', 'Failed', 'Refunded')),
    CONSTRAINT CK_Payment_Amount CHECK (amount > 0),
    CONSTRAINT CK_Payment_Source CHECK (
        (appointment_id IS NOT NULL AND admission_id IS NULL)
        OR (appointment_id IS NULL AND admission_id IS NOT NULL)
    )
);

-- =====================================================
-- Supporting indexes for foreign keys and common queries
-- =====================================================

-- Employee lookups by department and by type
CREATE INDEX IX_Employee_DepartmentId
    ON Employee(department_id);
CREATE INDEX IX_Employee_Type
    ON Employee(employee_type);

-- Patient lookups by insurance
CREATE INDEX IX_Patient_InsuranceId
    ON Patient(insurance_id);

-- Schedule lookups by employee (doctor) and date
CREATE INDEX IX_DoctorSchedule_EmployeeDate
    ON DoctorSchedule(employee_id, schedule_date);

-- Vacation approver lookup (FK index). The employee_id composite
-- index is defined in 04_create_indexes.sql as IX_DoctorVacation_EmpDates.
CREATE INDEX IX_DoctorVacation_ApprovedBy
    ON DoctorVacation(approved_by);

-- Appointment lookups
CREATE INDEX IX_Appointment_PatientId
    ON Appointment(patient_id);
CREATE INDEX IX_Appointment_ScheduleId
    ON Appointment(schedule_id);

-- Room and bed lookups
CREATE INDEX IX_Room_DepartmentId
    ON Room(department_id);
CREATE INDEX IX_Bed_RoomId
    ON Bed(room_id);

-- Admission lookups
CREATE INDEX IX_Admission_PatientId
    ON Admission(patient_id);
CREATE INDEX IX_Admission_BedId
    ON Admission(bed_id);
CREATE INDEX IX_Admission_AdmittingEmployeeId
    ON Admission(admitting_employee_id);
CREATE INDEX IX_Admission_IcuApprovedBy
    ON Admission(icu_approved_by);

-- Prescription lookups
CREATE INDEX IX_Prescription_AppointmentId
    ON Prescription(appointment_id);
CREATE INDEX IX_Prescription_AdmissionId
    ON Prescription(admission_id);

-- Payment lookups by source entity
CREATE INDEX IX_Payment_AppointmentId
    ON Payment(appointment_id);
CREATE INDEX IX_Payment_AdmissionId
    ON Payment(admission_id);
