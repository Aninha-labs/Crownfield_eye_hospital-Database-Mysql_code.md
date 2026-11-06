-- This command combines two lists: patients with a scheduled appointment 
-- and patients with an urgent open follow-up. A patient can appear twice, 
-- once for each reason, because the reason column is different in the two rows.
USE crownfield_eye;

SELECT p.patient_id, p.first_name, 'scheduled appointment' AS reason
FROM Patient p
JOIN Appointment a ON a.patient_id = p.patient_id
WHERE a.status = 'Scheduled'
UNION
SELECT p.patient_id, p.first_name, 'Follow-up urgente'
FROM Patient p
JOIN Appointment a ON a.patient_id = p.patient_id
JOIN follow_up_plan f ON f.appointment_id = a.appointment_id
WHERE f.priority = 'Urgent' AND f.status = 'Open';