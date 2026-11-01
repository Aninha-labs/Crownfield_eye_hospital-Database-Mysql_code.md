USE crownfield_eye;
-- T1 UPDATE: correct a postcode (single row, by key)
SELECT patient_id, postcode 
FROM patient 
WHERE patient_id = 'OP001';
UPDATE patient SET postcode = 'NE1 4AX' 
WHERE patient_id = 'OP001';

