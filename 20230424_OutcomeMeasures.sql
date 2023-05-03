USE [NHSE_IAPT_v2]

SET NOCOUNT ON
SET ANSI_WARNINGS OFF
PRINT CHAR(10)

DECLARE @Offset INT = -1

--DECLARE @Max_Offset INT = -29
---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [NHSE_IAPT_v2].[dbo].[IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [NHSE_IAPT_v2].[dbo].[IDS000_Header])

DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

--------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_Outcomes_v3]

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'

		,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
			WHEN  LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
			WHEN  LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
		ELSE 'Other' END AS 'Language_Treated'
 
		--------------------------
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Recovery'
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Improvement'
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Reliable_Recovery'
		--------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END)
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'   AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float)
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END
		AS 'Percentage_Recovery'
		--------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float))) END
		AS 'Percentage_Improvement'
		-----------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float))) END
		AS 'Percentage_Reliable_Recovery'
		----------------------------------

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON a.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodendDate]
		AND l.IsLatest = '1' AND UsePathway_Flag = 'True'
		AND CompletedTreatment_Flag = 'TRUE'
		AND LanguageCodePreferred <> 'en'

GROUP BY	DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR)
			,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
				WHEN  LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
				WHEN  LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
				ELSE 'Other' END

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_Outcomes_v3]'
