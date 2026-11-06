USE crownfield_eye;

-- Estado inicial
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;

-- Teste 1: ROLLBACK (desfaz a alteração)
START TRANSACTION;
UPDATE Appointment SET status = 'Cancelled' WHERE appointment_id = 3;
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;  -- mostra Cancelled
ROLLBACK;
SELECT appointment_id, status FROM Appointment WHERE appointment_id = 3;  -- volta a Scheduled

-- Teste 2: COMMIT (grava de forma permanente)
START TRANSACTION;
UPDATE Appointment SET notes = 'Patient confirmed by phone' WHERE appointment_id = 3;
COMMIT;
SELECT appointment_id, notes FROM Appointment WHERE appointment_id = 3;