-- Flow: Book appointment (happy path)  ->  sp_BookAppointment
SET SERVEROUTPUT ON

VARIABLE appt_id NUMBER

EXEC sp_BookAppointment(21, 5, 'In-Person', 'script-driven booking', :appt_id);

PRINT appt_id
COMMIT;
