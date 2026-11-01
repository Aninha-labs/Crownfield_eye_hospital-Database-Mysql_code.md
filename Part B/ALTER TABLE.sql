USE crownfield_eye;

-- 1. See how the column of grades is BEFORE
DESCRIBE Appointment;

-- 2. ALTER: increase the notes field from 255 to 500 characters
ALTER TABLE Appointment MODIFY notes VARCHAR(500);

-- 3. See how the notes column is AFTER
DESCRIBE Appointment;

-- 4.ALTER: create an index to search queries by date faster
ALTER TABLE Appointment DROP INDEX idx_appt_date;
ALTER TABLE Appointment ADD INDEX idx_appt_date (appointment_date);

-- 5. See the created index
SHOW INDEX FROM Appointment;

-- 6. ALTER: create a rule for the patient's date of birth
ALTER TABLE Patient DROP CHECK chk_patient_dob;
ALTER TABLE Patient
    ADD CONSTRAINT chk_patient_dob CHECK (date_of_birth >= '1900-01-01');

-- 7.See the rule created
SHOW CREATE TABLE Patient;