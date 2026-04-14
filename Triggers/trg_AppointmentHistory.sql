-- ============================================================================
-- Trigger:     trg_AppointmentHistory
-- Table:       Appointment
-- Fires:       AFTER UPDATE (row-level)
-- Purpose:     Captures appointment changes into the AppointmentHistory table
--              whenever the status or schedule_id is modified. Records the
--              previous and new values along with a snapshot of the old slot
--              time from DoctorSchedule.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_AppointmentHistory
AFTER UPDATE ON Appointment
FOR EACH ROW
DECLARE
    v_previous_slot_time VARCHAR2(5);
BEGIN
    -- Only insert a history record when status actually changed.
    -- schedule_id changes are handled explicitly by sp_RescheduleAppointment
    -- (which carries the change_reason the trigger cannot see), so we do NOT
    -- fire on schedule_id changes here to avoid double-writing the audit row.
    IF :OLD.status <> :NEW.status THEN

        -- Fetch the old slot time from DoctorSchedule
        BEGIN
            SELECT slot_time
            INTO v_previous_slot_time
            FROM DoctorSchedule
            WHERE schedule_id = :OLD.schedule_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_previous_slot_time := NULL;
        END;

        INSERT INTO AppointmentHistory
        (
            appointment_id,
            previous_schedule_id,
            previous_status,
            new_status,
            previous_slot_time,
            changed_at
        )
        VALUES
        (
            :OLD.appointment_id,
            :OLD.schedule_id,
            :OLD.status,
            :NEW.status,
            v_previous_slot_time,
            SYSDATE
        );
    END IF;
END trg_AppointmentHistory;
/
