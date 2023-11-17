SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Offset INT = -1
-------------------------------
--DECLARE @Max_Offset INT = -1
---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-----------------------------------------------------------------------------------------------------------------------------------
-- Create base tables -------------------------------------------------------------------------------------------------------------

-- Referrals --------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals]

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd

-- Accessed treatment ---------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment]

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,r.TherapySession_FirstDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND CareContDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CareContDate = TherapySession_FirstDate

-- Finished treatment ---------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,TreatmentCareContact_Count
		,CompletedTreatment_Flag
		,Recovery_Flag
		,NotCaseness_Flag

INTO	[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		AND CareContact_Count > 2

-- Calculate Counts --------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals_p]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals_p]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Referrals' 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals_p] 
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals] 
WHERE [PreferredLang] IS NOT NULL 
GROUP BY [PreferredLang]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment_p]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment_p]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Accessed' 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment_p]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment]
WHERE [PreferredLang] IS NOT NULL
GROUP BY [PreferredLang]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment_p]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment_p]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Finished'
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment_p]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]
WHERE [PreferredLang] IS NOT NULL
GROUP BY [PreferredLang]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Recovery_p]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Recovery_p]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Recovery'
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Recovery_p]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]
WHERE [PreferredLang] IS NOT NULL AND CompletedTreatment_flag = 'TRUE' AND  Recovery_Flag = 'True'
GROUP BY [PreferredLang]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_NotCaseness_p]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_NotCaseness_p]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_NotCaseness'
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_NotCaseness_p]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]
WHERE [PreferredLang] IS NOT NULL AND NotCaseness_Flag = 'TRUE'
GROUP BY [PreferredLang]

-- Insert data -------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]

SELECT TOP(20) 

		@MonthYear AS 'Month'
		,rp.PreferredLang
		,Count_Referrals
		,Count_Accessed
		,Count_Finished
		,Count_Recovery
		,Count_NotCaseness

FROM	[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals_p] rp
		---------------
		INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment_p] atp ON rp.PreferredLang = atp.PreferredLang
		INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment_p] ftp ON rp.PreferredLang = ftp.PreferredLang
		INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Recovery_p] rec ON rp.PreferredLang = rec.PreferredLang
		INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_NotCaseness_p] nc ON rp.PreferredLang = nc.PreferredLang 

GROUP BY rp.PreferredLang, Count_Referrals, Count_Accessed, Count_Finished, Count_Recovery, Count_NotCaseness

ORDER BY Count_Referrals DESC

--Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FinishedTreatment]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Referrals_p]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AccessedTreatment_p]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Recovery_p]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_NotCaseness_p]
----------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]'
