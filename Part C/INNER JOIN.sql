-- ---------------------------------------------------------------------
-- Q2  INNER JOIN across at least three related tables (here: six)
-- Question: For completed appointments, which patient saw which clinician,
--           at which clinic, and with what diagnosis?
-- ---------------------------------------------------------------------
USE crownfield_eye;

SELECT CONCAT(p.first_name, ' ', p.last_name)   AS patient,
       CONCAT(cl.first_name, ' ', cl.last_name) AS clinician,
       c.clinic_name,
       a.appointment_date,
       d.diagnosis_name
FROM Appointment a
INNER JOIN Patient p               ON p.patient_id      = a.patient_id
INNER JOIN Clinician cl            ON cl.clinician_id   = a.clinician_id
INNER JOIN Clinic c                ON c.clinic_id       = a.clinic_id
INNER JOIN appointment_diagnosis ad ON ad.appointment_id = a.appointment_id
INNER JOIN diagnosis d             ON d.diagnosis_id    = ad.diagnosis_id
WHERE a.status = 'Completed'
ORDER BY a.appointment_date, patient;
