-- =========================================================
-- EXTRA - SQL INJECTION
-- =========================================================
USE crownfield_eye;
SET @entrada = "x' OR '1'='1";   -- malicious text
 
-- ERROR: pasting the text inside the query (returns ALL patients)
SET @sql_error = CONCAT("SELECT first_name, last_name FROM Patient WHERE last_name = '", @entrada, "'");
PREPARE q1 FROM @sql_error;
EXECUTE q1;
 
-- RIGHT: use parameter "?" (returns 0 rows, attack failed)
PREPARE q2 FROM 'SELECT first_name, last_name FROM Patient WHERE last_name = ?';
EXECUTE q2 USING @entrada;
 