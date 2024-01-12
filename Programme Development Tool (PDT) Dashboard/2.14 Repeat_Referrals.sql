SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- CREATES NEW SPELL TABLE AND BASE TABLE -------------------------------------------------------------------------------------------------
-- Selects all People, PathwayIDs, Record numbers and ReferrralRequestReceivedDates for v2.0 who have completed treatment

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]
SELECT 
	CAST(mpi.[pseudo_nhs_number_ncdr] AS VARCHAR) AS 'PseudoNumber'
	,CAST(r.[PathwayID] AS VARCHAR(100)) AS 'PathwayID'
	,r.[RecordNumber] AS 'RecordNumber'
	,r.[ReferralRequestReceivedDate]
	,l.[ReportingPeriodStartDate]
	,l.[ReportingPeriodEndDate]
	,ph.[Organisation_Code] AS 'Provider Code'
	,ch.[Organisation_Code] AS 'CCG Code' 
	,CAST(r.[UniqueID_IDS101] AS BIGINT) AS UniqueID_IDS101
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] 
FROM	[mesh_IAPT].[IDS101referral] r
		-----------------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[recordnumber] = mpi.[recordnumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId] AND r.[Unique_MonthID] = l.[Unique_MonthID]
		-----------------------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
		
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL
WHERE l.IsLatest = 1 AND r.UsePathway_Flag = 'True' AND r.CompletedTreatment_Flag = 'True'
GO
-- SELECTS THE MAX RECORD NUMBER ----------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_MaxRecord]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_MaxRecord]
SELECT 
	PathwayID
	,MAX(RecordNumber) AS 'RecordNumber'
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_MaxRecord]
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]
GROUP BY PathwayID
GO
-- ALLOCATES REFERRAL ORDER ---------------------------------------------------------------------------------
--This table is limited to the max record number per PathwayID to represent 1 spell
--The referral received dates (REFRECDATE) for each Person are ranked
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell]
SELECT 
	ROW_NUMBER() OVER(PARTITION BY r.[PseudoNumber] ORDER BY r.ReferralRequestReceivedDate DESC) AS 'ReferralOrder2'
	,r.*
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell]
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] r
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_MaxRecord] t on r.PathwayID = t.PathwayID AND r.[RecordNumber] = t.[RecordNumber]
GO
-- SELECTS ALL FIELDS REQUIRED FOR SPELLS TABLE FROM v2.0 ------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2]
	SELECT 
		s.*
		,CAST(r.[UsePathway_Flag] AS VARCHAR) AS UsePathway_Flag
		,r.[Age_ReferralRequest_ReceivedDate]
		,CAST(r.[RECOVERY_FLAG] AS VARCHAR) AS RecoveryFlag
		,CAST(r.[ReliableDeterioration_Flag] AS VARCHAR) AS ReliableDeteriorationFlag
		,CAST(r.[ReliableImprovement_Flag] AS VARCHAR) AS ReliableImprovementFlag
		,CAST(r.[NotCaseness_Flag] AS VARCHAR) AS NotCasenessFlag
		,r.[ServDischDate]
		,r.[PresentingComplaintHigherCategory]
		,r.[PresentingComplaintLowerCategory]
		,r.[PrimaryPresentingComplaint]
		,r.[SecondaryPresentingComplaint]
		,r.[TreatmentCareContact_Count]
		,r.[ENDCODE]
		,'v2.0' AS 'Version'
	INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2]  
	FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell] s
	INNER JOIN [mesh_IAPT].[IDS101referral] r on CAST(r.[PathwayID] AS VARCHAR(100)) = s.[PathwayID] AND r.[RecordNumber] = s.[RecordNumber]
GO
-- SELECTS ALL 'VALID' REFERRALS (NOT LATE SUBMISSIONS) -----------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_ValidReferrals]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_ValidReferrals]
SELECT DISTINCT 
	PathwayID
	,ReferralRequestReceivedDate
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_ValidReferrals]
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]
WHERE Month(ReferralRequestReceivedDate) = Month(ReportingPeriodStartDate) AND Year(ReferralRequestReceivedDate) = Year(ReportingPeriodStartDate) 
GO
-- CREATE BASE TABLE FOR QUERY ------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
SELECT DISTINCT 
	a.PseudoNumber
	,'No Match' AS 'LatestProvider'
	,'No Match' AS 'PreviousProvider'
	,'No Match' AS 'LatestCCG'
	,'No Match' AS 'PreviousCCG'
	,a.[ReferralRequestReceivedDate] AS 'LatestReferral'
	,b.[ReferralRequestReceivedDate] AS 'PreviousReferral'
	,a.UsePathway_Flag AS 'LatestFlag'
	,b.UsePathway_Flag AS 'PreviousFlag'
	,a.[Age_ReferralRequest_ReceivedDate] AS 'LatestAge'
	,b.[Age_ReferralRequest_ReceivedDate] AS 'PreviousAge'
	,b.[RecoveryFlag] AS 'PreviousRecovery'
	,b.[ReliableDeteriorationFlag] AS 'PreviousDeterioration'
	,b.[ReliableImprovementFlag] AS 'PreviousImprovement'
	,b.[NotCasenessFlag] AS 'PreviousNotCaseness'
	,DATEDIFF(Day,b.[ServDischDate],a.[ReferralRequestReceivedDate]) AS 'Time between referrals'
	,CASE WHEN a.[Version] = 'v2.0' AND a.[PresentingComplaintHigherCategory] = 'Depression' OR a.[PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN a.[Version] = 'v2.0' AND a.[PresentingComplaintHigherCategory] = 'Unspecified' OR a.[PrimaryPresentingComplaint] = 'Unspecified' THEN 'Unspecified'
		WHEN a.[Version] = 'v2.0' AND a.[PresentingComplaintHigherCategory] = 'Other recorded problems' OR a.[PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
		WHEN a.[Version] = 'v2.0' AND a.[PresentingComplaintHigherCategory] = 'Other Mental Health problems' OR a.[PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
		WHEN a.[Version] = 'v2.0' AND a.[PresentingComplaintHigherCategory] = 'Invalid Data supplied' OR a.[PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR a.[SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR a.[SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR a.[SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR a.[SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR a.[SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR a.[SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR a.[SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR a.[SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR a.[SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR a.[SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR a.[SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'		
		WHEN a.[Version] = 'v2.0' AND (a.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR a.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (a.PresentingComplaintLowerCategory IS NULL OR a.[SecondaryPresentingComplaint] IS NULL) THEN 'No Code'
		ELSE 'Other' 
	END AS 'LatestDiagnosis'
	,CASE WHEN b.[Version] = 'v2.0' AND b.[PresentingComplaintHigherCategory] = 'Depression' OR b.[PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN b.[Version] = 'v2.0' AND b.[PresentingComplaintHigherCategory] = 'Unspecified' OR b.[PrimaryPresentingComplaint] = 'Unspecified' THEN 'Unspecified'
		WHEN b.[Version] = 'v2.0' AND b.[PresentingComplaintHigherCategory] = 'Other recorded problems' OR b.[PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
		WHEN b.[Version] = 'v2.0' AND b.[PresentingComplaintHigherCategory] = 'Other Mental Health problems' OR b.[PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
		WHEN b.[Version] = 'v2.0' AND b.[PresentingComplaintHigherCategory] = 'Invalid Data supplied' OR b.[PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR b.[SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR b.[SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR b.[SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR b.[SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR b.[SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR b.[SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR b.[SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR b.[SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR b.[SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR b.[SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR b.[SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'		
		WHEN b.[Version] = 'v2.0' AND (b.[PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' OR b.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (b.PresentingComplaintLowerCategory IS NULL OR b.[SecondaryPresentingComplaint] IS NULL) THEN 'No Code'
		ELSE 'Other' 
	END AS 'PreviousDiagnosis'
	,b.TreatmentCareContact_Count AS 'PreviousCountAppointments'
	,b.[ServDischDate] AS 'PreviousEndDate'
	,CASE WHEN b.[ENDCODE] = '10' THEN 'Ended Not Suitable'
		WHEN b.[ENDCODE] = '11' THEN 'Ended Signposted'
		WHEN b.[ENDCODE] = '12' THEN 'Ended Mutual Agreement'
		WHEN b.[ENDCODE] = '13' THEN 'Ended Referred Elsewhere'
		WHEN b.[ENDCODE] = '14' THEN 'Ended Declined'
		WHEN b.[ENDCODE] = '15' THEN 'Ended Deceased Assessed Only'
		WHEN b.[ENDCODE] = '97' THEN 'Ended Unknown Assessed Only'
		WHEN b.[ENDCODE] = '40' THEN 'Ended Stepped Up'
		WHEN b.[ENDCODE] = '41' THEN 'Ended Stepped Down'
		WHEN b.[ENDCODE] = '42' THEN 'Ended Completed'
		WHEN b.[ENDCODE] = '43' THEN 'Ended Dropped Out'
		WHEN b.[ENDCODE] = '44' THEN 'Ended Referred Non IAPT'
		WHEN b.[ENDCODE] = '45' THEN 'Ended Deceased Treated'
		WHEN b.[ENDCODE] = '98' THEN 'Ended Unknown Treated'
		when b.[ENDCODE] = '50' then 'Ended Not Assessed'
		when b.[ENDCODE] = '16' then 'Ended Incomplete Assessment'
		when b.[ENDCODE] = '17' then 'Ended Deceased (Seen but not taken on for a course of treatment)'
		when b.[ENDCODE] = '95' then 'Ended Not Known (Seen but not taken on for a course of treatment)'
		when b.[ENDCODE] = '46' then 'Ended Mutually agreed completion of treatment'
		when b.[ENDCODE] = '47' then 'Ended Termination of treatment earlier than Care Professional planned'
		when b.[ENDCODE] = '48' then 'Ended Termination of treatment earlier than patient requested'
		when b.[ENDCODE] = '49' then 'Ended Deceased (Seen and taken on for a course of treatment)'
		when b.[ENDCODE] = '96' then 'Ended Not Known (Seen and taken on for a course of treatment)'
	END AS 'EndCode'
	,a.[PathwayID] AS 'LatestID'
	,b.[PathwayID] AS 'PreviousID'
	,a.[ReferralOrder2] AS 'LatestRowID'
	,b.[ReferralOrder2] AS 'PreviousRowID'
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2] a
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2] b ON a.[PseudoNumber] = b.[PseudoNumber] AND a.[ReferralOrder2] = (b.[ReferralOrder2] -1)
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_ValidReferrals] v ON a.[PathwayID] = v.[PathwayID] AND a.[ReferralRequestReceivedDate] = v.[ReferralRequestReceivedDate]
WHERE 
	b.[ServDischDate] IS NOT NULL 
	AND a.[PseudoNumber] <> '0' 
	AND a.[PseudoNumber] IS NOT NULL 
	AND b.[PseudoNumber] <> '0' 
	AND b.[PseudoNumber] IS NOT NULL
GO
-- SELECTS THE FIRST [Provider Code] LISTED (MATCHES REFERRAL COUNT ORG) -- For v2.0 the REFERRAL_ID field contains UniqueID_IDS101

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2]
SELECT
	[PathwayID]
	,MAX([UniqueID_IDS101]) AS UniqueID_IDS101
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2]
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]
WHERE Month(ReferralRequestReceivedDate) = Month(ReportingPeriodStartDate) AND Year(ReferralRequestReceivedDate) = Year(ReportingPeriodStartDate) 
GROUP BY [PathwayID]
GO
---------------------------------------------------------------------------------------------------
UPDATE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
SET LatestCCG = CASE WHEN a.[CCG Code] IS NULL THEN 'Other' ELSE a.[CCG Code] END 
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1] r
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] a ON [LatestID] = a.[PathwayID]
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2] m ON m.[PathwayID] = [LatestID] AND m.[UniqueID_IDS101] = a.[UniqueID_IDS101]

UPDATE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
SET PreviousCCG = CASE WHEN a.[CCG Code] IS NULL THEN 'Other' ELSE a.[CCG Code] END
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1] r
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] a ON PreviousID = a.PathwayID
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2] m ON m.[PathwayID] = [PreviousID] AND m.[UniqueID_IDS101] = a.[UniqueID_IDS101]

UPDATE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
SET LatestProvider = CASE WHEN a.[Provider Code] IS NULL THEN 'Other' ELSE a.[Provider Code] END
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1] r
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] a ON [LatestID] = a.[PathwayID]
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2] m ON m.[PathwayID] = [LatestID] AND m.[UniqueID_IDS101] = a.[UniqueID_IDS101]

UPDATE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
SET PreviousProvider = CASE WHEN [Provider Code] IS NULL THEN 'Other' ELSE a.[Provider Code] END
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1] r
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All] a ON [PreviousID] = a.[PathwayID]
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2] m ON m.[PathwayID] = [PreviousID] AND m.[UniqueID_IDS101] = a.[UniqueID_IDS101]

--------------------------------------------------------------------------------------------------
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2]
SELECT DISTINCT
	rr.*
	,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2]	
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1] rr

--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON rr.[LatestCCG] = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, rr.[LatestCCG]) = ch.Organisation_Code COLLATE database_default
	AND ch.Effective_To IS NULL

LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON rr.[LatestProvider] = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, rr.[LatestProvider]) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL


-- Repeat Referrals Table ----------------------------------------------------------------------------------------------------

-- The full table has to be re-run each month ---------------------

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_RepeatReferrals]

DECLARE @Offset INT = 0

WHILE @Offset>= -((SELECT MAX(Unique_MonthID) FROM [mesh_IAPT].[IsLatest_SubmissionID])-1-1457) --Defines September 2021 so Repeat Referrals are looked at from Sept 2021 to the latest month

BEGIN 

DECLARE @Period_Start AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Period_end AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_RepeatReferrals]
SELECT * FROM (
	SELECT 
		DATENAME(m, @Period_Start) + ' ' + CAST(DATEPART(yyyy, @Period_Start) AS varchar) AS Month
		,[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		,'Problem Descriptor' AS Category
		,LatestDiagnosis AS LatestDiagnosis
		,PreviousDiagnosis AS PreviousDiagnosis
		,COUNT(DISTINCT CASE WHEN [Time between referrals] < 92 THEN LatestID END) AS '91 days or fewer'
		,COUNT(DISTINCT CASE WHEN [Time between referrals] BETWEEN 92 AND 182 THEN LatestID END) AS '92-182 days'
		,COUNT(DISTINCT CASE WHEN [Time between referrals] BETWEEN 183 AND 273 THEN LatestID END) AS '183-273 days'
		,COUNT(DISTINCT CASE WHEN [Time between referrals] > 273 THEN LatestID END) AS 'More than 273 days'

	FROM	[MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2] rr
			------------------
	WHERE LatestReferral BETWEEN @Period_Start AND @Period_end AND [Time between referrals] BETWEEN 0 AND 365  AND PreviousCountAppointments >= 2 
	AND LatestID <> PreviousID AND PseudoNumber IS NOT NULL AND LatestReferral <> PreviousReferral AND PseudoNumber <> '0'

	GROUP BY 	
		[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		,LatestDiagnosis
		,PreviousDiagnosis		
)_

SET @Offset = @Offset - 1
END
GO


---- Create [MHDInternal].[TEMP_TTAD_PDT_RepeatReferrals_Insert] -------------------------------------------------------------------------

DELETE FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatReferrals_Insert]

DECLARE @Offset INT = 0

WHILE @Offset>= -((SELECT MAX(Unique_MonthID) FROM [mesh_IAPT].[IsLatest_SubmissionID])-1-1457) --Defines September 2021 so Repeat Referrals are looked at from Sept 2021 to the latest month

BEGIN 

DECLARE @Period_Start AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Period_end AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])

INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_RepeatReferrals_Insert]
SELECT 
	CAST(DATENAME(m, @Period_Start) + ' ' + CAST(DATEPART(yyyy, @Period_Start) AS VARCHAR) AS DATE) AS 'Month'
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Total' AS Category
	,'Total' AS Variable
	,COUNT (DISTINCT LatestID) AS 'Repeat Referrals'
FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2] rr
WHERE 	
	LatestReferral BETWEEN @Period_Start AND @Period_end 
	AND [Time between referrals] BETWEEN 0 AND 365  
	AND [PreviousCountAppointments] >= 2 
	AND [LatestID] <> [PreviousID] 
	AND [PseudoNumber] IS NOT NULL 
	AND [LatestReferral] <> [PreviousReferral] 
	AND [PseudoNumber] <> '0'

GROUP BY
		[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]

SET @Offset = @Offset - 1
END

-- Update [RepeatReferrals2] in [DASHBOARD_TTAD_PDT_Inequalities] from [DASHBOARD_TTAD_PDT_RepeatReferrals_Insert] -------------------

UPDATE [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] SET [RepeatReferrals2] = NULL
UPDATE [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] SET [RepeatReferrals2] = b.[Repeat Referrals]

FROM [MHDInternal].[TEMP_TTAD_PDT_RepeatReferrals_Insert] b

INNER JOIN [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] a ON a.[Month] = b.[Month]
			AND a.[Region Code] = b.[Region Code] 
			AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code]
			AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] 
			AND (a.[Variable] = b.[Variable] OR a.[Variable] IS NULL AND b.[Variable] IS NULL)

------------------------------------------------------------------------------------------------------------------------------------
--Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_All]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_MaxRecord]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Spell2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_ValidReferrals]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base1]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Record2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_RepeatRefs_Base2]
-------------------------
PRINT CHAR(10)
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_RepeatReferrals]'
PRINT 'Updated - [MHDInternal].[TEMP_TTAD_PDT_RepeatReferrals_Insert]'