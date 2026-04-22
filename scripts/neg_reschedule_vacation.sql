-- Negative: Reschedule into doctor vacation  -> expect ORA-20003 (BR5)
-- Slot 174 is inside Dr. David Kim's approved vacation.
-- Edit appointment_id 1 to a live Scheduled appt if needed.
SET SERVEROUTPUT ON

EXEC sp_RescheduleAppointment(1, 174, 'negative flow demo');
