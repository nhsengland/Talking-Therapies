SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- DELETE MAX(Month) -----------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics]
 
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics])

-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics] -----------------------------

DECLARE @Offset AS INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

---------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics]

SELECT * FROM (

	SELECT	[Month]
			,[DataSource]
			,[GroupType]
			,[Level]
			,[Region Code]
			,[Region Name]
			,[CCG Code]
			,[CCG Name]
			,[Provider Code]
			,[Provider Name]
			,[STP Code]
			,[STP Name]
			,[Category]
			,[Variable]
			,[Measure]
			,[Value]

	FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded] s

	UNPIVOT ([Value] FOR [Measure] IN ([Finished Treatment - 2 or more Apps], [Referrals], [EnteringTreatment])) u

	WHERE	[Level] <> 'CCG/ Provider' 
		AND ([Month] = @MonthYear OR [Month] = DATEADD(MONTH, -1, @MonthYear))

	UNION -----------------------------------------------------------------------

	SELECT	[Month]
			,[DataSource]
			,[GroupType]
			,[Level]
			,[Region Code]
			,[Region Name]
			,[CCG Code]
			,[CCG Name]
			,[Provider Code]
			,[Provider Name]
			,[STP Code]
			,[STP Name]
			,[Category]
			,[Variable]
			,[Measure]
			,[Value]

	FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesNewIndicatorsRounded] s

	UNPIVOT ([Value] FOR [Measure] IN ([FinishedCourseTreatment6WeeksRate], [FinishedCourseTreatment18WeeksRate], [RecoveryRate], [ReliableImprovementRate], [OpenReferral90daysRate], [FirsttoSecond90daysRate])) u

	WHERE	[Level] <> 'CCG/ Provider' 
		AND ([Month] = @MonthYear OR [Month] = DATEADD(MONTH, -1, @MonthYear))

	UNION -----------------------------------------------------------------------

	SELECT	[Month]
			,[DataSource]
			,[GroupType]
			,[Level]
			,[Region Code]
			,[Region Name]
			,[CCG Code]
			,[CCG Name]
			,[Provider Code]
			,[Provider Name]
			,[STP Code]
			,[STP Name]
			,[Category]
			,[Variable]
			,[Measure]
			,[Value]

	FROM	[MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities] s

	UNPIVOT ([Value] FOR [Measure] IN ([RecRate])) u

	WHERE [Month] = @MonthYear OR [Month] = DATEADD(MONTH, -1, @MonthYear)

	UNION -----------------------------------------------------------------------

	SELECT	[Month]
			,[DataSource]
			,[GroupType]
			,[Level]
			,[Region Code]
			,[Region Name]
			,[CCG Code]
			,[CCG Name]
			,[Provider Code]
			,[Provider Name]
			,[STP Code]
			,[STP Name]
			,[Category]
			,[Variable]
			,[Measure]
			,[Value]

	FROM	[MHDInternal].[STAGING_TTAD_PDT_Over65Metrics] s

	UNPIVOT ([Value] FOR [Measure] IN ([EnteringTreatment])) u

	WHERE [Month] = @MonthYear OR [Month] = DATEADD(MONTH, -1, @MonthYear)

)_

-----------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics]'
