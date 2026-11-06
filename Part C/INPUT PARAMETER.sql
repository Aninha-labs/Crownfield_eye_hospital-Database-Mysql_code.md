-- =====================================================================
-- 03_simple_procedure_input_parameter.sql  
-- =====================================================================
USE crownfield_eye;
 CALL sp_appointments_by_patient('OP001');
DELIMITER $$
-- ---------------------------------------------------------------------
-- Q5  STORED PROCEDURE with input parameter
-- Question: What are a patient's appointments?
-- Input: p_patient_id (e.g., 'OP001')
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_appointments_by_patient $$
CREATE PROCEDURE  sp_appointments_by_patient(IN p_patient_id CHAR(5))
BEGIN
    SELECT appointment_id, appointment_date, appointment_time, status, notes
    FROM Appointment
    WHERE patient_id = p_patient_id
    ORDER BY appointment_date;
END $$
 
 
-- =====================================================================
-- TESTS
-- =====================================================================
-- Q5: procedure
-- CALL sp_appointments_by_patient('OP001');
-- CALL sp_appointments_by_patient('OP004');
 
