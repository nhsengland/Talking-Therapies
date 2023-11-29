SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for: [MHDInternal].[DASHBOARD_TTAD_Averages] -----------------------------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------
--There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each sexual orientation code based on the SocPerCircumstanceRecDate 
--so that the latest record of a sexual orientation is labelled as 1. Only records with a SocPerCircumstanceLatest=1 are used in the queries to produce 
--[MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base] table

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_Averages_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SocPerCircRank]
SELECT *
	,ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] desc, SocPerCircumstanceRank asc) as SocPerCircumstanceLatest
	--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SocPerCircRank]
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

----------------------------------------------------------------------------------------------------------
-- Base table: Finished Treatment ------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
SELECT DISTINCT
		CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
		,r.PathwayID 
		,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN mpi.Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' 
		END AS 'Ethnicity'
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown'
		END AS 'Age'
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR mpi.Gender IS NULL THEN 'Unspecified' 
		END AS 'Gender'
		,CASE WHEN spc.SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN spc.SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN spc.SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN spc.SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN spc.SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN spc.SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN spc.SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN spc.SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN spc.SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN spc.SocPerCircumstance = '766822004' THEN 'Confusion'
		END AS 'SexualOrientation'
		,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR r.[PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR r.[PrimaryPresentingComplaint] = 'Unspecified' THEN 'Unspecified'
			WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR r.[PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR r.[PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR r.[PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR r.[SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR r.[SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR r.[SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR r.[SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR r.[SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR r.[SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR r.[SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR r.[SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR r.[SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR r.[SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR r.[SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
			WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR r.[SecondaryPresentingComplaint] IS NULL) THEN 'No Code'
			ELSE 'Other' 
		END AS 'ProblemDescriptor'
		,r.TreatmentCareContact_Count
		,r.PHQ9_FirstScore
		,r.GAD_FirstScore
		,IMD.[IMD_Decile]
		,DATEDIFF(dd,r.[ReferralRequestReceivedDate],r.[TherapySession_FirstDate]) AS RefFirstWait
		,DATEDIFF(dd,r.[TherapySession_FirstDate],r.[TherapySession_SecondDate]) AS FirstSecondWait
		,CASE WHEN r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS 'Finished Treatment - 2 or more Apps' --Filters below for ServDischDate being between reporting period and TreatmentCareContact_Count>1 mean each PathwayID in this table meet this criteria
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

INTO	[MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
		
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL
		--------------------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
			AND spc.SocPerCircumstanceLatest=1
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] AND [Effective_Snapshot_Date] = '2015-12-31' -- to match reference table used in NCDR

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = '1'
		AND r.TreatmentCareContact_Count > 1 
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -34, @PeriodStart) AND @PeriodStart --For monthly refreshes this should be 0 so just the latest month is run
		AND r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]

----------------------------------------------------------------------------------------------------------
-- Base table: First Treatment ---------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
SELECT DISTINCT 

		CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
		,r.PathwayID
		,DATEDIFF(dd,r.[ReferralRequestReceivedDate],r.[TherapySession_FirstDate]) AS Reftofirst
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,CASE WHEN r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS EnteringTreatment --The filter below for TherapySession_FirstDate being between Reporting Period Start and End Date means each PathwayID in this table meet the criteria
INTO	[MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		------------------------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
		
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = '1'
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -34, @PeriodStart) AND @PeriodStart --For monthly refreshes this should be 0 so just the latest month is run
		AND r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]
GO

-------------------------------------------------------------------------------------------------------------------------------------------------
-- National ----------------------------------------------------------------------------------------------------------------------

-- NationalMedianApps
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianApps]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS Category
	,'Total' AS Variable
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY Month) AS MedianApps
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GO

-- NationalMeanApps 
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
--National, Total
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,CAST('Total' AS VARCHAR(100)) AS Category
	,CAST('Total' AS VARCHAR(255)) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY
	Month
GO

--National, Ethnicity
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
SELECT DISTINCT Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS Category
	,[Ethnicity] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Ethnicity]

--National, Age
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Age' AS Category
	,[Age] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,Age

--National, Gender
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Gender' AS Category
	,[Gender] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Gender]
	
--National, Problem Descriptor
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[ProblemDescriptor]
			

--National, Deprivation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Deprivation' AS Category
	,CAST([IMD_Decile] AS Varchar) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,CAST([IMD_Decile] AS Varchar)

--National, Sexual Orientation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
	SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Sexual Orientation' AS Category
	,[SexualOrientation] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,SexualOrientation

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- National Wait Times ------------------------------------------------------------------------------------------------------------------------------------------

-- National Median Wait ---------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianWait]
SELECT DISTINCT 
	Month
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY Month) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GO

-- National Mean Wait -----------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanWait]
SELECT DISTINCT 
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait
	,SUM(EnteringTreatment) AS EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GROUP BY 
	Month
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Region -----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--Region Median Apps
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY Month,[Region code]) AS MedianApps
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]

-- Region Mean Apps
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
--Region, Total
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,CAST('Total' AS VARCHAR(100)) AS Category
	,CAST('Total'AS VARCHAR(255)) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Region Code]
	,[Region Name]
GO

--Region, Ethnicity
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS Category
	,[Ethnicity] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Ethnicity]
	,[Region Code]
	,[Region Name]

--Region, Age
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Age' AS Category
	,[Age] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Age]
	,[Region Code]
	,[Region Name]

--Region, Gender
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Gender' AS Category
	,[Gender] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Gender]
	,[Region Code]
	,[Region Name]
		
--Region, Problem Descriptor
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[ProblemDescriptor]
	,[Region Code]
	,[Region Name]

--Region, Deprivation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Deprivation' AS Category
	,CAST([IMD_Decile] AS Varchar) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,CAST([IMD_Decile] AS Varchar)
	,[Region Code]
	,[Region Name]

--Region, Sexual Orientation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Sexual Orientation' AS Category
	,[SexualOrientation] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,SexualOrientation
	,[Region Code]
	,[Region Name]

-- Region Median Wait ------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianWait]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY Month,[Region Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]

--------------------
-- Region Mean Wait ------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanWait]
SELECT DISTINCT 
	Month
	,'Region' AS 'Level'
	,'Refresh' AS DataSource
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait
	,SUM(EnteringTreatment) AS EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GROUP BY 
	Month
	,[Region Code]
	,[Region Name]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ICB -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ICB Median Apps ----------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY Month,[STP Code]) AS MedianApps
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GO

-- ICB Mean Apps -------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
--ICB, Total
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,CAST('Total' AS VARCHAR(100)) AS Category
	,CAST('Total' AS VARCHAR(255)) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[STP Code]
	,[STP Name]
GO
--ICB, Ethnicity
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Ethnicity' AS Category
	,[Ethnicity] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Ethnicity]
	,[STP Code]
	,[STP Name] 

--ICB, Age
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Age' AS Category
	,[Age] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Age]
	,[STP Code]
	,[STP Name]

--ICB, Gender
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Gender' AS Category
	,[Gender] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Gender]
	,[STP Code]
	,[STP Name]
		
--ICB, Problem Descriptor
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[ProblemDescriptor] 
	,[STP Code]
	,[STP Name]

--ICB, Deprivation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Deprivation' AS Category
	,CAST([IMD_Decile] AS Varchar) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[STP Code]
		,[STP Name]

--ICB, Sexual Orientation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Sexual Orientation' AS Category
	,[SexualOrientation] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[SexualOrientation]
	,[STP Code]
	,[STP Name]
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ICB Median Wait ---------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianWait]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY Month,[STP Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GO
-- ICB Mean Wait ---------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanWait]
SELECT DISTINCT 
	Month
	,'STP' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait
	,SUM(EnteringTreatment) AS EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GROUP BY 
	[Month]
	,[STP Code]
	,[STP Name]

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sub-ICB -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sub-ICB Median Appointments ---------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY Month,[CCG Code]) AS MedianApps
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GO
-- Sub-ICB Mean Appointments ------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
--Sub-ICB, Total
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,CAST('Total' AS VARCHAR(100)) AS Category
	,CAST('Total' AS VARCHAR(255)) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps] 
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	[Month]
	,[CCG Code]
	,[CCG Name]
GO

--Sub-ICB, Ethnicity
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS Category
	,[Ethnicity] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month	
	,Ethnicity
	,[CCG Code]
	,[CCG Name]

--Sub-ICB, Age
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Age' AS Category
	,[Age] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Age]
	,[CCG Code]
	,[CCG Name]

--Sub-ICB, Gender
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Gender' AS Category
	,[Gender] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Gender]
	,[CCG Code]
	,[CCG Name]
		
--Sub-ICB, Problem Descriptor
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[ProblemDescriptor]
	,[CCG Code]
	,[CCG Name]

--Sub-ICB, Deprivation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Deprivation' AS Category
	,CAST([IMD_Decile] AS Varchar) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,CAST([IMD_Decile] AS Varchar)
	,[CCG Code]
	,[CCG Name]

--Sub-ICB, Sexual Orientation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Sexual Orientation' AS Category
	,[SexualOrientation] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[SexualOrientation]
	,[CCG Code]
	,[CCG Name]

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sub-ICB Median Wait -----------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianWait]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY Month,[CCG Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]

-- Sub-ICB Mean Wait -----------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanWait]
SELECT DISTINCT 
	Month
	,'CCG' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait
	,SUM(EnteringTreatment) AS EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GROUP BY 
	Month
	,[CCG Code]
	,[CCG Name]



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider --------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider Median Apps --------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY Month,[Provider Code]) AS MedianApps
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]

----------------------------------------------------------------------
--Provider Mean Apps
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
--Provider, Total
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,CAST('Total' AS VARCHAR(100)) AS Category
	,CAST('Total' AS VARCHAR(255)) AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Provider Code]
	,[Provider Name] 
GO
--Provider, Ethnicity
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS Category
	,[Ethnicity] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Ethnicity]
	,[Provider Code]
	,[Provider Name] 

--Provider, Age
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Age' AS Category
	,[Age] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY
	Month
	,[Age]
	,[Provider Code]
	,[Provider Name]

--Provider, Gender
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Gender' AS Category
	,[Gender] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[Gender] 
	,[Provider Code]
	,[Provider Name] 
		
--Provider, Problem Descriptor
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,[ProblemDescriptor]
	,[Provider Code]
	,[Provider Name] 

--Provider, Deprivation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Deprivation' AS Category
	,CAST([IMD_Decile] AS Varchar) AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY 
	Month
	,CAST([IMD_Decile] AS Varchar)
	,[Provider Code]
	,[Provider Name] 

--Provider, Sexual Orientation
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Sexual Orientation' AS Category
	,[SexualOrientation] AS 'Variable'
	,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
	,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
	,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
	,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
	,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
GROUP BY
	Month
	,[SexualOrientation]
	,[Provider Code]
	,[Provider Name]

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider Median Wait --------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianWait]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY Month,[Provider Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]

-- Provider Mean Wait --------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanWait]
SELECT DISTINCT 
	Month
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait
	,SUM(EnteringTreatment) AS EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]
GROUP BY
	Month
	,[Provider Code] 
	,[Provider Name]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Unsuppressed Final Table -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
--National
SELECT DISTINCT	
		a.[Month]
		,a.[Level]
		,a.[DataSource]
		,CAST(a.[Region Code] AS VARCHAR(100)) AS [Region Code]
		,CAST(a.[Region Name] AS VARCHAR(255)) AS [Region Name]
		,CAST(a.[CCG Code] AS VARCHAR(100)) AS [CCG Code]
		,CAST(a.[CCG Name] AS VARCHAR(255)) AS [CCG Name]
		,CAST(a.[Provider Code] AS VARCHAR(100)) AS [Provider Code]
		,CAST(a.[Provider Name] AS VARCHAR(255)) AS [Provider Name]
		,CAST(a.[STP Code] AS VARCHAR(100)) AS [STP Code]
		,CAST(a.[STP Name] AS VARCHAR(255)) AS [STP Name]
		,CAST(a.[Category] AS VARCHAR(100)) AS [Category]
		,CAST(a.[Variable] AS VARCHAR(255)) AS [Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps]
		,a.[MeanFirstWaitFinished]
		,a.[MeanSecondWaitFinished]
		,a.[MeanFirstPHQ9Finished]
		,a.[MeanFirstGAD7Finished]
		,a.[Finished Treatment - 2 or more Apps]
		,b.EnteringTreatment
INTO [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps] a
--------------------
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanWait] b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianWait] c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianApps] d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]
GO
--Region
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
SELECT DISTINCT	
	a.[Month]
	,a.[Level]
	,a.[DataSource]
	,a.[Region Code]
	,a.[Region Name]
	,a.[CCG Code]
	,a.[CCG Name]
	,a.[Provider Code]
	,a.[Provider Name]
	,a.[STP Code]
	,a.[STP Name]
	,a.[Category]
	,a.[Variable]
	,d.[MedianApps]
	,b.[MeanWait]
	,c.[MedianWait]
	,a.[MeanApps]
	,a.[MeanFirstWaitFinished]
	,a.[MeanSecondWaitFinished]
	,a.[MeanFirstPHQ9Finished]
	,a.[MeanFirstGAD7Finished]
	,a.[Finished Treatment - 2 or more Apps]
	,b.EnteringTreatment
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps] a
-------------------
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanWait] b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianWait] c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianApps] d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

--ICB
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
SELECT DISTINCT	
	a.[Month]
	,a.[Level]
	,a.[DataSource]
	,a.[Region Code]
	,a.[Region Name]
	,a.[CCG Code]
	,a.[CCG Name]
	,a.[Provider Code]
	,a.[Provider Name]
	,a.[STP Code]
	,a.[STP Name]
	,a.[Category]
	,a.[Variable]
	,d.[MedianApps]
	,b.[MeanWait]
	,c.[MedianWait]
	,a.[MeanApps]
	,a.[MeanFirstWaitFinished]
	,a.[MeanSecondWaitFinished]
	,a.[MeanFirstPHQ9Finished]
	,a.[MeanFirstGAD7Finished]
	,a.[Finished Treatment - 2 or more Apps]
	,b.EnteringTreatment
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps] a
---------------
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanWait] b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianWait] c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianApps] d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

--Sub-ICB
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
SELECT DISTINCT	
	a.[Month]
	,a.[Level]
	,a.[DataSource]
	,a.[Region Code]
	,a.[Region Name]
	,a.[CCG Code]
	,a.[CCG Name]
	,a.[Provider Code]
	,a.[Provider Name]
	,a.[STP Code]
	,a.[STP Name]
	,a.[Category]
	,a.[Variable]
	,d.[MedianApps]
	,b.[MeanWait]
	,c.[MedianWait]
	,a.[MeanApps]
	,a.[MeanFirstWaitFinished]
	,a.[MeanSecondWaitFinished]
	,a.[MeanFirstPHQ9Finished]
	,a.[MeanFirstGAD7Finished]
	,a.[Finished Treatment - 2 or more Apps]
	,b.EnteringTreatment
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps] a
---------------
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanWait] b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianWait] c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianApps] d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

--Provider
INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
SELECT DISTINCT	
	a.[Month]
	,a.[Level]
	,a.[DataSource]
	,a.[Region Code]
	,a.[Region Name]
	,a.[CCG Code]
	,a.[CCG Name]
	,a.[Provider Code]
	,a.[Provider Name]
	,a.[STP Code]
	,a.[STP Name]
	,a.[Category]
	,a.[Variable]
	,d.[MedianApps]
	,b.[MeanWait]
	,c.[MedianWait]
	,a.[MeanApps]
	,a.[MeanFirstWaitFinished]
	,a.[MeanSecondWaitFinished]
	,a.[MeanFirstPHQ9Finished]
	,a.[MeanFirstGAD7Finished]
	,a.[Finished Treatment - 2 or more Apps]
	,b.EnteringTreatment
FROM [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]  a
----------------------
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanWait] b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianWait] c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianApps] d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

-------------------------------------------------------------------------------------------------
-- Rounding & Supression ------------------------------------------------------------------------
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_Averages]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_Averages]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_Averages]
SELECT 
	[Month]
	,[Level]
	,[DataSource]
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Category]
	,[Variable]

	,ROUND([MedianWait],1) AS [MedianWait]
	,ROUND(MeanWait,1) AS [MeanWait]

	,ROUND([MedianApps],1) AS [MedianApps] 
	,ROUND([MeanApps],1) AS [MeanApps]

	,ROUND([MeanFirstWaitFinished],1) AS [MeanFirstWaitFinished] 
	,ROUND([MeanSecondWaitFinished],1) AS [MeanSecondWaitFinished]
	,ROUND([MeanFirstPHQ9Finished],1) AS [MeanFirstPHQ9Finished]
	,ROUND([MeanFirstGAD7Finished],1) AS [MeanFirstGAD7Finished]
--INTO [MHDInternal].[DASHBOARD_TTAD_Averages]
FROM [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
WHERE Level='National'
GO

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_Averages]
SELECT
	[Month]
	,[Level]
	,[DataSource]
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Category]
	,[Variable]

	,CASE WHEN EnteringTreatment<5 THEN NULL ELSE ROUND([MedianWait],1) END AS [MedianWait]
	,CASE WHEN EnteringTreatment<5 THEN NULL ELSE ROUND(MeanWait,1) END AS [MeanWait]

	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MedianApps],1) END AS [MedianApps] 
	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MeanApps],1) END AS [MeanApps]
	
	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MeanFirstWaitFinished],1) END AS [MeanFirstWaitFinished]
	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MeanSecondWaitFinished],1) END AS [MeanSecondWaitFinished]
	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MeanFirstPHQ9Finished],1) END AS [MeanFirstPHQ9Finished]
	,CASE WHEN [Finished Treatment - 2 or more Apps]<5 THEN NULL ELSE ROUND([MeanFirstGAD7Finished],1) END AS [MeanFirstGAD7Finished]
FROM [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
WHERE Level<>'National'

-------------------------------------------------
--Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SocPerCircRank]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_FinishedTreatment]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_FirstTreatment]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMedianWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_NationalMeanWait]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMedianWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_RegionMeanWait]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMedianWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ICBMeanWait]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMedianWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_SubICBMeanWait]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMedianWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Averages_ProviderMeanWait]

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AveragesUnsuppressed]
-------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_Averages]'
