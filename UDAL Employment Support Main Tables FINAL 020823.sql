/****** Script for Employment Support Dashboard to produce tables for Employment Support Outcomes, National Recording of Employment Status and Sickness Absence,and Clinical Outcomes******/
------------------------------------------------------------------------------------------------------------------------
--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------
--There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each sexual orientation code based on the SocPerCircumstanceRecDate 
--so that the latest record of a sexual orientation is labelled as 1. Only records with a SocPerCircumstanceLatest=1 are used in the queries to produce 
--[MHDInternal].[TEMP_TTAD_EmpSupp_Base] and [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base] tables

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank]
SELECT *
	,ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] desc, SocPerCircumstanceRank asc) as SocPerCircumstanceLatest
	--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank]
FROM(
SELECT DISTINCT
	AuditID
	,SocPerCircumstance
	,SocPerCircumstanceRecDate
	,Person_ID
	,RecordNumber
	,UniqueID_IDS011
	,OrgID_Provider
	,UniqueSubmissionID
	,Unique_MonthID
	,EFFECTIVE_FROM
	--,CASE WHEN SocPerCircumstance IN ('20430005','89217008','76102007','38628009','42035005','765288000','766822004') THEN 1
	--	WHEN SocPerCircumstance IN ('1064711000000100','699042003','440583007') THEN 2
	--ELSE NULL END AS SocPerCircumstanceRank1
	,CASE WHEN SocPerCircumstance IN ('20430005','89217008','76102007','42035005','765288000','766822004') THEN 1
	--Heterosexual, Homosexual (Female), Homosexual (Male), Bisexual,Sexually attracted to neither male nor female sex, Confusion
		WHEN SocPerCircumstance='38628009' THEN 2 
		--Homosexual (Gender not specified) (there are occurrences where this is listed alongside Homosexual (Male) or Homosexual (Female) for the same record 
		--so has been ranked below these to prioritise a social personal circumstance with the max amount of information)
		WHEN SocPerCircumstance IN ('1064711000000100','699042003','440583007') THEN 3 --Person asked and does not know or IS not sure, Declined, Unknown
	ELSE NULL END AS SocPerCircumstanceRank
	--Ranks the social personal circumstances by the amount of information they provide to help decide which one to use
	--when a record has more than one social personal circumstance on the same day
FROM [mesh_IAPT].[IDS011socpercircumstances]
--Filters for codes relevant to sexual orientation
WHERE SocPerCircumstance IN('20430005','89217008','76102007','38628009','42035005','1064711000000100','699042003','765288000','440583007','766822004')
)_

-----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------Employment Support Outcomes----------------------------------------------------------------------
-- Compares the employment status, self-employment indicator, sickness absence indicator, statutory sick pay indicator,
--benefit indicator, employment and support allowance indicator, universal credit indicator, and personal independence payment indicator 
--at the earliest employment status record date to the latest employment status record date

--Employment Support Outcomes Base Table
--This table produces a record level table for the refresh period defined below, as a basis for the output table produced further below ([MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp])

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

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

		--,CASE WHEN emp.EmployStatusRecDate IS NOT NULL THEN ROW_NUMBER() OVER(PARTITION BY emp.Person_ID, emp.RecordNumber
		--ORDER BY emp.[EmployStatusRecDate] asc) ELSE 0 END AS 'EmpFirstRecord' --ranks employment status record dates to get the first employment status record as 1 for filtering later
		--,CASE WHEN emp.EmployStatusRecDate IS NOT NULL THEN ROW_NUMBER() OVER(PARTITION BY emp.Person_ID, emp.RecordNumber
		--ORDER BY emp.[EmployStatusRecDate] desc) ELSE 0 END AS 'EmpLastRecord'--ranks employment status record dates to get the last employment status record as 1 for filtering later
		
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

-----------------Sexual Orientation
		,CASE WHEN spc.SocPerCircumstance = '20430005' THEN 'Heterosexual'
				WHEN spc.SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
				WHEN spc.SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
				WHEN spc.SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
				WHEN spc.SocPerCircumstance = '42035005' THEN 'Bisexual'
				WHEN spc.SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
				WHEN spc.SocPerCircumstance = '699042003' THEN 'Declined'
				WHEN spc.SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
				WHEN spc.SocPerCircumstance = '440583007' THEN 'Unknown'
				WHEN spc.SocPerCircumstance = '766822004' THEN 'Confusion'
				ELSE 'Unspecified'
		END AS 'SexualOrientationDesc'
		,ch.Organisation_Code as 'Sub-ICBCode'
		,ch.Organisation_Name as 'Sub-ICB Name'
		,ch.STP_Name as 'ICB Name'
		,ch.Region_Name as 'RegionNameComm'
		,ph.Organisation_Code as 'ProviderCode'
		,ph.Organisation_Name as 'Provider Name'
		,ph.Region_Name as 'RegionNameProv'
		,r.EmploymentSupport_Count

FROM [mesh_IAPT].[IDS101referral] r
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		--Provides data for gender, validated ethnic category and gender identity
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--Allows filtering for the latest data
		LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.recordnumber = emp.recordnumber AND emp.AuditId = l.AuditId
		--Provides data for employment status and other indicators		
		LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1
		--Provides data for sexual orientation
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] and IMD.Effective_Snapshot_Date='2019-12-31'
		--Provides data for IMD
		LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE r.UsePathway_Flag = 'True' 
		AND l.IsLatest = 1	--To get the latest data
		AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
		AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodStart
		and emp.RecordNumber is not null
)_
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
		,emp1.[SexualOrientationDesc]
		,emp1.[Sub-ICB Name]
		,emp1.[ICB Name]
		,emp1.RegionNameComm
		,emp1.[Provider Name]
		,emp1.RegionNameProv
		,emp1. EmploymentSupport_Count	--number of employment support appointments
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
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_FirstAndLastEmp]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Base] as emp1 
INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_Base] as emp2 
ON emp1.PathwayID = emp2.PathwayID AND emp1.RecordNumber = emp2.RecordNumber AND emp1.EmpFirstRecord <> emp2.EmpFirstRecord
--Only shows records where there are at least two appointments as emp1.EmpFirstRecord can't be equal to emp2.EmpFirstRecord
WHERE emp1.EmpFirstRecord = 1 AND emp2.EmpLastRecord = 1
--Filters to just show fist  records for emp1 table and last records for emp2 table 
GO

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
WHERE EmploymentSupport_Count>0
GROUP BY Month
GO

  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------Clinical Outcomes-------------------------------------------------------------------

--Clinical Outcomes Base Table
--This produces a table with a unique record in each row and each flag that is true is assigned the value of 1 so that they can be summed to produce the relevant aggregated value in the table below [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset (for getting the period start and end) should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
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
	
	,r.TherapySession_LastDate
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate)<61 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralLessThan61DaysNoContact	--Flag for all open referrals where the last therapy session date is less than 61 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral61-90DaysNoContact'	--Flag for all open referrals where the last therapy session date is between than 61 and 90 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 91 and 120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral91-120DaysNoContact'	--Flag for all open referrals where the last therapy session date is between than 91 and 120 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.TherapySession_LastDate, l.ReportingPeriodEndDate) >120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralOver120daysNoContact	--Flag for all open referrals where the last therapy session date is more than 120 days prior to the reporting period end date

	,r.EmpSupport_LastDate
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) <61 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is less than 61 days prior to the reporting period end date
	END AS EmpOpenReferralLessThan61DaysNoContact
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is between 61 and 90 days prior to the reporting period end date
	END AS 'EmpOpenReferral61-90DaysNoContact'
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is between 91 and 120 days prior to the reporting period end date
	END AS 'EmpOpenReferral91-120DaysNoContact'
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND r.EmpSupport_LastDate<=l.ReportingPeriodEndDate AND DATEDIFF(DD ,r.EmpSupport_LastDate, l.ReportingPeriodEndDate) >120 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0	--Flag for open referrals, for just employment support, where the last session date is more than 120 days prior to the reporting period end date
	END AS EmpOpenReferralOver120daysNoContact
	
	--Proportions waiting for first contact - all appointment types:		
	,CASE WHEN r.ServDischDate IS NULL AND TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd	--Flag for all open referrals with no contact where the referral date is less than 61 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral61-90DaysReferraltoReportingPeriodEnd'	--Flag for all open referrals with no contact where the referral date is between 61 and 90 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'AllOpenReferral91-120DaysReferraltoReportingPeriodEnd'	--Flag for all open referrals with no contact where the referral date is between 91 and 120 days prior to the reporting period end date
	,CASE WHEN r.ServDischDate IS NULL AND TherapySession_FirstDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate)  >120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS AllOpenReferralOver120daysReferraltoReportingPeriodEnd	--Flag for all open referrals with no contact where the referral date is more than 120 days prior to the reporting period end date

	--Proportions waiting for first contact - employment support appointments:	
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate)  <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd	--Flag for open referrals for employment support with no contact, where the referral date is less than 61 days prior to the reporting period end date
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd'	--Flag for open referrals for employment support with no contact, where the referral date is between 61 and 90 days prior to the reporting period end date
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
		AND DATEDIFF(DD ,emp.EmpSupportReferral, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS 'EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd'	--Flag for open referrals for employment support with no contact, where the referral date is between 91 and 120 days prior to the reporting period end date
	,CASE WHEN emp.[EmpSupportDischargeDate] IS NULL AND EmpSupport_FirstDate IS NULL AND emp.EmpSupportReferral<=l.ReportingPeriodEndDate
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
	,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpFinishedTreatment	--Flag for finished treatment for employment support, where the discharge date is within the reporting period and the completed treatment flag is true

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
	
	,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpCompTreatFlagRecFlag	--Flag for recovery for employment support, where the discharge date is within the reporting period, completed treatment flag is true and recovery flag is true
	,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.NotCaseness_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpNotCaseness	--Flag for not caseness for employment support, where the discharge date is within the reporting period, completed treatment flag is true and not caseness flag is true
	,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpCompTreatFlagRelImpFlag	--Flag for reliable improvement for employment support, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (emp.[EmpSupportDischargeDate] BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableDeterioration_Flag = 'True'
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS EmpCompTreatFlagRelDetFlag	--Flag for reliable deterioration for employment support, where the discharge date is within the reporting period, completed treatment flag is true and reliable deterioration flag is true
	
--Dosage
	,CASE WHEN CompletedTreatment_Flag = 'True' THEN r.TreatmentCareContact_Count ELSE NULL 
	END AS TreatmentCareContact_Count --Total number of appointments for any type of appointment, where the completed treatment flag is true
	,CASE WHEN CompletedTreatment_Flag = 'True' THEN r.EmploymentSupport_Count ELSE NULL 
	END AS EmploymentSupport_Count --Total number of appointments for employment support, where the completed treatment flag is true
	,r.TreatmentCareContact_Count AS AllTreatmentCareContact_Count	--Total number of appointments for any type of appointment
	,r.EmploymentSupport_Count AS AllEmploymentSupport_Count	--Total number of appointments for employment support	

--Geography
	,r.[OrgID_Provider]
	,ph.[Organisation_Name] as [Prov_Name]
	,ph.[Region_Name] as [Prov_Region]
	,r.[OrgIDComm]
	,ch.[Organisation_Name] as [SubICB_Name]
	,ch.[STP_Code] as [ICB_Code]
	,ch.[STP_Name] as [ICB_Name]
	,ch.[Region_Name] as [Comm_Region]

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

	--Sexual Orientation
	,CASE WHEN spc.SocPerCircumstance = '20430005' THEN 'Heterosexual'
		WHEN spc.SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
		WHEN spc.SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
		WHEN spc.SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
		WHEN spc.SocPerCircumstance = '42035005' THEN 'Bisexual'
		WHEN spc.SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
		WHEN spc.SocPerCircumstance = '699042003' THEN 'Declined'
		WHEN spc.SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
		WHEN spc.SocPerCircumstance = '440583007' THEN 'Unknown'
		WHEN spc.SocPerCircumstance = '766822004' THEN 'Confusion'
		ELSE 'Unspecified'
	END AS 'SexualOrientationDesc'

INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
FROM [mesh_IAPT].[IDS101referral] r
	INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
	--Provides data for gender, validated ethnic category and gender identity
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--Allows filtering for the latest data
	LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.recordnumber = emp.recordnumber
	--Provides data for employment support referrals/appointments/discharges
	LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1
	--Provides data for sexual orientation
	LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] and IMD.Effective_Snapshot_Date='2019-12-31'
	--Provides data for IMD
	LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
	--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE UsePathway_Flag = 'True' 
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart	--for refresh the offset should be 0 as only want the data for the latest month
	AND IsLatest = 1	--To get the latest data
GO

--Active Provides for Employment Support
--This table has the distinct list of Providers that have any records with at least 1 employment support contact (EmploymentSupport_Count>0) regardless of whether they have completed treatment
--This is used for the Provider Participation page of the dashboard

--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_ActiveEAProviders]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ActiveEAProviders]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ActiveEAProviders]
SELECT DISTINCT
	OrgID_Provider
	,Prov_Name
	,Prov_Region
	,Month
--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ActiveEAProviders]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
WHERE AllEmploymentSupport_Count>0	--Filters for any record with EmploymentSupport_Count>0 regardless of if they have completed treatment

--Aggregated Output Clinical Outcomes Table
--This table sums the flags produced in the base table above to produce the aggregate values at provider/Sub-ICB/ICB/National levels, for the protected characteristics of Gender, Ethnicity, 
--Gender Identity, Deprivation, Age, Problem Descriptor and Sexual Orientation, and for either any appointment types or employment support appointments.
--This table is used in the dashboard.

--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
------------------Provider, Gender, Employment
SELECT
	Month
	,cast('Provider' as varchar(max)) as [OrgType]
	,cast(Prov_Name as varchar(max)) as [OrgName]
	,cast(OrgID_Provider as varchar(max)) as [OrgCode]
	,cast(Prov_Region as varchar(max)) as [Region]
	,cast('Gender' as varchar(max)) as Category
	,cast(GenderDesc as varchar(max)) as Variable
	,cast('Employment Support'  as varchar(max)) as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment
	
--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, GenderDesc, EmploymentSupport_Count

------------------Provider, Gender, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, GenderDesc, TreatmentCareContact_Count

	------------------Provider, Problem Descriptor, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, ProblemDescriptor, EmploymentSupport_Count

------------------Provider, Problem Descriptor, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, ProblemDescriptor, TreatmentCareContact_Count

		------------------Provider, Ethnicity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, EthnicityDesc, EmploymentSupport_Count

------------------Provider, Ethnicity, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, EthnicityDesc, TreatmentCareContact_Count

			------------------Provider, Age, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, AgeGroups, EmploymentSupport_Count

------------------Provider, Age, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, AgeGroups, TreatmentCareContact_Count

				------------------Provider, Deprivation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd

--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, IMD_Decile, EmploymentSupport_Count

------------------Provider, Deprivation, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, IMD_Decile, TreatmentCareContact_Count

					------------------Provider, Gender Identity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, GenderIdentityDesc, EmploymentSupport_Count

------------------Provider, Gender Identity, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, GenderIdentityDesc, TreatmentCareContact_Count

					------------------Provider, Sexual Orientation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, SexualOrientationDesc, EmploymentSupport_Count

------------------Provider, Sexual Orientation, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Provider' as [OrgType]
	,Prov_Name as [OrgName]
	,OrgID_Provider as [OrgCode]
	,Prov_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, Prov_Name, OrgID_Provider, Prov_Region, SexualOrientationDesc, TreatmentCareContact_Count


------------------------------------Sub-ICBs--------------------------------------------
------------------Sub-ICB, Gender, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, GenderDesc, EmploymentSupport_Count

------------------Sub-ICB, Gender, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, GenderDesc, TreatmentCareContact_Count

------------------Sub-ICB, Problem Descriptor, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, ProblemDescriptor, EmploymentSupport_Count

------------------Sub-ICB, Problem Descriptor, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, ProblemDescriptor, TreatmentCareContact_Count

------------------Sub-ICB, Ethnicity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, EthnicityDesc, EmploymentSupport_Count

------------------Sub-ICB, Ethnicity, All
	
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, EthnicityDesc, TreatmentCareContact_Count

------------------Sub-ICB, Age, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, AgeGroups, EmploymentSupport_Count

------------------Sub-ICB, Age, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, AgeGroups, TreatmentCareContact_Count

------------------Sub-ICB, Deprivation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, IMD_Decile, EmploymentSupport_Count

------------------Sub-ICB, Deprivation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, IMD_Decile, TreatmentCareContact_Count

------------------Sub-ICB, Gender Identity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, GenderIdentityDesc, EmploymentSupport_Count

------------------Sub-ICB, Gender Identity, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, GenderIdentityDesc, TreatmentCareContact_Count

------------------Sub-ICB, Sexual Orientation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, SexualOrientationDesc, EmploymentSupport_Count

------------------Sub-ICB, Sexual Orientation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'Sub-ICB' as [OrgType]
	,SubICB_Name as [OrgName]
	,OrgIDComm as [OrgCode]
	,Comm_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, SubICB_Name, OrgIDComm, Comm_Region, SexualOrientationDesc, TreatmentCareContact_Count


---------------------------------------------------ICBs----------------------------------
------------------ICB, Gender, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, GenderDesc, EmploymentSupport_Count

------------------ICB, Gender, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, GenderDesc, TreatmentCareContact_Count

------------------ICB, Problem Descriptor, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, ProblemDescriptor, EmploymentSupport_Count

------------------ICB, Problem Descriptor, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, ProblemDescriptor, TreatmentCareContact_Count

------------------ICB, Ethnicity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, EthnicityDesc, EmploymentSupport_Count

------------------ICB, Ethnicity, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, EthnicityDesc, TreatmentCareContact_Count

------------------ICB, Age, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, AgeGroups, EmploymentSupport_Count

------------------ICB, Age, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, AgeGroups, TreatmentCareContact_Count

------------------ICB, Deprivation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calcs
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, IMD_Decile, EmploymentSupport_Count

------------------ICB, Deprivation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, IMD_Decile, TreatmentCareContact_Count

------------------ICB, Gender Identity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, GenderIdentityDesc, EmploymentSupport_Count

------------------ICB, Gender Identity, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, GenderIdentityDesc, TreatmentCareContact_Count

------------------ICB, Sexual Orientation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, SexualOrientationDesc, EmploymentSupport_Count

------------------ICB, Sexual Orientation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'ICB' as [OrgType]
	,ICB_Name as [OrgName]
	,ICB_Code as [OrgCode]
	,Comm_Region as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ICB_Name, ICB_Code, Comm_Region, SexualOrientationDesc, TreatmentCareContact_Count

------------------------------------National--------------------------------------------------------------------------------
------------------National, Gender, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, GenderDesc, EmploymentSupport_Count

------------------National, Gender, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Gender' as Category
	,GenderDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, GenderDesc, TreatmentCareContact_Count

------------------National, Problem Descriptor, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, ProblemDescriptor, EmploymentSupport_Count

------------------National, Problem Descriptor, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Problem Descriptor' as Category
	,ProblemDescriptor as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, ProblemDescriptor, TreatmentCareContact_Count

------------------National, Ethnicity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, EthnicityDesc, EmploymentSupport_Count

------------------National, Ethnicity, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Ethnicity' as Category
	,EthnicityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month, EthnicityDesc, TreatmentCareContact_Count

------------------National, Age, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

	FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
	GROUP BY Month,  AgeGroups, EmploymentSupport_Count

------------------National, Age, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Age' as Category
	,AgeGroups as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month,  AgeGroups, TreatmentCareContact_Count

------------------National, Deprivation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month,  IMD_Decile, EmploymentSupport_Count

------------------National, Deprivation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Deprivation' as Category
	,IMD_Decile as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month,  IMD_Decile, TreatmentCareContact_Count

------------------National, Gender Identity, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month,  GenderIdentityDesc, EmploymentSupport_Count

------------------National, Gender Identity, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Gender Identity' as Category
	,GenderIdentityDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month,  GenderIdentityDesc, TreatmentCareContact_Count

------------------National, Sexual Orientation, Employment
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Employment Support' as AppointmentType
	,EmploymentSupport_Count as Dosage

--Referrals
	,SUM(EmpReferrals) AS Referrals
	,SUM(EmpOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([EmpOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([EmpOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(EmpOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(EmpOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([EmpOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([EmpOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(EmpOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
--Access
	,SUM(EmpAccess) as Access

--Finished Treatment
	,SUM(EmpFinishedTreatment) as FinishedTreatment

--For Clinical Outcomes Calc
	,SUM(EmpCompTreatFlagRecFlag) as RecoveryFlag
	,SUM(EmpNotCaseness) as NotCasenessFlag
	,SUM(EmpCompTreatFlagRelImpFlag) as ReliableImprovementFlag
	,SUM(EmpCompTreatFlagRelDetFlag) as ReliableDeteriorationFlag

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]
GROUP BY Month, SexualOrientationDesc, EmploymentSupport_Count

------------------National, Sexual Orientation, All
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_ClinOutcomes]
SELECT
	Month
	,'National' as [OrgType]
	,'England' as [OrgName]
	,'ENG' as [OrgCode]
	,'All Regions' as [Region]
	,'Sexual Orientation' as Category
	,SexualOrientationDesc as Variable
	,'Any Appointment Type' as AppointmentType
	,TreatmentCareContact_Count as Dosage

--Referrals
	,SUM(AllReferrals) AS Referrals
	,SUM(AllOpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([AllOpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([AllOpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM(AllOpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact

	,SUM(AllOpenReferralLessThan61DaysReferraltoReportingPeriodEnd) AS OpenReferralLessThan61DaysReferraltoReportingPeriodEnd
	,SUM([AllOpenReferral61-90DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral61-90DaysReferraltoReportingPeriodEnd'
	,SUM([AllOpenReferral91-120DaysReferraltoReportingPeriodEnd]) AS 'OpenReferral91-120DaysReferraltoReportingPeriodEnd'
	,SUM(AllOpenReferralOver120daysReferraltoReportingPeriodEnd) AS OpenReferralOver120daysReferraltoReportingPeriodEnd
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
GROUP BY Month,  SexualOrientationDesc, TreatmentCareContact_Count


--Drop temporary tables created to produce the final output tables
-- DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_SocPerCircRank]
-- DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base]
-- DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Base2]
-- DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Clin_Base]


	
