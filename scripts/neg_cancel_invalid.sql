-- Negative: Cancel a non-existent appointment  -> expect ORA-20001
SET SERVEROUTPUT ON

EXEC sp_CancelAppointment(999999, 'negative flow demo');
