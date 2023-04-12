USE [NHSE_IAPT_v2]

SET NOCOUNT ON
SET ANSI_WARNINGS OFF
PRINT CHAR(10)

DECLARE @Offset INT = -1
DECLARE @Max_Offset INT = -25

---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create base table of care contacts (Preferred language not = English) -------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#CareContacts_NotEng') IS NOT NULL DROP TABLE #CareContacts_NotEng

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,ReferralRequestReceivedDate
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'

INTO #CareContacts_NotEng

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		FULL JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06') -- attended on time or arrived late
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND LanguageCodePreferred <> 'en'

-- Create base table of care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#CareContacts_Eng') IS NOT NULL DROP TABLE #CareContacts_Eng

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,ReferralRequestReceivedDate
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'

INTO #CareContacts_Eng

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		FULL JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06') -- attended on time or arrived late
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND LanguageCodePreferred = 'en'

-- Create table of 1st care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#FirstCareContacts_NotEng') IS NOT NULL DROP TABLE #FirstCareContacts_NotEng

SELECT * INTO #FirstCareContacts_NotEng

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_NotEng )_

WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#SecondCareContacts_NotEng') IS NOT NULL DROP TABLE #SecondCareContacts_NotEng

SELECT * INTO #SecondCareContacts_NotEng

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_NotEng )_

WHERE countAppts = 2

-- Create table of 1st care contacts (Preferred language = English) -----------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#FirstCareContacts') IS NOT NULL DROP TABLE #FirstCareContacts

SELECT * INTO #FirstCareContacts

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_Eng )_

WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#SecondCareContacts') IS NOT NULL DROP TABLE #SecondCareContacts

SELECT * INTO #SecondCareContacts

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_Eng )_

WHERE countAppts = 2

-- Averages --------------------------------------------------------------------------------------------------------------------------------

Declare @AVG_WaitToFirst_Eng AS FLOAT = (SELECT(AVG(WaitToFirstTreatment)) AS 'Avg_WaitToFirstTreatment' FROM #FirstCareContacts WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)
Declare @AVG_WaitToFirst_NotEng AS FLOAT = (SELECT(AVG(WaitToFirstTreatment)) AS 'Avg_WaitToFirstTreatment_NotEng' FROM #FirstCareContacts_NotEng WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)

DECLARE @AVG_WaitToSecond_Eng AS FLOAT = (SELECT(AVG(WaitToSecondTreatment)) AS 'Avg_WaitToSecondTreatment' FROM #SecondCareContacts WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)
DECLARE @AVG_WaitToSecond_NotEng AS FLOAT = (SELECT(AVG(WaitToSecondTreatment)) AS 'Avg_WaitToSecondTreatment_NotEng' FROM #SecondCareContacts_NotEng WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)

-- Final table --------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_AvgWaits_v2]

------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'
		,@AVG_WaitToFirst_NotEng AS 'AVG_WaitToFirst_NotEng'
		,(@AVG_WaitToSecond_NotEng - @AVG_WaitToFirst_NotEng) AS 'AVG_WaitToSecond_NotEng'
		,@AVG_WaitToFirst_Eng AS 'AVG_WaitToFirst_Eng' 
		,(@AVG_WaitToSecond_Eng - @AVG_WaitToFirst_Eng) AS 'AVG_WaitToSecond_Eng' 	

------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

-----------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_AvgWaits_v2]'