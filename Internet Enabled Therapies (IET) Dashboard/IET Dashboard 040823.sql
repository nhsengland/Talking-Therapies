--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Internet Enabled Therapies Dashboard to produce tables for Appointments, Clinical Outcomes by Therapy Type, Clinical Outcomes by Problem Descriptor,
Reason for Ending Treatment, Finished Treatment, Integration Engine, Severity, Pathway Type and PEQ ******/

----------------------------------------- IET Appointments Clinical Time--------------------------------
--This table calculates the total clinical time per PathwayID and therapy type for just IET Appointments.
--This is used below to include the IET therapist time per treatment in the [MHDInternal].[TEMP_TTAD_IET_Base] 
--which is used in the averages script to calculate the average IET therapist time per treatment.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]
SELECT  
    i.PathwayID
    ,CASE WHEN (i.IntEnabledTherProg LIKE 'SilverCloud%' OR i.IntEnabledTherProg LIKE  'Slvrcld%' ) THEN 'SilverCloud'
		WHEN (i.IntEnabledTherProg LIKE 'Mnddstrct%' OR i.IntEnabledTherProg LIKE 'Minddistrict%') THEN 'Minddistrict'
		WHEN i.IntEnabledTherProg LIKE 'iCT%' THEN 'iCT'
		WHEN i.IntEnabledTherProg LIKE 'OCD%' THEN 'OCD-NET'
		WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
	END IntEnabledTherProg
	,i.IntegratedSoftwareInd
    ,SUM(DurationIntEnabledTher) AS DurationIntEnabledTher
	,COUNT(DISTINCT CASE WHEN i.[EndDateIntEnabledTherLog] BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate THEN [UniqueID_IDS205] ELSE NULL END) AS Count_IET
INTO [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]
FROM [mesh_IAPT].[IDS205internettherlog] i
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON i.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND i.[AuditId] = l.[AuditId]
WHERE l.IsLatest = 1 
GROUP BY i.PathwayID
,CASE WHEN (i.IntEnabledTherProg LIKE 'SilverCloud%' OR i.IntEnabledTherProg LIKE  'Slvrcld%' ) THEN 'SilverCloud'
		WHEN (i.IntEnabledTherProg LIKE 'Mnddstrct%' OR i.IntEnabledTherProg LIKE 'Minddistrict%') THEN 'Minddistrict'
		WHEN i.IntEnabledTherProg LIKE 'iCT%' THEN 'iCT'
		WHEN i.IntEnabledTherProg LIKE 'OCD%' THEN 'OCD-NET'
		WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
		END, 
		i.IntegratedSoftwareInd

----------------------------------------- Any Appointment Type Clinical Time--------------------------------
--This table calculates the total clinical time per PathwayID for any appointment type (including IET).
--This is used below to include the any therapist time per treatment in the [MHDInternal].[TEMP_TTAD_IET_Base] 
--which is used in the averages script to calculate the average any therapist time per treatment.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_NoIETDuration]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_NoIETDuration]
SELECT  
    ca.PathwayID
    ,SUM(ca.ClinContactDurOfCareAct) AS ClinContactDurOfCareAct
INTO [MHDInternal].[TEMP_TTAD_IET_NoIETDuration]
FROM [mesh_IAPT].[IDS202careactivity] ca
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON ca.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND ca.[AuditId] = l.[AuditId]
WHERE l.IsLatest = 1 
GROUP BY ca.PathwayID

------------------------------------------Main Base table-------------------------------------
--This creates a base table with one record per row which is then aggregated to produce [MHDInternal].[DASHBOARD_TTAD_IET_Main]
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--For monthly refresh @PeriodStart2 should always be set for September 2020 
--The full period is run due to the average tables (which use this base table) recalculating the averages for each quarter
DECLARE @PeriodStart2 DATE
SET @PeriodStart2= '2020-09-01'	 

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_Base]
SELECT DISTINCT
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,[Fin_Year_Quarter_QQ_YY_YY] AS Quarter
	,l.ReportingPeriodStartDate
	,l.ReportingPeriodEndDate
	,r.PathwayID
	,r.Unique_MonthID

	,r.ReferralRequestReceivedDate
	,r.Assessment_FirstDate
	,r.TherapySession_FirstDate
	,r.TherapySession_SecondDate
	,r.ServDischDate

	--Wait Times
	,DATEDIFF(DD,r.ReferralRequestReceivedDate,r.Assessment_FirstDate) AS WaitRefToFirstAssess
	,DATEDIFF(DD,r.ReferralRequestReceivedDate,r.TherapySession_FirstDate) AS WaitRefToFirstTherapy
	,DATEDIFF(DD,r.TherapySession_FirstDate,r.TherapySession_SecondDate) AS WaitFirstTherapyToSecondTherapy
		
	--Number of Appointments
    ,r.InternetEnabledTherapy_Count AS OldIETCount
	,i.Count_IET AS InternetEnabledTherapy_Count
    --Type of IET
	,CASE WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
	END IntEnabledTherProg

	--Therapist Time
	,i.DurationIntEnabledTher
	,ca.ClinContactDurOfCareAct
	
	--Integration Engine Flag
	,i.IntegratedSoftwareInd

	--Reasons for Ending Treatment
	,r.EndCode
	,CASE WHEN r.EndCode='' THEN 'Referred but not seen/Seen but not taken on for a course of treatment/Seen and taken on for a course of treatment'
		WHEN r.EndCode='50' THEN 'Not assessed'	
		WHEN r.EndCode='10' THEN 'Not suitable for IAPT service - no action taken or directed back to referrer'
		WHEN r.EndCode='11'	THEN 'Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient'
		WHEN r.EndCode='12' THEN 'Discharged by mutual agreement following advice and support'
		WHEN r.EndCode='13' THEN 'Referred to another therapy service by mutual agreement'
		WHEN r.EndCode='14'	THEN 'Suitable for IAPT service, but patient declined treatment that was offered'
		WHEN r.EndCode='16' THEN 'Incomplete Assessment (Patient dropped out)'
		WHEN r.EndCode='17' THEN 'Deceased (Seen but not taken on for a course of treatment)'
		WHEN r.EndCode='95' THEN 'Not Known (Seen but not taken on for a course of treatment)'
		WHEN r.EndCode='46' THEN 'Mutually agreed completion of treatment'
		WHEN r.EndCode='47' THEN 'Termination of treatment earlier than Care Professional planned'
		WHEN r.EndCode='48' THEN 'Termination of treatment earlier than patient requested'
		WHEN r.EndCode='49' THEN 'Deceased (Seen and taken on for a course of treatment)'
		WHEN r.EndCode='96' THEN 'Not Known (Seen and taken on for a course of treatment)'
		ELSE 'Missing/invalid'
		END AS EndCodeDescription

    --Clinical Outcomes	
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS CompTreatFlagRecFlag	--Flag for recovery, where the discharge date is within the reporting period, completed treatment flag is true and recovery flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.NotCaseness_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS CompTreatFlagNotCasenessFlag	--Flag for not caseness, where the discharge date is within the reporting period, completed treatment flag is true and not caseness flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlagRelImpFlag	--Flag for reliable improvement, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlagRelRecFlags	--Flag for reliable improvement and recovery, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlag --Flag for completed treatment flag, where the discharge date is within the reporting period
    
    --Problem Descriptor
	,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR r.[PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR r.[PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
		WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR r.[PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
		WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR r.[PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
		WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR r.[PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
		ELSE 'Other'
	END AS 'ProblemDescriptor'
    
	--Severity
	,CASE WHEN r.GAD_FirstScore BETWEEN 0 AND 4 THEN 'Minimal Anxiety'
		WHEN r.GAD_FirstScore BETWEEN 5 AND 9 THEN 'Mild Anxiety'
		WHEN r.GAD_FirstScore BETWEEN 10 AND 14 THEN 'Moderate Anxiety'
		WHEN r.GAD_FirstScore > 14 THEN 'Severe Anxiety' 
	END AS 'GAD7 Cluster'

	,CASE WHEN r.PHQ9_FirstScore BETWEEN 0 AND 4 THEN 'None-Minimal'
		WHEN r.PHQ9_FirstScore BETWEEN 5 AND 9 THEN 'Mild'
		WHEN r.PHQ9_FirstScore BETWEEN 10 AND 14 THEN 'Moderate'
		WHEN r.PHQ9_FirstScore BETWEEN 15 AND 19 THEN 'Moderate Severe'
		WHEN r.PHQ9_FirstScore BETWEEN 20 AND 27 THEN 'Severe' 
	END AS 'PHQ9 Cluster'

	,CASE WHEN i.Count_IET=0 AND r.TreatmentCareContact_Count>0
		THEN 'No IET'
		WHEN i.Count_IET>0 AND r.TreatmentCareContact_Count=i.Count_IET
		THEN 'Only IET'
		WHEN i.Count_IET>0 AND r.TreatmentCareContact_Count>i.Count_IET
		THEN 'Mixed IET and No IET'
	END AS UniqueMixedPathway

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
INTO [MHDInternal].[TEMP_TTAD_IET_Base]
FROM [MESH_IAPT].[IDS101referral] r

INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
	AND ch.Effective_To IS NULL

LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL

LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration] i ON i.PathwayID = r.PathwayID
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_NoIETDuration] ca ON ca.PathwayID=r.PathwayID

INNER JOIN [Internal_Reference].[Date_Full] ON Full_Date = l.ReportingPeriodStartDate

WHERE r.UsePathway_Flag = 'True' 
	AND l.IsLatest = 1	--To get the latest data
	AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
	AND r.ReferralRequestReceivedDate BETWEEN @PeriodStart2 AND @PeriodEnd
	AND l.ReportingPeriodStartDate BETWEEN @PeriodStart2 AND @PeriodStart
	
------------------------------------------------------------------------------------	
----------------------------------------Aggregated Main Table------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_Base] table to get the number of PathwayIDs with the recovery flag,
-- not caseness flag, reliable improvement flag, completed treatment flag, and both the recovery and reliable improvement flag.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types (1+ IET, 2+ IET and No IET),
--by IET Therapy Types, by Integration Engine Indicator, by End Codes, by Problem Descriptors, by severity scores,
-- by pathway type (unique or mixed IET pathway) and Month.
--The full table is re-run each month as base table contains all months
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_Main]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_Main]
--National, IET 1+
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway
GO
--National, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--National, IET 2+
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Region, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm AS OrgName
,RegionCodeComm AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Region, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Region, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway


--ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway


--ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Provider, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway


--Provider, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway

--Provider, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,[GAD7 Cluster]
,[PHQ9 Cluster]
,UniqueMixedPathway
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
	,[GAD7 Cluster]
	,[PHQ9 Cluster]
	,UniqueMixedPathway
-------------------------------------------------------------------------------
--For Patient Experience Questionnaire (PEQ)

--------------------------Ranking PEQ Table-----------------------------------------
--This table ranks answers using the Effective_From date to get the latest answer.
--This table is used to produce [MHDInternal].[TEMP_TTAD_IET_BasePEQ].
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_PEQRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_PEQRank]
SELECT DISTINCT 
*
,ROW_NUMBER() OVER(PARTITION BY PathwayID,CodedAssToolType ORDER BY Effective_From desc) as LatestAnswer 
INTO [MHDInternal].[TEMP_TTAD_IET_PEQRank]
FROM(
	SELECT DISTINCT 
	csa.PathwayID
	,csa.CodedAssToolType
	,s2.Term
	,csa.PersScore
	,csa.EFFECTIVE_FROM
	FROM [mesh_IAPT].[IDS607codedscoreassessmentact] csa 
	LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) 
		AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1

	WHERE csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101'
	,'747941000000105','747951000000108','747861000000100','747871000000107','747881000000109','904691000000103'
	,'747891000000106') --Snomed codes for the PEQ questions of interest
)_

-----------------------------------PEQ Base Table------------------------------------------------------------
--This creates a base table with one record per row which is then aggregated to produce [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--For monthly refresh the offset should be set to 0 as we only want the latest refreshed month
DECLARE @Offset int
SET @Offset=0

DECLARE @PeriodStart2 DATE
SET @PeriodStart2= '2020-09-01'	 --This is for defining the period for referrals

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_BasePEQ]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
SELECT DISTINCT 
CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) as Month
,r.PathwayID
,CASE WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
END IntEnabledTherProg
,i.Count_IET AS InternetEnabledTherapy_Count
,CASE WHEN p.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 1 score (observable entity)' THEN 'Assessment Question 1'
	WHEN p.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 2 score (observable entity)' THEN 'Assessment Question 2'
	WHEN p.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 3 score (observable entity)' THEN 'Assessment Question 3'
	WHEN p.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 4 score (observable entity)' THEN 'Assessment Question 4'
	WHEN p.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire satisfaction question 1 score (observable entity)' THEN 'Satisfaction Assessment Question 1'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 1 score (observable entity)' THEN 'Treatment Question 1'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 2 score (observable entity)' THEN 'Treatment Question 2'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 3 score (observable entity)' THEN 'Treatment Question 3'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 4 score (observable entity)' THEN 'Treatment Question 4'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 5 score (observable entity)' THEN 'Treatment Question 5'
	WHEN p.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 6 score (observable entity)' THEN 'Treatment Question 6'
	ELSE NULL		
END AS 'Question'
,CASE 
	-- Treatment
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
	--Assessment
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
	--Satifaction
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
END AS 'Answer'

,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlag --Flag for completed treatment flag, where the discharge date is within the reporting period
    
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
INTO [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
FROM [MESH_IAPT].[IDS101referral] r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
	AND ch.Effective_To IS NULL
LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL
--For IET Therapy Type:
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration] i ON i.PathwayID = r.PathwayID
--PEQ Questions and latest answer:
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_PEQRank] p ON p.PathwayID=r.PathwayID AND p.LatestAnswer=1

WHERE l.IsLatest = 1	--To get the latest data
	AND UsePathway_Flag='True'
	AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
	AND r.ReferralRequestReceivedDate BETWEEN @PeriodStart2 AND @PeriodEnd
	AND l.ReportingPeriodStartDate BETWEEN DATEADD(MONTH, @Offset, @PeriodStart) AND @PeriodStart
	
----------------------------------------Aggregated PEQ Table------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_BasePEQ] table to get the number of PathwayIDs with the completed treatment flag.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types 
--(1+ IET, 2+ IET and No IET), by IET Therapy Types, by PEQ Questions and Answers, and by Month.
--Only the latest refreshed month is added each month

--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_PEQ]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
--National, IET 1+
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
--INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer
GO
--National, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer

--National, IET 2+
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer

--Region, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm AS OrgName
,RegionCodeComm AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg
	,Question
	,Answer

--Region, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,Question
	,Answer

--Region, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,Question
	,Answer


--ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer


--ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Provider, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer


--Provider, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Provider, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer
GO


---------------------------------------------------------
---Number of Appointments and Recording of Therapist Time

--------------------------Ranking IET Contacts Table-------------------------------------------------
--This table lists each IET contact for each PathwayID and also ranks them so the latest contact is labelled as 1.
--It is used to produce [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase] in the averages script and [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_IETContacts]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_IETContacts]
SELECT
*
,ROW_NUMBER() OVER(PARTITION BY PathwayID ORDER BY StartDateIntEnabledTherLog desc) as LatestContactRank
INTO [MHDInternal].[TEMP_TTAD_IET_IETContacts]	
FROM(
	SELECT DISTINCT
		i.PathwayID
		,i.StartDateIntEnabledTherLog
		,i.EndDateIntEnabledTherLog
		,i.DurationIntEnabledTher
		,i.Unique_MonthID
		,CASE WHEN (i.IntEnabledTherProg LIKE 'SilverCloud%' OR i.IntEnabledTherProg LIKE  'Slvrcld%' ) THEN 'SilverCloud'
		WHEN (i.IntEnabledTherProg LIKE 'Mnddstrct%' OR i.IntEnabledTherProg LIKE 'Minddistrict%') THEN 'Minddistrict'
		WHEN i.IntEnabledTherProg LIKE 'iCT%' THEN 'iCT'
		WHEN i.IntEnabledTherProg LIKE 'OCD%' THEN 'OCD-NET'
		WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
		END AS IntEnabledTherProg
		--,l.ReportingPeriodStartDate
	FROM [mesh_IAPT].[IDS205internettherlog] i
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON i.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND i.[AuditId] = l.[AuditId]
	WHERE l.IsLatest = 1
)_
------------------------------------------Appts Base table-------------------------------------
--This creates a base table with one record per row which is then aggregated to produce [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--For monthly refresh @periodStart2 should always be set for September 2020 
--The full period is run due to the average tables (which use this base table) recalculating the averages for each quarter
DECLARE @PeriodStart2 DATE
SET @PeriodStart2= '2020-09-01'	 	 

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_BaseAppts]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
SELECT DISTINCT
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,r.PathwayID
	,r.Unique_MonthID

    --Type of IET
	,CASE WHEN ic.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE ic.IntEnabledTherProg
	END AS IntEnabledTherProg
	
	--Therapist Time
	,ic.DurationIntEnabledTher
	,CASE WHEN (ic.DurationIntEnabledTher IS NULL OR ic.DurationIntEnabledTher=0) THEN 'No Therapist Time Recorded'
		WHEN ic.DurationIntEnabledTher>0 THEN 'Therapist Time Recorded'
	END AS TherapistTimeRecorded --Flag for whether IET therapist time was recorded or not

	,ic.StartDateIntEnabledTherLog
	,ic.EndDateIntEnabledTherLog
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
INTO [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
FROM [MESH_IAPT].[IDS101referral] r

INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
	AND ch.Effective_To IS NULL

LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL

LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_IETContacts] ic ON ic.PathwayID = r.PathwayID and ic.Unique_MonthID=r.Unique_MonthID
WHERE r.UsePathway_Flag = 'True' 
	AND l.IsLatest = 1	--To get the latest data
	AND ic.EndDateIntEnabledTherLog BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
	AND l.ReportingPeriodStartDate BETWEEN @PeriodStart2 AND @PeriodStart
	
------------------------------------Aggregate IET Therapist Time Record
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase] table to get the number of PathwayIDs with the completed treatment flag 
--and have an IET therapy type.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Therapist Time Recorded, 
--by IET Therapy Types and Month.
--The full table is re-run each month as base table contains all months
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
--National
SELECT
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,TherapistTimeRecorded
,IntEnabledTherProg
,COUNT(StartDateIntEnabledTherLog) AS NumberofAppointments
INTO [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
FROM [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
WHERE IntEnabledTherProg<>'No IET'
GROUP BY
	Month
	,IntEnabledTherProg
	,TherapistTimeRecorded
GO

--Region
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm AS OrgName
,RegionCodeComm AS OrgCode
,TherapistTimeRecorded
,IntEnabledTherProg
,COUNT(StartDateIntEnabledTherLog) AS NumberofAppointments
FROM [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
WHERE IntEnabledTherProg<>'No IET'
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg
	,TherapistTimeRecorded

--ICB
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,TherapistTimeRecorded
,IntEnabledTherProg
,COUNT(StartDateIntEnabledTherLog) AS NumberofAppointments
FROM [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
WHERE IntEnabledTherProg<>'No IET'
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,TherapistTimeRecorded

--Sub-ICB
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,TherapistTimeRecorded
,IntEnabledTherProg
,COUNT(StartDateIntEnabledTherLog) AS NumberofAppointments
FROM [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
WHERE IntEnabledTherProg<>'No IET'
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,TherapistTimeRecorded

--Provider
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_IETTherapistTimeRecord]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,TherapistTimeRecorded
,IntEnabledTherProg
,COUNT(StartDateIntEnabledTherLog) AS NumberofAppointments
FROM [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
WHERE IntEnabledTherProg<>'No IET'
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,TherapistTimeRecorded
