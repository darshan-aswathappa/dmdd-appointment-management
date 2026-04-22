-- ============================================================================
-- Negative flow: Book with a non-existent patient
-- Mirrors: ui/app.py :: _run_negative_scenario('book-invalid-patient')
-- Rule:     Patient existence
-- Expected: ORA-20001: Patient with ID 99999 does not exist.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

DECLARE
    v_slot_id NUMBER;
    v_out     NUMBER;
BEGIN
    -- Find any free slot for the call (irrelevant to the failure; the
    -- patient-existence check fires before the slot check).
    BEGIN
        SELECT schedule_id INTO v_slot_id
        FROM (
            SELECT ds.schedule_id
              FROM DoctorSchedule ds
             WHERE ds.is_available = 1
               AND NOT EXISTS (
                   SELECT 1 FROM Appointment a
                    WHERE a.schedule_id = ds.schedule_id
                      AND a.status = 'Scheduled'
               )
             ORDER BY ds.schedule_date, ds.slot_time
        )
        WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        v_slot_id := 1;
    END;

    DBMS_OUTPUT.PUT_LINE(
        'Calling sp_BookAppointment(99999, ' || v_slot_id ||
        ', ''In-Person'', ''negative flow demo'', OUT) ...');

    sp_BookAppointment(99999, v_slot_id, 'In-Person',
                       'negative flow demo', v_out);

    DBMS_OUTPUT.PUT_LINE('UNEXPECTED SUCCESS: appt ' || v_out);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
