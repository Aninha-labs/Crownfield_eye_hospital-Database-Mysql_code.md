# 👁️ Crownfield Eye Hospital Database – Part D: Security, Data Protection and Control
 
Role-based access control, encryption, hashing and SQL injection prevention for the `crownfield_eye` MySQL database (schema and data in [Part B](README_PartB.md), queries in [Part C](README_PartC.md)).
 
![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1?logo=mysql&logoColor=white)
![Part](https://img.shields.io/badge/Part-D%20Security-red)
 
> 🔬 **Fictional teaching scenario.** All data, users and passwords below are synthetic demo values. Never reuse them in a real system.
 
*Linked to Learning Outcome 3: analyse and implement database security measures, data protection and transaction management.*

---
 
## 📝 Technical Explanation
 
**Access control.** The database follows the principle of least privilege. Four roles (administrator, doctor, receptionist, patient) are created with `CREATE ROLE`, given only the privileges they need with `GRANT`, and assigned to users, so changing a role updates every user in it. Column-level privileges hide `phone_enc` from clinical and front-desk staff and `notes` from the receptionist. No clinical role has `DELETE`, which protects patient records, and the foreign keys from Part B (`RESTRICT` and `CASCADE`) add a second layer of protection.
 
**Patient privacy.** MySQL does not have row-level security, so patients get four views that filter on the connected user (`USER()`). Patients can read only their own rows and have no privileges on the base tables.
 
**Encryption.** Phone numbers are encrypted with AES-256 in CBC mode, using a random IV for each value and a key derived with SHA-256. Anyone reading the table, a backup or a copy of the data sees only binary data. Decryption needs the correct key, and the wrong key returns `NULL`.
 
**Hashing.** Passwords are stored as a salted SHA-256 hash, which cannot be reversed. Login checks recompute the hash and compare it. A production system would use bcrypt or Argon2.
 
**SQL injection.** Concatenating user input into SQL lets an attacker change the query. Parameterised statements keep input as data, and the role design limits the damage if a flaw still exists.
 
**Limitations.** The encryption key is passed to a procedure for demonstration, which is not safe for production. Real systems keep keys in a vault or key management service, use TLS for connections, enable auditing and take encrypted backups.
 
---
