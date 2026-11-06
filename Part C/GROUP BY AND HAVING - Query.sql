-- =====================================================================
-- 02_individual_queries.sql |
-- =====================================================================
USE crownfield_eye;
 
-- ---------------------------------------------------------------------
-- Q1  AGGREGATE QUERY: GROUP BY + HAVING
-- Question: Which clinicians have at least 2 non-cancelled appointments,
--           and how many does each have?
-- ---------------------------------------------------------------------
SELECT CONCAT(cl.first_name, ' ', cl.last_name) AS clinician,
       s.specialty_name                          AS specialty,
       COUNT(*)                                  AS total_appointments
FROM Appointment a
JOIN Clinician cl ON cl.clinician_id = a.clinician_id
JOIN specialty s  ON s.specialty_id  = cl.specialty_id
WHERE a.status <> 'Cancelled'
GROUP BY cl.clinician_id, cl.first_name, cl.last_name, s.specialty_name
HAVING COUNT(*) >= 2
ORDER BY total_appointments DESC;
 
 
 
