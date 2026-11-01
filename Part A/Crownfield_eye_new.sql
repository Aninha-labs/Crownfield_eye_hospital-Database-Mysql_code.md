-- =========================================================
-- CROWNFIELD_EYE Hospital DATABASE
-- =========================================================

DROP DATABASE IF EXISTS crownfield_eye;
CREATE DATABASE crownfield_eye;
USE crownfield_eye;

-- ---------------------------------------------------------
-- 1. Main and reference tables
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 2. Related queries and tables
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 3. Reference data
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 4. Clinician
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 5. Pacients
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 6. Appointment
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 7. Appointment_diagnosis
-- ---------------------------------------------------------

INSERT INTO appointment_diagnosis (appointment_id, diagnosis_id) VALUES
(1, 1), (2, 2), (3, 1), (4, 3),
(5, 4), (6, 5), (7, 9), (8, 8),
(9, 10), (10, 7), (11, 11), (13, 2),
(14, 12), (14, 1), (15, 11), (16, 2);

-- ---------------------------------------------------------
-- 8. Prescription
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 9. Follow_up_plans
-- ---------------------------------------------------------

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

-- ---------------------------------------------------------
-- 10. Verification
-- ---------------------------------------------------------

-- SELECT COUNT(*) AS total_patients FROM Patient;
-- SELECT COUNT(*) AS total_clinicians FROM Clinician;
-- SELECT COUNT(*) AS total_clinics FROM Clinic;
-- SELECT COUNT(*) AS total_appointments FROM Appointment;
-- SELECT COUNT(*) AS total_diagnoses FROM diagnosis;
-- SELECT COUNT(*) AS total_medicines FROM medicine;
