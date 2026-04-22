-- Negative: Complete a non-existent appointment  -> expect ORA-20001
SET SERVEROUTPUT ON

EXEC sp_CompleteAppointment(999999, 'negative flow demo', 100);
