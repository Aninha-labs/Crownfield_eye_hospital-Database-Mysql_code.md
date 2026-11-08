# Crownfield Eye Hospital: Relational Database (MySQL)

**Module:** CPU4:103 Introduction to Database (Level 4)
**Student:** Ana Paula Silva (G1433759)

> This is a **fictional teaching scenario**. All patients, clinicians and records are fictional and do not describe any real hospital system.

---

## 1. Project overview

Crownfield Eye Hospital NHS Foundation Trust currently manages ophthalmology information in paper records, Word documents and Excel spreadsheets. This causes duplicated data, inconsistent values and slow retrieval.

This repository contains a MySQL relational database prototype that replaces those files with 11 normalised (3NF) tables. It covers:

- patients, clinicians, specialties and clinic locations
- appointments, diagnoses, prescriptions, medicines and follow-up plans
- individual SQL queries, a stored procedure and a trigger
- role-based security, data encryption and transactions

---

## 2. Repository structure

| File / folder | Purpose |
|---|---|
| `01_schema.sql` | Creates the `crownfield_eye` database, all tables, constraints, index and synthetic data (shared with the group) |
| `02_individual_queries.sql` | Individual queries: GROUP BY + HAVING, INNER JOIN, LEFT JOIN, subquery/CTE |
| `03_procedure_and_trigger.sql` | Stored procedure with input parameter and trigger enforcing a business rule |
| `04_security.sql` | Roles, privileges, users, restricted view and AES encryption of phone numbers |
| `06_transactions.sql` | `START TRANSACTION`, `COMMIT` and `ROLLBACK` demonstration |
| `05_ERD/` | Entity-Relationship diagram (Crow's Foot notation), image and original file |
| `README.md` | This file |

---

## 3. Setup and execution order

### Requirements

- **MySQL 8.0.16 or later** (needed for enforced `CHECK` constraints and `CREATE ROLE`)
- MySQL Workbench (or the `mysql` command-line client)
- An account with administrator privileges (e.g. `root`) to create users and roles

### Steps

1. Download the repository as a ZIP file (green **Code** button > **Download ZIP**) and extract it..
2. Open MySQL Workbench and connect to your local server as `root`.
3. Run the files **in this exact order**:

| Part | File | Notes |
|---|---|---|
| A | `01_schema.sql` | **Warning:** starts with `DROP DATABASE IF EXISTS crownfield_eye`, so it deletes any existing database with that name |
| B | `02_individual_queries.sql` | Read-only queries (plus the controlled UPDATE test) |
| C | `03_procedure_and_trigger.sql` | Uses `DELIMITER $$`; run the whole file |
| D | `04_security.sql` | Needs admin rights. Safe to re-run (see note below) |
| D | `06_transactions.sql` | Run the statements block by block to see each result |

In Workbench: **File > Open SQL Script**, then click the lightning-bolt button to run the file.

From the command line:

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_individual_queries.sql
mysql -u root -p < 03_procedure_and_trigger.sql
mysql -u root -p < 04_security.sql
mysql -u root -p < 06_transactions.sql
```

> **Re-running scripts:** `01_schema.sql` rebuilds the database from zero. In `04_security.sql`, use `DROP USER IF EXISTS` before `CREATE USER`. Otherwise MySQL returns **Error 1396** because the user already exists.

---

## 4. Database design

### Tables (11)

| Table | Description | Rows |
|---|---|---|
| `Patient` | Patient details and encrypted phone (`phone_enc`) | 14 |
| `specialty` | Specialty names (UNIQUE) | 10 |
| `Clinician` | Clinicians, each with one primary specialty | 11 |
| `Clinic` | Clinic names and addresses | 10 |
| `diagnosis` | Diagnosis names (UNIQUE) | 12 |
| `medicine` | Medicine names (UNIQUE) | 11 |
| `Appointment` | Central table: patient, clinician, clinic, date, time, status | 16 |
| `appointment_diagnosis` | Bridge table: Appointment <-> diagnosis (many-to-many) | 16 |
| `prescription` | Prescription issued during an appointment | 11 |
| `prescription_item` | Bridge table: prescription <-> medicine, with dose, route, frequency, duration | 13 |
| `follow_up_plan` | At most one plan per appointment (due date, priority, status) | 11 |

### Relationships

- One patient has many appointments; each appointment belongs to one patient.
- Each appointment has one clinician and one clinic; each clinician has one primary specialty.
- An appointment can have zero or more diagnoses and zero or more prescriptions.
- A prescription contains one or more medicines (`prescription_item`).
- An appointment has zero or one follow-up plan (`UNIQUE` on `follow_up_plan.appointment_id`).

### Constraints used

| Type | Examples |
|---|---|
| `PRIMARY KEY` | All tables; composite keys on both bridge tables |
| `FOREIGN KEY` | All relationships; `ON DELETE RESTRICT` for core data, `ON DELETE CASCADE` for child records of an appointment |
| `UNIQUE` | Specialty, clinic, diagnosis and medicine names; clinician + date + time (prevents double booking); one follow-up plan per appointment |
| `NOT NULL` | Required fields on all tables |
| `DEFAULT` | Appointment status = `Scheduled`; follow-up priority = `Routine`; follow-up status = `Open` |
| `ENUM` | Appointment status, follow-up priority and status (restricts allowed values) |
| `CHECK` | `appointment_date >= '2020-01-01'`; `duration_days > 0` |
| Index | `idx_appt_patient` on `Appointment(patient_id)` |

---

## 5. Individual SQL features (Part C)

| # | Feature | Question answered | File |
|---|---|---|---|
| 1 | `GROUP BY` + `HAVING` | Which clinicians have more than one appointment? | `02_individual_queries.sql` |
| 2 | `INNER JOIN` (3+ tables) | What are the patient, clinician and clinic details for each completed appointment? | `02_individual_queries.sql` |
| 3 | `LEFT JOIN` | Which appointments have no follow-up plan? | `02_individual_queries.sql` |
| 4 | Subquery + CTE | Which patients have more appointments than the average patient? | `02_individual_queries.sql` |
| 5 | Stored procedure | `sp_appointments_by_patient(p_patient_id)`: what are a patient's appointments? | `03_procedure_and_trigger.sql` |
| 6 | Trigger | `trg_no_past_appointments`: blocks a `Scheduled` appointment with a past date | `03_procedure_and_trigger.sql` |

Example calls:

```sql
USE crownfield_eye;
CALL sp_appointments_by_patient('OP001');
```

---

## 6. Security and data protection (Part D)

### Roles and permissions (principle of least privilege)

| Role | Patient | Appointment | Diagnosis / Prescription tables | Other |
|---|---|---|---|---|
| `administrator` | ALL | ALL | ALL | ALL PRIVILEGES on `crownfield_eye.*` |
| `doctor` | SELECT | SELECT, UPDATE | SELECT, INSERT, UPDATE | No DELETE anywhere |
| `receptionist` | SELECT, INSERT, UPDATE | SELECT, INSERT, UPDATE | None | No DELETE anywhere |
| `patient` | None | None | None | SELECT on view `v_op001_appointments` only (own appointments) |

Demo users (`admin1`, `doctor1`, `recep1`, `patient1`) are created in `04_security.sql` and linked to their roles with `GRANT role TO user` and `SET DEFAULT ROLE`. Passwords in that file are **demonstration values only**.

To check a role:

```sql
SHOW GRANTS FOR 'doctor';
```

### Data protection

- Patient phone numbers are encrypted with **AES** (`AES_ENCRYPT`) and stored in `Patient.phone_enc` (`VARBINARY`).
- They can be read only with the key, using `AES_DECRYPT`.
- **Limitation:** the key `my_secret_key` is hard-coded for demonstration. In a real system it must be stored outside the script and database (e.g. a key management service).

### Transactions

`06_transactions.sql` shows that:

- `ROLLBACK` cancels an uncommitted change, so the original value returns.
- `COMMIT` saves a change permanently.

Tables use the **InnoDB** engine (MySQL default), which supports transactions and foreign keys.

---

## 7. Test summary

| Test | Expected result |
|---|---|
| `UPDATE Patient SET postcode = 'NE1 4AX' WHERE patient_id = 'OP001'` | One row updated; postcode changes |
| Delete a patient who still has appointments | **Error 1451**: foreign key `RESTRICT` protects referential integrity |
| Insert a `Scheduled` appointment with a past date | **Error 1644**: "Cannot schedule an appointment in the past" (trigger) |
| `CREATE USER` for a user that already exists | **Error 1396**: fixed with `DROP USER IF EXISTS` |
| Encrypt and decrypt phone number of `OP001` | `HEX(phone_enc)` is unreadable; `AES_DECRYPT` returns the real number |
| `UPDATE` inside a transaction, then `ROLLBACK` | Original value is restored |

Screenshots of each test are in the individual report.

---

## 8. Assumptions

- Follow-up text such as "6 weeks | High" is converted into a `due_date` (appointment date + interval), a `priority` and a `status`.
- "None" under medicines means the appointment has **no** prescription row.
- Each clinician has **one** primary specialty.
- An appointment has **at most one** follow-up plan, and the same medicine appears **once** per prescription (composite primary key).
- Status values are standardised with `ENUM` (e.g. only `Completed`, never `Complete`).
- `appointment_date >= '2020-01-01'` is used as the "valid date" rule. The "no past scheduled appointment" rule is enforced by the trigger.
- All data is synthetic. Every main table has at least 10 records.
- The `patient` role uses a view fixed to patient `OP001` as a demonstration. A production system would need one restricted view per patient or application-level control.

---

## 9. My individual contribution

- [ ] Shared with group: schema design, ER diagram, normalisation and sample data
- [ ] My own work: individual queries (Part C), procedure and trigger, security (D1 and D2), transactions, testing and report

---

## 10. Limitations and future improvements

- Stronger encryption and secure key management; passwords should be hashed, never stored in plain text.
- A complete audit trail (e.g. a log table filled by triggers).
- More validation rules and testing with invalid inputs.
- Clinical validation before any real-world use.

---

## 11. References

- Galaba, S. P. (2026) *Database normalization*. Code Begun. Available at: https://www.codebegun.com/learn/sql/database-design/database-normalization (Accessed: 26 October 2026).
- Architecture Manual (2026) *Logical data modeling*. archman.dev. Available at: https://archman.dev/docs/foundational-concepts/data-fundamentals/data-modeling/logical (Accessed: 26 October 2026).
- Silberschatz, A., Korth, H.F. and Sudarshan, S. (2006) *Database system concepts*. 6th edn.
- Kroenke, D.M. and Auer, D.J. (2014) *Database concepts*. 7th global edn. Pearson.
