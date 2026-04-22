-- Flow: Complete + bill appointment (happy path)  ->  sp_CompleteAppointment
-- trg_AppointmentInsDiscount fires on UPDATE and sets insurance_coverage_amt.
SET SERVEROUTPUT ON

EXEC sp_CompleteAppointment(1, 'script-driven completion', 350);

COMMIT;
