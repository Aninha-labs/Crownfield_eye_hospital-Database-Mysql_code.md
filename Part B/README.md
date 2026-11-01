# Crownfield Eye Hospital Database – Part B: Physical Design and Implementation
 
Implementation of the approved logical schema (Part A) as a working **MySQL** database named `crownfield_eye`.
 
![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1?logo=mysql&logoColor=white)
![Part](https://img.shields.io/badge/Part-B%20Implementation-green)
 
> 🔬 This is a **fictional teaching scenario**. All patients, clinicians and records are synthetic and do not describe any real hospital system.
 
---
 
## 📑 Table of Contents
 
1. [Deliverables](#-deliverables)
2. [Repository Structure](#-repository-structure)
3. [ER Diagram](#-er-diagram)
4. [Physical Design Decisions](#-physical-design-decisions)
5. [How to Run](#-how-to-run)
6. [Shared Schema (DDL)](#-shared-schema-ddl)
7. [ALTER TABLE Statements](#-alter-table-statements)
8. [Data Population](#-data-population)
9. [Controlled UPDATE and DELETE](#-controlled-update-and-delete)
10. [Test Log](#-test-log)
11. [Execution Evidence](#-execution-evidence)
---
 
## ✅ Deliverables
 
| Requirement | Where to find it |
|-------------|------------------|
| Implement the logical schema in MySQL | [Shared Schema (DDL)](#-shared-schema-ddl) |
| `CREATE TABLE` and `ALTER TABLE` | [Shared Schema](#-shared-schema-ddl), [ALTER TABLE Statements](#-alter-table-statements) |
| PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, CHECK | [Constraints summary](#constraints-summary) |
| At least 10 synthetic records per main table | [Data Population](#-data-population) |
| Controlled `UPDATE` and `DELETE` keeping referential integrity | [Controlled UPDATE and DELETE](#-controlled-update-and-delete) |
| Successful execution evidence | [Execution Evidence](#-execution-evidence) |
| Short test log | [Test Log](#-test-log) |
 
---
---
 
## 🗺️ ER Diagram
 
![ER Diagram](docs/DIAGRAM_DATABASE.png)
 
---
 
## 🧩 Physical Design Decisions
 
### Naming conventions
 
| Object | Convention | Example |
|--------|-----------|---------|
| Columns | `snake_case` | `appointment_date` |
| Primary keys | `<table>_id` | `clinician_id` |
| Foreign keys | `fk_<child>_<parent>` | `fk_app_patient` |
| Check constraints | `chk_<meaning>` | `chk_pi_duration` |
| Unique constraints | `uq_<meaning>` | `uq_clinician_slot` |
| Indexes | `idx_<table>_<column>` | `idx_appt_patient` |
 
 
### Data types
 
| Data | Type | Reason |
|------|------|--------|
| Patient ID (`OP001`) | `CHAR(5)` | Fixed-length hospital number |
| Other IDs | `INT AUTO_INCREMENT` | Compact surrogate keys |
| Names, notes | `VARCHAR(n)` | Variable-length text with a sensible limit |
| Dates / times | `DATE`, `TIME` | Native types allow validation and date maths |
| Status, priority | `ENUM(...)` | Restricts values to a valid list |
| Phone number | `VARBINARY(255)` | Stores encrypted (binary) data |
| Duration | `INT` + `CHECK (> 0)` | Must be a positive number of days |
 
### Constraints summary
 
| Constraint | Where used |
|------------|-----------|
| **PRIMARY KEY** | Every table (composite on `appointment_diagnosis` and `prescription_item`) |
| **FOREIGN KEY** | 10 relationships, `RESTRICT` on reference data, `CASCADE` on dependent records |
| **UNIQUE** | `specialty_name`, `clinic_name`, `diagnosis_name`, `medicine_name`, `follow_up_plan.appointment_id`, `(clinician_id, appointment_date, appointment_time)` |
| **NOT NULL** | All required columns |
| **DEFAULT** | `Appointment.status = 'Scheduled'`, `follow_up_plan.priority = 'Routine'`, `follow_up_plan.status = 'Open'` |
| **CHECK** | `appointment_date >= '2020-01-01'`, `duration_days > 0` (plus the ALTER examples below) |
 
---
 
## 🚀 How to Run
 
**Requirements:** MySQL 8.0.16 or later (needed for `CHECK` constraints enforcement) and MySQL Workbench or the `mysql` client.
 
```bash
mysql -u root -p < crownfield_eye.sql
mysql -u root -p crownfield_eye < alter_tables.sql
mysql -u root -p crownfield_eye < tests.sql
```
 
> ⚠️ The script begins with `DROP DATABASE IF EXISTS crownfield_eye;`, which deletes any existing database with that name.
 
---
 
## 💾 Shared Schema (DDL)
 
### 1. Create the database
 
```sql
DROP DATABASE IF EXISTS crownfield_eye;
CREATE DATABASE crownfield_eye;
USE crownfield_eye;
```
 
### 2. Main and reference tables
 
```sql
CREATE TABLE Patient (
    patient_id CHAR(5) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    postcode VARCHAR(10) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone_enc VARBINARY(255) NULL
);
 
CREATE TABLE specialty (
    specialty_id INT AUTO_INCREMENT PRIMARY KEY,
    specialty_name VARCHAR(75) NOT NULL UNIQUE
);
 
CREATE TABLE Clinician (
    clinician_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialty_id INT NOT NULL,
    CONSTRAINT fk_clinician_specialty
        FOREIGN KEY (specialty_id) REFERENCES specialty(specialty_id)
        ON DELETE RESTRICT
);
 
CREATE TABLE Clinic (
    clinic_id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_name VARCHAR(75) NOT NULL UNIQUE,
    address VARCHAR(150) NOT NULL
);
 
CREATE TABLE diagnosis (
    diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,
    diagnosis_name VARCHAR(100) NOT NULL UNIQUE
);
 
CREATE TABLE medicine (
    medicine_id INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL UNIQUE
);
```
 
### 3. Related tables
 
```sql
CREATE TABLE Appointment (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id CHAR(5) NOT NULL,
    clinician_id INT NOT NULL,
    clinic_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled')
        NOT NULL DEFAULT 'Scheduled',
    notes VARCHAR(255) NULL,
 
    CONSTRAINT fk_app_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_app_clinician
        FOREIGN KEY (clinician_id) REFERENCES Clinician(clinician_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_app_clinic
        FOREIGN KEY (clinic_id) REFERENCES Clinic(clinic_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_future_or_valid_date
        CHECK (appointment_date >= '2020-01-01'),
    CONSTRAINT uq_clinician_slot
        UNIQUE (clinician_id, appointment_date, appointment_time)
);
 
CREATE INDEX idx_appt_patient ON Appointment(patient_id);
 
-- Many-to-many relationship: Appointment <-> diagnosis
CREATE TABLE appointment_diagnosis (
    appointment_id INT NOT NULL,
    diagnosis_id INT NOT NULL,
    PRIMARY KEY (appointment_id, diagnosis_id),
    CONSTRAINT fk_ad_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ad_diag
        FOREIGN KEY (diagnosis_id) REFERENCES diagnosis(diagnosis_id)
        ON DELETE RESTRICT
);
 
CREATE TABLE prescription (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    issued_date DATE NOT NULL,
    CONSTRAINT fk_rx_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE
);
 
-- Many-to-many relationship with attributes: prescription <-> medicine
CREATE TABLE prescription_item (
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dose VARCHAR(40) NOT NULL,
    route VARCHAR(40) NOT NULL,
    frequency VARCHAR(40) NOT NULL,
    duration_days INT NOT NULL,
    PRIMARY KEY (prescription_id, medicine_id),
    CONSTRAINT fk_pi_rx
        FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pi_med
        FOREIGN KEY (medicine_id) REFERENCES medicine(medicine_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_pi_duration CHECK (duration_days > 0)
);
 
CREATE TABLE follow_up_plan (
    followup_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    due_date DATE NOT NULL,
    priority ENUM('Routine', 'High', 'Urgent')
        NOT NULL DEFAULT 'Routine',
    status ENUM('Open', 'Completed', 'Cancelled')
        NOT NULL DEFAULT 'Open',
    CONSTRAINT fk_fu_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE
);
```
 
---
 
## 🧪 Data Population
 
All data is synthetic. Every main table has at least 10 records.
 
### 4. Reference data
 
```sql
INSERT INTO specialty (specialty_name) VALUES
('Glaucoma'),
('Retina'),
('Cornea'),
('Cataract'),
('Oculoplastics'),
('Paediatric Ophthalmology'),
('Neuro-ophthalmology'),
('Uveitis'),
('Medical Retina'),
('Refractive Surgery');
 
INSERT INTO Clinic (clinic_name, address) VALUES
('City Road', 'City Road, London'),
('Bedford', 'Bedford, London'),
('Croydon', 'Croydon, London'),
('Harrow', 'Harrow, London'),
('Stratford', 'Stratford, London'),
('Greenwich', 'Greenwich, London'),
('Ealing', 'Ealing, London'),
('Barnet', 'Barnet, London'),
('Richmond', 'Richmond, London'),
('Islington', 'Islington, London');
 
INSERT INTO diagnosis (diagnosis_name) VALUES
('Ocular hypertension'),
('Diabetic macular oedema'),
('Glaucoma suspect'),
('Keratoconus'),
('Age-related cataract'),
('Dry eye disease'),
('Anterior uveitis'),
('Amblyopia'),
('Ptosis'),
('Optic neuritis'),
('Retinal vein occlusion'),
('Primary open-angle glaucoma');
 
INSERT INTO medicine (medicine_name) VALUES
('Latanoprost'),
('Timolol'),
('Aflibercept'),
('Sodium chloride drops'),
('Prednisolone acetate'),
('Hypromellose'),
('Brimonidine'),
('Dorzolamide'),
('Atropine'),
('Chloramphenicol'),
('Ranibizumab');
```
 
### 5. Clinicians
 
```sql
INSERT INTO Clinician (first_name, last_name, specialty_id) VALUES
('Maya', 'Shah', 1),
('Leo', 'Grant', 2),
('Priya', 'Nair', 3),
('Tom', 'Hughes', 4),
('Aisha', 'Khan', 5),
('Ben', 'Carter', 6),
('Helen', 'Wu', 7),
('Samuel', 'Ode', 8),
('Irene', 'Costa', 9),
('Raj', 'Patel', 4),
('Fiona', 'Gray', 2);
```
 
### 6. Patients
 
```sql
INSERT INTO Patient
    (patient_id, first_name, last_name, postcode, date_of_birth)
VALUES
('OP001', 'Amina', 'Yusuf', 'NE1 4AB', '1985-04-12'),
('OP002', 'Daniel', 'Reed', 'N16 7QP', '1978-09-23'),
('OP003', 'Sofia', 'Bennett', 'E8 2LD', '1992-01-17'),
('OP004', 'Michael', 'Okoro', 'SE6 3RT', '1969-06-05'),
('OP005', 'Grace', 'Thompson', 'HA1 2AB', '1981-11-29'),
('OP006', 'Omar', 'Farouk', 'E15 4CD', '1995-02-14'),
('OP007', 'Lily', 'Chen', 'SE10 8EF', '2001-07-08'),
('OP008', 'James', 'Walker', 'W5 3GH', '1974-03-19'),
('OP009', 'Priya', 'Singh', 'EN5 1JK', '1988-12-01'),
('OP010', 'Tom', 'Ellis', 'TW9 2LM', '1965-05-26'),
('OP011', 'Hannah', 'Brooks', 'N1 9NP', '1990-08-11'),
('OP012', 'Kwame', 'Mensah', 'CR0 6QR', '1971-10-30'),
('OP013', 'Elena', 'Rossi', 'EC1 4ST', '1983-02-22'),
('OP014', 'Noah', 'Fraser', 'NW3 5UV', '1998-06-16');
```
 
### 7. Appointments
 
```sql
INSERT INTO Appointment
    (appointment_id, patient_id, clinician_id, clinic_id,
     appointment_date, appointment_time, status, notes)
VALUES
(1,  'OP001', 1,  1, '2026-10-05', '09:00:00', 'Completed', 'Review IOP'),
(2,  'OP002', 2,  1, '2026-10-05', '09:30:00', 'Completed', 'OCT before review'),
(3,  'OP001', 1,  2, '2026-11-16', '10:15:00', 'Scheduled', 'Visual field test'),
(4,  'OP003', 1,  1, '2026-10-06', '11:00:00', 'Completed', 'Monitor'),
(5,  'OP004', 3,  3, '2026-10-07', '14:00:00', 'Completed', 'Corneal topography'),
(6,  'OP005', 4,  4, '2026-10-08', '09:00:00', 'Completed', 'Pre-op assessment'),
(7,  'OP006', 5,  5, '2026-10-08', '10:30:00', 'Completed', 'Eyelid assessment'),
(8,  'OP007', 6,  6, '2026-10-09', '13:00:00', 'Completed', 'Vision screening'),
(9,  'OP008', 7,  7, '2026-10-12', '09:45:00', 'Completed', 'Visual field and MRI referral'),
(10, 'OP009', 8,  8, '2026-10-12', '11:15:00', 'Completed', 'Recurrent inflammation'),
(11, 'OP010', 9,  9, '2026-10-13', '14:30:00', 'Completed', 'Vein occlusion review'),
(12, 'OP011', 10, 10, '2026-10-14', '10:00:00', 'Cancelled', 'Patient unwell'),
(13, 'OP012', 11, 1, '2026-10-15', '15:00:00', 'Completed', 'Laser planning'),
(14, 'OP013', 1,  1, '2026-10-16', '09:15:00', 'Completed', 'Pressure check'),
(15, 'OP014', 2,  2, '2026-11-20', '11:30:00', 'Scheduled', 'Routine retinal review'),
(16, 'OP002', 2,  1, '2026-11-02', '09:30:00', 'Scheduled', 'Post-injection review');
```
 
### 8. Diagnoses per appointment
 
```sql
INSERT INTO appointment_diagnosis (appointment_id, diagnosis_id) VALUES
(1, 1), (2, 2), (3, 1), (4, 3),
(5, 4), (6, 5), (7, 9), (8, 8),
(9, 10), (10, 7), (11, 11), (13, 2),
(14, 12), (14, 1), (15, 11), (16, 2);
```
 
### 9. Prescriptions and follow-up plans
 
```sql
INSERT INTO prescription (prescription_id, appointment_id, issued_date) VALUES
(1, 1, '2026-10-05'),
(2, 2, '2026-10-05'),
(3, 3, '2026-11-16'),
(4, 5, '2026-10-07'),
(5, 6, '2026-10-08'),
(6, 7, '2026-10-08'),
(7, 10, '2026-10-12'),
(8, 11, '2026-10-13'),
(9, 13, '2026-10-15'),
(10, 14, '2026-10-16'),
(11, 8, '2026-10-09');
 
INSERT INTO prescription_item
    (prescription_id, medicine_id, dose, route, frequency, duration_days)
VALUES
(1, 1, '1 drop', 'Topical (eye)', 'Once daily at night', 42),
(1, 2, '1 drop', 'Topical (eye)', 'Twice daily', 42),
(2, 3, '2 mg', 'Intravitreal injection', 'Single dose', 1),
(3, 1, '1 drop', 'Topical (eye)', 'Once daily at night', 84),
(4, 4, '1 drop', 'Topical (eye)', 'Four times daily', 56),
(5, 10, '1 drop', 'Topical (eye)', 'Four times daily', 7),
(6, 6, '1 drop', 'Topical (eye)', 'Three times daily', 30),
(7, 5, '1 drop', 'Topical (eye)', 'Four times daily', 28),
(8, 11, '0.5 mg', 'Intravitreal injection', 'Single dose', 1),
(9, 3, '2 mg', 'Intravitreal injection', 'Single dose', 1),
(10, 7, '1 drop', 'Topical (eye)', 'Twice daily', 90),
(10, 8, '1 drop', 'Topical (eye)', 'Three times daily', 90),
(11, 9, '1 drop', 'Topical (eye)', 'Once daily', 60);
 
INSERT INTO follow_up_plan (appointment_id, due_date, priority, status) VALUES
(1,  '2026-11-16', 'High',    'Open'),
(2,  '2026-11-02', 'Urgent',  'Open'),
(3,  '2027-02-08', 'Routine', 'Open'),
(4,  '2027-04-06', 'Routine', 'Open'),
(5,  '2026-12-02', 'Routine', 'Open'),
(6,  '2026-10-15', 'High',    'Completed'),
(7,  '2026-12-31', 'Routine', 'Open'),
(9,  '2026-11-09', 'Urgent',  'Open'),
(10, '2026-10-26', 'High',    'Open'),
(11, '2026-11-10', 'Urgent',  'Open'),
(14, '2027-01-08', 'Routine', 'Open');
```
 
### Row count check
 
```sql
SELECT 'Patient' AS table_name, COUNT(*) AS total_rows FROM Patient
UNION ALL SELECT 'specialty', COUNT(*) FROM specialty
UNION ALL SELECT 'Clinician', COUNT(*) FROM Clinician
UNION ALL SELECT 'Clinic', COUNT(*) FROM Clinic
UNION ALL SELECT 'diagnosis', COUNT(*) FROM diagnosis
UNION ALL SELECT 'medicine', COUNT(*) FROM medicine
UNION ALL SELECT 'Appointment', COUNT(*) FROM Appointment
UNION ALL SELECT 'appointment_diagnosis', COUNT(*) FROM appointment_diagnosis
UNION ALL SELECT 'prescription', COUNT(*) FROM prescription
UNION ALL SELECT 'prescription_item', COUNT(*) FROM prescription_item
UNION ALL SELECT 'follow_up_plan', COUNT(*) FROM follow_up_plan;
```
 
**Expected result**
 
| Table | Rows |
|-------|------|
| Patient | 14 |
| specialty | 10 |
| Clinician | 11 |
| Clinic | 10 |
| diagnosis | 12 |
| medicine | 11 |
| Appointment | 16 |
| appointment_diagnosis | 16 |
| prescription | 11 |
| prescription_item | 13 |
| follow_up_plan | 11 |
 
---
 
### DELETE 3 – Blocked deletes (`ON DELETE RESTRICT`)
 
These statements are rejected because other records still depend on them.
 
```sql
DELETE FROM Patient  WHERE patient_id = 'OP001';   -- ERROR 1451: patient has appointments
DELETE FROM medicine WHERE medicine_id = 1;        -- ERROR 1451: used in prescription_item
DELETE FROM specialty WHERE specialty_id = 1;      -- ERROR 1451: used by Clinician
```
 
---
 
## 📋 Test Log
 
Run the statements in `tests.sql` and record the actual result in the last column.
 
### A. Structure and data
 
| ID | Test | SQL | Expected result | Result |
|----|------|-----|-----------------|--------|
| T01 | Database created | `SHOW DATABASES LIKE 'crownfield_eye';` | 1 row | ⬜ |
| T02 | All tables created | `SHOW TABLES;` | 11 tables | ⬜ |
| T03 | Data loaded | Row count check above | Counts match the table above (all ≥ 10 for main tables) | ⬜ |
| T04 | ALTER TABLE applied | `SHOW INDEX FROM Appointment;` | `idx_appt_date` listed | ⬜ |
 
### B. Constraint tests (each statement should fail)
 
| ID | Constraint | SQL | Expected error |
|----|------------|-----|----------------|
| T05 | PRIMARY KEY | `INSERT INTO Patient VALUES ('OP001','Test','User','N1 1AA','1990-01-01',NULL);` | ERROR 1062 Duplicate entry |
| T06 | FOREIGN KEY | `INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time) VALUES ('ZZ999',1,1,'2026-12-01','10:00:00');` | ERROR 1452 Cannot add or update a child row |
| T07 | UNIQUE (double booking) | `INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time) VALUES ('OP003',1,1,'2026-10-05','09:00:00');` | ERROR 1062 (`uq_clinician_slot`) |
| T08 | CHECK (date) | `INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time) VALUES ('OP003',1,1,'2019-12-31','09:00:00');` | ERROR 3819 (`chk_future_or_valid_date`) |
| T09 | CHECK (duration) | `INSERT INTO prescription_item VALUES (1,3,'1 drop','Topical (eye)','Daily',0);` | ERROR 3819 (`chk_pi_duration`) |
| T10 | NOT NULL | `INSERT INTO Patient VALUES ('OP099','Test',NULL,'N1 1AA','1990-01-01',NULL);` | ERROR 1048 Column 'last_name' cannot be null |
| T11 | ENUM | `INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time, status) VALUES ('OP003',3,1,'2026-12-01','10:00:00','Done');` | ERROR 1265 Data truncated for column 'status' |
| T12 | CHECK added by ALTER | `UPDATE Patient SET date_of_birth = '1800-01-01' WHERE patient_id = 'OP001';` | ERROR 3819 (`chk_patient_dob`) |
 
Record the actual result of T05 to T12 here: ⬜
 
### C. DEFAULT value
 
| ID | Test | SQL | Expected result | Result |
|----|------|-----|-----------------|--------|
| T13 | Default status | See below | `status = 'Scheduled'` | ⬜ |
 
```sql
START TRANSACTION;
INSERT INTO Appointment (patient_id, clinician_id, clinic_id, appointment_date, appointment_time)
VALUES ('OP003', 3, 1, '2026-12-01', '10:00:00');
SELECT appointment_id, status FROM Appointment WHERE appointment_date = '2026-12-01';
ROLLBACK;
```
 
### D. UPDATE and DELETE
 
| ID | Test | Expected result | Result |
|----|------|-----------------|--------|
| T14 | UPDATE 1: follow-up completed | 1 row affected; status = Completed | ⬜ |
| T15 | UPDATE 2: reschedule appointment 3 | 1 row affected; date = 2026-11-23 | ⬜ |
| T16 | UPDATE with invalid FK: `UPDATE Appointment SET clinic_id = 99 WHERE appointment_id = 1;` | ERROR 1452 | ⬜ |
| T17 | DELETE 1: cancelled appointment 12 | 1 row affected; OP011, clinician 10 and clinic 10 still exist | ⬜ |
| T18 | DELETE 2: cascade on appointment 14 | Before: 2, 1, 1. After: 0, 0, 0. After ROLLBACK: 2, 1, 1 | ⬜ |
| T19 | DELETE 3: delete patient OP001 | ERROR 1451 | ⬜ |
| T20 | DELETE 3: delete medicine 1 | ERROR 1451 | ⬜ |
| T21 | DELETE 3: delete specialty 1 | ERROR 1451 | ⬜ |
 
--- 
---
 

