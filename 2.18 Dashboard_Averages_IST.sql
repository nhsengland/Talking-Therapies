SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for: [MHDInternal].[DASHBOARD_TTAD_Averages] -----------------------------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Drop temp tables ----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Finishedtreatment') IS NOT NULL DROP TABLE #FinishedTreatment
IF OBJECT_ID ('tempdb..#FinishedtreatmentSexOri') IS NOT NULL DROP TABLE #FinishedTreatmentSexOri
IF OBJECT_ID ('tempdb..#FirstTreatment') IS NOT NULL DROP TABLE #FirstTreatment
IF OBJECT_ID ('tempdb..#NationalMedianApps') IS NOT NULL DROP TABLE #NationalMedianApps
IF OBJECT_ID ('tempdb..#NationalMeanApps') IS NOT NULL DROP TABLE #NationalMeanApps
IF OBJECT_ID ('tempdb..#NationalMeanWait') IS NOT NULL DROP TABLE #NationalMeanWait
IF OBJECT_ID ('tempdb..#NationalMedianWait') IS NOT NULL DROP TABLE #NationalMedianWait
IF OBJECT_ID ('tempdb..#CCGMedianApps') IS NOT NULL DROP TABLE #CCGMedianApps
IF OBJECT_ID ('tempdb..#CCGMeanApps') IS NOT NULL DROP TABLE #CCGMeanApps
IF OBJECT_ID ('tempdb..#CCGMeanWait') IS NOT NULL DROP TABLE #CCGMeanWait
IF OBJECT_ID ('tempdb..#CCGMedianWait') IS NOT NULL DROP TABLE #CCGMedianWait
IF OBJECT_ID ('tempdb..#ProviderMedianApps') IS NOT NULL DROP TABLE #ProviderMedianApps
IF OBJECT_ID ('tempdb..#ProviderMeanApps') IS NOT NULL DROP TABLE #ProviderMeanApps
IF OBJECT_ID ('tempdb..#ProviderMeanWait') IS NOT NULL DROP TABLE #ProviderMeanWait
IF OBJECT_ID ('tempdb..#ProviderMedianWait') IS NOT NULL DROP TABLE #ProviderMedianWait
IF OBJECT_ID ('tempdb..#ProviderCCGMedianApps') IS NOT NULL DROP TABLE #ProviderCCGMedianApps
IF OBJECT_ID ('tempdb..#ProviderCCGMeanApps') IS NOT NULL DROP TABLE #ProviderCCGMeanApps
IF OBJECT_ID ('tempdb..#ProviderCCGMeanWait') IS NOT NULL DROP TABLE #ProviderCCGMeanWait
IF OBJECT_ID ('tempdb..#ProviderCCGMedianWait') IS NOT NULL DROP TABLE #ProviderCCGMedianWait
IF OBJECT_ID ('tempdb..#RegionMedianApps') IS NOT NULL DROP TABLE #RegionMedianApps
IF OBJECT_ID ('tempdb..#RegionMeanApps') IS NOT NULL DROP TABLE #RegionMeanApps
IF OBJECT_ID ('tempdb..#RegionMeanWait') IS NOT NULL DROP TABLE #RegionMeanWait
IF OBJECT_ID ('tempdb..#RegionMedianWait') IS NOT NULL DROP TABLE #RegionMedianWait
IF OBJECT_ID ('tempdb..#STPMedianApps') IS NOT NULL DROP TABLE #STPMedianApps
IF OBJECT_ID ('tempdb..#STPMeanApps') IS NOT NULL DROP TABLE #STPMeanApps
IF OBJECT_ID ('tempdb..#STPMeanWait') IS NOT NULL DROP TABLE #STPMeanWait
IF OBJECT_ID ('tempdb..#STPMedianWait') IS NOT NULL DROP TABLE #STPMedianWait

----------------------------------------------------------------------------------------------------------
-- Base table: Finished Treatment ------------------------------------------------------------------------

SELECT DISTINCT 
		
		@MonthYear AS 'Month'
		,r.PathwayID 
		,Validated_EthnicCategory
		,Age_ReferralRequest_ReceivedDate
		,Gender
		,PrimaryPresentingComplaint
		,SecondaryPresentingComplaint
		,TreatmentCareContact_Count
		,PHQ9_FirstScore
		,GAD_FirstScore
		,[IMD_Decile]
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS RefFirstWait
		,DATEDIFF(dd,[TherapySession_FirstDate],[TherapySession_SecondDate]) AS FirstSecondWait 
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

INTO	 #FinishedTreatment

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND l.IsLatest = '1'
		AND TreatmentCareContact_Count > 1 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd

----------------------------------------------------------------------------------------------------------
-- Base table: Finished Treatment Sexual Orientation -----------------------------------------------------

SELECT DISTINCT 
		
		@MonthYear AS 'Month'
		,r.PathwayID 
		,SocPerCircumstance
		,SecondaryPresentingComplaint
		,TreatmentCareContact_Count
		,PHQ9_FirstScore
		,GAD_FirstScore
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS RefFirstWait
		,DATEDIFF(dd,[TherapySession_FirstDate],[TherapySession_SecondDate]) AS FirstSecondWait 
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

INTO	#FinishedTreatmentSexOri

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		------------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		------------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND l.IsLatest = '1'
		AND TreatmentCareContact_Count > 1 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND SocPerCircumstance IN('20430005', '89217008', '76102007', '38628009', '42035005', '1064711000000100', '699042003', '765288000', '440583007', '766822004')

----------------------------------------------------------------------------------------------------------
-- Base table: First Treatment ---------------------------------------------------------------------------

SELECT DISTINCT 

		@MonthYear AS 'Month'
		,r.PathwayID
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS Reftofirst
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

INTO	#FirstTreatment

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		------------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND l.IsLatest = '1'
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [TherapySession_FirstDate] BETWEEN @PeriodStart AND @PeriodEnd

-------------------------------------------------------------------------------------------------------------------------------------------------
-- National level averages ----------------------------------------------------------------------------------------------------------------------

-- #NationalMedianApps

SELECT DISTINCT 

		Month
		,'National' AS 'Level'
		,'Refresh' AS DataSource
		,'All' AS 'Region Code','All' AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER()AS MedianApps

INTO #NationalMedianApps FROM #FinishedTreatment

-- #NationalMeanApps 

SELECT * INTO #NationalMeanApps 

FROM (

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month

UNION --------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Ethnicity' AS Category
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION --------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Age' AS Category
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
				WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
				WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
				WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
				ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unknown' END 

UNION --------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Gender' AS Category
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' 
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END
		
UNION --------------------------------------------------------------------- ---------------

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
				,'Problem Descriptor' AS Category
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END 

UNION --------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)

UNION --------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'CCG Code'
				,'All' AS 'CCG Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Sexual Orientation' AS Category
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
					WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
					WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
					WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
					WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
					WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
					WHEN SocPerCircumstance = '699042003' THEN 'Declined'
					WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
					WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
					WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
				END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion' END
			
)_

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Wait times ------------------------------------------------------------------------------------------------------------------------------------------

-- National mean wait -----------------
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

INTO	#NationalMeanWait 

FROM	#FirstTreatment

GROUP BY Month

-- National median wait ---------------------------------------------------------------------------

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
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER()AS MedianWait

INTO #NationalMedianWait FROM #FirstTreatment

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SUB ICBs -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SUB ICB median apps ---------------------------------------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY [CCG Code]) AS MedianApps

INTO #CCGMedianApps FROM #FinishedTreatment

-- SUB ICB mean apps ------------------------------------------------------------------------------

SELECT * INTO #CCGMeanApps FROM (

SELECT DISTINCT Month
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY [Month], [CCG Code],[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 
		,[CCG Code]
		,[CCG Name]

UNION --------------------------------------------------------------------- 

SELECT DISTINCT Month
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
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unknown' END 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' 
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END 
		,[CCG Code]
		,[CCG Name]
		
UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
					WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
					WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
					WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
					WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
					WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
					WHEN SocPerCircumstance = '699042003' THEN 'Declined'
					WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
					WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
					WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
				END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion' END 
		,[CCG Code]
		,[CCG Name]
)_

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SUB ICB mean Wait -----------------------------------------------

SELECT DISTINCT Month
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

INTO #CCGMeanWait FROM #FirstTreatment

GROUP BY Month
		,[CCG Code]
		,[CCG Name]

-- SUB ICB median wait -----------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY [CCG Code]) AS MedianWait

INTO #CCGMedianWait FROM #FirstTreatment

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- REGIONAL

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY [Region code]) AS MedianApps

INTO #RegionMedianApps FROM #FinishedTreatment

SELECT * INTO #RegionMeanApps FROM (

SELECT DISTINCT Month
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,[Region Code]
		,[Region Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
				WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
				WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
				WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
				WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
				WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END 
		,[Region Code]
		,[Region Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
				ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown' END , [Region Code], [Region Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
				WHEN Gender IN ('2','02') THEN 'Female'
				WHEN Gender IN ('9','09') THEN 'Indeterminate'
				WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END
		,[Region Code]
		,[Region Name]
		
UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END , [Region Code], [Region Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[Region Code]
		,[Region Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
					WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
					WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
					WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
					WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
					WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
					WHEN SocPerCircumstance = '699042003' THEN 'Declined'
					WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
					WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
					WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
				END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
			END
		,[Region Code]
		,[Region Name]
)_

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Region mean wait ------------------------------------------------------------------------------------------

SELECT DISTINCT Month
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

INTO #RegionMeanWait FROM #FirstTreatment

GROUP BY Month
		,[Region Code]
		,[Region Name]

-- Region median wait ------------------------------------------------------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY [Region Code]) AS MedianWait

INTO #RegionMedianWait FROM #FirstTreatment

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider --------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provider median apps --------------------------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY [Provider Code]) AS MedianApps

INTO #ProviderMedianApps FROM #FinishedTreatment

SELECT * INTO #ProviderMeanApps FROM (

SELECT DISTINCT Month
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,[Provider Code]
		,[Provider Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END 
		,[Provider Code]
		,[Provider Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
				ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown' END 
		,[Provider Code]
		,[Provider Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END 
		,[Provider Code]
		,[Provider Name] 
		
UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END 
		,[Provider Code]
		,[Provider Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[Provider Code]
		,[Provider Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
					WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
					WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
					WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
					WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
					WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
					WHEN SocPerCircumstance = '699042003' THEN 'Declined'
					WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
					WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
					WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
					END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
			END 
		,[Provider Code]
		,[Provider Name] 
)_

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provider mean wait --------------------------------------------------------------------------------------

SELECT DISTINCT Month
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

INTO #ProviderMeanWait FROM #FirstTreatment 

GROUP BY Month
		,[Provider Code] 
		,[Provider Name] 

-- Provider median wait --------------------------------------------------------------------------------------


SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY [Provider Code]) AS MedianWait

INTO #ProviderMedianWait FROM #FirstTreatment

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider/SUB ICB ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provider/SUB ICB median apps -----------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY [Provider Code],[CCG Code]) AS MedianApps

INTO #ProviderCCGMedianApps FROM #FinishedTreatment

-- Provider/SUB ICB mean apps -----------------------------------------------------------

SELECT * INTO #ProviderCCGMeanApps FROM (

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,[Provider Code] 
		,[Provider Name]
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Ethnicity' AS Category
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END 
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Age' AS Category
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
				WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
				WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
				WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
				ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown' END 
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Gender' AS Category
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
				WHEN Gender IN ('2','02') THEN 'Female'
				WHEN Gender IN ('9','09') THEN 'Indeterminate'
				WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END 
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]
		
UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Problem Descriptor' AS Category
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END 
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Sexual Orientation' AS Category
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
					WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
					WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
					WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
					WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
					WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
					WHEN SocPerCircumstance = '699042003' THEN 'Declined'
					WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
					WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
					WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
					END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY [Month], CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						END ,[Provider Code], [Provider Name], [CCG Code], [CCG Name]
)_

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provider SUB ICB mean wait ----------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,ROUND(AVG(CAST(Reftofirst AS DECIMAL)),1) AS MeanWait

INTO #ProviderCCGMeanWait FROM #FirstTreatment

GROUP BY Month
		,[Provider Code] 
		,[Provider Name] 
		,[CCG Code]
		,[CCG Name]

SELECT DISTINCT Month
				,'CCG/ Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[CCG Code] AS 'CCG Code'
				,[CCG Name] AS 'CCG Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'STP Code'
				,'All' AS 'STP Name'
				,'Total' AS 'Category'
				,'Total' AS 'Variable'
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY [Provider Code],[CCG Code]) AS MedianWait

INTO #ProviderCCGMedianWait FROM #FirstTreatment

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ICB -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ICB mean apps ----------------------------------------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TreatmentCareContact_Count) OVER(PARTITION BY [STP Code]) AS MedianApps

INTO #STPMedianApps FROM #FinishedTreatment

-- ICB median apps -------------------------------------------------------------------------

SELECT * INTO #STPMeanApps FROM (

SELECT DISTINCT Month
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,[STP Code]
		,[STP Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END
		,[STP Code]
		,[STP Name] 

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
				ELSE 'Unknown'
				END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown' END 
		,[STP Code]
		,[STP Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END
		,[STP Code]
		,[STP Name]
		
UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
					WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
					WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
					WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
					WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
					WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END 
		,[STP Code]
		,[STP Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,'IMD' AS Category
				,CAST([IMD_Decile] AS Varchar) AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatment

GROUP BY Month
		,CAST([IMD_Decile] AS Varchar)
		,[STP Code]
		,[STP Name]

UNION ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
							WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
							WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
							WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
							WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
							WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
							WHEN SocPerCircumstance = '699042003' THEN 'Declined'
							WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
							WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
							WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
							END as 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished

FROM #FinishedTreatmentSexOri

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or is not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
			END
		,[STP Code]
		,[STP Name]
)_

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ICB mean wait ---------------------------------------------------------------------

SELECT DISTINCT Month
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

INTO #STPMeanWait FROM #FirstTreatment

GROUP BY [Month],[STP Code],[STP Name]

-- ICB median wait ---------------------------------------------------------------------

SELECT DISTINCT Month
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
				,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reftofirst) OVER(PARTITION BY [STP Code]) AS MedianWait

INTO #STPMedianWait FROM #FirstTreatment

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Final Table -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_Averages]

SELECT * FROM 

(

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#NationalMeanApps a
		--------------------
		LEFT JOIN #NationalMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #NationalMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #NationalMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

UNION --------------------------------------------------------------------- -----------------------------------------------

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#CCGMeanApps a
		---------------
		LEFT JOIN #CCGMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #CCGMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #CCGMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

UNION --------------------------------------------------------------------- -----------------------------------------------

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#ProviderMeanApps  a
		----------------------
		LEFT JOIN #ProviderMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #ProviderMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #ProviderMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

UNION --------------------------------------------------------------------- -----------------------------------------------

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#ProviderCCGMeanApps a
		-----------------------
		LEFT JOIN #ProviderCCGMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #ProviderCCGMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #ProviderCCGMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

UNION --------------------------------------------------------------------- -----------------------------------------------

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#RegionMeanApps a
		-------------------
		LEFT JOIN #RegionMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #RegionMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #RegionMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

UNION --------------------------------------------------------------------- -----------------------------------------------

SELECT DISTINCT	
		
		a.[Month], a.[Level], a.[DataSource], a.[Region Code], a.[Region Name], a.[CCG Code], a.[CCG Name], a.[Provider Code], a.[Provider Name], a.[STP Code], a.[STP Name], a.[Category], a.[Variable]
		,d.[MedianApps]
		,b.[MeanWait]
		,c.[MedianWait]
		,a.[MeanApps], a.[MeanFirstWaitFinished], a.[MeanSecondWaitFinished], a.[MeanFirstPHQ9Finished], a.[MeanFirstGAD7Finished]

FROM	#STPMeanApps a
		---------------
		LEFT JOIN #STPMeanWait b ON a.[Level] = b.[Level] AND a.[Month] = b.[Month] AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code] AND a.[Region Code] = b.[Region Code] AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] AND a.[Variable] = b.[Variable]
		LEFT JOIN #STPMedianWait c ON a.[Level] = c.[Level] AND a.[Month] = c.[Month] AND a.[CCG Code] = c.[CCG Code] AND a.[Provider Code] = c.[Provider Code] AND a.[Region Code] = c.[Region Code] AND a.[STP Code] = c.[STP Code] AND a.[Category] = c.[Category] AND a.[Variable] = c.[Variable]
		LEFT JOIN #STPMedianApps d ON a.[Level] = d.[Level] AND a.[Month] = d.[Month] AND a.[CCG Code] = d.[CCG Code] AND a.[Provider Code] = d.[Provider Code] AND a.[Region Code] = d.[Region Code] AND a.[STP Code] = d.[STP Code] AND a.[Category] = d.[Category] AND a.[Variable] = d.[Variable]

 )_

 -------------------------------------------------------------------------------------------------
 -- Rounding & Supression ------------------------------------------------------------------------

 IF OBJECT_ID ('tempdb..#Suppress') IS NOT NULL DROP TABLE #Suppress

 SELECT * INTO #Suppress FROM (

 SELECT	Month
		,'Refresh' AS DataSource
		,'England' AS GroupType
		,'All' AS 'Region Code'
		,'All' AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,Category
		,Variable
		,SUM([Finished Treatment - 2 or more Apps]) AS Finished
		,SUM([EnteringTreatment]) AS EnteringTreatment
		,'National' AS 'Level'

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE [Month] = @MonthYear

GROUP BY [Month], [Category], [Variable] 

UNION ---------------------------------------------------------------------------------

SELECT	[Month], 
		'Refresh' AS 'DataSource',
		'England' AS 'GroupType',
		[Region Code] AS 'Region Code',
		[Region Name] AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category],
		[Variable],
		CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT)  END AS [Finished Treatment - 2 or more Apps],
		CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT)  END AS [EnteringTreatment],
		'Region' AS 'Level'

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE [Month] = @MonthYear

GROUP BY [Month], [Region Code], [Region Name], [Category], [Variable] 

UNION ---------------------------------------------------------------------------------

SELECT	[Month], 
		'Refresh' AS 'DataSource',
		'England' AS 'GroupType',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		[STP Code] AS 'ICB Code',
		[STP Name] AS 'ICB Name',
		[Category],
		[Variable],
		CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT)  END AS [Finished Treatment - 2 or more Apps],
		CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT)  END AS [EnteringTreatment],
		'STP' AS 'Level'

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE [Month] = @MonthYear

GROUP BY [Month], [STP Code], [STP Name], [Category], [Variable] 

UNION ---------------------------------------------------------------------------------

SELECT	[Month], 
		'Refresh' AS 'DataSource',
		'England' AS 'GroupType',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'Sub ICB Code',
		[CCG Name] AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category],
		[Variable],
		CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT)  END AS [Finished Treatment - 2 or more Apps],
		CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT)  END AS [EnteringTreatment],
		'CCG' AS 'Level'

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE [Month] = @MonthYear

GROUP BY [Month], [CCG Code], [CCG Name], [Category], [Variable] 

UNION ---------------------------------------------------------------------------------

SELECT	[Month], 
		'Refresh' AS 'DataSource',
		'England' AS 'GroupType',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category],
		[Variable],
		CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT)  END AS [Finished Treatment - 2 or more Apps],
		CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT)  END AS [EnteringTreatment],
		'Provider' AS 'Level'

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE [Month] = @MonthYear

GROUP BY [Month], [Provider Code], [Provider Name], [Category], [Variable] 

UNION ---------------------------------------------------------------------------------

SELECT	[Month], 
		'Refresh' AS 'DataSource',
		'England' AS 'GroupType',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'Sub ICB Code',
		[CCG Name] AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category],
		[Variable],
		CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT)  END AS [Finished Treatment - 2 or more Apps],
		CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT)  END AS [EnteringTreatment],
		'CCG/ Provider' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	[Month] = @MonthYear

GROUP BY [Month], [CCG Code], [CCG Name], [Provider Code], [Provider Name], [Category], [Variable] 

)_

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages] 

SET MeanWait =  CASE WHEN EnteringTreatment IS NULL THEN NULL ELSE MeanWait END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET	MedianApps =  CASE WHEN Finished IS NULL THEN NULL ELSE MedianApps END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE	a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MedianWait =  CASE WHEN EnteringTreatment IS NULL THEN NULL ELSE MedianWait END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE	a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MeanApps =  CASE WHEN Finished IS NULL THEN NULL ELSE MeanApps END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MeanFirstWaitFinished =  CASE WHEN Finished IS NULL THEN NULL ELSE MeanFirstWaitFinished END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MeanSecondWaitFinished =  CASE WHEN Finished IS NULL THEN NULL ELSE MeanSecondWaitFinished END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MeanFirstPHQ9Finished =  CASE WHEN Finished IS NULL THEN NULL ELSE MeanFirstPHQ9Finished END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE a.[Month] = @MonthYear

--------------------------------------------------------------------------
UPDATE [MHDInternal].[DASHBOARD_TTAD_Averages]

SET MeanFirstGAD7Finished  =  CASE WHEN Finished IS NULL THEN NULL ELSE MeanFirstGAD7Finished END

FROM	#Suppress a
		----------
		INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] b ON a.[Level] = b.[Level] 
		AND a.[CCG Code] = b.[CCG Code] 
		AND a.[Month] = b.[Month] 
		AND a.[Provider Code] = b.[Provider Code] 
		AND a.[STP Code] = b.[STP Code] 
		AND a.[Region Code] = b.[Region Code] 
		AND a.[Category] = b.[Category] 
		AND a.[Variable] = b.[Variable]

WHERE	a.[Month] = @MonthYear

-------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_Averages]'
