-- Negative: Reschedule a non-existent appointment  -> expect ORA-20001
SET SERVEROUTPUT ON

EXEC sp_RescheduleAppointment(999999, 10, 'negative flow demo');
