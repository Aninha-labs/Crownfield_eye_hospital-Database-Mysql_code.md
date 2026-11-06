-- ---------------------------------------------------------------------
-- Q6  TRIGGER with business rule
-- Rule: you can't schedule an appointment on a date that's already past.
-- Before saving a new appointment, the trigger checks the date.
-- ---------------------------------------------------------------------
USE crownfield_eye;
DELIMITER $$

DROP TRIGGER IF EXISTS trg_no_past_appointments $$
CREATE TRIGGER trg_no_past_appointments
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    IF NEW.status = 'Scheduled' AND NEW.appointment_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot schedule an appointment in the past';
    END IF;
END $$
 
DELIMITER $$

INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time, status)
VALUES ('OP003', 1, 1, '2027-03-22', '10:00:00', 'Scheduled');
DELIMITER ;

SELECT patient_id, clinician_id, clinic_id, appointment_date, appointment_time, status
from appointment


