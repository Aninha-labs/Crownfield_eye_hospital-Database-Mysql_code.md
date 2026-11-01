USE crownfield_eye;
DELETE FROM appointment 
WHERE appointment_id = 12 
AND status = 'Cancelled';