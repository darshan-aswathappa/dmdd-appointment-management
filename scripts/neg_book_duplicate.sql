-- Negative: Duplicate booking  -> expect ORA-20004
-- Pre-condition (seed data): patient 21 already has a Scheduled appt on slot 6.
SET SERVEROUTPUT ON

VARIABLE appt_id NUMBER

EXEC sp_BookAppointment(21, 6, 'In-Person', 'negative flow demo', :appt_id);
