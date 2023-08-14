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

-- Create base table of care contacts (Preferred language not = Treatment language) -------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#CareContacts') IS NOT NULL DROP TABLE #CareContacts

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,InterpreterPresentInd

INTO #CareContacts

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		FULL JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON a.LanguageCodeTreat = lct.LanguageCode
		FULL JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND CareContDate BETWEEN @PeriodStart AND @PeriodEnd
		AND AttendOrDNACode IN ('5','05','6','06') -- attended on time or arrived late
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND LanguageCodePreferred <> LanguageCodeTreat

------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_preferred_language_InterpreterPresent]

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Professional interpreter' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('1') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #CareContacts

UNION 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Family member or friend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('2') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #CareContacts

UNION 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Another Person' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('3') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #CareContacts

UNION 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter not required' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('4') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #CareContacts

UNION 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter was required but did not attend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('5') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #CareContacts

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

-----------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_preferred_language_InterpreterPresent]'