USE [NHSE_IAPT_v2]

SET NOCOUNT ON
SET ANSI_WARNINGS OFF
PRINT CHAR(10)

DECLARE @Offset INT = -1
DECLARE @Max_Offset INT = -25

---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [NHSE_IAPT_v2].[dbo].[IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [NHSE_IAPT_v2].[dbo].[IDS000_Header])

DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create base table of care contacts ---------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#OutcomeMeasures') IS NOT NULL DROP TABLE #OutcomeMeasures

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,LanguageCodeTreat
		,LanguageCodePreferred
		,a.InterpreterPresentInd
		,Recovery_Flag
		,NotCaseness_Flag
		,ReliableImprovement_Flag
		,NoChange_Flag
		,CompletedTreatment_Flag

INTO #OutcomeMeasures

FROM    [NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		----------------------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lct ON a.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[ISO_639_1_Language_Codes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		-------------------------------------------
		AND LanguageCodePreferred <> 'en'

-- Create variables for calculating outcome measures --------------------------------------------------------------------------------------------------------------------------

-- Treatment language not = preferred language

DECLARE @CompletedTreatment_NotPref AS FLOAT = (SELECT COUNT(CASE WHEN CompletedTreatment_Flag = 'True' AND LanguageCodeTreat <> LanguageCodePreferred THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @NotCaseness_NotPref AS FLOAT = (SELECT COUNT(CASE WHEN NotCaseness_Flag = 'True' AND LanguageCodeTreat <> LanguageCodePreferred THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @Recovery_NotPref AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND LanguageCodeTreat <> LanguageCodePreferred THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableRecovery_NotPref AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' AND LanguageCodeTreat <> LanguageCodePreferred THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableImprovement_NotPref AS FLOAT = (SELECT COUNT(CASE WHEN ReliableImprovement_Flag = 'True' AND LanguageCodeTreat <> LanguageCodePreferred THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)

-- Treatment language = preferred language (therapist)

DECLARE @CompletedTreatment_PrefTreat_therapist AS FLOAT = (SELECT COUNT(CASE WHEN CompletedTreatment_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @NotCaseness_PrefTreat_therapist AS FLOAT = (SELECT COUNT(CASE WHEN NotCaseness_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @Recovery_PrefTreat_therapist AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableRecovery_PrefTreat_therapist AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableImprovement_PrefTreat_therapist AS FLOAT = (SELECT COUNT(CASE WHEN ReliableImprovement_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)

-- Treatment language = preferred language (professional)

DECLARE @CompletedTreatment_PrefTreat_professional AS FLOAT = (SELECT COUNT(CASE WHEN CompletedTreatment_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @NotCaseness_PrefTreat_professional AS FLOAT = (SELECT COUNT(CASE WHEN NotCaseness_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @Recovery_PrefTreat_professional AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableRecovery_PrefTreat_professional AS FLOAT = (SELECT COUNT(CASE WHEN Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)
DECLARE @ReliableImprovement_PrefTreat_professional AS FLOAT = (SELECT COUNT(CASE WHEN ReliableImprovement_Flag = 'True' AND LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN pathwayID ELSE NULL END) FROM #OutcomeMeasures)

---------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_Outcomes_v2]

SELECT DISTINCT @MonthYear AS 'Month'
		,'National' AS 'Level'

		-- Treatment language not preferred ----------------------------------------------------------------------------

		,(@Recovery_NotPref / (@CompletedTreatment_NotPref - @NotCaseness_NotPref)) AS 'Recovery_Rate_NotPref'
		,@Recovery_NotPref AS 'Recovery_Count_NotPref'

		,(@ReliableImprovement_NotPref / @CompletedTreatment_NotPref) AS 'Reliable_Improvement_Rate_NotPref'
		,@ReliableImprovement_NotPref AS 'ReliableImprovement_Count_NotPref'

		,(@ReliableRecovery_NotPref / (@CompletedTreatment_NotPref - @NotCaseness_NotPref)) AS 'Reliable_Recovery_Rate_NotPref'
		,@ReliableRecovery_NotPref AS 'ReliableRecovery_Count_NotPref'

		-- Treatment language = preferred (therapist) ------------------------------------------------------------------

		,(@Recovery_PrefTreat_therapist / (@CompletedTreatment_PrefTreat_therapist - @NotCaseness_PrefTreat_therapist)) AS 'Recovery_Rate_PrefTreat_therapist'
		,@Recovery_PrefTreat_therapist AS 'Recovery_Count_PrefTreat_therapist'

		,(@ReliableImprovement_PrefTreat_therapist / @CompletedTreatment_PrefTreat_therapist) AS 'Reliable_Improvement_Rate_PrefTreat_therapist'
		,@ReliableImprovement_PrefTreat_therapist AS 'ReliableImprovement_Count_PrefTreat_therapist'

		,(@ReliableRecovery_PrefTreat_therapist / (@CompletedTreatment_PrefTreat_therapist - @NotCaseness_PrefTreat_therapist)) AS 'Reliable_Recovery_Rate_PrefTreat_therapist'
		,@ReliableRecovery_PrefTreat_therapist AS 'ReliableRecovery_Count_PrefTreat_therapist'

		-- Treatment language = preferred (professional) ---------------------------------------------------------------

		,(@Recovery_PrefTreat_professional / (@CompletedTreatment_PrefTreat_professional - @NotCaseness_PrefTreat_professional)) AS 'Recovery_Rate_PrefTreat_professional'
		,@Recovery_PrefTreat_professional AS 'Recovery_Count_PrefTreat_professional'

		,(@ReliableImprovement_PrefTreat_professional / @CompletedTreatment_PrefTreat_professional) AS 'Reliable_Improvement_Rate_PrefTreat_professional'
		,@ReliableImprovement_PrefTreat_professional AS 'ReliableImprovement_Count_PrefTreat_professional'

		,(@ReliableRecovery_PrefTreat_professional / (@CompletedTreatment_PrefTreat_professional - @NotCaseness_PrefTreat_professional)) AS 'Reliable_Recovery_Rate_PrefTreat_professional'
		,@ReliableRecovery_PrefTreat_professional AS 'ReliableRecovery_Count_PrefTreat_professional'

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_Preferred_Language_Outcomes_v2]'
