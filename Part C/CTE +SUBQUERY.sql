-- ---------------------------------------------------------------------
-- Q4  COMMON TABLE EXPRESSION (CTE) + SUBQUERY
-- Question: Which patients have had more appointments than the
--           average patient?
-- ---------------------------------------------------------------------
USE crownfield_eye;
WITH patient_counts AS (
    SELECT patient_id, COUNT(*) AS n
    FROM Appointment
    GROUP BY patient_id
)
SELECT p.patient_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient,
       pc.n AS appointments
FROM patient_counts pc
INNER JOIN Patient p ON p.patient_id = pc.patient_id
WHERE pc.n > (SELECT AVG(n) FROM patient_counts);
 