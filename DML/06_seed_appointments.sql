-- ============================================
-- FILE 6: Seed Appointments (Oracle SQL) (50 total)
-- ~30 Scheduled (future dates matching schedule slots)
-- ~10 Completed
-- ~7 Cancelled (with cancelled_at)
-- ~3 No-Show
--
-- REVAMP: Billing columns are now embedded on Appointment. Completed
-- and No-Show rows include bill_amount/insurance_coverage_amt/
-- billing_status/billing_date/due_date. Pre-billed Scheduled rows carry
-- Pending bills to mirror the original seed behavior so reports have
-- data to work with.
-- ============================================

-- ============================================
-- COMPLETED appointments (10) - past dates, fully billed
-- ============================================
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (1, 1, 1, 'In-Person', 'Completed', 'Chest pain evaluation', 'ECG performed, results normal', NULL, 350.00, 280.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (2, 2, 13, 'In-Person', 'Completed', 'Heart palpitations', 'Holter monitor recommended', NULL, 275.00, 192.50, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (3, 3, 24, 'In-Person', 'Completed', 'Knee pain after sports injury', 'X-ray ordered, possible meniscus tear', NULL, 450.00, 450.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (4, 4, 46, 'In-Person', 'Completed', 'Recurring headaches', 'MRI scheduled for follow-up', NULL, 500.00, 350.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (5, 5, 68, 'In-Person', 'Completed', 'Child wellness check', 'Growth and development on track', NULL, 200.00, 160.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (6, 6, 91, 'In-Person', 'Completed', 'Follow-up chemotherapy consult', 'Treatment plan reviewed', NULL, 800.00, 640.00, 'Partially Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (7, 7, 111, 'In-Person', 'Completed', 'Pre-operative evaluation', 'Cleared for laparoscopic procedure', NULL, 300.00, 210.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (8, 8, 121, 'In-Person', 'Completed', 'Ankle sprain follow-up', 'Healing well, physical therapy advised', NULL, 250.00, 200.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (9, 9, 144, 'Teleconsultation', 'Completed', 'Annual physical', 'Blood work ordered', NULL, 150.00, 150.00, 'Paid', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (10, 10, 157, 'Teleconsultation', 'Completed', 'Respiratory symptoms follow-up', 'Improving, continue current medication', NULL, 175.00, 122.50, 'Partially Paid', DATE '2026-04-14', DATE '2026-05-14');

-- ============================================
-- CANCELLED appointments (7) - with cancelled_at timestamps
-- First two carry a cancellation fee bill (Pending).
-- ============================================
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (11, 11, 2, 'In-Person', 'Cancelled', 'Routine cardiac check', 'Patient called to cancel', TO_DATE('2026-04-13 14:30:00', 'YYYY-MM-DD HH24:MI:SS'), 50.00, 0.00, 'Pending', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (12, 12, 25, 'In-Person', 'Cancelled', 'Hip pain assessment', 'Rescheduled to next week', TO_DATE('2026-04-13 09:15:00', 'YYYY-MM-DD HH24:MI:SS'), 50.00, 0.00, 'Pending', DATE '2026-04-14', DATE '2026-05-14');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (13, 13, 58, 'Teleconsultation', 'Cancelled', 'Epilepsy medication review', 'Insurance issue', TO_DATE('2026-04-12 16:00:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (14, 14, 81, 'In-Person', 'Cancelled', 'Child vaccination', 'Family emergency', TO_DATE('2026-04-14 07:30:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (15, 15, 102, 'In-Person', 'Cancelled', 'Radiation therapy planning', 'Patient hospitalized elsewhere', TO_DATE('2026-04-13 11:00:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (16, 16, 134, 'In-Person', 'Cancelled', 'Urgent care follow-up', 'Resolved at primary care', TO_DATE('2026-04-13 17:45:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (17, 17, 36, 'Teleconsultation', 'Cancelled', 'Joint replacement consultation', 'Patient travel conflict', TO_DATE('2026-04-12 10:30:00', 'YYYY-MM-DD HH24:MI:SS'));

-- ============================================
-- NO-SHOW appointments (3) - billed no-show fee, Overdue
-- ============================================
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (18, 18, 3, 'In-Person', 'No-Show', 'Stress test follow-up', NULL, NULL, 100.00, 0.00, 'Overdue', DATE '2026-04-14', DATE '2026-04-28');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (19, 19, 47, 'In-Person', 'No-Show', 'Migraine consultation', NULL, NULL, 100.00, 0.00, 'Overdue', DATE '2026-04-14', DATE '2026-04-28');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (20, 20, 92, 'Teleconsultation', 'No-Show', 'Treatment side effects review', NULL, NULL, 100.00, 0.00, 'Overdue', DATE '2026-04-14', DATE '2026-04-28');

-- ============================================
-- SCHEDULED appointments (30) - future dates matching valid schedule slots
-- IDs 21-35 have pre-computed Pending bills (check-in co-pays); 36-50 unbilled.
-- ============================================
-- 2026-04-15 slots
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (21, 21, 6, 'In-Person', 'Scheduled', 'Cardiac catheterization consult', NULL, NULL, 400.00, 0.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (22, 22, 18, 'In-Person', 'Scheduled', 'Arrhythmia evaluation', NULL, NULL, 350.00, 0.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (23, 23, 28, 'In-Person', 'Scheduled', 'Shoulder impingement', NULL, NULL, 375.00, 0.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (24, 24, 39, 'Teleconsultation', 'Scheduled', 'Post-surgery follow-up', NULL, NULL, 250.00, 0.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (25, 25, 51, 'In-Person', 'Scheduled', 'Neuropathy assessment', NULL, NULL, 500.00, 0.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (26, 26, 62, 'In-Person', 'Scheduled', 'Seizure medication adjustment', NULL, NULL, 400.00, 320.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (27, 176, 73, 'In-Person', 'Scheduled', 'Pediatric wellness exam', NULL, NULL, 200.00, 160.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (28, 177, 84, 'In-Person', 'Scheduled', 'Growth check-up', NULL, NULL, 200.00, 140.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (29, 29, 94, 'Teleconsultation', 'Scheduled', 'Oncology follow-up', NULL, NULL, 175.00, 140.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (30, 30, 105, 'In-Person', 'Scheduled', 'Radiation side effects review', NULL, NULL, 450.00, 225.00, 'Pending', DATE '2026-04-15', DATE '2026-05-15');

-- 2026-04-16 slots
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (31, 31, 9, 'In-Person', 'Scheduled', 'Blood pressure monitoring', NULL, NULL, 300.00, 210.00, 'Pending', DATE '2026-04-16', DATE '2026-05-16');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (32, 32, 32, 'In-Person', 'Scheduled', 'Fracture healing check', NULL, NULL, 350.00, 280.00, 'Pending', DATE '2026-04-16', DATE '2026-05-16');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (33, 33, 53, 'Teleconsultation', 'Scheduled', 'Multiple sclerosis review', NULL, NULL, 175.00, 175.00, 'Pending', DATE '2026-04-16', DATE '2026-05-16');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (34, 34, 76, 'In-Person', 'Scheduled', 'Childhood asthma management', NULL, NULL, 250.00, 175.00, 'Pending', DATE '2026-04-16', DATE '2026-05-16');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at, bill_amount, insurance_coverage_amt, billing_status, billing_date, due_date) VALUES (35, 35, 97, 'In-Person', 'Scheduled', 'Chemotherapy consultation', NULL, NULL, 600.00, 480.00, 'Pending', DATE '2026-04-16', DATE '2026-05-16');
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (36, 36, 116, 'In-Person', 'Scheduled', 'Hernia repair consultation', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (37, 37, 129, 'In-Person', 'Scheduled', 'Burn treatment follow-up', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (38, 38, 153, 'Teleconsultation', 'Scheduled', 'Diabetes management', NULL, NULL);

-- 2026-04-17 slots
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (39, 39, 21, 'In-Person', 'Scheduled', 'Pacemaker check', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (40, 40, 43, 'In-Person', 'Scheduled', 'ACL reconstruction consult', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (41, 41, 65, 'Teleconsultation', 'Scheduled', 'Headache disorder evaluation', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (42, 42, 88, 'In-Person', 'Scheduled', 'Pediatric cardiac screening', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (43, 43, 109, 'In-Person', 'Scheduled', 'Biopsy results discussion', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (44, 44, 141, 'In-Person', 'Scheduled', 'Emergency follow-up', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (45, 45, 164, 'Teleconsultation', 'Scheduled', 'Pulmonary function test review', NULL, NULL);

-- 2026-04-18 slots
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (46, 46, 34, 'In-Person', 'Scheduled', 'Rotator cuff evaluation', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (47, 47, 79, 'In-Person', 'Scheduled', 'Ear infection check', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (48, 48, 119, 'In-Person', 'Scheduled', 'Appendectomy follow-up', NULL, NULL);
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (49, 49, 167, 'Teleconsultation', 'Scheduled', 'COPD management', NULL, NULL);

-- 2026-04-19 slot
INSERT INTO Appointment (appointment_id, patient_id, schedule_id, visit_type, status, reason, notes, cancelled_at) VALUES (50, 50, 132, 'In-Person', 'Scheduled', 'Trauma follow-up assessment', NULL, NULL);

BEGIN
    DBMS_OUTPUT.PUT_LINE('Appointments seeded successfully (50 records: 10 completed, 7 cancelled, 3 no-show, 30 scheduled).');
END;
/

COMMIT;
