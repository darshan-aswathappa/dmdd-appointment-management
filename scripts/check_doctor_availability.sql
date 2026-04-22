-- Flow: Check doctor availability (read-only)  ->  sp_GetDoctorAvailability
SET SERVEROUTPUT ON

VARIABLE rc REFCURSOR

EXEC sp_GetDoctorAvailability(1, DATE '2026-04-01', DATE '2026-04-30', :rc);

PRINT rc
