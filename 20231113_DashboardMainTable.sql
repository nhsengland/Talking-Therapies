SET NOCOUNT ON
SET DATEFIRST 1
SET ANSI_WARNINGS OFF

--------------------
DECLARE @Offset INT = -1
--------------------

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------

/* There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each 
sexual orientation code based on the SocPerCircumstanceRecDate so that the latest record of a sexual orientation is labelled as 1. 
Only records where SocPerCircumstanceLatest=1 are used in the queries. 
*/

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank]

--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1

SELECT *, ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] DESC, SocPerCircumstanceRank ASC) AS 'SocPerCircumstanceLatest'

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

-- Create base table of UniqueCareContactIDs for Count_EndedCompleted metric ----------------------------------------------------------------

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_UniqeCarePathwayID_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_UniqeCarePathwayID_Base]

SELECT [Unique_MonthID]
        ,[PathwayID]
        ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_UniqeCarePathwayID_Base]

FROM (

SELECT DISTINCT
        
        r.[Unique_MonthID]
        ,r.[PathwayID]
        ,a.[Unique_CareContactID]
        ,CASE WHEN  a.[Unique_CareContactID] IS NOT NULL AND EndCode = '46' THEN 1 ELSE 0 END AS 'Count_EndedCompleted'

FROM	[mesh_IAPT].[IDS101referral] r
		-------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
        LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
        AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH,0,@PeriodStart) AND @PeriodStart -- Monthly refresh uses value of '0'
        
)_ GROUP BY [Unique_MonthID], [PathwayID]

-- Create base table of pathwayIDs -----------------------------------------------------------------------------------------------------------

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

SELECT DISTINCT 

        r.[PathwayID]

        ,DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		
        -- Ethnicity - Broad
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		END AS 'Ethnicity - Broad'

        -- Ethnicity - High-level
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other'
		END AS 'Ethnicity - High-level'

        -- Ethnicity - Detailed
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
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
			WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
			WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
		END AS 'GenderIdentity'
		
		-- Key Metrics --
		,CASE WHEN ReferralRequestReceivedDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_Referrals'
		,CASE WHEN TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_AccessedTreatment'
        ,u.[Count_EndedCompleted]
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_Recovery'
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_Improvement'
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_Finished'
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END AS 'Count_NotCaseness'
		
		--Number of treatment courses that included a combination of low and high intensity sessions
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
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
			   THEN 1 ELSE 0 END AS 'Count_FinishedCourseTreatmentHILI'
		
		--Number of high intensity sessions
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
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
				THEN 1 ELSE 0 END AS 'Count_FinishedCourseTreatmentHI'

		--Number of low intensity sessions
	  ,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND r.[PathwayID] IS NOT NULL AND 
				([GuidedSelfHelp_Book_Count] > 0 OR 
				[GuidedSelfHelp_Computer_Count] > 0 OR 
				[NonGuidedSelfHelp_Book_Count] > 0 OR 
				[NonGuidedSelfHelp_Computer_Count] > 0 OR 
				[OtherLowIntensity_Count] > 0 OR 
				[PsychoeducationalPeerSupport_Count] > 0 OR 
				[StructuredPhysicalActivity_Count] > 0 OR 
				[CommunitySignPosting_Count] > 0) THEN 1 ELSE 0 END AS 'Count_FinishedCourseTreatmentLI'

		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND CareContact_Count = '0' THEN 1 ELSE 0 END AS 'Count_EndedNotSeen'
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND EndCode = '12' THEN 1 ELSE 0 END AS 'Count_EndedMutualAgreement'
		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND TreatmentCareContact_Count = '1' THEN 1 ELSE 0 END AS 'Count_OneTreatment'

		,CASE WHEN TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 42 THEN 1 ELSE 0 END AS 'Count_FirstTreatment_6Weeks'
		,CASE WHEN TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND DATEDIFF(D, ReferralRequestReceivedDate, TherapySession_FirstDate) <= 126 THEN 1 ELSE 0 END AS 'Count_FirstTreatment_18Weeks'

		,CASE WHEN TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND DATEDIFF(D, TherapySession_FirstDate, TherapySession_SecondDate) > 90 AND ServDischDate IS NULL THEN 1 ELSE 0 END AS 'Count_WaitFirstToSecond_Over90days'

		,CASE WHEN ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL AND TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN 1 ELSE 0 END AS 'Count_Ended_Seen_NotTreated'

		----------------------------------------------------------------------------------------------------

INTO [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

FROM	[mesh_IAPT].[IDS101referral] r
		-------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1
		-------------------------
        INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_UniqeCarePathwayID_Base] u ON r.[PathwayID] = u.[PathwayID] AND r.[Unique_MonthID] = u.[Unique_MonthID]
        -------------------------
		---- Tables for up-to-date Sub-ICB/ICB/Region/Provider names/codes --------------------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		-------------------------
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH,0,@PeriodStart) AND @PeriodStart -- Monthly refresh uses value of '0'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aggregate output for dashboard table ----------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Ethnicity - Broad

SELECT [Month] 
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Ethnicity - Broad' AS [Category]
      ,[Ethnicity - Broad] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,[Ethnicity - Broad]

---------------------------------------------------------------------------------------
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Ethnicty - High-level

SELECT  [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Ethnicity - High-Level' AS [Category]
      ,[Ethnicity - High-Level] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Ethnicty - Detailed

SELECT  [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Ethnicity - Detailed' AS [Category]
      ,[Ethnicity - Detailed] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Sexual Orientation

SELECT  [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Sexual Orientation' AS [Category]
      ,[Sexual Orientation] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Age

SELECT  [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Age' AS [Category]
      ,[Age] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Gender

SELECT  [Month]
      ,[Region Code]
      ,[Region Name]
      ,[Sub ICB Code]
      ,[Sub ICB Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[ICB Code]
      ,[ICB Name]
      ,'Gender' AS [Category]
      ,[Gender] AS 'Variable'
      ,SUM([Count_Referrals]) AS 'Count_Referrals'
      ,SUM([Count_AccessedTreatment]) AS 'Count_AccessedTreatment'
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_MainTable] -- Gender Identity

SELECT  [Month]
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
      ,SUM([Count_EndedCompleted]) AS 'Count_EndedCompleted'
      ,SUM([Count_Recovery]) AS 'Count_Recovery'
      ,SUM([Count_Improvement]) AS 'Count_Improvement'
      ,SUM([Count_Finished]) AS 'Count_Finished'
      ,SUM([Count_NotCaseness]) AS 'Count_NotCaseness'
      ,SUM([Count_FinishedCourseTreatmentHILI]) AS 'Count_FinishedCourseTreatmentHILI'
      ,SUM([Count_FinishedCourseTreatmentHI]) AS 'Count_FinishedCourseTreatmentHI'
      ,SUM([Count_FinishedCourseTreatmentLI]) AS 'Count_FinishedCourseTreatmentLI'
      ,SUM([Count_EndedNotSeen]) AS 'Count_EndedNotSeen'
      ,SUM([Count_EndedMutualAgreement]) AS 'Count_EndedMutualAgreement'
      ,SUM([Count_OneTreatment]) AS 'Count_OneTreatment'
      ,SUM([Count_FirstTreatment_6Weeks]) AS 'Count_FirstTreatment_6Weeks'
      ,SUM([Count_FirstTreatment_18Weeks]) AS 'Count_FirstTreatment_18Weeks'
      ,SUM([Count_WaitFirstToSecond_Over90days]) AS 'Count_WaitFirstToSecond_Over90days'
      ,SUM([Count_Ended_Seen_NotTreated]) AS 'Count_Ended_Seen_NotTreated'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_PathwayID_Base]

GROUP BY [Month]
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