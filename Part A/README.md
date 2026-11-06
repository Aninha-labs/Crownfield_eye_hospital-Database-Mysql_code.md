# Crownfield Eye Hospital – Part A: Conceptual and Logical Database Design

*Flytech Ltd · Ophthalmology database prototype · Group members: \[Ana Paula Silva\], \[Jean Michel Dos Santos Medeiros\]*

**Deliverables in this document:** (A1) annotated anomaly analysis, (A2) ER diagram and modelling justification, (A3) normalization working and final relational schema.

## A1. Analysis of the unnormalized data

### A1.1 Unnormalized form (UNF)

The hospital's Word and Excel files behave like one wide record per appointment. Curly braces mark repeating groups.

**UNF** = ( patient\_id, first\_name, last\_name, postcode, date\_of\_birth, phone, appointment\_id, appointment\_date, appointment\_time, status, notes, clinician\_id, clinician\_first\_name, clinician\_last\_name, specialty\_name, clinic\_name, clinic\_address, **{** diagnosis\_name **}**, **{** prescription\_id, issued\_date, **{** medicine\_name, dose, route, frequency, duration\_days **}** **}**, followup\_due\_date, followup\_priority, followup\_status )

Example row (appointment 14):

| Field | Value |
| --- | --- |
| Patient | OP013, Elena Rossi, EC1 4ST, 1983-02-22 |
| Appointment | 14, 2026-10-16 09:15, Completed, Pressure check |
| Clinician | 1, Maya Shah, Glaucoma |
| Clinic | City Road, City Road, London |
| Diagnoses (repeating) | Primary open-angle glaucoma; Ocular hypertension |
| Prescription (repeating) | Rx 10, issued 2026-10-16: Brimonidine 1 drop, Topical (eye), Twice daily, 90 days; Dorzolamide 1 drop, Topical (eye), Three times daily, 90 days |
| Follow-up | Due 2027-01-08, Routine, Open |

### A1.2 Repeating groups

- **Diagnoses:** an appointment can have zero or more diagnoses (appointment 14 has two), so the diagnosis column holds a list.
- **Prescriptions:** an appointment can have zero or more prescriptions.
- **Medicines inside a prescription:** a prescription can hold several medicines, each with its own dose, route, frequency and duration (Rx 1 has Latanoprost and Timolol). This is a repeating group nested inside another repeating group.
- Diagnoses and prescriptions are **independent** of each other. Forcing both into one flat table would multiply rows (every diagnosis paired with every medicine) and invent relationships that do not exist.

### A1.3 Redundancy

| Duplicated data | Where it repeats in the sample data |
| --- | --- |
| Patient name, postcode, date of birth | OP001 (appointments 1 and 3); OP002 (appointments 2 and 16) |
| Clinician name and specialty | Maya Shah in appointments 1, 3, 4, 14; Leo Grant in 2, 15, 16 |
| Clinic name and address | City Road in appointments 1, 2, 4, 13, 14, 16 |
| Diagnosis wording | Ocular hypertension (1, 3, 14); Diabetic macular oedema (2, 13, 16); Retinal vein occlusion (11, 15) |
| Medicine names | Latanoprost (Rx 1, 3); Aflibercept (Rx 2, 9) |

### A1.4 Inconsistent representation

Because the records are free text across several files, the same fact can be written in different ways. Examples visible in the data:

- **Frequency:** Once daily at night, Once daily, Single dose, Four times daily. Equivalent wording such as QDS or 4x/day would break any report that counts by frequency.
- **Route and dose units:** Topical (eye) versus Intravitreal injection; 1 drop versus 2 mg versus 0.5 mg.
- **Clinic location:** the address is only a borough (Croydon, London), and the clinic name and address repeat the same text.
- **Free-text notes and abbreviations:** IOP, OCT, MRI; spelling variants such as oedema/edema are possible in paper records.
- **Dates, times and statuses** are typed by hand in the legacy files (for example 05/10/26 versus 2026-10-05, Done versus Completed).
- **Date and status logic:** appointment 3 is Scheduled for 2026-11-16, yet it already has a diagnosis and a prescription issued on that date. A rule linking status to clinical data is needed (see A2.4).

### A1.5 Anomalies

**Insertion anomaly.** A new clinician, clinic, specialty, diagnosis or medicine cannot be stored until an appointment exists, because every fact lives inside an appointment row. For example, a newly recruited Cornea clinician or a newly approved medicine has nowhere to be recorded.

**Update anomaly.** If Maya Shah changes specialty, or the City Road clinic changes address, every appointment row must be edited (4 rows and 6 rows respectively in the sample). Missing one row leaves two versions of the truth.

**Deletion anomaly.** Appointment 12 (cancelled) is the only appointment for patient OP011 Hannah Brooks, clinician Raj Patel and the Islington clinic. Deleting that row would also erase the patient, the clinician and the clinic.

### A1.6 Assumptions

1. A patient is identified by a 5-character hospital number (OP001 to OP014).
2. Each clinician has exactly one primary specialty (the brief says may have one; the prototype makes it mandatory so that every clinician can be classified).
3. A clinician cannot be booked twice at the same date and time.
4. Each appointment has at most one follow-up plan.
5. A prescription belongs to one appointment; it is not linked directly to the patient.
6. A prescription must contain at least one medicine item.
7. A diagnosis or medicine name identifies a single entry in the reference list (no synonyms).
8. The patient phone number is personal data and is stored encrypted.
9. Appointment dates before 2020-01-01 are treated as invalid.

## A2. Conceptual data model

### A2.1 Entities and attributes

| Entity | Attributes | Identifier |
| --- | --- | --- |
| Patient | first\_name, last\_name, postcode, date\_of\_birth, phone (encrypted) | patient\_id |
| Specialty | specialty\_name | specialty\_id |
| Clinician | first\_name, last\_name | clinician\_id |
| Clinic | clinic\_name, address | clinic\_id |
| Appointment | appointment\_date, appointment\_time, status, notes | appointment\_id |
| Diagnosis | diagnosis\_name | diagnosis\_id |
| Medicine | medicine\_name | medicine\_id |
| Prescription | issued\_date | prescription\_id |
| Prescription item (relationship with attributes) | dose, route, frequency, duration\_days | prescription\_id + medicine\_id |
| Follow-up plan | due\_date, priority, status | followup\_id |

### A2.2 Relationships (Crownfield eye hospital)

| Relationship | Cardinality | Optionality |
| --- | --- | --- |
| Patient attends Appointment | 1 : M | Patient has 0 or more appointments; an appointment has exactly 1 patient |
| Clinician conducts Appointment | 1 : M | Clinician has 0 or more; an appointment has exactly 1 clinician |
| Clinic hosts Appointment | 1 : M | Clinic has 0 or more; an appointment has exactly 1 clinic |
| Specialty classifies Clinician | 1 : M | Specialty has 0 or more clinicians; a clinician has exactly 1 specialty |
| Appointment results in Diagnosis | M : N (via appointment\_diagnosis) | An appointment has 0 or more diagnoses; a diagnosis may apply to 0 or more appointments |
| Appointment generates Prescription | 1 : M | An appointment has 0 or more prescriptions; a prescription belongs to exactly 1 appointment |
| Prescription contains Medicine | M : N (via prescription\_item) | A prescription has 1 or more items; a medicine may appear in 0 or more prescriptions |
| Appointment generates Follow-up plan | 1 : 0..1 | An appointment has 0 or 1 follow-up plan; a plan belongs to exactly 1 appointment |

### A2.3 ER diagram


### A2.4 Modelling justification

1. **Appointment is the central entity.** Diagnoses, prescriptions and follow-up plans all depend on a specific visit, so they link to Appointment and not directly to Patient.
2. **Junction table appointment\_diagnosis** resolves the many-to-many relationship between appointments and diagnoses and avoids a repeating group in Appointment.
3. **prescription\_item is a relationship entity with attributes.** Dose, route, frequency and duration describe a medicine inside one prescription, not the medicine itself or the prescription alone, so they sit on the junction.
4. **Prescription is separate from prescription\_item.** The issue date belongs to the whole prescription and would otherwise repeat for each medicine.
5. **Follow-up plan is a separate optional entity.** Most appointments have none, so storing it inside Appointment would create many NULLs. A UNIQUE foreign key enforces the 1 : 0..1 rule.
6. **Specialty, Diagnosis, Medicine and Clinic are lookup entities.** This removes inconsistent spelling and allows new values to be added without an appointment.
7. **Patient key.** A short natural key (hospital number) matches how staff identify patients; all other tables use auto-increment surrogate keys for stability.
8. **Constraints that support the business rules:** a UNIQUE (clinician, date, time) prevents double booking; ENUMs restrict status and priority; CHECK constraints reject invalid dates and non-positive durations; phone is stored as VARBINARY so it can be encrypted.
9. **Delete behaviour.** RESTRICT protects patients, clinicians, clinics and reference data from accidental deletion. CASCADE is used only for dependent records (diagnoses, prescriptions, items, follow-up) that have no meaning without their appointment.
10. **Suggested rule (not yet in the prototype).** Diagnoses and prescriptions should only be recorded when the appointment status is Completed. This can be enforced by a trigger or in the application.

## A3. Normalization and logical schema

### A3.1 Functional dependencies

- appointment\_id → patient\_id, clinician\_id, clinic\_id, appointment\_date, appointment\_time, status, notes
- (clinician\_id, appointment\_date, appointment\_time) → appointment\_id (candidate key, no double booking)
- patient\_id → first\_name, last\_name, postcode, date\_of\_birth, phone
- clinician\_id → first\_name, last\_name, specialty\_id
- specialty\_id → specialty\_name
- clinic\_id → clinic\_name, address (and clinic\_name → clinic\_id, as names are unique)
- diagnosis\_id → diagnosis\_name
- medicine\_id → medicine\_name
- prescription\_id → appointment\_id, issued\_date
- (prescription\_id, medicine\_id) → dose, route, frequency, duration\_days
- appointment\_id → due\_date, priority, status of the follow-up plan

### A3.2 Unnormalized form to First Normal Form (1NF)

**Problem:** repeating groups and independent multi-valued attributes.

**Action:** remove the repeating groups into their own relations, each with atomic values and a primary key. Diagnoses and prescriptions are split apart so they are not multiplied together.

- **R1** Appointment\_Flat ( **appointment\_id**, patient\_id, first\_name, last\_name, postcode, date\_of\_birth, phone, appointment\_date, appointment\_time, status, notes, clinician\_id, clinician\_first\_name, clinician\_last\_name, specialty\_name, clinic\_name, clinic\_address, followup\_due\_date, followup\_priority, followup\_status )
- **R2** Appt\_Diagnosis ( **appointment\_id**, **diagnosis\_name** )
- **R3** Appt\_Prescription ( **prescription\_id**, **medicine\_name**, appointment\_id, issued\_date, dose, route, frequency, duration\_days )

All attributes are now atomic and every relation has a primary key, so the data is in 1NF.

### A3.3 First Normal Form to Second Normal Form (2NF)

**Partial dependencies** exist only where the key is composite (R2 and R3). R1 has a single-attribute key, so it is already in 2NF.

| Relation | Composite key | Partial dependency | Fix |
| --- | --- | --- | --- |
| R2 | (appointment\_id, diagnosis\_name) | diagnosis\_name is a key attribute; give it an ID so the name is stored once: diagnosis\_id → diagnosis\_name | New relation **diagnosis** ( diagnosis\_id, diagnosis\_name ); junction keeps (appointment\_id, diagnosis\_id) |
| R3 | (prescription\_id, medicine\_name) | prescription\_id → appointment\_id, issued\_date | New relation **prescription** ( prescription\_id, appointment\_id, issued\_date ) |
| R3 | (prescription\_id, medicine\_name) | medicine\_name is stored per row; give it an ID so the name is stored once | New relation **medicine** ( medicine\_id, medicine\_name ) |
| R3 | (prescription\_id, medicine\_id) | dose, route, frequency, duration\_days depend on the whole key | Remain in **prescription\_item** |

**Result in 2NF:** Appointment\_Flat, appointment\_diagnosis, diagnosis, prescription, medicine, prescription\_item.

### A3.4 Second Normal Form to Third Normal Form (3NF)

**Transitive dependencies** in Appointment\_Flat (non-key attribute determines another non-key attribute):

| Transitive dependency | Decomposition |
| --- | --- |
| appointment\_id → patient\_id → first\_name, last\_name, postcode, date\_of\_birth, phone | **Patient** ( patient\_id, first\_name, last\_name, postcode, date\_of\_birth, phone\_enc ) |
| appointment\_id → clinician\_id → clinician\_first\_name, clinician\_last\_name, specialty | **Clinician** ( clinician\_id, first\_name, last\_name, specialty\_id ) |
| clinician\_id → specialty\_id → specialty\_name | **Specialty** ( specialty\_id, specialty\_name ) |
| appointment\_id → clinic\_id → clinic\_name, clinic\_address | **Clinic** ( clinic\_id, clinic\_name, address ) |
| appointment\_id → followup attributes (optional group) | **Follow\_up\_plan** ( followup\_id, appointment\_id, due\_date, priority, status ), which removes NULLs for appointments without a plan |

After these steps every non-key attribute depends on the key, the whole key and nothing but the key. The remaining Appointment relation holds only appointment facts and foreign keys. Every determinant in the final schema is a candidate key, so the design also satisfies BCNF.

**Deliberate limit:** route, frequency and dose are kept as controlled free text with validation in the application. They could be split into lookup tables, but that would add complexity without changing the business rules in the brief.

### A3.5 Final relational schema

PK = primary key, FK = foreign key, UQ = unique, NN = not null.

| Table | Columns and keys | Constraints |
| --- | --- | --- |
| **Patient** | **patient\_id** CHAR(5) PK; first\_name VARCHAR(50) NN; last\_name VARCHAR(50) NN; postcode VARCHAR(10) NN; date\_of\_birth DATE NN; phone\_enc VARBINARY(255) NULL | – |
| **specialty** | **specialty\_id** INT PK AUTO\_INCREMENT; specialty\_name VARCHAR(75) NN | UQ(specialty\_name) |
| **Clinician** | **clinician\_id** INT PK; first\_name NN; last\_name NN; specialty\_id INT NN FK → specialty | ON DELETE RESTRICT |
| **Clinic** | **clinic\_id** INT PK; clinic\_name VARCHAR(75) NN; address VARCHAR(150) NN | UQ(clinic\_name) |
| **diagnosis** | **diagnosis\_id** INT PK; diagnosis\_name VARCHAR(100) NN | UQ(diagnosis\_name) |
| **medicine** | **medicine\_id** INT PK; medicine\_name VARCHAR(100) NN | UQ(medicine\_name) |
| **Appointment** | **appointment\_id** INT PK; patient\_id FK → Patient; clinician\_id FK → Clinician; clinic\_id FK → Clinic; appointment\_date DATE NN; appointment\_time TIME NN; status ENUM(Scheduled, Completed, Cancelled) NN DEFAULT Scheduled; notes VARCHAR(255) NULL | RESTRICT on all FKs; CHECK (appointment\_date >= 2020-01-01); UQ(clinician\_id, appointment\_date, appointment\_time); index on patient\_id |
| **appointment\_diagnosis** | **appointment\_id** FK → Appointment, **diagnosis\_id** FK → diagnosis (composite PK) | CASCADE on appointment; RESTRICT on diagnosis |
| **prescription** | **prescription\_id** INT PK; appointment\_id INT NN FK → Appointment; issued\_date DATE NN | CASCADE on appointment |
| **prescription\_item** | **prescription\_id** FK → prescription, **medicine\_id** FK → medicine (composite PK); dose, route, frequency VARCHAR(40) NN; duration\_days INT NN | CHECK (duration\_days > 0); CASCADE on prescription; RESTRICT on medicine |
| **follow\_up\_plan** | **followup\_id** INT PK; appointment\_id INT NN FK → Appointment; due\_date DATE NN; priority ENUM(Routine, High, Urgent) NN DEFAULT Routine; status ENUM(Open, Completed, Cancelled) NN DEFAULT Open | UQ(appointment\_id) gives 1 : 0..1; CASCADE on appointment |

### A3.6 Check: no orphaned tables

Every table is connected to the rest of the schema by at least one foreign key:

- Patient, Clinician, Clinic → Appointment
- specialty → Clinician
- diagnosis → appointment\_diagnosis → Appointment
- medicine → prescription\_item → prescription → Appointment
- follow\_up\_plan → Appointment

The schema is one connected structure with Appointment at the centre, so there are no orphaned tables.


