USE crownfield_eye;

-- Initial state
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;

-- Test 1: ROLLBACK (undo the change)
START TRANSACTION;
UPDATE Appointment SET status = 'Cancelled' WHERE appointment_id = 3;
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;  -- mostra Cancelled
ROLLBACK;
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;  -- volta a Scheduled

-- Test 2: COMMIT (records permanently)
START TRANSACTION;
UPDATE Appointment SET notes = 'Patient confirmed by phone' WHERE appointment_id = 3;
COMMIT;
SELECT appointment_id, notes FROM Appointment WHERE appointment_id = 3;
