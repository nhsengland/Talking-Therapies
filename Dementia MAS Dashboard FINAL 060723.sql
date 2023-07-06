/****** Script for Memory Assessment Services Dashboard for calculating the following: 
		open referrals, open referrals with no contact, open referrals with a care plan, new referrals, discharges, 
		wait times from referral to first contact, and wait times from referral to diagnosis ******/

-----------------------------------------------------------------------------------------------------------------------------
----------------------Step 1---------------------------------------------------------------------------------------------------
--Before refreshing the new submissions of data for this financial year, delete the months in this financial year from last month's refresh
--and move to [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Old_Refresh] and [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Old_Refresh] tables. 
--These have been labelled 'R' for refresh in the column DataSubmissionType (they are the months in this current financial year)
--This first step is commented out to avoid being run by mistake, since it involves deletion
--Uncomment Step 1 and execute when refreshing months in financial year for superstats:

--DELETE [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
--OUTPUT 
--		DELETED.[Month]
--		,DELETED.[OrgCode]
--		,DELETED.[OrgName]
--		,DELETED.[Region]
--		,DELETED.[Orgtype]
--		,DELETED.[Teamtype]
--		,DELETED.[PrimReason]
--		,DELETED.[Category]
--		,DELETED.[Variable]
--		,DELETED.[Dementia Diagnosis Code]
--		,DELETED.[LatestDiagnosisArea]
--		,DELETED.[DementiaDiagnosis]
--		,DELETED.[NewReferrals]
--		,DELETED.[OpenReferrals]
--		,DELETED.[Discharges]
--		,DELETED.[OpenWaitingFirstCont]
--		,DELETED.[OpenRefwithCarePlanCreated]
--		,DELETED.[DataSubmissionType]
--		,DELETED.[SnapshotDate]
--INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Old_Refresh] ([Month]
--		,[OrgCode]
--		,[OrgName]
--		,[Region]
--		,[Orgtype]
--		,[Teamtype]
--		,[PrimReason]
--		,[Category]
--		,[Variable]
--		,[Dementia Diagnosis Code]
--		,[LatestDiagnosisArea]
--		,[DementiaDiagnosis]
--		,[NewReferrals]
--		,[OpenReferrals]
--		,[Discharges]
--		,[OpenWaitingFirstCont]
--		,[OpenRefwithCarePlanCreated]
--		,[DataSubmissionType]
--		,[SnapshotDate])
--where [DataSubmissionType]='R';

--DELETE [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Dashboard]
--OUTPUT 
--		DELETED.[Month]
--		,DELETED.[FirstContactDate]
--		,DELETED.[UniqServReqID]
--		,DELETED.[Der_Person_ID]
--		,DELETED.[OrgIDProv]
--		,DELETED.[Provider_Name]
--		,DELETED.[Prov_Region_Name]
--		,DELETED.[OrgIDComm]
--		,DELETED.[Sub_ICB_Name]
--		,DELETED.[ICB_Name]
--		,DELETED.[ICB_Code]
--		,DELETED.[Comm_Region_Name]
--		,DELETED.[ReferralRequestReceivedDate]
--		,DELETED.[ServDischDate]
--		,DELETED.[UniqMonthID]
--		,DELETED.[EthnicCategory]
--		,DELETED.[Gender]
--		,DELETED.[AgeServReferRecDate]
--		,DELETED.[ReportingPeriodStartDate]
--		,DELETED.[ReportingPeriodEndDate]
--		,DELETED.[ServTeamTypeRefToMH]
--		,DELETED.[TeamType]
--		,DELETED.[PrimReasonReferralMH]
--		,DELETED.[PrimReason]
--		,DELETED.[WaitRefContact]
--		,DELETED.[FirstContactDateMonthFlag]
--		,DELETED.[NewRef]
--		,DELETED.[DischRef]
--		,DELETED.[OpenRef]
--		,DELETED.[Refwaiting1stcontact]
--		,DELETED.[RefwithCarePlanCreated]
--		,DELETED.[EarliestDiagDate]
--		,DELETED.[EarliestDementiaDiagnosisCode]
--		,DELETED.[EarliestDiagnosisArea]
--		,DELETED.[WaitRefDiag]
--		,DELETED.[EarliestDiagDateMonthFlag]
--		,DELETED.[LatestDementiaDiagnosisCode]
--		,DELETED.[LatestDiagnosisArea]
--		,DELETED.[RefToEarliestDiagOrder]
--		,DELETED.[DementiaDiagnosis]
--		,DELETED.[ContactUnder6weeksNumber]
--		,DELETED.[Contact6to18weeksNumber]
--		,DELETED.[ContactOver18weeksNumber]
--		,DELETED.[TotalReferralsWithContact]
--		,DELETED.[DiagUnder6weeksNumber]
--		,DELETED.[Diag6to18weeksNumber]
--		,DELETED.[DiagOver18weeksNumber]
--		,DELETED.[TotalReferralsWithDiag]
--		,DELETED.[DataSubmissionType] 
--		,DELETED.[SnapshotDate]
--INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Old_Refresh] (
--		[Month]
--		,[FirstContactDate]
--		,[UniqServReqID]
--		,[Der_Person_ID]
--		,[OrgIDProv]
--		,[Provider_Name]
--		,[Prov_Region_Name]
--		,[OrgIDComm]
--		,[Sub_ICB_Name]
--		,[ICB_Name]
--		,[ICB_Code]
--		,[Comm_Region_Name]
--		,[ReferralRequestReceivedDate]
--		,[ServDischDate]
--		,[UniqMonthID]
--		,[EthnicCategory]
--		,[Gender]
--		,[AgeServReferRecDate]
--		,[ReportingPeriodStartDate]
--		,[ReportingPeriodEndDate]
--		,[ServTeamTypeRefToMH]
--		,[TeamType]
--		,[PrimReasonReferralMH]
--		,[PrimReason]
--		,[WaitRefContact]
--		,[FirstContactDateMonthFlag]
--		,[NewRef]
--		,[DischRef]
--		,[OpenRef]
--		,[Refwaiting1stcontact]
--		,[RefwithCarePlanCreated]
--		,[EarliestDiagDate]
--		,[EarliestDementiaDiagnosisCode]
--		,[EarliestDiagnosisArea]
--		,[WaitRefDiag]
--		,[EarliestDiagDateMonthFlag]
--		,[LatestDementiaDiagnosisCode]
--		,[LatestDiagnosisArea]
--		,[RefToEarliestDiagOrder]
--		,[DementiaDiagnosis]
--		,[ContactUnder6weeksNumber]
--		,[Contact6to18weeksNumber]
--		,[ContactOver18weeksNumber]
--		,[TotalReferralsWithContact]
--		,[DiagUnder6weeksNumber]
--		,[Diag6to18weeksNumber]
--		,[DiagOver18weeksNumber]
--		,[TotalReferralsWithDiag]
--		,[DataSubmissionType]
--		,[SnapshotDate])
--where [DataSubmissionType]='R';

-------------------------------------End of Step 1---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------Step 2------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
--Check the Offset, Period Start and Period End are set correctly for the Base Table
--Check the RefreshVsFinal is set to 'R' or 'F'correctly for the Wait Times Table
--Execute only step 2 of script (this is simply due to step 3 taking longer to run so it is easier to break up into steps)

-------------------------------------Diagnosis Table--------------------------------------------------------
-- Creates a table for anyone with a primary (i.e. the diagnosis listed first) or secondary (i.e. the diagnosis listed second) diagnosis of dementia as defined by the codes in the Dementia guidance
--This means that people with only a secondary diagnosis of dementia will be picked up, as well as those with a primary diagnosis
--All diagnosis dates are included in this table as we are interested in the earliest (for wait times to diagnosis) and latest diagnoses (for everything else). 
--The next table ([NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking]) ranks the diagnosis dates for use later in the script
 IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG]

SELECT DISTINCT 
	a.Der_Person_ID
	,a.UniqServReqID
	,a.CodedDiagTimestamp
	,CASE WHEN PrimDiag IS NOT NULL THEN a.PrimDiag
		ELSE SecDiag
		END AS [DiagnosisCode]
	,CASE WHEN PrimDiag IS NOT NULL THEN 'Primary'
		ELSE 'Secondary' 
		END AS Position
	,CASE WHEN PrimDiag IS NOT NULL THEN a.[Diagnosis Area] ELSE b.[Diagnosis Area]
	END AS [DiagnosisArea]
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG]
FROM
(
SELECT DISTINCT
	PrimDiag
	,Der_Person_ID
	,UniqServReqID
	,CodedDiagTimestamp
	,CASE WHEN PrimDiag IN ('F06.7','F067','386805003','28E0.','Xaagi') THEN 'MCI'
	ELSE 'Dementia' END AS 'Diagnosis Area'
FROM [NHSE_MHSDS].[dbo].[MHS604PrimDiag] p
WHERE
(p.[PrimDiag] IN

(--Dementia ICD10 codes Page 13 of Dementia Care Pathway Appendices
'F00.0','F00.1','F00.2','F00.9','F01.0','F01.1','F01.2','F01.3','F01.8','F01.9','F02.0','F02.1','F02.2','F02.3','F02.4','F02.8','F03','F05.1'
,'F000','F001','F002','F009','F010','F011','F012','F013','F018','F019','F020','F021','F022','F023','F024','F028','F051'

--This Dagger code is included as it is required in combination with F02.8 to identify Lewy body disease. 
--We are unable to filter MHSDS for those with both F02.8 AND G31.8 so have to filter for those with either F02.8 or G31.8
,'G318','G31.8'

--Dementia SNOMED codes Page 14 of Dementia Care Pathway Appendices
,'52448006','15662003','191449005','191457008','191461002','231438001','268612007','45864009','26929004','416780008','416975007','4169750 07','429998004','230285003'
,'56267009','230286002','230287006','230270009','230273006','90099008','230280008','86188000','13092008','21921000119103','429458009','442344002','792004'
,'713060000','425390006'
--Dementia SNOMED codes Page 15 of Dementia Care Pathway Appendices
,'713844000','191475009','80098002','312991009','135811000119107','13 5 8110 0 0119107','42769004','191519005','281004','191493005','111480006','1114 8 0 0 0 6'
,'32875003','59651006','278857002','230269008','79341000119107','12348006','421023003','713488003','191452002','65096006','31081000119101','191455000'
,'1089501000000102','10532003','191454001','230267005','230268000','230265002'
--Dementia SNOMED codes Page 16 of Dementia Care Pathway Appendices
,'230266001','191451009','1914510 09','22381000119105','230288001','191458003','191459006','191463004','191464005','191465006','191466007','279982005','6475002'
,'66108005'
	
--Dementia Read code v2 on Page 17 of Dementia Care Pathway Appendices
,'E00..%','E0 0..%','Eu01.%','Eu 01.%','Eu02.%','Eu 02.%','E012.%','Eu00.%','Eu 0 0.%','F110.%','A411.%','A 411.%','E02y1','E041.','E0 41.','Eu041','Eu 0 41'
,'F111.','F112.','F116.','F118.','F21y2','A410.','A 410.'
	
--Dementia CTV3 code on Page 17 of Dementia Care Pathway Appendices
--F110.%, Eu02.%,'E02y1' are in this list but are mentioned in the read code v2 list
,'XE1Xr%','X002w%','XE1Xs','Xa0sE'

--MCI codes
,'F06.7','F067' --ICD10 codes on Page 13 of Dementia Care Pathway Appendices
,'386805003' --SNOMED Code on Page 16 of Dementia Care Pathway Appendices
,'28E0.' --Read code v2 on Page 17 of Dementia Care Pathway Appendices
,'Xaagi' --CTV3 code on Page 17 of Dementia Care Pathway Appendices
)

OR p.PrimDiag LIKE 'F03%')
) AS a
LEFT JOIN  (
SELECT DISTINCT 
	SecDiag
	,Der_Person_ID
	,UniqServReqID --this column uniquely identifies the referral
	,CodedDiagTimestamp --The date, time and time zone for the PATIENT DIAGNOSIS.
	,CASE WHEN SecDiag IN ('F06.7','F067','386805003','28E0.','Xaagi') THEN 'MCI'
	ELSE 'Dementia' END AS 'Diagnosis Area'
FROM [NHSE_MHSDS].[dbo].[MHS605SecDiag] r
WHERE 
(r.[SecDiag] IN 

(--Dementia ICD10 codes Page 13 of Dementia Care Pathway Appendices
'F00.0','F00.1','F00.2','F00.9','F01.0','F01.1','F01.2','F01.3','F01.8','F01.9','F02.0','F02.1','F02.2','F02.3','F02.4','F02.8','F03','F05.1'
,'F000','F001','F002','F009','F010','F011','F012','F013','F018','F019','F020','F021','F022','F023','F024','F028','F051'

--This Dagger code is included as it is required in combination with F02.8 to identify Lewy body disease. 
--We are unable to filter MHSDS for those with both F02.8 AND G31.8 so have to filter for those with either F02.8 or G31.8
,'G318','G31.8'

--Dementia SNOMED codes Page 14 of Dementia Care Pathway Appendices
,'52448006','15662003','191449005','191457008','191461002','231438001','268612007','45864009','26929004','416780008','416975007','4169750 07','429998004','230285003'
,'56267009','230286002','230287006','230270009','230273006','90099008','230280008','86188000','13092008','21921000119103','429458009','442344002','792004'
,'713060000','425390006'
--Dementia SNOMED codes Page 15 of Dementia Care Pathway Appendices
,'713844000','191475009','80098002','312991009','135811000119107','13 5 8110 0 0119107','42769004','191519005','281004','191493005','111480006','1114 8 0 0 0 6'
,'32875003','59651006','278857002','230269008','79341000119107','12348006','421023003','713488003','191452002','65096006','31081000119101','191455000'
,'1089501000000102','10532003','191454001','230267005','230268000','230265002'
--Dementia SNOMED codes Page 16 of Dementia Care Pathway Appendices
,'230266001','191451009','1914510 09','22381000119105','230288001','191458003','191459006','191463004','191464005','191465006','191466007','279982005','6475002'
,'66108005'
	
--Dementia Read code v2 on Page 17 of Dementia Care Pathway Appendices
,'E00..%','E0 0..%','Eu01.%','Eu 01.%','Eu02.%','Eu 02.%','E012.%','Eu00.%','Eu 0 0.%','F110.%','A411.%','A 411.%','E02y1','E041.','E0 41.','Eu041','Eu 0 41'
,'F111.','F112.','F116.','F118.','F21y2','A410.','A 410.'
	
--Dementia CTV3 code on Page 17 of Dementia Care Pathway Appendices
--F110.%, Eu02.%,'E02y1' are in this list but are mentioned in the read code v2 list
,'XE1Xr%','X002w%','XE1Xs','Xa0sE'

--MCI codes
,'F06.7','F067' --ICD10 codes on Page 13 of Dementia Care Pathway Appendices
,'386805003' --SNOMED Code on Page 16 of Dementia Care Pathway Appendices
,'28E0.' --Read code v2 on Page 17 of Dementia Care Pathway Appendices
,'Xaagi' --CTV3 code on Page 17 of Dementia Care Pathway Appendices
)
OR r.[SecDiag] LIKE 'F03%')
) AS b
ON a.Der_Person_ID=b.Der_Person_ID AND a.UniqServReqID=b.UniqServReqID AND a.CodedDiagTimestamp=b.CodedDiagTimestamp
GO

-------------------------Ranking of Diagnosis Table------------------------------------------------
--Ranks diagnoses to give the earliest diagnosis (for wait to diagnosis) and latest diagnosis (For everything else) for use later in the script
 IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking]
SELECT
	*
	,ROW_NUMBER() OVER(PARTITION BY [UniqServReqID],[Der_Person_ID] ORDER BY [CodedDiagTimestamp] ASC, DiagnosisArea DESC) AS RowIDEarliest	--There are instances of more than one primary diagnosis with the same timestamp. In this case Dementia is used over MCI.
	,ROW_NUMBER() OVER(PARTITION BY [UniqServReqID],[Der_Person_ID] ORDER BY [CodedDiagTimestamp] DESC, DiagnosisArea ASC) AS RowIDLatest	--There are instances of more than one primary diagnosis with the same timestamp. In this case Dementia is used over MCI.
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking]
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG]
GO
-----------------------------------------Contact Table-----------------------------------
--This table gets the first contact date from the MHS201CareContact table for use in calculating wait times from referral to first contact
IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact]
SELECT
	UniqServReqID
	,Der_Person_ID as Person_ID
	,MIN(CareContDate) AS FirstContactDate
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact]
FROM [NHSE_MHSDS].[dbo].[MHS201CareContact] 

WHERE AttendOrDNACode IN ('5','6') AND ConsMechanismMH IN ('01', '02', '04', '11')
--Filtered for AttendOrDNACode of: "Attended on time or, if late, before the relevant care professional was ready to see the patient" 
--and "Arrived late, after the relevant care professional was ready to see the patient, but was seen"
--Filtered for consultation mechanism of: "Face to face", "Telephone", "Talk type for a person unable to speak", and "Video consultation"
GROUP BY UniqServReqID, Der_Person_ID
GO


USE [NHSE_MHSDS]

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 

------PLEASE UPDATE:
------For refreshing months each superstats this should be changed to the offset for the previous April (i.e. start of financial year)
DECLARE @Offset INT = 0
------For refreshing months each superstats this will always be -1 to get the latest refreshed month available
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [dbo].[MHSDS_SubmissionFlags])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [dbo].[MHSDS_SubmissionFlags])
SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd
-----------------------------------------Base Table----------------------------------------------------
--This table produces a record level table for the refresh period defined above, as a basis for the aggregated counts done below ([NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard])
IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]
SELECT DISTINCT
	CAST(DATENAME(m, sf.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, sf.ReportingPeriodStartDate) AS varchar)AS DATE) AS Month
	,c1.FirstContactDate
	,r.UniqServReqID
	,r.Der_Person_ID
	,r.OrgIDProv
	,o1.Organisation_Name as Provider_Name
	,o1.Region_Name as Prov_Region_Name
	,r.OrgIDComm
	,o2.Organisation_Name as Sub_ICB_Name
	,o2.STP_Name as ICB_Name
	,o2.STP_Code as ICB_Code
	,o2.Region_Name as Comm_Region_Name
	,r.ReferralRequestReceivedDate
	,r.ServDischDate
	,r.UniqMonthID
	,m.EthnicCategory
	,m.Gender
	,r.AgeServReferRecDate AS AgeServReferRecDate
	,sf.ReportingPeriodStartDate
	,sf.ReportingPeriodEndDate
	,s.ServTeamTypeRefToMH	--team code
	,ISNULL(r1.Main_Description,'Missing/invalid') AS TeamType --Team name (e.g. Memory services/clinic)
	,r.PrimReasonReferralMH --primary reason for referral code
	,ISNULL(r2.Main_Description, 'Missing/invalid') AS PrimReason --primary reason for referral name (e.g. organic brain disorder)
	,CASE WHEN (c1.FirstContactDate IS NOT NULL AND c1.FirstContactDate >=ReferralRequestReceivedDate and c1.FirstContactDate<=sf.ReportingPeriodEndDate)
		THEN DATEDIFF(DD,ReferralRequestReceivedDate,c1.FirstContactDate) 
		ELSE NULL END 
		AS WaitRefContact	
	--Works out the difference between referral date and first contact date in days to calculate the wait time from referral to first contact. This is just for those with a contact date
	--and the first contact has to be after the referral date
	,CASE WHEN c1.FirstContactDate BETWEEN sf.ReportingPeriodStartDate and sf.ReportingPeriodEndDate THEN 1 
		ELSE 0 END 
		AS FirstContactDateMonthFlag
	--Creates a flag for use in tableau for wait time graph which only shows wait times for first contacts within the reporting period in question, rather than for all open referrals.
	,CASE WHEN r.ReferralRequestReceivedDate BETWEEN sf.ReportingPeriodStartDate AND sf.ReportingPeriodEndDate THEN 1 
		ELSE 0 END 
		AS NewRef	--New referrals are defined by the referral request date being between the start and end date of the period in question
	,CASE WHEN r.ServDischDate BETWEEN sf.ReportingPeriodStartDate AND sf.ReportingPeriodEndDate THEN 1 
		ELSE 0 END 
		AS DischRef	--Discharges are defined by the discharge date being between the start and end date of the period in question
	,CASE WHEN r.ServDischDate IS NULL OR r.ServDischDate > sf.ReportingPeriodEndDate THEN 1 
		ELSE 0 END 
		AS OpenRef
	--Open referrals are defined by the service discharge being null or being after the period end i.e. haven't been discharged before or during the period in question
	,CASE WHEN (r.ServDischDate IS NULL OR r.ServDischDate > sf.ReportingPeriodEndDate) AND (c1.FirstContactDate IS NULL OR c1.FirstContactDate > sf.ReportingPeriodEndDate) 
		THEN 1 
		ELSE 0 END 
		AS Refwaiting1stcontact
	--Open referrals waiting for contact are defined by an open referral (as defined above) and also having a null first contact date
	--or the first contact date is after the end of the period in question
	,CASE WHEN (r.ServDischDate IS NULL OR r.ServDischDate > sf.ReportingPeriodEndDate) AND (c.CarePlanCreatDate <= sf.ReportingPeriodEndDate) 
		THEN 1 ELSE 0 END 
		AS RefwithCarePlanCreated
	--Open referrals with a care plan are defined by an open referral (as defined above) and the care plan creation date being before the end of the period in question
	,e.CodedDiagTimestamp as EarliestDiagDate
	,e.[DiagnosisCode] as EarliestDementiaDiagnosisCode 
	,e.[DiagnosisArea] as EarliestDiagnosisArea
	,CASE WHEN (e.CodedDiagTimestamp IS NOT NULL AND e.CodedDiagTimestamp >=ReferralRequestReceivedDate AND e.CodedDiagTimestamp<=sf.ReportingPeriodEndDate)
		THEN DATEDIFF(DD,ReferralRequestReceivedDate,e.CodedDiagTimestamp) 
		ELSE NULL END 
		AS WaitRefDiag 
		--Works out the difference between referral date and earliest diagnosis date to calculate wait time from referral to earliest diagnosis. This is just for those with a diagnosis date,
		--the diagnosis date has to be after referral date, and the diagnosis date has to be before the reporting period end date
	,CASE WHEN e.CodedDiagTimestamp between sf.ReportingPeriodStartDate and sf.ReportingPeriodEndDate THEN 1 
		ELSE 0 END 
		AS EarliestDiagDateMonthFlag
	--Creates a flag for use in tableau for wait time graph which only shows wait times for diagnoses within the reporting period in question, rather than for all open referrals.
	,l.[DiagnosisCode] as LatestDementiaDiagnosisCode
	,l.[DiagnosisArea] as LatestDiagnosisArea
	--Latest diagnosis area is used to define the diagnosis area for all charts/tables except for the wait times to diagnosis (uses earliest diagnosis area to go with earliest diagnosis date)
	--This is to give the most up to date diagnosis area
	,CASE WHEN e.CodedDiagTimestamp >= ReferralRequestReceivedDate THEN 'Diagnosis After Referral' 
		WHEN e.CodedDiagTimestamp<ReferralRequestReceivedDate THEN 'Diagnosis Before Referral' 
		ELSE 'No Diagnosis' END 
		AS RefToEarliestDiagOrder
	--Defines if diagnosis is given before or after referral or if there is no diagnosis.
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]
FROM [NHSE_MHSDS].[dbo].[MHS101Referral] r 
		INNER JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] m ON r.RecordNumber = m.RecordNumber
		LEFT JOIN [NHSE_MHSDS].[dbo].[MHS008CarePlanType] c ON r.RecordNumber = c.RecordNumber
		LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] s on r.UniqServReqID = s.UniqServReqID AND r.RecordNumber = s.RecordNumber  
		LEFT JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] sf ON r.NHSEUniqSubmissionID = sf.NHSEUniqSubmissionID AND sf.Der_IsLatest = 'Y'
------------------------------------------------------------------------------------------------------------------		
		--For April 2020 to March 2021 r.Der_Person_ID has to be joined on because it is different to Person_ID before April 2021:
		--LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact] c1 on c1.Person_ID=r.Der_Person_ID and c1.UniqServReqID=r.UniqServReqID
		--For April 2021 onwards r.Person_ID can be joined on as it is the same as Der_Person_ID:
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact] c1 on c1.Person_ID=r.Person_ID and c1.UniqServReqID=r.UniqServReqID
----------------------------------------------------------------------------------------------------------------------------------------

		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth r1 ON s.ServTeamTypeRefToMH = r1.Main_Code_Text AND r1.Is_Latest = 1 
		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_DataDic_ZZZ_ReasonForReferralToMentalHealth r2 ON r.PrimReasonReferralMH = r2.Main_Code_Text AND r2.Is_Latest = 1 
		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_ODS_Provider_Hierarchies o1 ON r.[OrgIDProv] = o1.Organisation_Code
------------------------------------------------------------------------------------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[CCG_2020_Lookup] cc ON r.OrgIDComm = cc.IC_CCG
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] o2 ON cc.CCG21=o2.Organisation_Code
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking] e ON s.UniqServReqID = e.UniqServReqID AND s.Der_Person_ID = e.Der_Person_ID and e.RowIDEarliest=1
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking] l ON s.UniqServReqID = l.UniqServReqID AND s.Der_Person_ID = l.Der_Person_ID and l.RowIDLatest=1
WHERE 
sf.ReportingPeriodStartDate IS NOT NULL and sf.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, @Offset, @PeriodStart) AND @PeriodStart
GO


--------------------------------------------------------Wait Times Table---------------------------------------------------------
----Table used in tableau to produce boxplots of wait times and the graphs for the proportions of wait times:
-----------------------------PLEASE CHECK IF THIS SHOULD BE SET TO REFRESH OR FINAL---------------------------------------------------------------
----For Refresh months (i.e. within financial year set to 'R' for Refresh)
----For months with final data set to 'F' for Final
DECLARE @RefreshVsFinal varchar='R'
--IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Dashboard]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Dashboard]
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Dashboard]
SELECT 
	*
	--For use in tableau to filter the waits reference to diagnosis box plots for just those with a diagnosis
	,CAST(CASE WHEN EarliestDementiaDiagnosisCode IS NOT NULL THEN 1 ELSE 0 END AS varchar) AS DementiaDiagnosis
	--Groups waits into the categories of less than 6 weeks (<=42 days), between 6 and 18 weeks (43 to 126 days) and over 18 weeks (>126 days) for both first contact and diagnosis waits
	--Diagnosis waits use the earliest diagnosis date
    ,CASE WHEN [WaitRefContact]<=42 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS ContactUnder6weeksNumber
	,CASE WHEN [WaitRefContact]>42 AND [WaitRefContact]<=126 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS Contact6to18weeksNumber
	,CASE WHEN [WaitRefContact]>126 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS ContactOver18weeksNumber
	,CASE WHEN [WaitRefContact] IS NOT NULL and [UniqServReqID] is not null THEN 1 ELSE 0 END AS TotalReferralsWithContact

	,CASE WHEN [WaitRefDiag]<=42 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS DiagUnder6weeksNumber
	,CASE WHEN [WaitRefDiag]>42 AND [WaitRefDiag]<=126 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS Diag6to18weeksNumber
	,CASE WHEN [WaitRefDiag]>126 and [UniqServReqID] is not null THEN 1 ELSE 0 END AS DiagOver18weeksNumber
    ,CASE WHEN [WaitRefDiag] IS NOT NULL and [UniqServReqID] is not null THEN 1 ELSE 0 END AS TotalReferralsWithDiag
	,@RefreshVsFinal AS [DataSubmissionType]
	,GETDATE() AS SnapshotDate
--INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Wait_Times_Dashboard]
	FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]
	WHERE [Teamtype]='Memory services/clinic' AND [PrimReason]='Organic brain disorder'
	GO

---------------------------------------------End of Step 2----------------------------------------------------
--------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
---------------------------------------------Step 3-----------------------------------------------------------
--Check RefreshVSFinal is set to 'R' or 'F' correctly
--Execute step 3 (this can take hours for 1 year of base data)

----PLEASE CHECK IF THIS SHOULD BE SET TO REFRESH OR FINAL
----For Refresh months (i.e. within financial year set to 'R' for Refresh)
----For months with final data set to 'F' for Final
DECLARE @RefreshVsFinal varchar='R'
----------------------------------------------------------------Main Metrics Table----------------------------------------------------------------------------------------------------
----This table aggregates the main metrics (open referrals, open referrals waiting 1st contact, open referrals with care plan, new referrals, discharges) 
----at different geography levels (Provider, Sub-ICB, ICB, National) for different categories (total, age, gender, ethnicity) and for those with and without a diagnosis of Dementia/MCI

----------------------------------------------------------------------------Provider---------------------------------------------------------------------------------
--Total
--IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
	SELECT 
		Month
		,OrgIDProv AS OrgCode
		,Provider_Name AS OrgName
		,Prov_Region_Name AS Region 
		,'Provider' AS Orgtype
		,Teamtype
		,PrimReason
		,cast('Total' as varchar(50)) AS 'Category'
		,cast('Total' as varchar(50)) AS 'Variable'
		,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
		,LatestDiagnosisArea
		--the latest diagnosis area is used to provide the most up to date data
		,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
		--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
		,SUM(NewRef) AS NewReferrals
		,SUM(OpenRef) AS OpenReferrals
		,SUM(DischRef) AS Discharges
		,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
		,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
		,@RefreshVsFinal AS DataSubmissionType
		,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
	--INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base] 		
GROUP BY 
	Month
	,OrgIDProv
	,Provider_Name
	,Prov_Region_Name
	,Teamtype
	,PrimReason
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN LatestDementiaDiagnosisCode IS NOT NULL THEN 1 ELSE 0 END
	-------------------------------------
--Age Group

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT
	Month
	,OrgIDProv AS OrgCode
	,Provider_Name AS OrgName
	,Prov_Region_Name AS Region
	,'Provider' AS Orgtype
	,Teamtype
	,PrimReason
	,'Age Group' AS 'Category'
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base] 			
GROUP BY 
	Month
	,OrgIDProv
	,Provider_Name
	,Prov_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
	

--Gender
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,OrgIDProv AS OrgCode
	,Provider_Name AS OrgName
	,Prov_Region_Name AS Region
	,'Provider' AS Orgtype 
	,[Teamtype]
	,PrimReason
	,'Gender' AS 'Category'
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base] 		
GROUP BY 
	Month
	,OrgIDProv
	,Provider_Name
	,Prov_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
	

--Ethnicity
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,OrgIDProv AS OrgCode
	,Provider_Name AS OrgName
	,Prov_Region_Name AS Region
	,'Provider' AS Orgtype
	,Teamtype
	,PrimReason
	,'Ethnicity' AS 'Category'
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base] 	
GROUP BY 
	Month
	,OrgIDProv
	,[Provider_Name]
	,Prov_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' END
	,[LatestDementiaDiagnosisCode]
	,[LatestDiagnosisArea]
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END 
	

------------------------------------------------------Sub-ICB------------------------------------------------------
--Total
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month 
	,OrgIDComm AS OrgCode
	,Sub_ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'Sub-ICB' AS Orgtype
	,[Teamtype]
	,PrimReason
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  				
GROUP BY 
	Month
	,OrgIDComm
	,[Sub_ICB_Name]
	,[Comm_Region_Name]
	,Teamtype
	,PrimReason
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
	
--Age Group
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,OrgIDComm AS OrgCode
	,[Sub_ICB_Name] AS OrgName
	,[Comm_Region_Name] AS Region
	,'Sub-ICB' AS Orgtype
	,[Teamtype] 
	,PrimReason
	,'Age Group' AS 'Category'
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  					
GROUP BY 
	Month
	,OrgIDComm
	,[Sub_ICB_Name]
	,[Comm_Region_Name]
	,Teamtype
	,PrimReason
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

-- Gender
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,OrgIDComm AS OrgCode
	,Sub_ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'Sub-ICB' AS Orgtype 
	,Teamtype 
	,PrimReason
	,'Gender' AS 'Category'
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  				
GROUP BY 
	Month
	,OrgIDComm
	,Sub_ICB_Name
	,Comm_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Ethnicity
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,OrgIDComm AS OrgCode
	,Sub_ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'Sub-ICB' AS Orgtype
	,Teamtype
	,PrimReason
	,'Ethnicity' AS 'Category'
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  				
GROUP BY 
	Month
	,OrgIDComm
	,Sub_ICB_Name
	,Comm_Region_Name
	,Teamtype 
	,PrimReason
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
	
--------------------------------------------------------------------National-----------------------------------------------------------------------------------
--Total
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,'England' AS OrgCode
	,'England' AS OrgName
	,'All Regions' AS Region
	,'National' AS Orgtype
	,Teamtype
	,PrimReason
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  
GROUP BY 
	Month
	,Teamtype
	,PrimReason
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
		
--Age Group
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT
	Month 
	,'England' AS OrgCode
	,'England' AS OrgName
	,'All Regions' AS Region
	,'National' AS Orgtype
	,Teamtype
	,PrimReason
	,'Age Group' AS 'Category'
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  
GROUP BY 
	Month
	,Teamtype
	,PrimReason
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Gender
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month 
	,'England' AS OrgCode
	,'England' AS OrgName
	,'All Regions' AS Region
	,'National' AS Orgtype
	,Teamtype 
	,PrimReason
	,'Gender' AS 'Category'
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  
GROUP BY
	Month
	,Teamtype
	,PrimReason
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Ethnicity
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,'England' AS OrgCode
	,'England' AS OrgName
	,'All Regions' AS Region
	,'National' AS Orgtype
	,Teamtype 
	,PrimReason
	,'Ethnicity' AS 'Category'
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  
GROUP BY 
	Month
	,Teamtype
	,PrimReason
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
--------------------------------------------------------------------------ICB-------------------------------------------------------------
--Total
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month 
	,ICB_Code AS OrgCode
	,ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'ICB' AS Orgtype
	,Teamtype
	,PrimReason
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  			
GROUP BY 
	Month
	,ICB_Code
	,ICB_Name
	,Comm_Region_Name
	,Teamtype
	,PrimReason
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Age Group
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,ICB_Code AS OrgCode
	,ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'ICB' AS Orgtype
	,Teamtype 
	,PrimReason
	,'Age Group' AS 'Category'
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  				
GROUP BY 
	Month
	,ICB_Code
	,ICB_Name
	,Comm_Region_Name
	,Teamtype 
	,PrimReason
	,CASE WHEN AgeServReferRecDate < 65 THEN 'Under65'
		WHEN AgeServReferRecDate BETWEEN 65 AND 74 THEN '65to74'
		WHEN AgeServReferRecDate BETWEEN 75 AND 84 THEN '75to84'
		WHEN AgeServReferRecDate >= 85 THEN '85+' 
		ELSE 'Unknown/Not Stated' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Gender 
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT 
	Month
	,ICB_Code AS OrgCode
	,ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'ICB' AS Orgtype 
	,Teamtype
	,PrimReason
	,'Gender' AS 'Category'
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  				
GROUP BY 
	Month
	,ICB_Code
	,ICB_Name
	,Comm_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN Gender = '1' THEN 'Males'
		WHEN Gender = '2' THEN 'Females'
		ELSE 'Other/Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END

--Ethnicity
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[DEM_MAS_Main_Metrics_Dashboard]
SELECT
	Month 
	,ICB_Code AS OrgCode
	,ICB_Name AS OrgName
	,Comm_Region_Name AS Region
	,'ICB' AS Orgtype
	,Teamtype
	,PrimReason
	,'Ethnicity' AS 'Category'
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' 
	END AS 'Variable'
	,LatestDementiaDiagnosisCode AS [Dementia Diagnosis Code]
	,LatestDiagnosisArea
	--the latest diagnosis area is used to provide the most up to date data
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END AS DementiaDiagnosis 
	--defines if diagnosed or not (the latest diagnosis code is used to provide the most up to date data)
	,SUM(NewRef) AS NewReferrals
	,SUM(OpenRef) AS OpenReferrals
	,SUM(DischRef) AS Discharges
	,SUM(Refwaiting1stcontact) AS OpenWaitingFirstCont
	,SUM(RefwithCarePlanCreated) AS OpenRefwithCarePlanCreated
	,@RefreshVsFinal AS DataSubmissionType
	,GETDATE() AS SnapshotDate --getdate tells us the date the query was run - so we can keep track of it	
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]  					
GROUP BY 
	Month
	,ICB_Code
	,ICB_Name
	,Comm_Region_Name
	,Teamtype
	,PrimReason
	,CASE WHEN EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN EthnicCategory IN ('H','J','K','L') THEN 'Asian'
		WHEN EthnicCategory IN ('M','N','P') THEN 'Black'
		WHEN EthnicCategory IN ('R','S') THEN 'Other'
		ELSE 'Not Stated/Not Known' END
	,LatestDementiaDiagnosisCode
	,LatestDiagnosisArea
	,CASE WHEN [LatestDementiaDiagnosisCode] IS NOT NULL THEN 1 ELSE 0 END
-------------------------------------------------End of Step 3----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Step 4------------------------------------------------------------------------------------

--Drops temporary tables used in the query
--DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG]
--DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_DIAG_Ranking]
--DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Contact]
--DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_DEM_MAS_Base]



---------------------------------------------End of Step 4--------------------------------------------------------------------------
---------------------------------------------------------End of Script--------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------


