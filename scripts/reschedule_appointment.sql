-- Flow: Reschedule appointment (happy path)  ->  sp_RescheduleAppointment
-- Args: appointment_id, new_schedule_id, reason.
SET SERVEROUTPUT ON

EXEC sp_RescheduleAppointment(1, 10, 'script-driven reschedule');

COMMIT;
