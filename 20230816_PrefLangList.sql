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
IF OBJECT_ID ('tempdb..#Referrals') IS NOT NULL DROP TABLE #Referrals

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	#Referrals

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd

-- Accessed treatment ---------------------------------------------------------------
IF OBJECT_ID ('tempdb..#AccessedTreatment') IS NOT NULL DROP TABLE #AccessedTreatment

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,r.TherapySession_FirstDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	#AccessedTreatment

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND CareContDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CareContDate = TherapySession_FirstDate

-- Finished treatment ---------------------------------------------------------------
IF OBJECT_ID ('tempdb..#FinishedTreatment') IS NOT NULL DROP TABLE #FinishedTreatment

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,TreatmentCareContact_Count
		,CompletedTreatment_Flag
		,Recovery_Flag
		,NotCaseness_Flag

INTO	#FinishedTreatment

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		AND CareContact_Count > 2

-- Calculate Counts --------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Referrals_p') IS NOT NULL DROP TABLE #Referrals_p
IF OBJECT_ID ('tempdb..#AccessedTreatment_p') IS NOT NULL DROP TABLE #AccessedTreatment_p
IF OBJECT_ID ('tempdb..#FinishedTreatment_p') IS NOT NULL DROP TABLE #FinishedTreatment_p
IF OBJECT_ID ('tempdb..#Recovery_p') IS NOT NULL DROP TABLE #Recovery_p
IF OBJECT_ID ('tempdb..#NotCaseness_p') IS NOT NULL DROP TABLE #NotCaseness_p

SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Referrals' INTO #Referrals_p FROM #Referrals WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Accessed' INTO #AccessedTreatment_p FROM #AccessedTreatment WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Finished' INTO #FinishedTreatment_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Recovery' INTO #Recovery_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL AND CompletedTreatment_flag = 'TRUE' AND  Recovery_Flag = 'True' GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_NotCaseness' INTO #NotCaseness_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL AND NotCaseness_Flag = 'TRUE' GROUP BY [PreferredLang]

-- Insert data -------------------------------------------------------------------------------------------------------------------

--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]

SELECT TOP(20) 

		@MonthYear AS 'Month'
		,rp.PreferredLang
		,Count_Referrals
		,Count_Accessed
		,Count_Finished
		,Count_Recovery
		,Count_NotCaseness

FROM	#Referrals_p rp
		---------------
		INNER JOIN #AccessedTreatment_p atp ON rp.PreferredLang = atp.PreferredLang
		INNER JOIN #FinishedTreatment_p ftp ON rp.PreferredLang = ftp.PreferredLang
		INNER JOIN #Recovery_p rec ON rp.PreferredLang = rec.PreferredLang
		INNER JOIN #NotCaseness_p nc ON rp.PreferredLang = nc.PreferredLang 

GROUP BY rp.PreferredLang, Count_Referrals, Count_Accessed, Count_Finished, Count_Recovery, Count_NotCaseness

ORDER BY Count_Referrals DESC

----------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]'