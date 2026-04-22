-- Negative: Book with a non-existent patient  -> expect ORA-20001
SET SERVEROUTPUT ON

VARIABLE appt_id NUMBER

EXEC sp_BookAppointment(99999, 5, 'In-Person', 'negative flow demo', :appt_id);
