SET ANSI_WARNINGS OFF
SET NOCOUNT ON

---------------------------------------------------------------------------------------------------------------------------------
-- This script MUST be run AFTER script 2.11 which feeds [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] ------------------------
---------------------------------------------------------------------------------------------------------------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Refresh updates for: [MHDInternal].[STAGING_TTAD_PDT_Over65Metrics] ------------------------------------------------------

--IF OBJECT_ID('[MHDInternal].[STAGING_TTAD_PDT_Over65Metrics]') IS NOT NULL DROP TABLE [MHDInternal].[STAGING_TTAD_PDT_Over65Metrics]
INSERT INTO [MHDInternal].[STAGING_TTAD_PDT_Over65Metrics]
SELECT *
--INTO [MHDInternal].[STAGING_TTAD_PDT_Over65Metrics]
FROM(
	--National
	SELECT
		[Month] 
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,'All' AS 'Region Code'
		,'All' AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,[Category]
		,[Variable]
		,SUM([Finished Treatment - 2 or more Apps]) AS 'Finished Treatment - 2 or more Apps'
		,SUM([Referrals]) AS 'Referrals'
		,SUM([EnteringTreatment]) AS 'EnteringTreatment'
		,'National' AS 'Level'

	FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

	WHERE 
		Category = 'Age'
		AND Variable = '65+' 
		AND [Month] = @MonthYear

	GROUP BY
		[Month]
		,[Category]
		,[Variable]

	UNION ----------------------------------------------------------------
	--Region
	SELECT	
		[Month]
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,[Region Code] AS 'Region Code'
		,[Region Name] AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,[Category]
		,[Variable]
		,CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT) END
		AS [Finished Treatment - 2 or more Apps]
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
		AS [Referrals]
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
		AS [EnteringTreatment]
		,'Region' AS 'Level'

	FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

	WHERE 
		Category = 'Age'
		AND Variable = '65+'
		AND [Month] = @MonthYear

	GROUP BY
		[Month]
		,[Region Code]
		,[Region Name]
		,[Category]
		,[Variable]

	UNION ----------------------------------------------------------------
	--ICB
	SELECT	
		[Month]
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,'All' AS 'Region Code'
		,'All' AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,[STP Code] AS 'STP Code'
		,[STP Name] AS 'STP Name'
		,[Category]
		,[Variable]
		,CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT) END
		AS [Finished Treatment - 2 or more Apps]
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
		AS [Referrals]
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
		AS [EnteringTreatment]
		,'STP' AS 'Level'

	FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

	WHERE 
		Category = 'Age' 
		AND Variable = '65+' 
		AND [Month] = @MonthYear

	GROUP BY
		[Month]
		,[STP Code]
		,[STP Name]
		,[Category]
		,[Variable]

	UNION ----------------------------------------------------------------

	--Sub-ICB
	SELECT	
		[Month]
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,'All' AS 'Region Code'
		,'All' AS 'Region Name'
		,[CCG Code] AS 'CCG Code'
		,[CCG Name] AS 'CCG Name'
		,'All' AS 'Provider Code'
		,'All' AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,[Category]
		,[Variable]
		,CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT) END
		AS [Finished Treatment - 2 or more Apps]
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
		AS [Referrals]
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
		AS [EnteringTreatment]
		,'CCG' AS 'Level'

	FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

	WHERE 
		Category = 'Age'
		AND Variable = '65+'
		AND [Month] = @MonthYear

	GROUP BY 
		[Month]
		,[CCG Code]
		,[CCG Name]
		,[Category]
		,[Variable]

	UNION ----------------------------------------------------------------

	--Provider
	SELECT	
		[Month] 
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,'All' AS 'Region Code'
		,'All' AS 'Region Name'
		,'All' AS 'CCG Code'
		,'All' AS 'CCG Name'
		,[Provider Code] AS 'Provider Code'
		,[Provider Name] AS 'Provider Name'
		,'All' AS 'STP Code'
		,'All' AS 'STP Name'
		,[Category]
		,[Variable]
		,CASE WHEN SUM([Finished Treatment - 2 or more Apps])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment - 2 or more Apps])+2) /5,0)*5 AS INT) END
		AS [Finished Treatment - 2 or more Apps]
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
		AS [Referrals]
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
		AS [EnteringTreatment]
		,'Provider' AS 'Level'

	FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

	WHERE 
		Category = 'Age' 
		AND Variable = '65+' 
		AND [Month] = @MonthYear

	GROUP BY
		[Month]
		,[Provider Code]
		,[Provider Name]
		,[Category]
		,[Variable]

)_
------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[STAGING_TTAD_PDT_Over65Metrics]'
