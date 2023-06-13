USE [NHSE_IAPT_v2]
----------------
SET NOCOUNT ON
SET DATEFIRST 1
SET ANSI_WARNINGS OFF
----------------
DECLARE @Offset INT = -1
--------------------

--------------------------------
--DECLARE @Max_Offset INT = -30
-----------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
-----------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

---------------------------------------------------------------------------------------------------------------------|
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardMainTable] --------------------------|
---------------------------------------------------------------------------------------------------------------------|

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		
		,'Ethnicity - Broad' AS 'Category'
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		END AS 'Variable'
		
		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

		----------------------------------------------------------------------------------------------------

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
			END

UNION ------------------------------------------------------------------------------------------------------------------------------- 

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN Validated_EthnicCategory = 'A' THEN 'White British'
				WHEN Validated_EthnicCategory = 'B' THEN 'White Irish'
				WHEN Validated_EthnicCategory = 'C' THEN 'Any other White background'
				
				WHEN Validated_EthnicCategory = 'D' THEN 'White and Black Caribbean'
				WHEN Validated_EthnicCategory = 'E' THEN 'White and Black African'
				WHEN Validated_EthnicCategory = 'F' THEN 'White and Asian'
				WHEN Validated_EthnicCategory = 'G' THEN 'Any other mixed background'

				WHEN Validated_EthnicCategory = 'H' THEN 'Indian'
				WHEN Validated_EthnicCategory = 'J' THEN 'Pakistani'
				WHEN Validated_EthnicCategory = 'K' THEN 'Bangladeshi'
				WHEN Validated_EthnicCategory = 'L' THEN 'Any other Asian background'

				WHEN Validated_EthnicCategory = 'M' THEN 'Caribbean'
				WHEN Validated_EthnicCategory = 'N' THEN 'African'
				WHEN Validated_EthnicCategory = 'P' THEN 'Any other Black background'

				WHEN Validated_EthnicCategory = 'R' THEN 'Chinese'
				WHEN Validated_EthnicCategory = 'S' THEN 'Any other ethnic group'
				WHEN Validated_EthnicCategory = 'Z' THEN 'Not stated'
				WHEN Validated_EthnicCategory = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END  
		,CASE WHEN Validated_EthnicCategory = 'A' THEN 'White British'
				WHEN Validated_EthnicCategory = 'B' THEN 'White Irish'
				WHEN Validated_EthnicCategory = 'C' THEN 'Any other White background'
				
				WHEN Validated_EthnicCategory = 'D' THEN 'White and Black Caribbean'
				WHEN Validated_EthnicCategory = 'E' THEN 'White and Black African'
				WHEN Validated_EthnicCategory = 'F' THEN 'White and Asian'
				WHEN Validated_EthnicCategory = 'G' THEN 'Any other mixed background'

				WHEN Validated_EthnicCategory = 'H' THEN 'Indian'
				WHEN Validated_EthnicCategory = 'J' THEN 'Pakistani'
				WHEN Validated_EthnicCategory = 'K' THEN 'Bangladeshi'
				WHEN Validated_EthnicCategory = 'L' THEN 'Any other Asian background'

				WHEN Validated_EthnicCategory = 'M' THEN 'Caribbean'
				WHEN Validated_EthnicCategory = 'N' THEN 'African'
				WHEN Validated_EthnicCategory = 'P' THEN 'Any other Black background'

				WHEN Validated_EthnicCategory = 'R' THEN 'Chinese'
				WHEN Validated_EthnicCategory = 'S' THEN 'Any other ethnic group'
				WHEN Validated_EthnicCategory = 'Z' THEN 'Not stated'
				WHEN Validated_EthnicCategory = '99' THEN 'Not known'
			
			ELSE 'Other' 
			END

UNION -------------------------------------------------------------------------------------------------------------------------------

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

		,'Ethnicity - High-level' AS 'Category'
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other'
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other' 
			END

-- Sexual Oritentation --------------------------------------------------------------------------------------------------------------------------------------

UNION -------------------------------------------------------------------------------------------------------------------------------

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

		,'Sexual Orientation' AS 'Category'
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
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
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
		END

-- Age --------------------------------------------------------------------------------------------------------------------------------------

UNION -------------------------------------------------------------------------------------------------------------------------------

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

		,'Age' AS 'Category'
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unspecified'
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unspecified'
		END

-- Gender --------------------------------------------------------------------------------------------------------------------------------------

UNION -------------------------------------------------------------------------------------------------------------------------------

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

		,'Gender' AS 'Category'
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
		END

-- Gender Identity --------------------------------------------------------------------------------------------------------------------------------------

UNION -------------------------------------------------------------------------------------------------------------------------------

SELECT  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

		,'GenderIdentity' AS 'Category'
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
			WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
			WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
		END AS 'Variable'

		-- Key Metrics --
		,COUNT(DISTINCT(CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_Referrals'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'Count_AccessedTreatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '46' THEN a.Unique_CareContactID END)) AS 'Count_EndedCompleted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Recovery'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Improvement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' THEN r.PathwayID END)) AS 'Count_Finished'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN r.PathwayID END)) AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'  AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) AND
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
			   THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([AppliedRelaxation_Count] > 0 OR 
				[BriefPsychodynamicPsychotherapy_Count] > 0 OR 
				[CognitiveBehaviourTherapy_Count] > 0 OR 
				[CollaborativeCare_Count] > 0 OR 
				[CounsellingDepression_Count] > 0 OR 
				[CouplesTherapyDepression_Count] > 0 OR 
				[EmploymentSupport_Count] > 0 OR 
				[EyeMovementDesensitisationReprocessing_Count] > 0 OR 
				[InterpersonalPsychotherapy_Count] > 0 OR 
				[Mindfulness_Count] > 0 OR 
				[OtherHighIntensity_Count] > 0 OR
				[InternetEnabledTherapy_Count] > 0)  
				THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN r.PathwayID END)) AS 'Count_FinishedCourseTreatmentLI'

		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CareContact_Count = '0' THEN r.PathwayID END)) AS 'Count_EndedNotSeen'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND EndCode = '12' THEN r.PathwayID END)) AS 'Count_EndedMutualAgreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND TreatmentCareContact_Count = '1' THEN r.PathwayID END)) AS 'Count_OneTreatment'

		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN r.PathwayID END)) AS 'Count_FirstTreatment_6Weeks'
		,COUNT(DISTINCT(CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN r.PathwayID END)) AS 'Count_FirstTreatment_18Weeks'

		,COUNT(DISTINCT(CASE WHEN TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN r.PathwayID END)) AS 'Count_WaitFirstToSecond_Over90days'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN (GenderIdentity IN ('1') or (Gender IN ('1') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Male (including trans men)'
			WHEN (GenderIdentity IN ('2') or (Gender IN ('2') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Female (including trans women)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN (GenderIdentity NOT IN ('1','2','3','4','x') OR GenderIdentity IS NULL) AND Gender = '9' then 'Indeterminate'
			ELSE 'Not Known/Not Stated'
		END
		
---------------------------------|
--SET @Offset = @Offset -1 END --| <-- End loop
---------------------------------|

------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardMainTable]'
