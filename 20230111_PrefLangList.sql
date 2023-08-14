USE [NHSE_IAPT_v2]

SET NOCOUNT ON
SET ANSI_WARNINGS OFF
PRINT CHAR(10)

DECLARE @Offset INT = -1
--DECLARE @Max_Offset INT = -25

---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

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

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

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

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

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

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		AND CareContact_Count > 2

 --GO --(Separate the script into two halves)

----------------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_language_PrefLangList_v4]

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

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_language_PrefLangList_v4]'