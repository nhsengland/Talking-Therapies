SET NOCOUNT OFF
-----------------------------------------------------------------------------------------------------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD([Month],@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD([Month],@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

---------------------------------------------------------------------------------------------------------------------|
--INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardMainTable] ---------------------------------|
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
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END,  
		CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other' 
			END

-------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardMainTable]'

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardAveragesTable] ----------------------------------------------------------------------------------------------------

-- Drop temp tables ----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]
IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

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
		,CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_FirstScore END AS WASAS_Work_FirstScore
		,CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore END AS WASAS_Work_LastScore
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS RefFirstWait
		,DATEDIFF(dd,[TherapySession_FirstDate],[TherapySession_SecondDate]) AS FirstSecondWait 
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

INTO	 [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

FROM	[NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		------------------------------------------
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IDS001_MPI] p ON r.recordnumber = p.recordnumber 
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID] i ON r.UniqueSubmissionID = i.UniqueSubmissionID AND r.AuditId = i.AuditId
		------------------------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [NHSE_Sandbox_Policy].[dbo].[IMD_Quintile_2015] IMD ON p.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND i.IsLatest = '1'
		AND CompletedTreatment_Flag = 'True' 
		AND i.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd

----------------------------------------------------------------------------------------------------------
-- Base table: First Treatment ---------------------------------------------------------------------------

SELECT DISTINCT 

		@MonthYear AS 'Month'
		,r.PathwayID
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS Reftofirst
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

INTO	[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]

FROM	[NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		-----------------------------------------
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IDS001_MPI] p ON r.recordnumber = p.recordnumber 
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID] i ON r.UniqueSubmissionID = i.UniqueSubmissionID AND r.AuditId = i.AuditId
		------------------------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND i.IsLatest = '1'
		AND i.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [TherapySession_FirstDate] BETWEEN @PeriodStart AND @PeriodEnd

-------------------------------------------------------------------------------------------------------------------------------------------------
-- National level averages ----------------------------------------------------------------------------------------------------------------------


-- #NationalMeanApps 

INSERT INTO [NHSE_Sandbox_MentalHealth].dbo.IAPT_Ethnicity_DashboardAveragesTable
SELECT *
FROM (

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
				
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
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

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
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
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code','All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

------Sub-ICB

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
				--CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN 
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
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

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
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
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

------Provider

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
				--CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN 
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
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

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
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
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

------ICB

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
				--CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN 
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
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

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
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
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END			

UNION --------------------------------------------------------------------------------------------

------Region

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
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
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
				--CASE WHEN WASAS_Work_LastScore IS NOT NULL THEN 
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Region Code],[Region Name]
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

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
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
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Region Code],[Region Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS DataSource
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST(TreatmentCareContact_Count AS DECIMAL)),1) AS MeanApps
				,ROUND(AVG(CAST(RefFirstWait AS DECIMAL)),1) AS MeanFirstWaitFinished
				,ROUND(AVG(CAST(FirstSecondWait AS DECIMAL)),1) AS MeanSecondWaitFinished
				,ROUND(AVG(CAST(PHQ9_FirstScore AS DECIMAL)),1) AS MeanFirstPHQ9Finished
				,ROUND(AVG(CAST(GAD_FirstScore AS DECIMAL)),1) AS MeanFirstGAD7Finished
				,ROUND(AVG(CAST(WASAS_Work_FirstScore AS DECIMAL)),1) AS Mean_FirstWSASW
				,ROUND(AVG(CAST(WASAS_Work_LastScore AS DECIMAL)),1) AS Mean_LastWSASW
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Region Code],[Region Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN Validated_EthnicCategory = 'A' THEN 'White British'
					ELSE 'Other' 
					END			
)_

----------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardAveragesTable]'
