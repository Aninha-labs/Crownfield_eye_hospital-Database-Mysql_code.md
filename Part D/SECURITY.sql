USE crownfield_eye;
-- =========================================================
-- D1 - ROLES (perfis) E PERMISSOES
-- =========================================================
 
-- Step 1: create the 4 profiles
CREATE ROLE IF NOT EXISTS 'administrator', 'doctor', 'receptionist', 'patient';
 
-- Step 2: give permissions to each profile
-- Administrator: can do everything
GRANT ALL PRIVILEGES ON crownfield_eye.* TO 'administrator';
 
-- Doctor: reads patients and consultations, creates diagnoses and prescriptions
GRANT SELECT ON crownfield_eye.Patient TO 'doctor';
GRANT SELECT, UPDATE ON crownfield_eye.Appointment TO 'doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.appointment_diagnosis TO 'doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.prescription TO 'doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.prescription_item TO 'doctor';
 
-- Receptionist: registers patients and schedules appointments (doesn't delete anything)
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.Patient TO 'receptionist';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.Appointment TO 'receptionist';
 
-- Patient: only sees THEIR OWN appointments (using a view)
CREATE OR REPLACE VIEW v_op001_appointments AS
SELECT appointment_date, appointment_time, status
FROM Appointment
WHERE patient_id = 'OP001';
 
GRANT SELECT ON crownfield_eye.v_op001_appointments TO 'patient';
 
-- Step 3: create users and link each one to their profile
DROP USER IF EXISTS 'admin1'@'localhost';
DROP USER IF EXISTS 'doctor1'@'localhost';
DROP USER IF EXISTS 'recep1'@'localhost';
DROP USER IF EXISTS 'patient1'@'localhost';

CREATE USER 'admin1'@'localhost'  IDENTIFIED BY 'Admin#123';
CREATE USER 'doctor1'@'localhost' IDENTIFIED BY 'Doctor#123';
CREATE USER 'recep1'@'localhost'  IDENTIFIED BY 'Recep#123';
CREATE USER 'patient1'@'localhost' IDENTIFIED BY 'Patient#123';
 
GRANT 'administrator' TO 'admin1'@'localhost';
GRANT 'doctor'        TO 'doctor1'@'localhost';
GRANT 'receptionist'  TO 'recep1'@'localhost';
GRANT 'patient'       TO 'patient1'@'localhost';
 
SET DEFAULT ROLE ALL TO 'admin1'@'localhost', 
                        'doctor1'@'localhost',
                        'recep1'@'localhost', 
                        'patient1'@'localhost';
 
-- Test:
SHOW GRANTS FOR 'doctor';
SHOW GRANTS FOR 'receptionist';
SHOW GRANTS FOR 'patient';
SHOW GRANTS FOR 'administrator';

