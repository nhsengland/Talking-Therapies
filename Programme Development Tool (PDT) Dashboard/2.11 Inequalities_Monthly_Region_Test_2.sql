
SET NOCOUNT ON

-- Refresh updates for : [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] -------------------------------

DECLARE @Offset AS INT = 0

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Refresh AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

DECLARE @PeriodStart2 AS DATE = (SELECT DATEADD(MONTH,+1,MAX(@PeriodStart)) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd2 AS DATE = (SELECT EOMONTH(DATEADD(MONTH,+1,MAX(@PeriodEnd))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Primary AS VARCHAR(50) = (DATENAME(M, @PeriodStart2) + ' ' + CAST(DATEPART(YYYY, @PeriodStart2) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@Refresh AS VARCHAR(50)) + CHAR(10)

-- Base Table for Paired ADSM ------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_InequalitiesADSMBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesADSMBase]

SELECT * INTO [MHDInternal].[TEMP_TTAD_PDT_InequalitiesADSMBase] FROM 

(SELECT pc.* 
	FROM [mesh_IAPT].[IDS603presentingcomplaints] pc
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] 
		AND pc.AuditId = l.AuditId 
		AND pc.Unique_MonthID = l.Unique_MonthID
	WHERE l.IsLatest = 1 AND l.[ReportingPeriodStartDate] <= @PeriodEnd

UNION -------------------------------------------------------------------------------

SELECT pc.* 
FROM [mesh_IAPT].[IDS603presentingcomplaints] pc
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] 
		AND pc.AuditId = l.AuditId 
		AND pc.Unique_MonthID = l.Unique_MonthID
	WHERE l.File_Type = 'Primary' AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodEnd2
)_

-- Presenting Complaints -----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_InequalitiesPresCompBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesPresCompBase]

SELECT DISTINCT pc.PathwayID
				,Validated_PresentingComplaint
				,row_number() OVER(PARTITION BY pc.PathwayID ORDER BY CASE WHEN Validated_PresentingComplaint IS NULL THEN 2 ELSE 1 END
					,PresCompCodSig, PresCompDate DESC, UniqueID_IDS603 DESC) AS rank

INTO	[MHDInternal].[TEMP_TTAD_PDT_InequalitiesPresCompBase]

FROM	[MHDInternal].[TEMP_TTAD_PDT_InequalitiesADSMBase] pc 
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND pc.AuditId = l.AuditId
			AND pc.Unique_MonthID = l.Unique_MonthID


--------------Social Personal Circumstance Ranked Table for Sexual Orientation Codes------------------------------------
--There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each sexual orientation code based on the SocPerCircumstanceRecDate 
--so that the latest record of a sexual orientation is labelled as 1. Only records with a SocPerCircumstanceLatest=1 are used in the queries to produce 
--[MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base] table

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_SocPerCircRank]
SELECT *
	,ROW_NUMBER() OVER(PARTITION BY Person_ID, RecordNumber,AuditID,UniqueSubmissionID ORDER BY [SocPerCircumstanceRecDate] desc, SocPerCircumstanceRank asc) as SocPerCircumstanceLatest
	--ranks each SocPerCircumstance with the same Person_ID, RecordNumber, AuditID and UniqueSubmissionID by the date so that the latest record is labelled as 1
INTO [MHDInternal].[TEMP_TTAD_PDT_SocPerCircRank]
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

-----------------------------------Inequalities Base Table---------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

SELECT DISTINCT
		CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
		,r.PathwayID
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

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
		END AS 'SexualOrientation'

		--Ethnicity
		,CASE WHEN mpi.Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN mpi.Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN mpi.Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN mpi.Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN mpi.Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' 
		END AS 'Ethnicity'

		--Age
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unknown'
		END AS 'Age'

		--Gender
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR mpi.Gender IS NULL THEN 'Unspecified' 
		END AS 'Gender'

		--Gender Identity
		,CASE WHEN mpi.GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			WHEN mpi.GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			WHEN mpi.GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN mpi.GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN mpi.GenderIdentity IN ('x','X') THEN 'Not Known'
			WHEN mpi.GenderIdentity IN ('z','Z') THEN 'Not Stated'
			WHEN mpi.GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR mpi.GenderIdentity IS NULL THEN 'Unspecified'
		END AS 'GenderIdentity'

		--Problem Descriptor
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

		--IMD
		,CAST(imd.[IMD_Decile] AS VARCHAR) AS 'IMD'

		,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_LastDate, l.ReportingPeriodEndDate) <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferralLessThan61DaysNoContact
		,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'OpenReferral61-90DaysNoContact'
		,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_LastDate, l.ReportingPeriodEndDate) BETWEEN 91 AND 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'OpenReferral91-120DaysNoContact'
		,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_LastDate, l.ReportingPeriodEndDate) >120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferralOver120daysNoContact
		,CASE WHEN r.ServDischDate IS NULL AND r.TherapySession_LastDate<=l.ReportingPeriodEndDate
			AND r.TherapySession_LastDate IS NOT NULL AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferral
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Treatment'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count>=2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Finished Treatment - 2 or more Apps'
		,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Referrals'
		,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS EnteringTreatment
		,CASE WHEN r.Assessment_FirstDate IS NULL AND r.ServDischDate IS NULL AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Waiting for Assessment'
		,CASE WHEN r.Assessment_FirstDate IS NULL AND r.ServDischDate IS NULL AND DATEDIFF(DD, r.ReferralRequestReceivedDate, l.ReportingPeriodEndDate) > 90
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'WaitingForAssessmentOver90days'
		,CASE WHEN r.Assessment_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.Assessment_FirstDate) < 29 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment28days'
		,CASE WHEN r.Assessment_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.Assessment_FirstDate) BETWEEN 29 AND 56 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment29to56days'
		,CASE WHEN r.Assessment_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.Assessment_FirstDate) BETWEEN 57 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment57to90days'
		,CASE WHEN r.Assessment_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.Assessment_FirstDate) > 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessmentOver90days'
		,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) < 29 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment28days'
		,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) BETWEEN 29 AND 56 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment29to56days'
		,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) BETWEEN 57 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment57to90days'
		,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) > 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatmentOver90days'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Referral'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '10' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Not Suitable'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '11' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Signposted'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '12' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Mutual Agreement'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '13' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Referred Elsewhere'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '14' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Declined'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode IS NOT NULL AND r.EndCode NOT IN ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Invalid'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode IS NULL AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended No Reason Recorded'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.TreatmentCareContact_Count = 0 AND r.CareContact_Count <> 0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 AND <> 0
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.TreatmentCareContact_Count = 1 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Treated Once'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CareContact_Count = 0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Recovery'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.ReliableImprovement_Flag = 'True' AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Recovery'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.NoChange_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'No Change'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.ReliableDeterioration_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Deterioration'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.ReliableImprovement_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Improvement'
		,CASE WHEN r.ServDischDate IS NOT NULL AND r.TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND r.NotCaseness_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'NotCaseness'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag = 'True' AND
			(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410'
			OR pc.Validated_PresentingComplaint LIKE 'F42%'	OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ADSMFinishedTreatment'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag = 'True'
			AND ((pc.[Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR (pc.[Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR (pc.[Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR (pc.[Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR (pc.[Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR (pc.[Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory'))
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'CountAppropriatePairedADSM'
		--v2.1:
		,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralIAPT = 'B1'
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'SelfReferral'
		,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralIAPT = 'A1'
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'GPReferral'
		,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralIAPT NOT IN ('B1','A1')
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'OtherReferral'
				-- --v2.0:
				-- ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralMH = 'B1'
				-- 	AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
				-- AS 'SelfReferral'
				-- 		,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralMH = 'A1'
				-- 	AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
				-- AS 'GPReferral'
				-- ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.SourceOfReferralMH NOT IN ('B1','A1')
				-- 	AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
				-- AS 'OtherReferral'
		,CASE WHEN r.TherapySession_SecondDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) <=28
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstToSecond28Days'
		,CASE WHEN r.TherapySession_SecondDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) BETWEEN 29 AND 56
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstToSecond28To56Days'
		,CASE WHEN r.TherapySession_SecondDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) BETWEEN 57 AND 90
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstToSecond57To90Days'
		,CASE WHEN r.TherapySession_SecondDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
			AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) > 90
			AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstToSecondMoreThan90Days'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '50' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Not Assessed'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '16' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Incomplete Assessment'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '17' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '95' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '46' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Mutually agreed completion of treatment'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '47' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Termination of treatment earlier than Care Professional planned'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '48' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Termination of treatment earlier than patient requested'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '49' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Deceased (Seen AND taken on for a course of treatment)'
		,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.EndCode = '96' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'ended Not Known (Seen AND taken on for a course of treatment)'

INTO [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

FROM [mesh_IAPT].[IDS101referral] r
	---------------------------	
	INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	---------------------------
	LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_SocPerCircRank] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		AND spc.SocPerCircumstanceLatest=1

	LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] AND [Effective_Snapshot_Date] = '2015-12-31' -- to match reference table used in NCDR
	---------------------------
	--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
	LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
		AND ch.Effective_To IS NULL

	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
		AND ph.Effective_To IS NULL
	---------------------------
	LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_InequalitiesPresCompBase] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	r.UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart
		AND l.IsLatest = 1
GO

--------------------------------------------------------------------------------------------
-- DELETE MAX(Month) -----------------------------------------------------------------------

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] 

WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities])

-- INSERT ----------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,CAST('Total' AS VARCHAR(255)) AS 'Category'
	,CAST('Total' AS VARCHAR(255)) AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
--INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
GO

--Sexual Orientation
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Sexual Orientation' AS 'Category'
	,[SexualOrientation] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[SexualOrientation]

--Ethnicity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Ethnicity]

--Age
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Age' AS 'Category'
	,[Age] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Age]

--Gender
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Gender' AS 'Category'
	,[Gender] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Gender]

--Gender Identity
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Gender Identity' AS 'Category'
	,[GenderIdentity] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[GenderIdentity]

--Problem Descriptor
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Problem Descriptor' AS 'Category'
	,[ProblemDescriptor] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[ProblemDescriptor]

--IMD
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]
SELECT 
	Month
	,'Refresh' AS DataSource
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Deprivation' AS 'Category'
	,[IMD] AS 'Variable'
	,SUM([OpenReferralLessThan61DaysNoContact]) AS [OpenReferralLessThan61DaysNoContact]
	,SUM([OpenReferral61-90DaysNoContact]) AS [OpenReferral61-90DaysNoContact]
	,SUM([OpenReferral91-120DaysNoContact]) AS [OpenReferral91-120DaysNoContact]
	,SUM([OpenReferralOver120daysNoContact]) AS [OpenReferralOver120daysNoContact]
	,SUM([OpenReferral]) AS [OpenReferral]
	,SUM([ended Treatment]) AS [ended Treatment]
	,SUM([Finished Treatment - 2 or more Apps]) AS [Finished Treatment - 2 or more Apps]
	,SUM([Referrals]) AS [Referrals]
	,SUM([EnteringTreatment]) AS [EnteringTreatment]
	,SUM([Waiting for Assessment]) AS [Waiting for Assessment]
	,SUM([WaitingForAssessmentOver90days]) AS [WaitingForAssessmentOver90days]
	,SUM([FirstAssessment28days]) AS [FirstAssessment28days]
	,SUM([FirstAssessment29to56days]) AS [FirstAssessment29to56days]
	,SUM([FirstAssessment57to90days]) AS [FirstAssessment57to90days]
	,SUM([FirstAssessmentOver90days]) AS [FirstAssessmentOver90days]
	,SUM([FirstTreatment28days]) AS [FirstTreatment28days]
	,SUM([FirstTreatment29to56days]) AS [FirstTreatment29to56days]
	,SUM([FirstTreatment57to90days]) AS [FirstTreatment57to90days]
	,SUM([FirstTreatmentOver90days]) AS [FirstTreatmentOver90days]
	,SUM([ended Referral]) AS [ended Referral]
	,SUM([ended Not Suitable]) AS [ended Not Suitable]
	,SUM([ended Signposted]) AS [ended Signposted]
	,SUM([ended Mutual Agreement]) AS [ended Mutual Agreement]
	,SUM([ended Referred Elsewhere]) AS [ended Referred Elsewhere]
	,SUM([ended Declined]) AS [ended Declined]
	--These are End Codes included in Version 1.5 only and not Version 2
	,NULL AS 'ended Deceased Assessed Only'
	,NULL AS 'ended Unknown Assessed Only'
	,NULL AS 'ended Stepped Up'
	,NULL AS 'ended Stepped Down'
	,NULL AS 'ended Completed'
	,NULL AS 'ended Dropped Out'
	,NULL AS 'ended Referred Non IAPT'
	,NULL AS 'ended Deceased Treated'
	,NULL AS 'ended Unknown Treated'
	,SUM([ended Invalid]) AS [ended Invalid]
	,SUM([ended No Reason Recorded]) AS [ended No Reason Recorded]
	,SUM([ended Seen Not Treated]) AS [ended Seen Not Treated]
	,SUM([ended Treated Once]) AS [ended Treated Once]
	,SUM([ended Not Seen]) AS [ended Not Seen]
	,SUM([Recovery]) AS [Recovery]
	,SUM([Reliable Recovery]) AS [Reliable Recovery]
	,SUM([No Change]) AS [No Change]
	,SUM([Reliable Deterioration]) AS [Reliable Deterioration]
	,SUM([Reliable Improvement]) AS [Reliable Improvement]
	,SUM([NotCaseness]) AS [NotCaseness]
	,SUM([ADSMFinishedTreatment]) AS [ADSMFinishedTreatment]
	,SUM([CountAppropriatePairedADSM]) AS [CountAppropriatePairedADSM]
	,SUM([SelfReferral]) AS [SelfReferral]
	,SUM([GPReferral]) AS [GPReferral]
	,SUM([OtherReferral]) AS [OtherReferral]
	,SUM([FirstToSecond28Days]) AS [FirstToSecond28Days]
	,SUM([FirstToSecond28To56Days]) AS [FirstToSecond28To56Days]
	,SUM([FirstToSecond57To90Days]) AS [FirstToSecond57To90Days]
	,SUM([FirstToSecondMoreThan90Days]) AS [FirstToSecondMoreThan90Days]
	,SUM([ended Not Assessed]) AS [ended Not Assessed]
	,SUM([ended Incomplete Assessment]) AS [ended Incomplete Assessment]
	,SUM([ended Deceased (Seen but not taken on for a course of treatment)]) AS [ended Deceased (Seen but not taken on for a course of treatment)]
	,SUM([ended Not Known (Seen but not taken on for a course of treatment)]) AS [Ended Not Known (Seen but not taken on for a course of treatment)]
	,SUM([ended Mutually agreed completion of treatment]) AS [ended Mutually agreed completion of treatment]
	,SUM([ended Termination of treatment earlier than Care Professional planned]) AS [Ended Termination of treatment earlier than Care Professional planned]
	,SUM([ended Termination of treatment earlier than patient requested]) AS [ended Termination of treatment earlier than patient requested]
	,SUM([ended Deceased (Seen AND taken on for a course of treatment)]) AS [ended Deceased (Seen and taken on for a course of treatment)]
	,SUM([ended Not Known (Seen AND taken on for a course of treatment)]) AS [ended Not Known (Seen and taken on for a course of treatment)]
	,NULL AS RepeatReferrals2	--This is just a column place holder. Every refresh, this column is reset to null and then repeat referrals are added in from the Repeat Referrals script 
FROM [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[IMD]


------------------------------------------------------------------
--Drop temporary tables
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesADSMBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesPresCompBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base]
------------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]'
