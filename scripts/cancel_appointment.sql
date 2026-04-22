-- Flow: Cancel appointment (happy path)  ->  sp_CancelAppointment
-- Edit the appointment_id below to a Scheduled appt >24h in the future.
SET SERVEROUTPUT ON

EXEC sp_CancelAppointment(1, 'script-driven cancellation');

COMMIT;
