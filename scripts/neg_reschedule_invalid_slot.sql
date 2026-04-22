-- Negative: Reschedule to a non-existent slot  -> expect ORA-20002
-- Edit appointment_id 1 to a live Scheduled appt if needed.
SET SERVEROUTPUT ON

EXEC sp_RescheduleAppointment(1, 999999, 'negative flow demo');
