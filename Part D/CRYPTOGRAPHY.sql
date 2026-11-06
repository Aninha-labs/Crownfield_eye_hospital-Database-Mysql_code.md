-- =========================================================
-- D2 - DATA PROTECTION
-- =========================================================
 USE crownfield_eye;
-- (A) CRYPTOGRAPHY: hide the patients' phone numbers
UPDATE Patient
SET phone_enc = AES_ENCRYPT('07700900001', 'my_secret_key')
WHERE patient_id = 'OP001';
 
-- See the encrypted data (unreadable):
SELECT patient_id, HEX(phone_enc) AS encrypted_phone
FROM Patient WHERE patient_id = 'OP001';
 
-- Decrypt (only those who have the key can accsess):
SELECT patient_id,
       CAST(AES_DECRYPT(phone_enc, 'my_secret_key') AS CHAR) AS real_phone
FROM Patient WHERE patient_id = 'OP001';
 