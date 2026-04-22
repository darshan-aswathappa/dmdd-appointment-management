-- Negative: Book during doctor vacation  -> expect ORA-20003
-- Slot 174 = Dr. David Kim on 2026-04-22, inside his approved vacation.
SET SERVEROUTPUT ON

VARIABLE appt_id NUMBER

EXEC sp_BookAppointment(65, 174, 'In-Person', 'negative flow demo', :appt_id);
