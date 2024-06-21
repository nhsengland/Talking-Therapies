SET NOCOUNT ON
SET ANSI_WARNINGS OFF

----------------------------------------------------------------------------------------------------------
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[[DASHBOARD_TTAD_ProtChar_Averages_Suppressed])
----------------------------------------------------------------------------------------------------------

----------------------------
DECLARE @Offset INT = 0
----------------------------

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Base]

SELECT DISTINCT

      r.[PathwayID]

      ,CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS DATE) AS 'Month'

      ,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
      ,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
      ,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
      ,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
      ,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
      ,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
      ,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
      ,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		
      -- Ethnicity - Broad
      ,CASE WHEN mpi.Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
            WHEN mpi.Validated_EthnicCategory = 'A' THEN 'White British'
            ELSE 'Other' 
      END AS 'Ethnicity - Broad'

      -- Ethnicity - High-level
      ,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
            WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
            WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
            WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
            WHEN mpi.Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
            WHEN mpi.Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
            ELSE 'Other'
      END AS 'Ethnicity - High-level'

      -- Ethnicity - Detailed
      ,CASE WHEN mpi.Validated_EthnicCategory = 'A' THEN 'White British'
            WHEN mpi.Validated_EthnicCategory = 'B' THEN 'White Irish'
            WHEN mpi.Validated_EthnicCategory = 'C' THEN 'Any other White background'
            
            WHEN mpi.Validated_EthnicCategory = 'D' THEN 'White and Black Caribbean'
            WHEN mpi.Validated_EthnicCategory = 'E' THEN 'White and Black African'
            WHEN mpi.Validated_EthnicCategory = 'F' THEN 'White and Asian'
            WHEN mpi.Validated_EthnicCategory = 'G' THEN 'Any other mixed background'

            WHEN mpi.Validated_EthnicCategory = 'H' THEN 'Indian'
            WHEN mpi.Validated_EthnicCategory = 'J' THEN 'Pakistani'
            WHEN mpi.Validated_EthnicCategory = 'K' THEN 'Bangladeshi'
            WHEN mpi.Validated_EthnicCategory = 'L' THEN 'Any other Asian background'

            WHEN mpi.Validated_EthnicCategory = 'M' THEN 'Caribbean'
            WHEN mpi.Validated_EthnicCategory = 'N' THEN 'African'
            WHEN mpi.Validated_EthnicCategory = 'P' THEN 'Any other Black background'

            WHEN mpi.Validated_EthnicCategory = 'R' THEN 'Chinese'
            WHEN mpi.Validated_EthnicCategory = 'S' THEN 'Any other ethnic group'
            WHEN mpi.Validated_EthnicCategory = 'Z' THEN 'Not stated'
            WHEN mpi.Validated_EthnicCategory = '99' THEN 'Not known'
            ELSE 'Other'
      END AS 'Ethnicity - Detailed'

      -- Age
      ,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
            WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
            WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
            WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
            ELSE 'Unspecified'
      END AS 'Age'

      -- Gender
      ,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
            WHEN mpi.Gender IN ('2','02') THEN 'Female'
            WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
            WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
            WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
      END AS 'Gender'

      -- Gender Identity
      ,CASE WHEN mpi.GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
            WHEN mpi.GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
            WHEN mpi.GenderIdentity IN ('3','03') THEN 'Non-binary'
            WHEN mpi.GenderIdentity IN ('4','04') THEN 'Other (not listed)'
            WHEN mpi.GenderIdentity IN ('x','X') THEN 'Not Known'
            WHEN mpi.GenderIdentity IN ('z','Z') THEN 'Not Stated'
            WHEN mpi.GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR mpi.GenderIdentity IS NULL THEN 'Unspecified'
      END AS 'GenderIdentity'
		
      -- Key Metrics --
      ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_Referrals'
      ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_AccessedTreatment'

      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_Recovery'
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.ReliableImprovement_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_Improvement'
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_ReliableRecovery'
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_Finished'
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.NotCaseness_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
      AS 'Count_NotCaseness'
      
      --Number of treatment courses that included a combination of low and high intensity sessions
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
            ([GuidedSelfHelp_Book_Count] > 0 OR 
            [GuidedSelfHelp_Computer_Count] > 0 OR 
            [NonGuidedSelfHelp_Book_Count] > 0 OR 
            [NonGuidedSelfHelp_Computer_Count] > 0 OR 
            [OtherLowIntensity_Count] > 0 OR 
            [PsychoeducationalPeerSupport_Count] > 0 OR 
            [StructuredPhysicalActivity_Count] > 0 OR 
            [CommunitySignPosting_Count] > 0)
            AND
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
            THEN 1 ELSE 0 END
      AS 'Count_FinishedCourseTreatmentHILI'
      
      --Number of high intensity sessions
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
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
            THEN 1 ELSE 0 END
      AS 'Count_FinishedCourseTreatmentHI'

      --Number of low intensity sessions
      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
            ([GuidedSelfHelp_Book_Count] > 0 OR 
            [GuidedSelfHelp_Computer_Count] > 0 OR 
            [NonGuidedSelfHelp_Book_Count] > 0 OR 
            [NonGuidedSelfHelp_Computer_Count] > 0 OR 
            [OtherLowIntensity_Count] > 0 OR 
            [PsychoeducationalPeerSupport_Count] > 0 OR 
            [StructuredPhysicalActivity_Count] > 0 OR 
            [CommunitySignPosting_Count] > 0) 
            THEN 1 ELSE 0 END
      AS 'Count_FinishedCourseTreatmentLI'

      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND r.CareContact_Count = '0' THEN 1 ELSE 0 END
      AS 'Count_EndedNotSeen'

      ,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND r.TreatmentCareContact_Count = '1' THEN 1 ELSE 0 END
      AS 'Count_OneTreatment'

      ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL 
            AND DATEDIFF(D, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) <= 42 THEN 1 ELSE 0 END
      AS 'Count_FirstTreatment_6Weeks'
      ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL
            AND DATEDIFF(D, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) <= 126 THEN 1 ELSE 0 END
      AS 'Count_FirstTreatment_18Weeks'

      ,CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL
            AND DATEDIFF(D, r.TherapySession_FirstDate, r.TherapySession_SecondDate) > 90 AND r.ServDischDate IS NULL THEN 1 ELSE 0 END
      AS 'Count_WaitFirstToSecond_Over90days'

--For Averages
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN r.[TreatmentCareContact_Count] ELSE NULL END
      AS FinishedTreat_TreatmentCareContact_Count
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN r.[PHQ9_FirstScore] ELSE NULL END
      AS FinishedTreat_PHQ9_FirstScore
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN r.[GAD_FirstScore] ELSE NULL END
      AS FinishedTreat_GAD_FirstScore
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND r.[WASAS_Work_LastScore] IS NOT NULL THEN [WASAS_Work_FirstScore] END
      AS FinishedTreat_WASAS_Work_FirstScore
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND r.[WASAS_Work_LastScore] IS NOT NULL THEN [WASAS_Work_LastScore] END
      AS FinishedTreat_WASAS_Work_LastScore

	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL 
            THEN DATEDIFF(dd, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) ELSE NULL END
      AS FinishedTreat_RefFirstWait
	,CASE WHEN r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL
            THEN DATEDIFF(dd, r.[TherapySession_FirstDate], r.[TherapySession_SecondDate]) ELSE NULL END
      AS FinishedTreat_FirstSecondWait
	----------------------------------------------------------------------------------------------------

INTO [MHDInternal].[TEMP_TTAD_ProtChar_Base]

FROM	[mesh_IAPT].[IDS101referral] r
		-------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		---- Tables for up-to-date Sub-ICB/ICB/Region/Provider names/codes --------------------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		-------------------------
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = 1
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart -- For monthly refresh the offset uses a value of '-1'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------ Averages -------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- National, Ethnicity - Broad ----------------------------------------------------------------------------------------------------------------------------------------------------------------

--IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      [Month]
      ,CAST('National' AS VARCHAR(255)) AS OrganisationType
      ,CAST('All Regions' AS VARCHAR(255)) AS Region
      ,CAST('ENG' AS VARCHAR(255)) AS OrganisationCode
      ,CAST('England' AS VARCHAR(255)) AS OrganisationName
      ,CAST('Ethnicity - Broad' AS VARCHAR(255)) AS Category
      ,CAST([Ethnicity - Broad] AS VARCHAR(255)) AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Ethnicity - Broad]

-- Region, Ethnicity - Broad ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'


FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - Broad]

-- ICB, Ethnicity - Broad ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Broad]

-- Sub-ICB, Ethnicity - Broad ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - Broad]

-- National, Ethnicity - High-level ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Ethnicity - High-Level' AS Category
      ,[Ethnicity - High-Level] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Ethnicity - High-Level]

-- Region, Ethnicity - High-level ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Ethnicity - High-Level' AS Category
      ,[Ethnicity - High-Level] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - High-Level]

-- ICB, Ethnicity - High-level ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Ethnicity - High-Level' AS Category
      ,[Ethnicity - High-Level] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - High-Level]

-- Sub-ICB, Ethnicity - High-level ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed] 

SELECT 
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Ethnicity - High-Level' AS Category
      ,[Ethnicity - High-Level] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - High-Level]

-- National, Ethnicity - Detailed ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT  
      [Month]
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Ethnicity - Detailed]

-- Region, Ethnicity - Detailed ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT  
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - Detailed]

-- ICB, Ethnicity - Detailed ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT  
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Detailed]

-- Sub-ICB, Ethnicity - Detailed ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT  
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - Detailed]

-- National, Age ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Age' AS Category
      ,[Age] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Age]

-- Region, Age ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Age' AS Category
      ,[Age] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Age]

-- ICB, Age ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Age' AS Category
      ,[Age] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Age]

-- Sub-ICB, Age ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Age' AS Category
      ,[Age] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Age]

-- National, Gender ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Gender' AS Category
      ,[Gender] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Gender]

-- Region, Gender ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Gender' AS Category
      ,[Gender] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Gender]

-- ICB, Gender ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Gender' AS Category
      ,[Gender] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Gender]

-- Sub-ICB, Gender ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Gender' AS Category
	  ,[Gender] AS Variable
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Gender]

-- National, Gender Identity ------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Gender Identity' AS [Category]
      ,[GenderIdentity] AS 'Variable'
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY
      [Month]
      ,[GenderIdentity]

-- Region, Gender Identity ----------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Gender Identity' AS [Category]
      ,[GenderIdentity] AS 'Variable'
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[GenderIdentity]

-- ICB, Gender Identity --------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Gender Identity' AS [Category]
      ,[GenderIdentity] AS 'Variable'
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[GenderIdentity]

--Sub-ICB, Gender Identity -----------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]

SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Gender Identity' AS [Category]
      ,[GenderIdentity] AS 'Variable'
	  ,CASE WHEN COUNT(FinishedTreat_TreatmentCareContact_Count) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) ELSE NULL END AS 'MeanApps'
	  ,CASE WHEN COUNT(FinishedTreat_RefFirstWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) ELSE NULL END AS 'MeanFirstWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_FirstSecondWait) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) ELSE NULL END AS 'MeanSecondWaitFinished'
	  ,CASE WHEN COUNT(FinishedTreat_PHQ9_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstPHQ9Finished'
	  ,CASE WHEN COUNT(FinishedTreat_GAD_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) ELSE NULL END AS 'MeanFirstGAD7Finished'
	  ,CASE WHEN COUNT(FinishedTreat_WASAS_Work_FirstScore) >= 5 THEN ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) ELSE NULL END AS 'Mean_FirstWSASW'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]

GROUP BY
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[GenderIdentity]

--------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages_Suppressed]' + CHAR(10)
