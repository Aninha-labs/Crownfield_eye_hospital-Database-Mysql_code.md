use crownfield_eye;

START TRANSACTION;
 
UPDATE Appointment
SET appointment_date = '2026-11-23',
    notes = 'Visual field test (rescheduled)'
WHERE appointment_id = 3 AND status = 'Scheduled';
 
SELECT appointment_id, appointment_date, appointment_time, status, notes
FROM Appointment WHERE appointment_id = 3;
 
COMMIT;
