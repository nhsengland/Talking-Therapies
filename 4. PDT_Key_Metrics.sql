SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities_Rounded_Unpivot] -----------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

---------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics]

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

FROM	[MHDInternal].[STAGING_TTAD_PDT_Inequalities_Rounded] s

UNPIVOT ([Value] FOR [Measure] IN ([Finished Treatment - 2 or more Apps], [Referrals], [EnteringTreatment])) u

WHERE	[Level] <> 'CCG/ Provider' AND [Month] = @MonthYear

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

FROM	[MHDInternal].[DASHBOARD_TTAD_PAD_Inequalities_New_Indicators_Rounded] s

UNPIVOT ([Value] FOR [Measure] IN ([FinishedCourseTreatment6WeeksRate], [FinishedCourseTreatment18WeeksRate], [RecoveryRate], [ReliableImprovementRate], [OpenReferral90daysRate], [FirsttoSecond90daysRate])) u

WHERE	[Level] <> 'CCG/ Provider' AND [Month] = @MonthYear

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

FROM	[MHDInternal].[DASHBOARD_TTAD_PAD_BAME] s

UNPIVOT ([Value] FOR [Measure] IN ([RecRate])) u

WHERE	[Level] <> 'CCG/ Provider' AND [Month] = @MonthYear

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

FROM	[MHDInternal].[DASHBOARD_TTAD_PAD_Over_65_Metrics] s

UNPIVOT ([Value] FOR [Measure] IN ([EnteringTreatment])) u

WHERE	[Level] <> 'CCG/ Provider' AND [Month] = @MonthYear;

-----------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_KeyMetrics]'
