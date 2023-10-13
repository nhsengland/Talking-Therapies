--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Unique Care Pathways Dashboard to produce the base table for the box plots ******/

------------------------------------------------------------------------------------------------------------------------
--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------
--There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each sexual orientation code based on the SocPerCircumstanceRecDate 
--so that the latest record of a sexual orientation is labelled as 1. Only records with a SocPerCircumstanceLatest=1 are used in the queries to produce 
--[MHDInternal].[DASHBOARD_TTAD_UCP_Base] table
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank]
SELECT *
	,ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] desc, SocPerCircumstanceRank asc) as SocPerCircumstanceLatest
	--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1
INTO [MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank]
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
-----------------------------------------------------------------
-------------Base Table for Unique Care Pathways
--This is a record-level base table with columns for the unique care pathway, outcome measures, protected characteristics and location.
--This table is used as the base of the aggregated table called [MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 

-- Set the start and end dates of the reporting period based on the latest submission ID
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

-- Set the first day of the week as Monday
SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

-- When refreshing the dashboard each month, insert the latest month of data into [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
--IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_UCP_Base]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
SELECT DISTINCT
	-- Extract the month from the reporting period start date
	CONVERT(date, '01' + DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)) as Month
		
	-- Set the region code and region name
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS [Region Code Comm]
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS [Region Name Comm]
	,CASE WHEN ph.[Region_Code] IS NOT NULL THEN ph.[Region_Code] ELSE 'Other' END AS [Region Code Prov]
	,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS [Region Name Prov]

	-- Set the Organisation code and Organisation name
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS [Sub-ICB Code]
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS [Sub-ICB Name]
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS [Provider Code]
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS [Provider Name]

	-- Set ICB Code and ICB Name
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS [ICB Code]
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS [ICB Name]

	,r.PathwayID AS [Pathway ID]

	-- Set the treatment care contact count, display '30+' if count is 30 or more
	,CASE 
		WHEN TreatmentCareContact_Count >= 30 THEN '30+' 
		ELSE CAST(TreatmentCareContact_Count AS VARCHAR)
	END AS TreatmentCareContact_Count

	,TreatmentCareContact_Count AS [Numeric treatment count]

	--Creates a flag for those completing a course of treatment within the reporting period
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS CompTreatFlag

	--Creates a flag for those completing a course of treatment within the reporting period and have the recovery flag
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'TRUE' AND r.Recovery_Flag = 'TRUE'  and r.PathwayID is not null THEN 1 ELSE 0 END AS CompTreatFlagRecFlag

	--Creates a flag for those completing a course of treatment within the reporting period and have the not caseness flag
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'TRUE' AND r.NotCaseness_Flag = 'TRUE'  and r.PathwayID is not null THEN 1 ELSE 0 END AS NotCaseness
		
	--Creates a flag for those completing a course of treatment within the reporting period and have the reliable improvement flag
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'TRUE' AND r.ReliableImprovement_Flag = 'TRUE'  and r.PathwayID is not null THEN 1 ELSE 0 END AS CompTreatFlagRelImpFlag
		
	--Creates a flag for those completing a course of treatment within the reporting period and have the reliable deterioration flag
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'TRUE' AND r.ReliableDeterioration_Flag = 'TRUE'
	and r.PathwayID is not null THEN 1 ELSE 0 END AS CompTreatFlagRelDetFlag

	--Defines the problem descriptors
	,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR [PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR [PrimaryPresentingComplaint] = 'Unspecified' THEN 'Unspecified'
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
		
	--Defines the gender variables based on mpi.Gender
	,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
		WHEN mpi.Gender IN ('2','02') THEN 'Female'
		WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
		WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
		WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Unspecified' 
		END AS [GenderDescriptor]

	--Defines the ethnicity variables based on mpi.Validated_EthnicCategory
	,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
		WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
		WHEN mpi.Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
		WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Unspecified' 
	END AS [EthnicityDescriptor]

	--Defines the gender identity variables based on GenderIdentity
	,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
		WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
		WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
		WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
		WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
		WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
		WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
		END AS [GenderIdentityDescriptor]

	--Defines the age groups based on r.Age_ReferralRequest_ReceivedDate
	,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
		WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
		WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unspecified'
		END AS [AgeDescriptor]

	--Defines the sexual orientation variables based on spc.SocPerCircumstance
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
	END AS [SexualOrientationDescriptor]

	--Defines the deprivation variables based on IMD.Decile
	,CASE WHEN IMD.IMD_Decile IS NOT NULL THEN CAST(IMD.[IMD_Decile] AS VARCHAR) ELSE 'Unspecified' END AS [DeprivationDescriptor]


 	,(CASE 
		
-- If there are counts only for 'Guided Self-Help Book' pathway and no counts for other pathways then set the value as 'Guide Self-Help Book'
	WHEN 
		[GuidedSelfHelp_Book_Count] > 0
		AND [NonGuidedSelfHelp_Book_Count] =0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Guide Self-Help Book'
-- If there are counts only for 'Non-Guided Self-Help Book' pathway and no counts for other pathways then set the value as 'Non-Guided Self-Help Book'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] > 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Non-Guided Self-Help Book'
-- If there are counts only for 'Guided Self-Help Computer' pathway and no counts for other pathways then set the value as 'Guided Self-Help Computer'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] > 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Guided Self-Help Computer'
-- If there are counts only for 'Non-Guided Self-Help Computer' pathway and no counts for other pathways then set the value as 'Non-Guided Self-Help Computer'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] > 0 

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Non-Guided Self-Help Computer'
-- If there are counts only for 'Structured Physical Activity' pathway and no counts for other pathways then set the value as 'Structured Physical Activity'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] > 0 
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Structured Physical Activity'
-- If there are counts only for 'Internet Enabled Therapy' pathway and no counts for other pathways then set the value as 'Internet Enabled Therapy'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = TreatmentCareContact_Count
		AND [InternetEnabledTherapy_Count] > 0 
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Internet Enabled Therapy'
-- If there are counts only for 'Psychoeducational Peer Support' pathway and no counts for other pathways then set the value as 'Psychoeducational Peer Support'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] > 0 
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Psychoeducational Peer Support'
-- If there are counts only for 'Other Low Intensity' pathway and no counts for other pathways then set the value as 'Other Low Intensity'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] > 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Other Low Intensity'
-- If there are counts only for 'Applied Relaxation' pathway and no counts for other pathways then set the value as 'Applied Relaxation'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0	
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] > 0 
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Applied Relaxation'
-- If there are counts only for 'Couples Therapy Depression' pathway and no counts for other pathways then set the value as 'Couples Therapy Depression'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] > 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Couples Therapy Depression'
-- If there are counts only for 'Collaborative Care' pathway and no counts for other pathways then set the value as 'Collaborative Care'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] > 0 
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Collaborative Care'
-- If there are counts only for 'Counselling Depression' pathway and no counts for other pathways then set the value as 'Counselling Depression'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] > 0 

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Counselling Depression'
-- If there are counts only for 'Brief Psychodynamic Psychotherapy' pathway and no counts for other pathways then set the value as 'Brief Psychodynamic Psychotherapy'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] > 0 
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN  'Brief Psychodynamic Psychotherapy'
-- If there are counts only for 'Eye Movement Desensitisation Reprocessing' pathway and no counts for other pathways then set the value as 'Eye Movement Desensitisation Reprocessing'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] > 0 
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Eye Movement Desensitisation Reprocessing'
-- If there are counts only for 'Mindfulness' pathway and no counts for other pathways then set the value as 'Mindfulness'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] > 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Mindfulness'
-- If there are counts only for 'Other High Intensity' pathway and no counts for other pathways then set the value as 'Other High Intensity'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] > 0 

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Other High Intensity'
-- If there are counts only for 'Cognitive Behaviour Therapy' pathway and no counts for other pathways then set the value as 'Cognitive Behaviour Therapy'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] > 0 
		AND [InterpersonalPsychotherapy_Count] = 0
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Cognitive Behaviour Therapy'
-- If there are counts only for 'Interpersonal Psychotherapy' pathway and no counts for other pathways then set the value as 'Interpersonal Psychotherapy'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] > 0 
			
		AND [CommunitySignPosting_Count] = 0
	THEN 'Interpersonal Psychotherapy'
-- If there are counts only for 'Community Signposting' pathway and no counts for other pathways then set the value as 'Community Signposting'
	WHEN 
		[GuidedSelfHelp_Book_Count] = 0
		AND [NonGuidedSelfHelp_Book_Count] = 0 
		AND [GuidedSelfHelp_Computer_Count] = 0 
		AND [NonGuidedSelfHelp_Computer_Count] = 0

		AND [StructuredPhysicalActivity_Count] = 0
		--AND AntePostNatalCounselApts = 0
		AND [InternetEnabledTherapy_Count] = 0
		AND [PsychoeducationalPeerSupport_Count] = 0
		AND [OtherLowIntensity_Count] = 0

		AND [AppliedRelaxation_Count] = 0
		AND [CouplesTherapyDepression_Count] = 0 
		AND [CollaborativeCare_Count] = 0
		AND [CounsellingDepression_Count] = 0

		AND [BriefPsychodynamicPsychotherapy_Count] = 0
		AND [EyeMovementDesensitisationReprocessing_Count] = 0
		AND [Mindfulness_Count] = 0 
		AND [OtherHighIntensity_Count] = 0

		AND [CognitiveBehaviourTherapy_Count] = 0
		AND [InterpersonalPsychotherapy_Count] = 0
		
		AND [CommunitySignPosting_Count] > 0 
	THEN 'Community Signposting'
	ELSE NULL END) AS [UniqueCarePathway]

--INTO [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
FROM [mesh_IAPT].[IDS101referral] r

INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId

--Provides data for sexual orientation
LEFT JOIN [MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId 
AND r.UniqueSubmissionID = spc.UniqueSubmissionID AND spc.SocPerCircumstanceLatest=1

LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] and IMD.Effective_Snapshot_Date='2019-12-31'
LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId AND a.Unique_MonthID = l.Unique_MonthID
LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = l.AuditId AND c.Unique_MonthID = l.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 

--Four tables joined to get Provider, Sub-ICB, ICB and Region codes and names
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
	AND ch.Effective_To IS NULL
LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL

WHERE	
--Filters for the latest data
UsePathway_Flag = 'True'
AND IsLatest = 1

--Defines the full time period included in the table
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart --For superstats monthly refresh, the offset should be set to 0 to just get the latest month
	
--Filters for at least 1 treatment session
AND TreatmentCareContact_Count>0

--Filters for those who have completed treatment
AND CompletedTreatment_Flag = 'TRUE'

ORDER BY 2

-- Drop the temporary table [MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank]
DROP TABLE [MHDInternal].[TEMP_TTAD_UCP_SocPerCircRank]
