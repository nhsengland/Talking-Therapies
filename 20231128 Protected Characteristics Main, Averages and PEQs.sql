

--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------

/* There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each 
sexual orientation code based on the SocPerCircumstanceRecDate so that the latest record of a sexual orientation is labelled as 1. 
Only records where SocPerCircumstanceLatest=1 are used in the queries. 
*/

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]

--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1

SELECT 
      *
      ,ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] DESC, SocPerCircumstanceRank ASC) AS 'SocPerCircumstanceLatest'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]

FROM (

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
            ,CASE WHEN SocPerCircumstance IN ('20430005','89217008','76102007','42035005','765288000','766822004') THEN 1
            --Heterosexual, Homosexual (Female), Homosexual (Male), Bisexual, Sexually attracted to neither male nor female sex, Confusion
                  WHEN SocPerCircumstance='38628009' THEN 2
                  --Homosexual (Gender not specified) (there are occurrences where this is listed alongside Homosexual (Male) or Homosexual (Female) for the same record
                  --so has been ranked below these to prioritise a social personal circumstance with the max amount of information)
                  WHEN SocPerCircumstance IN ('1064711000000100','699042003','440583007') THEN 3 --Person asked and does not know or IS not sure, Declined, Unknown
            ELSE NULL END AS SocPerCircumstanceRank
            --Ranks the social personal circumstances by the amount of information they provide, to help decide which one to use when a record has more than one social personal circumstance on the same day

      FROM [mesh_IAPT].[IDS011socpercircumstances]

      WHERE SocPerCircumstance IN('20430005','89217008','76102007','38628009','42035005','1064711000000100','699042003','765288000','440583007','766822004') --Filters for codes relevant to sexual orientation
)_

DECLARE @Offset INT = -1
--------------------

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

-- Create base table -----------------------------------------------------------------------------------------------------------

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

      -- Sexual Orientation
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
      END AS 'Sexual Orientation'

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
		LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1
		-------------------------
		---- Tables for up-to-date Sub-ICB/ICB/Region/Provider names/codes --------------------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		-------------------------
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = 1
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -35, @PeriodStart) AND @PeriodStart -- For monthly refresh the offset uses a value of '0'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aggregate output for dashboard table ----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ethnicity - Broad
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,CAST('Ethnicity - Broad' AS VARCHAR(255)) AS Category
      ,CAST([Ethnicity - Broad] AS VARCHAR(255)) AS Variable
      ,SUM(Count_Referrals) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Broad]
GO

---------------------------------------------------------------------------------------
--Ethnicity - High-level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] 
SELECT 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Ethnicity - High-Level' AS Category
      ,[Ethnicity - High-Level] AS Variable
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - High-Level]

-------------------------------------------------------------------------------------
--Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT  
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Detailed]

------------------------------------------------------------------------------------
--Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT 
      Month
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Sexual Orientation]

---------------------------------------------------------------------
--Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT 
      Month
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Age' AS Category
      ,[Age] AS Variable
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Age]

------------------------------------------------------------------------
--Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT 
      Month
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Gender' AS Category
      ,[Gender] AS Variable
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Gender]

---------------------------------------------------------------------------------
--Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]
SELECT 
      Month
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Gender Identity' AS [Category]
      ,[GenderIdentity] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_ReliableRecovery]) AS 'Count_ReliableRecovery'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[GenderIdentity]
--------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable]' + CHAR(10)
GO

---------------------------------------------------------------------------------------------------------
------------------------------Averages
--------------------------------------------------------------------------------------------------------
-- National, Ethnicity - Broad
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
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
INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Ethnicity - Broad]
GO
-- Region, Ethnicity - Broad
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - Broad]

-- ICB, Ethnicity - Broad
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Broad]

-- Sub-ICB, Ethnicity - Broad
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Ethnicity - Broad' AS Category
      ,[Ethnicity - Broad] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - Broad]
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--National, Ethnicity - High-level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
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

--Region, Ethnicity - High-level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
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
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - High-Level]

--ICB, Ethnicity - High-level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - High-Level]


--Sub-ICB, Ethnicity - High-level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages] 
SELECT 
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - High-Level]
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--National, Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
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

--Region, Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT  
      [Month]
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
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
      ,[Region Code]
      ,[Region Name]
      ,[Ethnicity - Detailed]

--ICB, Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT  
      [Month]
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Detailed]

--Sub-ICB, Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT  
      [Month]
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Ethnicity - Detailed]
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--National, Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'National' AS OrganisationType
      ,'All Regions' AS Region
      ,'ENG' AS OrganisationCode
      ,'England' AS OrganisationName
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY
      [Month]
      ,[Sexual Orientation]

--Region, Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sexual Orientation]

--ICB, Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Sexual Orientation]

--Sub-ICB, Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,ROUND(AVG(CAST(FinishedTreat_TreatmentCareContact_Count AS FLOAT)),1) AS MeanApps
      ,ROUND(AVG(CAST(FinishedTreat_RefFirstWait AS FLOAT)),1) AS MeanFirstWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_FirstSecondWait AS FLOAT)),1) AS MeanSecondWaitFinished
      ,ROUND(AVG(CAST(FinishedTreat_PHQ9_FirstScore AS FLOAT)),1) AS MeanFirstPHQ9Finished
      ,ROUND(AVG(CAST(FinishedTreat_GAD_FirstScore AS FLOAT)),1) AS MeanFirstGAD7Finished
      ,ROUND(AVG(CAST(FinishedTreat_WASAS_Work_FirstScore AS FLOAT)),1) AS Mean_FirstWSASW
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Base]
GROUP BY 
      [Month]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Sexual Orientation]
---------------------------------------------------------------------
---------------------------------------------------------------------
--National, Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
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

--Region, Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
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
      ,[Region Code]
      ,[Region Name]
      ,[Age]

--ICB, Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Age]

--Sub-ICB, Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Age]
------------------------------------------------------------------------
------------------------------------------------------------------------
--National, Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
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

--Region, Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
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
      ,[Region Code]
      ,[Region Name]
      ,[Gender]

--ICB, Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Gender]

--Sub-ICB, Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Gender]
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--National, Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
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

--Region, Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Region' AS OrganisationType
      ,[Region Name] AS Region
      ,[Region Code] AS OrganisationCode
      ,[Region Name] AS OrganisationName
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
      ,[Region Code]
      ,[Region Name]
      ,[GenderIdentity]

--ICB, Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[ICB Code] AS OrganisationCode
      ,[ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[GenderIdentity]

--Sub-ICB, Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]
SELECT 
      Month
      ,'Sub-ICB' AS OrganisationType
      ,[Region Name] AS Region
      ,[Sub ICB Code] AS OrganisationCode
      ,[Sub ICB Name] AS OrganisationName
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
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[GenderIdentity]
--------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_Averages]' + CHAR(10)
GO
---------------------------------------------------------------------------------------------------------------------
-----------PEQs
------------------------------------------------------------------------------------------------------------------------------
DECLARE @Offset INT = -1
DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS DATE) AS 'Month'
	,r.PathwayID

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

	-- Sexual Orientation
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
	END AS 'Sexual Orientation'

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
		
	,CASE WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 1 score (observable entity)' THEN 'Assessment Q1: Were you given information about options for choosing a treatment that is appropriate for your problems?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 2 score (observable entity)' THEN 'Assessment Q2: Do you prefer any of the treatments among the options available?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 3 score (observable entity)' THEN 'Assessment Q3: Have you been offered your preference?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 4 score (observable entity)' THEN 'Assessment Q4: Did your assessment cover your employment needs?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire satisfaction question 1 score (observable entity)' THEN 'How satisfied were you with your assessment?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 1 score (observable entity)' THEN 'Treatment Q1: Did staff listen to you and treat your concerns seriously?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 2 score (observable entity)' THEN 'Treatment Q2: Do you feel that the service has helped you to better understand and address your difficulties?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 3 score (observable entity)' THEN 'Treatment Q3: Did you feel involved in making choices about your treatment and care?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 4 score (observable entity)' THEN 'Treatment Q4: On reflection, did you get the help that mattered to you?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 5 score (observable entity)' THEN 'Treatment Q5: Did you have the confidence in your therapist and his /her skills and techniques?'
		WHEN  s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 6 score (observable entity)' THEN 'Treatment Q6: Did you receive the employment help that you required?'
		ELSE NULL		
	END AS 'Question'

	,CASE 
		-- Treatment
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('0') THEN 'Never'
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('1') THEN 'Rarely'
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('2') THEN 'Sometimes'
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('3') THEN 'Most of the time'
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('4') THEN 'All of the time'
		WHEN csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND csa.[PersScore] IN ('NA') THEN 'Not applicable'
		--Assessment
		WHEN csa.[CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND csa.[PersScore] IN ('Y') THEN 'Yes'
		WHEN csa.[CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND csa.[PersScore] IN ('N') THEN 'No'
		WHEN csa.[CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND csa.[PersScore] IN ('NA') THEN 'Not applicable'
		--Satifaction
		WHEN csa.[CodedAssToolType] IN('747891000000106') AND csa.[PersScore] IN ('0') THEN 'Not satisfied at all'
		WHEN csa.[CodedAssToolType] IN('747891000000106') AND csa.[PersScore] IN ('1') THEN 'Not satisfied'
		WHEN csa.[CodedAssToolType] IN('747891000000106') AND csa.[PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
		WHEN csa.[CodedAssToolType] IN('747891000000106') AND csa.[PersScore] IN ('3') THEN 'Mostly satisfied'
		WHEN csa.[CodedAssToolType] IN('747891000000106') AND csa.[PersScore] IN ('4') THEN 'Completely satisfied'
	END AS 'Answer'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]

FROM	[mesh_IAPT].[IDS101referral] r
		-------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1
		-------------------------
		LEFT JOIN [mesh_IAPT].[IDS607codedscoreassessmentact] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
WHERE	r.UsePathway_Flag = 'True' AND IsLatest = 1
		AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
		AND r.CompletedTreatment_Flag = 'True'
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -35, @PeriodStart) AND @PeriodStart
		AND csa.[CodedAssToolType] IN
		('747901000000107','747911000000109','747921000000103','747931000000101'
		,'747941000000105','747951000000108','747891000000106','747861000000100'
		,'747871000000107','747881000000109','904691000000103')

--Final Aggregated PEQ Table		

--Ethnicity - Broad
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,CAST('Ethnicity - Broad' AS VARCHAR(255)) AS Category
      ,CAST([Ethnicity - Broad] AS VARCHAR(255)) AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Ethnicity - Broad]
      ,Question
      ,Answer

--Ethnicity - High Level
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Ethnicity - High Level' AS Category
      ,[Ethnicity - High-level] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Ethnicity - High-level]
      ,Question
      ,Answer

--Ethnicity - Detailed
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Ethnicity - Detailed' AS Category
      ,[Ethnicity - Detailed] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Ethnicity - Detailed]
      ,Question
      ,Answer

--Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Gender' AS Category
      ,[Gender] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Gender]
      ,Question
      ,Answer

--Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Gender Identity' AS Category
      ,[GenderIdentity] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[GenderIdentity]
      ,Question
      ,Answer

--Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Age' AS Category
      ,[Age] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Age]
      ,Question
      ,Answer

--Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PEQs]
SELECT
      Month 
      ,'Sexual Orientation' AS Category
      ,[Sexual Orientation] AS Variable
      ,Question
      ,Answer
      ,COUNT(PathwayID) AS Count
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]
GROUP BY
      [Month]
      ,[Sexual Orientation]
      ,Question
      ,Answer

--Drop Temporary Tables
--DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]
--DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Base]
--DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PEQBase]