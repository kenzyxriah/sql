-- ADD A CHECK IF DB ALREADY EXISTS
CREATE DATABASE HospitalDB
GO

USE HospitalDB
GO


-- Patients
IF OBJECT_ID('dbo.Patients', 'U') IS NULL
BEGIN
    CREATE TABLE Patients (
	    PatientID INT PRIMARY KEY IDENTITY(1,1), -- CREATES VALUES AUTOMATICALLY FOR THIS COLUMN UPON INSERT
	    FullName NVARCHAR (100) NOT NULL,
	    Address NVARCHAR(255) NOT NULL,
        DateOfBirth DATE NOT NULL,
        Insurance NVARCHAR(50) NOT NULL,
	    Username NVARCHAR(50) UNIQUE NOT NULL,
        Password NVARCHAR(255) NOT NULL,
        Email NVARCHAR(100),
        Telephone NVARCHAR(15),
        DateLeft DATE

    );
END
GO

-- departments
IF OBJECT_ID('dbo.Departments', 'U') IS NULL
BEGIN
    CREATE TABLE Departments (
	    DepartmentID INT PRIMARY KEY IDENTITY(1,1), -- CREATES VALUES AUTOMATICALLY FOR THIS COLUMN UPON INSERT
	    DepartmentName NVARCHAR (100) NOT NULL
    );
END
GO

-- doctors table
IF OBJECT_ID('dbo.Doctors', 'U') IS NULL
BEGIN
    CREATE TABLE Doctors (
	    DoctorID INT PRIMARY KEY IDENTITY(1,1), -- CREATES VALUES AUTOMATICALLY FOR THIS COLUMN UPON INSERT
        FullName NVARCHAR (100) NOT NULL,
	    DepartmentID INT NOT NULL,
        CONSTRAINT FK_DeptID FOREIGN KEY(DepartmentID) REFERENCES Departments(DepartmentID),
        Speciality VARCHAR(175)
    );
END
GO

-- FACTS TABLES
-- appointments
IF OBJECT_ID('dbo.Appointments', 'U') IS NULL
BEGIN  
    CREATE TABLE Appointments (
        AppointmentID INT PRIMARY KEY IDENTITY(1,1),
        PatientID INT NOT NULL,
        DoctorID INT NOT NULL,
        AppointmentDate DATE NOT NULL,
        AppointmentTime TIME NOT NULL,
        Status VARCHAR(50) CHECK (Status IN ('Pending', 'Cancelled', 'Completed')),
        -- Explicit constraint: CONSTRAINT CHK_StatusValid CHECK (Status IN ('Pending', 'Cancelled', 'Completed'))
        CONSTRAINT FK_Appointments_PatientID FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
        CONSTRAINT FK_Appointments_DoctorID FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
)
END
GO

-- Medical Record
IF OBJECT_ID('dbo.MedicalRecords', 'U') IS NULL
BEGIN
CREATE TABLE MedicalRecords (
    MedicalRecordID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL,
    AppointmentID INT NOT NULL,
    Diagnoses NVARCHAR(255),
    Medicines NVARCHAR(255),
    PrescribedDate DATE,
    Allergies NVARCHAR(255),
    CONSTRAINT FK_MedicalRecords_PatientID FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_MedicalRecords_AppointmentID FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
);
END
GO


-- INSERTING DATA
-- PATIENTS
--INSERTING VALUES INTO PATIENT TABLE
INSERT INTO Patients (FullName, Address, DateOfBirth, Insurance, Username, Password, Email, Telephone, DateLeft)
VALUES
('Anosike Tare', 'No 9 henry street', '2003-05-15', 'stable insurance ltd', 'Tare_anosike', 'Tare2003$', 'misstare@gmail.com', '08099761234', NULL),
('Oke Oghene', 'jakpa road street', '1990-08-22', 'relayed insurance company', 'okeoghene', 'enehgoeko', 'okeoghene@gmail.com', '09087654321', NULL),
('Jimi Owen', 'no 18 queen idia road', '1975-03-30', 'allied Insurance Company', 'jimowens', 'jimi123owens', NULL, '09111223383', NULL),
('Aminu Mustapha', '31 ugbowo road ', '1985-07-14', 'Insurance Arrays', 'Mustify', 'musty419#', 'mustify@gmail.com', '07099941989', NULL),
('Michael osue', 'no 6 aka avenue St', '2015-09-05', 'big rays insured', 'osuemicheal', 'osue222micheal', NUll, '08123234545', NULL),
('Sarah izokaiah', '44 new site estate', '2000-12-25', 'null', 'sarah_izokhai', 'sarah###', 'sarahizzy@gmail.com', '+234815556666', NULL),
('emenahor Nonye', 'no 25 crd road', '1988-11-11', 'aggy Insurance ', 'nonye emenahor', 'nons999', 'emenahornons@gmail.com', '07088289999', NULL),
('Usen Elohor' , 'No 1 obada close', '1997-12-05', 'stable insurance ltd', 'usen_elohor', 'elohor1997', 'elohorusen@gmail.com', '09129467234', NULL),
('Progress Erharbor', 'no 17 praise center jakpa road street', '1999-03-17', 'aggy insurance company', 'Progressusen', 'progress123', 'progressusen@gmail.com', '08067659329', NULL),
('Mudiaga Macs', 'no 18 ssq road', '1989-03-13', 'aggy Insurance Company', 'Mudiqt', 'mudimacs#', NULL, '07155523338', NULL),
('Shelter Omoregie', '31 ugbowo road ', '1985-07-14', 'Insurance Arrays', 'shelteromo', 'sheltey1985pink', 'shelteromoregie@gmail.com', '070229874439', NULL),
('Bona Elochukwu', 'no 22 old market St', '1999-05-03', 'big rays insured', 'bonaumeaku', 'elochukwu1', NUll, '090228966711', NULL),
('chukwuma Blessing', '44 car wash road', '2001-12-11', 'null', 'blessing_chuks', 'blesschukwuma000', 'chukwumablessing@gmail.com', '0912229756340', NULL)
GO

-- INSERTING MORE VALUES INTO PATIENT TABLE
INSERT INTO Patients (FullName, Address, DateOfBirth, Insurance, Username, Password, Email, Telephone, DateLeft)
VALUES
('Akpevwe Onatere', 'Lagos, Nigeria', '1980-01-15', 'Aetna', 'john_doe', 'password123', 'john.doe@example.com', '08012345678', NULL),
('Sadoh Vera', 'Abuja, Nigeria', '1975-02-20', 'UnitedHealthcare', 'jane_smith', 'password123', 'jane.smith@example.com', '08023456789', NULL),
('Nnsodima Charity', 'Kano, Nigeria', '1970-03-25', 'Cigna', 'alice_johnson', 'password123', 'alice.johnson@example.com', '08034567890', NULL),
('Osas Osayi', 'Ibadan, Nigeria', '1965-04-30', 'BlueCross', 'robert_brown', 'password123', 'robert.brown@example.com', '08045678901', NULL),
('Isreal Akakari', 'Port Harcourt, Nigeria', '1978-05-15', 'Kaiser', 'emily_davis', 'password123', 'emily.davis@example.com', '08056789012', NULL),
('Michael Omaweru', 'Benin City, Nigeria', '1980-06-20', 'Humana', 'michael_miller', 'password123', 'michael.miller@example.com', '08067890123', NULL),
('Jessica Onatere', 'Jos, Nigeria', '1979-07-25', 'Aetna', 'jessica_wilson', 'password123', 'jessica.wilson@example.com', '08078901234', NULL),
('David Erharbor', 'Enugu, Nigeria', '1977-08-30', 'UnitedHealthcare', 'david_moore', 'password123', 'david.moore@example.com', '08089012345', NULL),
('Sarah Aroture', 'Calabar, Nigeria', '1982-09-05', 'Cigna', 'sarah_taylor', 'password123', 'sarah.taylor@example.com', '08090123456', NULL),
('Chris Anderson', 'Ilorin, Nigeria', '1973-10-10', 'BlueCross', 'chris_anderson', 'password123', 'chris.anderson@example.com', '08001234567', NULL),
('Patricia Oshobugie', 'Maiduguri, Nigeria', '1972-11-15', 'Kaiser', 'patricia_thomas', 'password123', 'patricia.thomas@example.com', '08012345670', NULL),
('Matthew Adjayi', 'Abeokuta, Nigeria', '1968-12-20', 'Humana', 'matthew_jackson', 'password123', 'matthew.jackson@example.com', '08023456781', NULL),
('Mrs Laura Avwerusuo', 'Uyo, Nigeria', '1971-01-25', 'Aetna', 'laura_white', 'password123', 'laura.white@example.com', '08034567892', NULL),
('James Harrison', 'Ogbomosho, Nigeria', '1983-02-28', 'UnitedHealthcare', 'james_harris', 'password123', 'james.harris@example.com', '08045678903', NULL),
('Linda Martins', 'Akure, Nigeria', '1980-03-05', 'Cigna', 'linda_martin', 'password123', 'linda.martin@example.com', '08056789014', NULL),
('Joshua Oghenekevwe', 'Kaduna, Nigeria', '1975-04-10', 'BlueCross', 'joshua_thompson', 'password123', 'joshua.thompson@example.com', '08067890125', NULL),
('Karen Oghenekevwe', 'Owerri, Nigeria', '1979-05-15', 'Kaiser', 'karen_robinson', 'password123', 'karen.robinson@example.com', '08078901236', NULL),
('Ryan Omaweru', 'Onitsha, Nigeria', '1976-06-20', 'Humana', 'ryan_walker', 'password123', 'ryan.walker@example.com', '08089012347', NULL),
('Betty Usen', 'Ife, Nigeria', '1980-07-25', 'Aetna', 'betty_hall', 'password123', 'betty.hall@example.com', '08090123458', NULL),
('Jason Adjayi', 'Warri, Nigeria', '1981-08-30', 'UnitedHealthcare', 'jason_young', 'password123', 'jason.young@example.com', '08001234569', NULL),
('Angela Erharbor', 'Ado Ekiti, Nigeria', '1978-09-05', 'Cigna', 'angela_king', 'password123', 'angela.king@example.com', '08012345670', NULL),
('Kevin Scott', 'Sokoto, Nigeria', '1969-10-10', 'BlueCross', 'kevin_wright', 'password123', 'kevin.wright@example.com', '08023456781', NULL),
('Nancy Scott', 'Zaria, Nigeria', '1977-11-15', 'Kaiser', 'nancy_scott', 'password123', 'nancy.scott@example.com', '08034567892', NULL);
GO

-- DEPARTMENTS
-- INSERTING VALUES INTO DEPARTMENT TABLE
INSERT INTO Departments (DepartmentName)
VALUES
('Cardiology'),
('Neurology'),
('Orthopedics'),
('Pediatrics'),
('Dermatology'),
('Gastroenterology'),
('Oncology');
GO

--INSERTING MORE VALUES INTO DEPARTMENT TABLE
INSERT INTO Departments (DepartmentName)
VALUES
    ('Cardiology'),
    ('Neurology'),
    ('Oncology'),
    ('Pediatrics'),
    ('Radiology'),
    ('Orthopedics'),
    ('Dermatology'),
    ('Gynecology'),
    ('Urology'),
    ('Ophthalmology'),
    ('Gastroenterology'),
    ('Hematology'),
    ('Endocrinology'),
    ('Pulmonology'),
    ('Nephrology'),
    ('Rheumatology'),
    ('Infectious Diseases'),
    ('Allergy and Immunology'),
    ('Anesthesiology'),
    ('Pathology'),
    ('Psychiatry'),
    ('Surgery'),
    ('Emergency Medicine');
GO

INSERT INTO Departments (DepartmentName)
VALUES
    ('Emergency Medicine'),
    ('General Medicine'),
    ('Plastic Surgery'),
    ('Occupational Medicine'),
    ('Rehabilitation'),
    ('Sports Medicine');

GO
-- 36 DEPTS

-- DOCTORS
--INSERTING VALUES INTO DOCTORS TABLE
INSERT INTO Doctors (FullName, DepartmentID, Speciality)
VALUES
('Dr. Bright Anukam', 1, 'Gastroenterologist'),
('Dr. Jeffery Olisa', 2, 'Cardiologist'),
('Dr. Osas Azeez', 3, 'Neurologist'),
('Dr. Caroline Ugochi', 1, 'Gastroenterologist'),
('Dr. Adewunmi Olorundare', 2, 'Cardiologist'),
('Dr. Somto Kosi', 3, 'Neurologist'),
('Dr. Jolomi Tejere', 1, 'Gastroenterologist');


--INSERTING MORE VALUES INTO DOCTORS TABLE
INSERT INTO Doctors(FullName,DepartmentID, Speciality)
VALUES
    ('Dr. Adeola Adetokunbo',24, 'Gastroenterologist'),
    ('Dr. Chiamaka Akintola',5, 'Pediatrician'),
    ('Dr. Babajide Bamidele',7, 'Dermatologist'),
    ('Dr. Funmilayo Chukwuma',9, 'Endocrinologist'),
    ('Dr. Ifeanyi Durojaiye',11, 'General Surgeon'),
    ('Dr. Kemi Eze',13, 'Ophthalmologist'),
    ('Dr. Adebayo Fashola',15,'Hematologist'),
    ('Dr. Nneka Ige',17,'Rheumatologist'),
    ('Dr. Bolaji Idowu',19,'Gynecologist'),
    ('Dr. Yemi Jibola',21,'Family Physician'),
    ('Dr. Emeka Kalu',23,'Internist'),
    ('Dr. Sade Lawal',25,'Anesthesiologist'),
    ('Dr. Chinedu Madu',27,'Neonatologist'),
    ('Dr. Oluwatoyin Nwachukwu',29,'Pathologist'),
    ('Dr. Folake Okafor',31,'Plastic Surgeon'),
    ('Dr. Bisi Oladipo',33,'Pain Management Specialist'),
    ('Dr. Tunde Omisore',35,'Sleep Medicine Specialist'),
    ('Dr. Yetunde Onyekachi',4,'Orthopedic Surgeon'),
    ('Dr. Ngozi Opara',6,'Oncologist'),
    ('Dr. Abiodun Osagie',8,'Dermatologist'),
    ('Dr. Niyi Peters',10,'Psychiatrist'),
    ('Dr. Chisom Richards',12,'Radiologist'),
    ('Dr. Kayode Sanni',14,'Urologist'),
    ('Dr. Chinelo Taiwo',16,'Hematologist'),
    ('Dr. Solomon Uche',17,'Rheumatologist'),
    ('Dr. Abimbola Udo',18,'Infectious Disease Specialist'),
    ('Dr. Kehinde Williams',19,'Gynecologist'),
    ('Dr. Temidayo Yusuf',20,'General Surgeon'),
    ('Dr. Obinna Zubair',22,'Cardiologist');
GO

-- TRIGGERS OUR FOREIGN KEY CHECK
--INSERT INTO Doctors(FullName,DepartmentID, Speciality)
--VALUES
--   ('Dr. Adeola Adetokunbo',49, 'Gastroenterologist')

-- INSERTING VALUES INTO APPOINTMENT TABLES
INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Status)
VALUES
    (1, 1, '2026-07-01', '08:00', 'Pending'),
    (2, 2, '2026-06-01', '09:00', 'Completed'),
    (3, 3, '2026-07-01', '10:00', 'Cancelled'),
    (4, 4, '2026-07-02', '08:30', 'Pending'),
    (5, 5, '2026-06-02', '09:30', 'Completed'),
    (6, 6, '2026-07-02', '10:30', 'Cancelled'),
    (7, 7, '2026-07-03', '08:00', 'Pending'),
    (8, 8, '2026-06-03', '09:00', 'Completed'),
    (9, 9, '2026-07-03', '10:00', 'Cancelled'),
    (10, 10, '2026-07-04', '08:15', 'Pending'),
    (11, 11, '2026-06-04', '09:15', 'Completed'),
    (12, 12, '2026-07-04', '10:15', 'Cancelled'),
    (13, 13, '2026-07-05', '08:45', 'Pending'),
    (14, 14, '2026-06-05', '09:45', 'Completed'),
    (15, 15, '2026-07-05', '10:45', 'Cancelled'),
    (16, 16, '2026-07-06', '08:00', 'Pending'),
    (17, 17, '2026-06-06', '09:00', 'Completed'),
    (18, 18, '2026-07-06', '10:00', 'Cancelled'),
    (19, 19, '2026-07-07', '08:30', 'Pending'),
    (20, 20, '2026-06-07', '09:30', 'Completed'),
    (21, 21, '2026-07-07', '10:30', 'Cancelled'),
    (22, 22, '2026-07-08', '08:00', 'Pending'),
    (23, 23, '2026-06-08', '09:00', 'Completed'),
    (24, 24, '2026-07-08', '10:00', 'Cancelled'),
    (25, 25, '2026-07-09', '08:15', 'Pending'),
    (26, 26, '2026-06-09', '09:15', 'Completed'),
    (27, 27, '2026-07-09', '10:15', 'Cancelled'),
    (28, 28, '2026-07-10', '08:45', 'Pending'),
    (29, 29, '2026-06-10', '09:45', 'Completed'),
    (30, 30, '2026-07-10', '10:45', 'Cancelled'),
    (31, 31, '2026-07-11', '08:00', 'Pending'),
    (32, 32, '2026-06-11', '09:00', 'Completed'),
    (33, 33, '2026-07-11', '10:00', 'Cancelled'),
    (34, 34, '2026-07-12', '08:30', 'Pending'),
    (35, 1, '2026-06-12', '09:30', 'Completed'),
    (1, 2, '2026-07-12', '10:30', 'Cancelled'),
    (2, 3, '2026-07-13', '08:00', 'Pending'),
    (3, 4, '2026-06-13', '09:00', 'Completed'),
    (4, 5, '2026-07-13', '10:00', 'Cancelled'),
    (5, 6, '2026-07-14', '08:15', 'Pending'),
    (6, 7, '2026-06-14', '09:15', 'Completed'),
    (7, 8, '2026-07-14', '10:15', 'Cancelled'),
    (8, 9, '2026-07-15', '08:45', 'Pending'),
    (9, 10, '2026-05-15', '09:45', 'Completed'),
    (10, 11, '2026-07-15', '10:45', 'Cancelled'),
    (11, 12, '2026-07-16', '08:00', 'Pending'),
    (12, 13, '2026-06-16', '09:00', 'Completed'),
    (13, 14, '2026-07-16', '10:00', 'Cancelled'),
    (14, 15, '2026-07-17', '08:30', 'Pending'),
    (15, 16, '2026-06-17', '09:30', 'Completed');
GO

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Status)
VALUES
    (1, 14, '2026-06-23', '08:00', 'Pending')
GO

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Status)
VALUES
    (13, 5, '2026-06-29', '12:00', 'Pending')
GO

INSERT INTO MedicalRecords
(PatientID, AppointmentID, Diagnoses, Medicines, PrescribedDate, Allergies)
VALUES
(2, 2, 'Migraine', 'Ibuprofen', '2026-07-01', 'None'),
(5, 5, 'Asthma', 'Cromolyn', '2026-07-02', 'Dust'),
(8, 8, 'Hypertension', 'Amlodipine', '2026-07-03', 'None'),
(11, 11, 'Fever', 'Paracetamol', '2026-07-04', 'Penicillin'),
(14, 14, 'Back Pain', 'Diclofenac', '2026-07-05', 'None'),
(17, 17, 'Influenza', 'Oseltamivir', '2026-07-06', 'None'),
(20, 20, 'Type 2 Diabetes', 'Insulin', '2026-07-07', 'Sugar'),
(23, 23, 'Sinusitis', 'Nasal Spray', '2026-07-08', 'Pollen'),
(26, 26, 'Kidney Stones', 'Pain Relief Therapy', '2026-07-09', 'None'),
(29, 29, 'Obesity', 'Orlistat', '2026-07-10', 'None'),
(32, 32, 'Anxiety Disorder', 'Sertraline', '2026-07-11', 'None'),
(35, 35, 'Gastritis', 'Omeprazole', '2026-07-12', 'Spicy Food'),
(1, 38, 'Fracture Follow-up', 'Calcium Supplement', '2026-07-13', 'None'),
(6, 41, 'Bronchitis', 'Antibiotics', '2026-07-14', 'Smoke'),
(9, 44, 'Hypertension Review', 'Lifestyle Control', '2026-07-15', 'Salt'),
(12, 47, 'Asthma Control', 'Inhaler Therapy', '2026-07-16', 'Dust'),
(15, 50, 'Routine Checkup', 'Multivitamins', '2026-07-17', 'None');
GO
