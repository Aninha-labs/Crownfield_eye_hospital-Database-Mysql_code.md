-- ---------------------------------------------------------------------
-- Q3  LEFT JOIN revealing missing / optional related data
-- Question: Which appointments have NO follow-up plan recorded
--           (a possible gap in patient care)?
-- ---------------------------------------------------------------------
USE crownfield_eye;
SELECT a.appointment_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient,
       a.appointment_date,
       a.status
FROM Appointment a
INNER JOIN Patient p ON p.patient_id = a.patient_id
LEFT JOIN follow_up_plan f ON f.appointment_id = a.appointment_id
WHERE f.followup_id IS NULL
ORDER BY a.appointment_date;
