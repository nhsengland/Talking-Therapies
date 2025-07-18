--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Employment Support Dashboard to produce tables for Employment Support Outcomes, National Recording of Employment Status and Sickness Absence,and Clinical Outcomes******/

-- DELETE MAX(Month) -----------------------------------------------------------------------
--Delete the latest month from the following two tables so that the refreshed version of that month can be added.
--Only two tables in this script require this as the rest run the full time period from September 2020 each month.

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes])

---Employment Support Appointment Count
--There is currently an issue with EmploymentSupport_Count field in IDS101referral table so we are calculating the number of employment support appointments in this table
--This is based on the criteria specified for this field in the Technical Output Specification
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
SELECT  
    r.PathwayID
	,COUNT(DISTINCT CASE WHEN c.CareContDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate THEN c.CareContactID ELSE NULL END) AS Count_EmpSupp
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
FROM [mesh_IAPT].IDS101referral r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
LEFT JOIN [mesh_IAPT].[IDS201carecontact] c ON c.RecordNumber=r.RecordNumber AND r.[UniqueSubmissionID] = c.[UniqueSubmissionID] AND r.[AuditId] = c.[AuditId]
LEFT JOIN [mesh_IAPT].[IDS202careactivity] ca on c.PathwayID = ca.PathwayID and c.RecordNumber=ca.RecordNumber and c.CareContactID=ca.CareContactID and c.AuditId=ca.AuditId 
LEFT JOIN [mesh_IAPT].[IDS004empstatus] e ON r.RecordNumber=e.RecordNumber AND r.AuditId=e.AuditId

WHERE l.IsLatest = 1 
AND (c.AttendOrDNACode IN (5,6) OR c.PlannedCareContIndicator='N') 
AND 
(
	(c.AppType<>06 AND r.ReferralRequestReceivedDate<= c.CareContDate 
	AND (c.CareContDate<=r.ServDischDate OR (r.ServDischDate IS NULL AND c.CareContDate<=l.ReportingPeriodEndDate))
	AND ca.CodeProcAndProcStatus='1098051000000103'
	)
OR
	(c.AppType=06 AND c.CareContDate>r.ServDischDate
	AND ca.CodeProcAndProcStatus='1098051000000103'
	)
OR
	((c.AppType=10 OR (ca.CodeProcAndProcStatus='1098051000000103' AND c.AppType=06)) AND 
	r.ReferralRequestReceivedDate<=c.CareContDate 
	AND (c.CareContDate<=e.EmpSupportDischargeDate OR (e.EmpSupportDischargeDate IS NULL AND c.CareContDate<=l.ReportingPeriodEndDate))
	)
)
GROUP BY r.PathwayID
GO

-----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------Employment Support Outcomes----------------------------------------------------------------------
-- Compares the employment status, self-employment indicator, sickness absence indicator, statutory sick pay indicator,
--benefit indicator, employment and support allowance indicator, universal credit indicator, and personal independence payment indicator 
--at the earliest employment status record date to the latest employment status record date

--Employment Support Outcomes Base Table
--This table produces a record level table for the refresh period defined below, as a basis for the output table produced further below ([MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp])

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be 0 to get the latest month
SET @PeriodStart = (SELECT DATEADD(MONTH,0,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,0,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

DECLARE @PeriodStart2 DATE
SET @PeriodStart2='2020-09-01' --this should always be September 2020

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base]
SELECT * 
,CASE WHEN EmployStatusRecDate IS NOT NULL THEN ROW_NUMBER() OVER(PARTITION BY Person_ID, PathwayID, RecordNumber
		ORDER BY [EmployStatusRecDate] asc) ELSE 0 END AS 'EmpFirstRecord' --ranks employment status record dates to get the first employment status record as 1 for filtering later
		,CASE WHEN EmployStatusRecDate IS NOT NULL THEN ROW_NUMBER() OVER(PARTITION BY Person_ID, PathwayID, RecordNumber
		ORDER BY [EmployStatusRecDate] desc) ELSE 0 END AS 'EmpLastRecord'--ranks employment status record dates to get the last employment status record as 1 for filtering later
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Base]	
FROM(
SELECT DISTINCT
DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) as Month
		,r.Person_ID
		,r.PathwayID
		,emp.RecordNumber
		,emp.[UniqueID_IDS004]
		,emp.[EmployStatusRecDate]
		,CASE WHEN emp.[EmployStatus]='01' THEN 'Employed'
		WHEN emp.[EmployStatus]='02' THEN 'Unemployed and actively seeking work'
		WHEN emp.[EmployStatus]='03' THEN 'Undertaking full (at least 16 hours per week) or part-time (less than 16 hours per week) education or training as a student and not working or actively seeking work'
		WHEN emp.[EmployStatus]='04' THEN 'Long-term sick or disabled, those receiving government sickness and disability benefits'
		WHEN emp.[EmployStatus]='05' THEN 'Looking after the family or home as a homemaker and not working or actively seeking work'
		WHEN emp.[EmployStatus]='06' THEN 'Not receiving government sickness and disability benefits and not working or actively seeking work'
		WHEN emp.[EmployStatus]='07' THEN 'Unpaid voluntary work and not working or actively seeking work'
		WHEN emp.[EmployStatus]='08' THEN 'Retired'
		WHEN emp.[EmployStatus]='ZZ' THEN 'Not Stated (Person asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'EmployStatus'	--Employment status
		,CASE WHEN emp.[WeekHoursWorked]='01' THEN '30+ hours'
		WHEN emp.[WeekHoursWorked]='02' THEN '16-29 hours'
		WHEN emp.[WeekHoursWorked]='03' THEN '5-15 hours'
		WHEN emp.[WeekHoursWorked]='04' THEN '1-4 hours'
		WHEN emp.[WeekHoursWorked]='97' THEN 'Not Stated (Person asked but declined to provide a response)'
		WHEN emp.[WeekHoursWorked]='98' THEN 'Not applicable (Person not employed)'
		WHEN emp.[WeekHoursWorked]='99' THEN 'Number of hours worked not known'
		ELSE 'Unspecified'
		END as 'WeekHoursWorked'	--Hours worked per week
		,CASE WHEN emp.[SelfEmployInd]='Y' THEN 'Yes - Employed as a self-employed worker'
		WHEN emp.[SelfEmployInd]='N' THEN 'No - Not self employed'
		WHEN emp.[SelfEmployInd]='8' THEN 'Not Applicable (Person is unemployed)'
		WHEN emp.[SelfEmployInd]='Z' THEN 'Not Stated (Person asked but declined to provide a response)'
		WHEN emp.[SelfEmployInd]='X' THEN 'Not Known (Not Recorded)'
		ELSE 'Unspecified'
		END	as 'SelfEmployInd'	--Self-Employment Indicator
		, CASE WHEN emp.[SickAbsenceInd]='Y' THEN 'Yes - a person in employment is currently unable to work due to sickness'
		WHEN emp.[SickAbsenceInd]='N' THEN 'No - a person in employment is not currently unable to work due to sickness'
		WHEN emp.[SickAbsenceInd]='8' THEN 'Not Applicable (Person is unemployed)'
		WHEN emp.[SickAbsenceInd]='Z' THEN 'Not Stated (Person asked but declined to provide a response)'
		WHEN emp.[SickAbsenceInd]='X' THEN 'Not Known (Not Recorded)'
		ELSE 'Unspecified'
		END as 'SickAbsenceInd'	--Sickness Absence Indicator
		,CASE WHEN emp.[SSPInd]='Y' THEN 'Yes - the person is currently in receipt of Statutory Sick Pay'
		WHEN emp.[SSPInd]='N' THEN 'No - the person is currently not in receipt of Statutory Sick Pay'
		WHEN emp.[SSPInd]='U' THEN 'Unknown (Person asked and does not know or is not sure)'
		WHEN emp.[SickAbsenceInd]='Z' THEN 'Not stated (Person asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'SSPInd'	--Statutory Sick Pay Indicator
		,CASE WHEN emp.[BenefitRecInd]='Y' THEN 'Yes - the patient is currently in receipt of a benefit'
		WHEN emp.[BenefitRecInd]='N' THEN 'No - the patient is not currently in receipt of a benefit'
		WHEN emp.[BenefitRecInd]='U' THEN 'Unknown (Patient asked and does not know or is not sure)'
		WHEN emp.[BenefitRecInd]='Z' THEN 'Not stated (Patient asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'BenefitRecInd'	--Benefit Indicator
		,CASE WHEN emp.[ESAInd]='Y' THEN 'Yes - receiving Employment and Support Allowance'
		WHEN emp.[ESAInd]='N' THEN 'No - not receiving Employment and Support Allowance'
		WHEN emp.[ESAInd]='U' THEN 'Unknown (Patient asked and does not know or is not sure)'
		WHEN emp.[ESAInd]='Z' THEN 'Not stated (Patient asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'ESAInd'	--Employment and Support Allowance Indicator
		,CASE WHEN emp.[UCInd]='Y' THEN 'Yes - receiving Universal Credit'
		WHEN emp.[UCInd]='N' THEN 'No - not receiving Universal Credit'
		WHEN emp.[UCInd]='U' THEN 'Unknown (Patient asked and does not know or is not sure)'
		WHEN emp.[UCInd]='Z' THEN 'Not stated (Patient asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'UCInd'	--Universal Credit Indicator
		,CASE WHEN emp.[PIPInd]='Y' THEN 'Yes - receiving Personal Independence Payment'
		WHEN emp.[PIPInd]='N' THEN 'No - not receiving Personal Independence Payment'
		WHEN emp.[PIPInd]='U' THEN 'Unknown (Patient asked and does not know or is not sure)'
		WHEN emp.[PIPInd]='Z' THEN 'Not stated (Patient asked but declined to provide a response)'
		ELSE 'Unspecified'
		END as 'PIPInd'	--Personal Independence Payment Indicator
		,CASE WHEN emp.[EmpSupportInd] ='Y' THEN 'Yes - the patient is a suitable candidate for referral to Employment Support'
		WHEN emp.[EmpSupportInd] ='N' THEN 'No - the patient is not a suitable candidate for referral to Employment Support'
		WHEN emp.[EmpSupportInd] ='NA' THEN 'Not Applicable'
		ELSE 'Unspecified'
		END as 'EmpSupportInd'	--Employment Support Indicator

		,CASE WHEN (emp.[BenefitRecInd]='Y' OR emp.[ESAInd]='Y' OR emp.[PIPInd]='Y' OR emp.[UCInd]='Y') THEN 'Benefit Received'
		WHEN (emp.[BenefitRecInd]='N' OR emp.[ESAInd]='N' OR emp.[PIPInd]='N' OR emp.[UCInd]='N') THEN 'No Benefit Received'
		ELSE 'Unknown/Not Stated If Benefit Received'
		END AS 'GeneralBenefitReceived'

	  --Protected characteristics
----------------Gender
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Unspecified' 
		END AS 'GenderDesc'
-----------------Ethnicity
		,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
				WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
				WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
				WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
				WHEN mpi.Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
				WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Unspecified' 
		END AS 'EthnicityDesc'
-----------------Gender Identity
		,CASE WHEN mpi.GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			  WHEN mpi.GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			  WHEN mpi.GenderIdentity IN ('3','03') THEN 'Non-binary'
			  WHEN mpi.GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			  WHEN mpi.GenderIdentity IN ('x','X') THEN 'Not Known'
			  WHEN mpi.GenderIdentity IN ('z','Z') THEN 'Not Stated'
			  WHEN mpi.GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
		END AS 'GenderIdentityDesc'
-------------------IMD (indices of multiple deprivation)
		,IMD.[IMD_Decile]
---------------------Age
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
		WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unspecified'
		END AS 'AgeGroups'
---------------------Problem Descriptor
		,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR [PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR [PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
			WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR [PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR [PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR [PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
			ELSE 'Other' 
		END AS 'ProblemDescriptor'

		--Geography
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICBName'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
		,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS 'RegionNameProv'
		,CASE WHEN ph.[Region_Code] IS NOT NULL THEN ph.[Region_Code] ELSE 'Other' END AS 'RegionCodeProv'

		,CASE WHEN ec.Count_EmpSupp IS NOT NULL THEN ec.Count_EmpSupp ELSE 0 END AS Count_EmpSupp
		,CASE WHEN emp.EmpSupportDischargeDate IS NOT NULL THEN 1 ELSE 0 END
		AS EmpSupportDischargeDatePresent

FROM [mesh_IAPT].[IDS101referral] r
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		--Provides data for gender, validated ethnic category and gender identity
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--Allows filtering for the latest data
		LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.recordnumber = emp.recordnumber AND emp.AuditId = l.AuditId
		--Provides data for employment status and other indicators		
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] and IMD.Effective_Snapshot_Date='2019-12-31'
		--Provides data for IMD

		LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount] ec ON ec.PathwayID=r.PathwayID

		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE r.UsePathway_Flag = 'True' 
		AND l.IsLatest = 1	--To get the latest data
		AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
		AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodStart
		and emp.RecordNumber is not null
)_
GO
------Output Table for Employment Support Outcomes
--This table is used in the dashboard and has the status or indicator for employment outcomes at the first and last employment status record dates for comparison
--This table is re-run each month as the full time period needs to be used for the rankings to work correctly
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp]
SELECT DISTINCT
		emp1.Month
		,emp1.Person_ID
		,emp1.PathwayID
		,emp1.RecordNumber
		,emp1.[GenderDesc]
		,emp1.[EthnicityDesc]
		,emp1.[GenderIdentityDesc]
		,emp1.[IMD_Decile]
		,emp1.[AgeGroups]
		,emp1.[ProblemDescriptor]
		,emp1.[Sub-ICBName]
		,emp1.[Sub-ICBCode]
		,emp1.[ICBName]
		,emp1.[ICBCode]
		,emp1.RegionNameComm
		,emp1.RegionCodeComm
		,emp1.[ProviderName]
		,emp1.ProviderCode
		,emp1.RegionNameProv
		,emp1.RegionCodeProv
		,emp1.Count_EmpSupp AS EmploymentSupport_Count	--number of employment support appointments
		--Status/Indicator at First employment status record date:
		,emp1.[EmployStatus] AS EmployStatusFirst
		,emp1.[EmployStatusRecDate] AS EmployStatusRecDateFirst
		,emp1.[WeekHoursWorked] AS WeekHoursWorkedFirst
		,emp1.[SelfEmployInd] AS SelfEmployIndFirst
		,emp1.[SickAbsenceInd] AS SickAbsenceIndFirst
		,emp1.[SSPInd] AS SSPIndFirst
		,emp1.[BenefitRecInd] AS BenefitRecIndFirst
		,emp1.[ESAInd] AS ESAIndFirst
		,emp1.[UCInd] AS UCIndFirst
		,emp1.[PIPInd] AS PIPIndFirst
		,emp1.[EmpSupportInd] AS EmpSupportIndFirst
		--Status/Indicator at Last employment status record date:
		,emp2.[EmployStatus] AS EmployStatusLast
		,emp2.[EmployStatusRecDate] AS EmployStatusRecDateLast
		,emp2.[WeekHoursWorked] AS WeekHoursWorkedLast
		,emp2.[SelfEmployInd] AS SelfEmployIndLast
		,emp2.[SickAbsenceInd] AS SickAbsenceIndLast
		,emp2.[SSPInd] AS SSPIndLast
		,emp2.[BenefitRecInd] AS BenefitRecIndLast
		,emp2.[ESAInd] AS ESAIndLast
		,emp2.[UCInd] AS UCIndLast
		,emp2.[PIPInd] AS PIPIndLast
		,emp2.[EmpSupportInd] AS EmpSupportIndLast
		--Flags for when the status or indicator at the first date is the same as the status or indicator at the last date (used as a filter in tableau):
		,CASE WHEN emp1.[EmployStatus] = emp2.[EmployStatus] THEN 1 
		ELSE 0 END as EmployStatusSameFlag
		,CASE WHEN emp1.EmpSupportInd=emp2.EmpSupportInd THEN 1
		ELSE 0 END as EmpSupportIndSameFlag
		,CASE WHEN emp1.WeekHoursWorked=emp2.WeekHoursWorked THEN 1
		ELSE 0 END as WeekHoursWorkedSameFlag
		,CASE WHEN emp1.SelfEmployInd=emp2.SelfEmployInd THEN 1
		ELSE 0 END as SelfEmployIndSameFlag
		,CASE WHEN emp1.SickAbsenceInd=emp2.SickAbsenceInd THEN 1
		ELSE 0 END as SickAbsenceSameFlag
		,CASE WHEN emp1.SSPInd=emp2.SSPInd THEN 1
		ELSE 0 END as SSPIndSameFlag
		,CASE WHEN emp1.BenefitRecInd=emp2.BenefitRecInd THEN 1
		ELSE 0 END as BenefitRecIndSameFlag
		,CASE WHEN emp1.ESAInd=emp2.ESAInd THEN 1
		ELSE 0 END as ESAIndSameFlag
		,CASE WHEN emp1.UCInd=emp2.UCInd THEN 1
		ELSE 0 END as UCIndSameFlag
		,CASE WHEN emp1.PIPInd=emp2.PIPInd THEN 1
		ELSE 0 END as PIPIndSameFlag
		,emp1.EmpFirstRecord
		,emp1.EmpLastRecord
		,emp2.EmpSupportDischargeDatePresent
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base] as emp1 
INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_Base] as emp2 
ON emp1.PathwayID = emp2.PathwayID AND emp1.RecordNumber = emp2.RecordNumber AND emp1.EmpFirstRecord <> emp2.EmpFirstRecord
--Only shows records where there are at least two appointments as emp1.EmpFirstRecord can't be equal to emp2.EmpFirstRecord
WHERE emp1.EmpFirstRecord = 1 AND emp2.EmpLastRecord = 1
--Filters to just show fist  records for emp1 table and last records for emp2 table 
GO

--------------------
--This table aggregates the number finishing a course of treatment grouped by geography and if they receive a benefit in their first record
--This table is re-run each month because the base table it uses ([MHDInternal].[TEMP_TTAD_EmpSupp_Base]) is run for the full time period
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_Benefits]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Benefits]
SELECT 
	CAST([Month] AS DATE) AS Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EmpSupportDischargeDatePresent
	,GeneralBenefitReceived
	,COUNT(PathwayID) AS NumberFinishingCourseOfTreatment
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Benefits]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base]
WHERE EmpFirstRecord=1 --To look at first employment support record only
GROUP BY 
	[Month]
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EmpSupportDischargeDatePresent
	,GeneralBenefitReceived

-----------------------------------------------------------------------------------------------------------------------------------
-----------------National Recording of Employment Status and Sickness Absence------------------------------------------------------
--The dashboard looks at the proportion who finish a course of treatment with one or more records, or two or more records of employment status/sickness absence 
--to see how well recorded these fields are at a National level

---National Recording of Employment Status and Sickness Absence Base Table
--This table produces a record level table, as a basis for the aggregated table produced further below ([MHDInternal].[DASHBOARD_TTAD_EmpSupp_FinishedTreatmentAndEmpSupp])
--This table is re-run each month because the base table it uses ([MHDInternal].[TEMP_TTAD_EmpSupp_Base]) is run for the full time period
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Base2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
SELECT
	 *
	 --Creates a flag for those with at least 1 employment status record
	,CASE WHEN EmpFirstRecord=1 and EmployStatusRecDate is not null and EmployStatus<>'Unspecified' then 1 else 0 END as FinishedTreatmentOneEmpStatus
	--Creates a flag for those with at least 2 employment status records
	,CASE WHEN EmpFirstRecord=2 and EmployStatusRecDate is not null and EmployStatus<>'Unspecified' then 1 else 0 END as FinishedTreatmentTwoEmpStatus
	--Creates a flag for those with at least 1 sickness absence record
	,CASE WHEN EmpFirstRecord=1 and EmployStatusRecDate is not null and SickAbsenceInd<>'Unspecified' then 1 else 0 END as FinishedTreatmentOneSickAbsence
	--Creates a flag for those with at least 2 sickness absence records
	,CASE WHEN EmpFirstRecord=2 and EmployStatusRecDate is not null and SickAbsenceInd<>'Unspecified' then 1 else 0 END as FinishedTreatmentTwoSickAbsence
	--Creates a flag for those who have finished treatment
	,CASE WHEN EmpFirstRecord=0 or EmpFirstRecord=1 THEN 1 Else 0 END as FinishedTreatment
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base]


--Aggregated Output for National Recording of Employment Status and Sickness Absence

--National, Any appointment type
--This table sums the flags produced in the base table above, for any appointment type and at a National level. This table is used in the dashboard.
--This table is re-run each month because the base table it uses ([MHDInternal].[TEMP_IAPT_EmpSupp_Base2]) is run for the full time period (see above)
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_FinishedTreatmentAndEmpSupp]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FinishedTreatmentAndEmpSupp]
SELECT
	Month
	,'National' as OrgType
	,'All Regions' as Region
	,'England' as OrgName
	,'Any Appointment Type' as AppointmentType
	,SUM(FinishedTreatmentOneEmpStatus) AS FinishedTreatmentOneEmpStatus
	,SUM(FinishedTreatmentTwoEmpStatus) as FinishedTreatmentTwoEmpStatus
	,SUM(FinishedTreatmentOneSickAbsence) as FinishedTreatmentOneSickAbsence
	,SUM(FinishedTreatmentTwoSickAbsence) as FinishedTreatmentTwoSickAbsence
	,SUM(FinishedTreatment) as FinishedTreatment
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FinishedTreatmentAndEmpSupp]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
GROUP BY Month

--National, Employment Support appointments only
--This table sums the flags produced in the base table above, for employment support appointments only and at a National level. This table is used in the dashboard.
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FinishedTreatmentAndEmpSupp]
SELECT
	Month
	,'National' as OrgType
	,'All Regions' as Region
	,'England' as OrgName
	,'Employment Support' as AppointmentType
	,SUM(FinishedTreatmentOneEmpStatus) AS FinishedTreatmentOneEmpStatus
	,SUM(FinishedTreatmentTwoEmpStatus) as FinishedTreatmentTwoEmpStatus
	,SUM(FinishedTreatmentOneSickAbsence) as FinishedTreatmentOneSickAbsence
	,SUM(FinishedTreatmentTwoSickAbsence) as FinishedTreatmentTwoSickAbsence
	,SUM(FinishedTreatment) as FinishedTreatment
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
WHERE Count_EmpSupp>0
GROUP BY Month
GO

  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------Clinical Outcomes-------------------------------------------------------------------

--Clinical Outcomes Base Table
--This produces a table with a unique record in each row and each flag that is true is assigned the value of 1 so that they can be summed to produce the relevant aggregated value in the table below [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset (for getting the period start and end) should be 0 to get the latest month
SET @PeriodStart = (SELECT DATEADD(MONTH,0,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,0,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
SELECT DISTINCT
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS DATE) as Month
	,r.PathwayID
	,r.[Person_ID]
	,r.[RecordNumber]
	,r.[UniqueSubmissionID]
	,r.[Unique_MonthID]
	,r.[EFFECTIVE_FROM]

--Referrals
	,r.[ReferralRequestReceivedDate]	--Referral received date for any appointment type
	,CASE WHEN (r.[ReferralRequestReceivedDate] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllReferrals	--Flag for new referrals for any appointment type in talking therapies, within the reporting period
				
	,emp.[EmpSupportReferral]	--Referral received date for employment support
	,CASE WHEN ([EmpSupportReferral] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpReferrals	--Flag for new referrals for employment support appointments only in talking therapies, within the reporting period
	
	--Open Referrals - time since last contact, All Appointment Types:
	,r.TherapySession_LastDate
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate)<61 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralLessThan61DaysTimeSinceLastContact	--Flag for all open referrals where the last therapy session date is less than 61 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral61-90DaysTimeSinceLastContact'	--Flag for all open referrals where the last therapy session date is between than 61 and 90 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 91 and 120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral91-120DaysTimeSinceLastContact'	--Flag for all open referrals where the last therapy session date is between than 91 and 120 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) >120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralOver120daysTimeSinceLastContact	--Flag for all open referrals where the last therapy session date is more than 120 days prior to the reporting period end date
	
	--Open Referrals - time since last contact, Employment Support Appointments:
	,r.EmpSupport_LastDate
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) <61 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is less than 61 days prior to the reporting period end date
	END AS EmpOpenReferralLessThan61DaysTimeSinceLastContact
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is between 61 and 90 days prior to the reporting period end date
	END AS 'EmpOpenReferral61-90DaysTimeSinceLastContact'
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is between 91 and 120 days prior to the reporting period end date
	END AS 'EmpOpenReferral91-120DaysTimeSinceLastContact'
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) >120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is more than 120 days prior to the reporting period end date
	END AS EmpOpenReferralOver120daysTimeSinceLastContact
	
	--Open Referrals Waiting for First Contact - All Appointment Types:		
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd	--Flag for all open referrals with no contact where the referral date is less than 61 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral61-90DaysReferraltoReportingPeriodEnd'	--Flag for all open referrals with no contact where the referral date is between 61 and 90 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral91-120DaysReferraltoReportingPeriodEnd'	--Flag for all open referrals with no contact where the referral date is between 91 and 120 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate)  >120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralOver120daysReferraltoReportingPeriodEnd	--Flag for all open referrals with no contact where the referral date is more than 120 days prior to the reporting period end date

	--Open Referrals Waiting for First Contact - Employment Support Appointments:	
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate)  <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd	--Flag for open referrals for employment support with no contact, where the referral date is less than 61 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd'	--Flag for open referrals for employment support with no contact, where the referral date is between 61 and 90 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd'	--Flag for open referrals for employment support with no contact, where the referral date is between 91 and 120 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate) >120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpOpenReferralOver120daysReferraltoReportingPeriodEnd	--Flag for open referrals for employment support with no contact, where the referral date is over 120 days prior to the reporting period end date
	
--Access
	,r.TherapySession_FirstDate	--First therapy session date for any appointment type access
	,CASE WHEN (r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllAccess	--Flag for access for any appointment type, where the first therapy session is within the reporting period
	
	,r.EmpSupport_FirstDate	--First session date for employment support access 
	,CASE WHEN (r.EmpSupport_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpAccess	--Flag for access for employment support, where the first session is within the reporting period
	
--Finished Treatment
	,r.CompletedTreatment_Flag

	,r.ServDischDate --Discharge date for any appointment type
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag  = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllFinishedTreatment	--Flag for finished treatment for any appointment type, where the discharge date is within the reporting period and the completed treatment flag is true
		
	,emp.[EmpSupportDischargeDate] --Discharge date for employment support
	-- ,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	-- END AS EmpFinishedTreatment	--Flag for finished treatment for employment support, where the discharge date is within the reporting period and the completed treatment flag is true
	,CASE WHEN emp.EmpSupportDischargeDate IS NOT NULL THEN 1 ELSE 0 END
	AS EmpSupportDischargeDatePresent

--Clinical Outcomes	
	,r.Recovery_Flag
	,r.NotCaseness_Flag
	,r.ReliableImprovement_Flag
	,r.ReliableDeterioration_Flag

	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllCompTreatFlagRecFlag	--Flag for recovery for any appointment type, where the discharge date is within the reporting period, completed treatment flag is true and recovery flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.NotCaseness_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllNotCaseness	--Flag for not caseness for any appointment type, where the discharge date is within the reporting period, completed treatment flag is true and not caseness flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS AllCompTreatFlagRelImpFlag	--Flag for reliable improvement for any appointment type, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableDeterioration_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllCompTreatFlagRelDetFlag	--Flag for reliable deterioration for any appointment type, where the discharge date is within the reporting period, completed treatment flag is true and reliable deterioration flag is true
	

--Dosage
	,r.TreatmentCareContact_Count AS AllTreatmentCareContact_Count	--Total number of appointments for any type of appointment
	,CASE WHEN ec.Count_EmpSupp IS NOT NULL THEN ec.Count_EmpSupp ELSE 0 END AS AllEmploymentSupport_Count	--Total number of appointments for employment support	

	--Geography
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICBName'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
	,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS 'RegionNameProv'
	,CASE WHEN ph.[Region_Code] IS NOT NULL THEN ph.[Region_Code] ELSE 'Other' END AS 'RegionCodeProv'
--Protected characteristics
	--Gender
	,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
		WHEN mpi.Gender IN ('2','02') THEN 'Female'
		WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
		WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
		WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Unspecified' 
	END AS 'GenderDesc'

	--Ethnicity
	,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
		WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
		WHEN mpi.Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
		WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Unspecified' 
	END AS 'EthnicityDesc'

	--Gender Identity
	,CASE WHEN mpi.GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
		WHEN mpi.GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
		WHEN mpi.GenderIdentity IN ('3','03') THEN 'Non-binary'
		WHEN mpi.GenderIdentity IN ('4','04') THEN 'Other (not listed)'
		WHEN mpi.GenderIdentity IN ('x','X') THEN 'Not Known'
		WHEN mpi.GenderIdentity IN ('z','Z') THEN 'Not Stated'
		WHEN mpi.GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
	END AS 'GenderIdentityDesc'

	--IMD
	,IMD.[IMD_Decile]

	--Age
	,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
		WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unspecified'
	END AS 'AgeGroups'

	--Problem Descriptor
	,CASE WHEN PresentingComplaintHigherCategory = 'Depression' OR [PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN PresentingComplaintHigherCategory = 'Unspecified' OR [PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
		WHEN PresentingComplaintHigherCategory = 'Other recorded problems' OR [PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
		WHEN PresentingComplaintHigherCategory = 'Other Mental Health problems' OR [PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
		WHEN PresentingComplaintHigherCategory = 'Invalid Data supplied' OR [PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
		WHEN (PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
		ELSE 'Other'
	END AS 'ProblemDescriptor'

INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
FROM [mesh_IAPT].[IDS101referral] r
	INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
	--Provides data for gender, validated ethnic category and gender identity
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--Allows filtering for the latest data
	LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.recordnumber = emp.recordnumber
	--Provides data for employment support referrals/appointments/discharges
	LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] and IMD.Effective_Snapshot_Date='2019-12-31'
	--Provides data for IMD

	LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount] ec ON ec.PathwayID=r.PathwayID

	LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
		AND ch.Effective_To IS NULL
	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
		AND ph.Effective_To IS NULL
	--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE UsePathway_Flag = 'True' 
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart	--for monthly refresh the offset should be -1 as we want the data for the latest 2 months month (i.e. to refresh the previous month's primary data)
	AND IsLatest = 1	--To get the latest data
GO

-------------------
--Open Referrals No Contact Table
--This table is just for Open Referrals with no first contact date. It is separate to the clinical outcomes table below as the EmploymentSupport_Count
--field can't be used as a filter since these referrals have no first contact date so won't have a record of an employment support contact
--This table aggregates [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base] for the number of open referrals with no contact at the Provider, Sub-ICB, ICB and National levels
-- for Any Appointment Type and Employment Support.
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]
--Employment
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,CAST('Employment Support'  AS varchar(max)) AS AppointmentType
	,CAST(EmpSupportDischargeDatePresent AS VARCHAR(5)) AS EmpSupportDischargeDatePresent --Looks at if an employment support discharge date is present since we are looking at the ServDischDate to define the open ref

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd

--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EmpSupportDischargeDatePresent

--Any Appointment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_OpenRefsNoContact]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Any Appointment Type' AS AppointmentType
	,'NA' AS EmpSupportDischargeDatePresent

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName


--Aggregated Output Clinical Outcomes Table
--This table sums the flags produced in the base table above to produce the aggregate values at provider/Sub-ICB/ICB/National levels, for the protected characteristics of Gender, Ethnicity, 
--Gender Identity, Deprivation, Age and Problem Descriptor, and for either any appointment types, any appointment type except employment support, or employment support appointments.
--This table is used in the dashboard.

--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]

----------Employment Support Appointments
------------------Gender, Employment
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,CAST('Gender' AS varchar(max)) AS Category
	,CAST(GenderDesc AS varchar(max)) AS Variable
	,CAST('Employment Support'  AS varchar(max)) AS AppointmentType
	,AllEmploymentSupport_Count AS Dosage
	,CAST(EmpSupportDischargeDatePresent AS VARCHAR(5)) AS EmpSupportDischargeDatePresent

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact

	--Access
	,SUM(EmpAccess) AS Access

--Finished Treatment
	,SUM(AllFinishedTreatment) AS FinishedTreatment --Using Service Discharge Date as grouping by if Emp Supp Disch Date is present
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) AS RecoveryFlag
	,SUM(AllNotCaseness) AS NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) AS ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) AS ReliableDeteriorationFlag

--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderDesc
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent
GO
------------------Problem Descriptor, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Problem Descriptor' AS Category
	,ProblemDescriptor AS Variable
	,'Employment Support' AS AppointmentType
	,AllEmploymentSupport_Count AS Dosage
	,EmpSupportDischargeDatePresent
--Referrals
	,SUM(EmpReferrals) AS Referrals

	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(EmpAccess) AS Access

--Finished Treatment
	,SUM(AllFinishedTreatment) AS FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) AS RecoveryFlag
	,SUM(AllNotCaseness) AS NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) AS ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) AS ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,ProblemDescriptor
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent

------------------Ethnicity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Employment Support' as AppointmentType
	,AllEmploymentSupport_Count as Dosage
	,EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(EmpReferrals) AS Referrals

	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EthnicityDesc
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent

------------------Age, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Age' as Category
	,AgeGroups as Variable
	,'Employment Support' as AppointmentType
	,AllEmploymentSupport_Count as Dosage
	,EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(EmpReferrals) AS Referrals

	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,AgeGroups
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent

				------------------Deprivation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Employment Support' as AppointmentType
	,AllEmploymentSupport_Count as Dosage
	,EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(EmpReferrals) AS Referrals

	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact

--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,IMD_Decile
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent

					------------------Gender Identity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Employment Support' as AppointmentType
	,AllEmploymentSupport_Count as Dosage
	,EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(EmpReferrals) AS Referrals

	,SUM(EmpOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([EmpOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([EmpOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(EmpOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderIdentityDesc
	,AllEmploymentSupport_Count
	,EmpSupportDischargeDatePresent

--------------------------All Appointments
------------------Gender, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent


------------------Problem Descriptor, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,ProblemDescriptor
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Ethnicity, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EthnicityDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Age, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,AgeGroups
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Deprivation, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,IMD_Decile
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Gender Identity, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderIdentityDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

--------All Appointments except Employment Support

------------------Gender, All except Emp Supp
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent


------------------Problem Descriptor, All except Emp Supp
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,ProblemDescriptor
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Ethnicity, All except Emp Supp
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,EthnicityDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Age, All except Emp Supp
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,AgeGroups
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Deprivation, All except Emp Supp
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	

--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,IMD_Decile
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

------------------Gender Identity, All except Emp Supp
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type except Employment Support' as AppointmentType
	,AllTreatmentCareContact_Count as Dosage
	,'NA' AS EmpSupportDischargeDatePresent
	
--Referrals
	,SUM(AllReferrals) AS Referrals

	,SUM(AllOpenReferralLessThan61DaysTimeSinceLastContact) AS OpenReferralLessThan61DaysTimeSinceLastContact
	,SUM([AllOpenReferral61-90DaysTimeSinceLastContact]) AS [OpenReferral61-90DaysTimeSinceLastContact]
	,SUM([AllOpenReferral91-120DaysTimeSinceLastContact]) AS [OpenReferral91-120DaysTimeSinceLastContact]
	,SUM(AllOpenReferralOver120daysTimeSinceLastContact) AS OpenReferralOver120daysTimeSinceLastContact
--Access
	,SUM(AllAccess) as Access
	
--Finished Treatment
	,SUM(AllFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calcs
	,SUM(AllCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(AllNotCaseness) as NotCasenessFlag
	,SUM(AllCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(AllCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag
	
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count=0
GROUP BY
	Month
	,RegionNameComm
	,RegionCodeComm
	,RegionCodeProv
	,RegionNameProv
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,GenderIdentityDesc
	,AllTreatmentCareContact_Count
	,EmpSupportDischargeDatePresent

-- Drop temporary tables
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
