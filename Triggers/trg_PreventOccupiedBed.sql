-- ============================================================================
-- Trigger:     trg_PreventOccupiedBed
-- Table:       Admission
-- Fires:       BEFORE INSERT (row-level)
-- Purpose:     Prevents admitting a patient to a bed that is already occupied
--              by checking for an existing Active admission on the same bed.
--              Raises an error if the bed is occupied; otherwise allows the
--              INSERT to proceed normally.
-- Note:        Oracle does not support INSTEAD OF triggers on tables, so this
--              is implemented as a BEFORE INSERT trigger that validates and
--              raises an error to block the insert when the bed is occupied.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_PreventOccupiedBed
BEFORE INSERT ON Admission
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Check if the bed is already occupied (Active admission exists)
    SELECT COUNT(*) INTO v_count
    FROM Admission
    WHERE bed_id = :NEW.bed_id
      AND status = 'Active';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Bed is currently occupied. Transaction failed. Cannot admit patient to an occupied bed.');
    END IF;
END trg_PreventOccupiedBed;
/
