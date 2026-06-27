USE HospitalDB
GO

SELECT *
FROM Appointments

SELECT *
FROM Patients

SELECT *
FROM MedicalRecords

SELECT *
FROM Doctors

SELECT *
FROM Departments



--  List all the patients with older than 40 and have Cancer in diagnosis.
SELECT *
FROM Patients as P
JOIN MedicalRecords as MR
ON P.PatientID = MR.PatientID
WHERE DATEDIFF(YEAR,DateOfBirth,GETDATE()) > 20
AND Diagnoses LIKE 'CANCER%';
GO

--  Search the database of the hospital for matching character strings by name of medicine
DROP PROCEDURE IF EXISTS Search_Medicine;
GO

CREATE PROCEDURE Search_Medicine
		@MedicineName VARCHAR(100)
AS
BEGIN
	SELECT *
	FROM MedicalRecords
	WHERE Medicines LIKE @MedicineName + '%'
	ORDER BY PrescribedDate DESC

END
GO

-- EXECUTE
EXEC Search_Medicine
@MedicineNamE = 'Ibuprofen';
GO

-- Return a full list of PRIOR diagnosis and allergies for a specific patient who has an appointment today
CREATE PROCEDURE Get_Patient_Diagnosis_and_Allergies
	-- parameter
    @PatientID INT
AS
BEGIN
	-- LOCAL VARIABLE (SCOPED AND ONLY ACCESSED WITHIN THE STORED PROCEDURE
	DECLARE @Today DATE = GETDATE();

	Select 
		MR.Diagnoses,
		MR.Allergies

	FROM Appointments as A
	JOIN MedicalRecords as MR
	ON MR.PatientID = A.PatientID
	WHERE A.PatientID = @PatientID
	AND AppointmentDate =  @Today

END
GO

EXEC Get_Patient_Diagnosis_and_Allergies
-- 1 is the argument/value passed to the parameter
@PatientID = '1'
GO

-- ANALYTICAL VIEW
-- PENDING APPOINTMENT within the next 2 weeks

CREATE OR ALTER VIEW v_Pending_Queue
AS
SELECT 
    A.AppointmentID,
    A.AppointmentDate,
    A.AppointmentTime,
    A.Status,
    P.PatientID,
    P.FullName AS PatientName,
	DATEDIFF(YEAR, P.DateOfBirth, GETDATE()) AS PatientAge,
    Doc.FullName AS DoctorName,
    Doc.Speciality,
	Dep.DepartmentName

FROM Appointments as A
JOIN Patients as P on  P.PatientID =  A.PatientID
JOIN Doctors as Doc on  Doc.DoctorID = A.DoctorID
JOIN Departments AS Dep on Dep.DepartmentID = Doc.DepartmentID
WHERE A.Status = 'Pending'
	and A.AppointmentDate BETWEEN CAST(GETDATE() AS DATE) AND CAST(DATEADD(DAY, 14, GETDATE()) AS DATE);
GO

SELECT * FROM v_Pending_Queue
GO

-- TRIGGER

-- APPOINTMENTS HAVE STATUS, FROM PENDING TO EITHER CANCELLED OR COMPLETED
-- WE REVERT CANCELLED BACK TO PENDING
-- REVERT COMPLETED TO ANYTHING ELSE

CREATE TRIGGER trg_Prevent_Status_Reversion ON Appointments
AFTER UPDATE
AS
BEGIN
	IF EXISTS (
		SELECT 1
		FROM deleted AS d
		JOIN inserted as i
		on d.AppointmentID = i.AppointmentID
		WHERE d.Status like 'Completed%' 
          AND i.Status NOT like 'Completed%' 
	)
	BEGIN
		PRINT 'Cannot overturn a completed appointment.';
		RAISERROR('Cannot overturn a completed appointment.', 16, 1);
		ROLLBACK TRANSACTION;
	END

END
GO

--
UPDATE Appointments
SET Appointments.Status = 'Cancelled'
where Appointments.PatientID = 15
and Appointments.DoctorID = 16

--