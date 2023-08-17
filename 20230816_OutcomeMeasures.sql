SET NOCOUNT ON
SET ANSI_WARNINGS OFF
PRINT CHAR(10)

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

--------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_Outcomes]

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'

		,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
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
		-----------------------------------

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodendDate]
		AND l.IsLatest = '1' AND UsePathway_Flag = 'True'
		AND CompletedTreatment_Flag = 'TRUE'
		AND LanguageCodePreferred <> 'en'

GROUP BY	DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR)
			,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
				ELSE 'Other' END

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_Outcomes]' + CHAR(10)