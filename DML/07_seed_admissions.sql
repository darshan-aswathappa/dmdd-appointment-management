-- ============================================
-- FILE 7: Seed Admissions (Oracle SQL) (10 total)
-- 6 Active admissions (patients currently in beds)
-- 4 Discharged admissions (with discharge info)
-- Mix of Emergency, Elective, Transfer types
-- 1-2 with icu_approved_by filled
--
-- REVAMP:
--   - admitting_doctor_id renamed to admitting_employee_id (FK -> Employee).
--   - Billing columns are embedded (bill_amount,
--     insurance_coverage_amt, billing_status, billing_date, due_date).
-- ============================================

-- ============================================
-- ACTIVE admissions (6) -- Pending bills
-- ============================================
-- Patient 51 in ICU bed 51, admitted for acute MI, ICU approved by Dr. Chen
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (1, 51, 51, 1, 1, 'Emergency', 'Acute myocardial infarction', 'Active', NULL, TO_DATE('2026-04-12 03:45:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 4500.00, 3600.00, 'Pending', DATE '2026-04-12', DATE '2026-05-12');

-- Patient 52 in General bed 5, admitted for hip replacement
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (2, 52, 5, 3, NULL, 'Elective', 'Osteoarthritis - scheduled hip replacement', 'Active', NULL, TO_DATE('2026-04-13 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 3200.00, 2560.00, 'Pending', DATE '2026-04-13', DATE '2026-05-13');

-- Patient 53 in ICU bed 53, admitted for stroke, ICU approved by Dr. Kim
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (3, 53, 53, 5, 5, 'Emergency', 'Ischemic stroke - left hemisphere', 'Active', NULL, TO_DATE('2026-04-13 14:20:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 5000.00, 3500.00, 'Pending', DATE '2026-04-13', DATE '2026-05-13');

-- Patient 178 (minor) in Pediatrics bed 13, transferred from another hospital
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (4, 178, 13, 7, NULL, 'Transfer', 'Severe asthma exacerbation', 'Active', NULL, TO_DATE('2026-04-12 19:30:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 2800.00, 2800.00, 'Pending', DATE '2026-04-12', DATE '2026-05-12');

-- Patient 55 in Oncology bed 17, elective admission for chemo
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (5, 55, 17, 9, NULL, 'Elective', 'Non-Hodgkin lymphoma - cycle 3 chemotherapy', 'Active', NULL, TO_DATE('2026-04-11 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 3500.00, 2450.00, 'Pending', DATE '2026-04-11', DATE '2026-05-11');

-- Patient 56 in Emergency bed 25, admitted for trauma
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (6, 56, 25, 12, NULL, 'Emergency', 'Multiple rib fractures from fall', 'Active', NULL, TO_DATE('2026-04-13 22:15:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 2200.00, 1760.00, 'Pending', DATE '2026-04-13', DATE '2026-05-13');

-- ============================================
-- DISCHARGED admissions (4) -- Paid/Partially Paid
-- ============================================
-- Patient 57 was in General bed 9 for appendectomy
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (7, 57, 9, 11, NULL, 'Emergency', 'Acute appendicitis', 'Discharged', 'Appendectomy performed successfully. Patient recovered well. Follow-up in 2 weeks. Avoid heavy lifting for 4 weeks.', TO_DATE('2026-04-08 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2026-04-11 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 4200.00, 4200.00, 'Paid', DATE '2026-04-08', DATE '2026-05-08');

-- Patient 58 was in Private bed 61 for cardiac observation
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (8, 58, 61, 1, NULL, 'Emergency', 'Unstable angina', 'Discharged', 'Stabilized with medication. Prescribed Nitroglycerin and Metoprolol. Cardiac rehab program recommended. Follow-up in 1 week.', TO_DATE('2026-04-09 06:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2026-04-12 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 3800.00, 3040.00, 'Partially Paid', DATE '2026-04-09', DATE '2026-05-09');

-- Patient 59 was in Semi-Private bed 33 for knee surgery
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (9, 59, 33, 4, NULL, 'Elective', 'Torn ACL - surgical repair', 'Discharged', 'ACL reconstruction successful. Physical therapy 3x/week starting in 2 weeks. Non-weight bearing for 6 weeks. Pain management with prescribed medications.', TO_DATE('2026-04-10 07:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2026-04-13 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 4800.00, 3840.00, 'Paid', DATE '2026-04-10', DATE '2026-05-10');

-- Patient 60 was in ICU bed 55 then transferred out, transferred from another facility
INSERT INTO Admission (admission_id, patient_id, bed_id, admitting_employee_id, icu_approved_by, admission_type, diagnosis, status, discharge_notes, admission_datetime, discharge_datetime, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (10, 60, 55, 13, 13, 'Transfer', 'Severe pneumonia with respiratory failure', 'Discharged', 'Intubated for 3 days. Weaned off ventilator successfully. Completed IV antibiotics course. Transitioned to oral antibiotics. Follow-up with pulmonologist in 1 week.', TO_DATE('2026-04-07 23:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2026-04-12 16:45:00', 'YYYY-MM-DD HH24:MI:SS'), 5000.00, 5000.00, 'Paid', DATE '2026-04-07', DATE '2026-05-07');

BEGIN
    DBMS_OUTPUT.PUT_LINE('Admissions seeded successfully (10 records: 6 active, 4 discharged, billing embedded).');
END;
/

COMMIT;
