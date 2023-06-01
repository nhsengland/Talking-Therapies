SET ANSI_WARNINGS OFF
SET DATEFIRST 1
SET NOCOUNT ON

-- Refresh update for: [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot] -----------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID])

DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

---------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot]

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

FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded] s

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

FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Monthly_IST_New_Indicators_Rounded] s

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

FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Intensive_Support_Dashboard_BAME] s

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

FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Over_65_Metrics] s

UNPIVOT ([Value] FOR [Measure] IN ([EnteringTreatment])) u

WHERE	[Level] <> 'CCG/ Provider' AND [Month] = @MonthYear;

-----------------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot]'
