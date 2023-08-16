SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Offset INT = -1
--------------------------
-- DECLARE @Max_Offset INT = -25
---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Interpreter present ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create base table of care contacts (Preferred language not = Treatment language) -----------

IF OBJECT_ID ('tempdb..#InterpreterPresent') IS NOT NULL DROP TABLE #InterpreterPresent

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,InterpreterPresentInd

INTO #InterpreterPresent

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
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')
		AND LanguageCodePreferred <> LanguageCodeTreat

-- Insert data -------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_InterpreterPresent]

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Professional interpreter' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('1') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Family member or friend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('2') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Another Person' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('3') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter not required' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('4') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter was required but did not attend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('5') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_InterpreterPresent]'