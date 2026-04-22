-- Negative: Book on a non-existent slot  -> expect ORA-20002
SET SERVEROUTPUT ON

VARIABLE appt_id NUMBER

EXEC sp_BookAppointment(21, 99999, 'In-Person', 'negative flow demo', :appt_id);
