SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_PHQ9_GAD7] ----------------------------------------------------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Sub ICB / ICB ------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_PHQ9_GAD7]

SELECT	@MonthYear AS 'Month'
		,'Refresh' AS 'DataSource'
		,'PHQ-9' AS 'Indicator'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,CASE WHEN PHQ9_FirstScore = 0 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 0 
			WHEN PHQ9_FirstScore = 1 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 1 
			WHEN PHQ9_FirstScore = 2 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 2 
			WHEN PHQ9_FirstScore = 3 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 3 
			WHEN PHQ9_FirstScore = 4 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 4 
			WHEN PHQ9_FirstScore = 5 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 5 
			WHEN PHQ9_FirstScore = 6 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 6 
			WHEN PHQ9_FirstScore = 7 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 7 
			WHEN PHQ9_FirstScore = 8 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 8 
			WHEN PHQ9_FirstScore = 9 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 9 
			WHEN PHQ9_FirstScore = 10 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 10
			WHEN PHQ9_FirstScore = 11 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 11 
			WHEN PHQ9_FirstScore = 12 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 12 
			WHEN PHQ9_FirstScore = 13 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 13 
			WHEN PHQ9_FirstScore = 14 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 14 
			WHEN PHQ9_FirstScore = 15 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 15 
			WHEN PHQ9_FirstScore = 16 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 16 
			WHEN PHQ9_FirstScore = 17 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 17 
			WHEN PHQ9_FirstScore = 18 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 18 
			WHEN PHQ9_FirstScore = 19 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 19 
			WHEN PHQ9_FirstScore = 20 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 20 
			WHEN PHQ9_FirstScore = 21 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 21
			WHEN PHQ9_FirstScore = 22 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 22
			WHEN PHQ9_FirstScore = 23 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 23
			WHEN PHQ9_FirstScore = 24 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 24
			WHEN PHQ9_FirstScore = 25 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 25
			WHEN PHQ9_FirstScore = 26 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 26
			WHEN PHQ9_FirstScore = 27 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 27 
			END AS 'Score'
		,COUNT (DISTINCT r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND h.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN PHQ9_FirstScore = 0 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 0 
			WHEN PHQ9_FirstScore = 1 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 1 
			WHEN PHQ9_FirstScore = 2 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 2 
			WHEN PHQ9_FirstScore = 3 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 3 
			WHEN PHQ9_FirstScore = 4 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 4 
			WHEN PHQ9_FirstScore = 5 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 5 
			WHEN PHQ9_FirstScore = 6 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 6 
			WHEN PHQ9_FirstScore = 7 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 7 
			WHEN PHQ9_FirstScore = 8 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 8 
			WHEN PHQ9_FirstScore = 9 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 9 
			WHEN PHQ9_FirstScore = 10 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 10
			WHEN PHQ9_FirstScore = 11 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 11 
			WHEN PHQ9_FirstScore = 12 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 12 
			WHEN PHQ9_FirstScore = 13 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 13 
			WHEN PHQ9_FirstScore = 14 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 14 
			WHEN PHQ9_FirstScore = 15 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 15 
			WHEN PHQ9_FirstScore = 16 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 16 
			WHEN PHQ9_FirstScore = 17 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 17 
			WHEN PHQ9_FirstScore = 18 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 18 
			WHEN PHQ9_FirstScore = 19 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 19 
			WHEN PHQ9_FirstScore = 20 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 20 
			WHEN PHQ9_FirstScore = 21 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 21
			WHEN PHQ9_FirstScore = 22 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 22
			WHEN PHQ9_FirstScore = 23 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 23
			WHEN PHQ9_FirstScore = 24 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 24
			WHEN PHQ9_FirstScore = 25 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 25
			WHEN PHQ9_FirstScore = 26 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 26
			WHEN PHQ9_FirstScore = 27 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 27 
		END

UNION 

SELECT @MonthYear AS 'Month'
		,'Refresh' AS 'DataSource'
		,'GAD7' AS 'Indicator'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,CASE WHEN GAD_FirstScore = 0 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 0 
			WHEN GAD_FirstScore = 1 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 1 
			WHEN GAD_FirstScore = 2 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 2 
			WHEN GAD_FirstScore = 3 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 3 
			WHEN GAD_FirstScore = 4 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 4 
			WHEN GAD_FirstScore = 5 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 5 
			WHEN GAD_FirstScore = 6 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 6 
			WHEN GAD_FirstScore = 7 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 7 
			WHEN GAD_FirstScore = 8 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 8 
			WHEN GAD_FirstScore = 9 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 9 
			WHEN GAD_FirstScore = 10 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 10
			WHEN GAD_FirstScore = 11 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 11 
			WHEN GAD_FirstScore = 12 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 12 
			WHEN GAD_FirstScore = 13 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 13 
			WHEN GAD_FirstScore = 14 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 14 
			WHEN GAD_FirstScore = 15 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 15 
			WHEN GAD_FirstScore = 16 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 16 
			WHEN GAD_FirstScore = 17 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 17 
			WHEN GAD_FirstScore = 18 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 18 
			WHEN GAD_FirstScore = 19 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 19 
			WHEN GAD_FirstScore = 20 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 20 
			WHEN GAD_FirstScore = 21 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 21
		END AS 'Score'
		,COUNT (DISTINCT r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND h.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN GAD_FirstScore = 0 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 0 
			WHEN GAD_FirstScore = 1 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 1 
			WHEN GAD_FirstScore = 2 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 2 
			WHEN GAD_FirstScore = 3 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 3 
			WHEN GAD_FirstScore = 4 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 4 
			WHEN GAD_FirstScore = 5 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 5 
			WHEN GAD_FirstScore = 6 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 6 
			WHEN GAD_FirstScore = 7 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 7 
			WHEN GAD_FirstScore = 8 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 8 
			WHEN GAD_FirstScore = 9 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 9 
			WHEN GAD_FirstScore = 10 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 10
			WHEN GAD_FirstScore = 11 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 11 
			WHEN GAD_FirstScore = 12 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 12 
			WHEN GAD_FirstScore = 13 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 13 
			WHEN GAD_FirstScore = 14 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 14 
			WHEN GAD_FirstScore = 15 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 15 
			WHEN GAD_FirstScore = 16 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 16 
			WHEN GAD_FirstScore = 17 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 17 
			WHEN GAD_FirstScore = 18 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 18 
			WHEN GAD_FirstScore = 19 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 19 
			WHEN GAD_FirstScore = 20 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 20 
			WHEN GAD_FirstScore = 21 AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN 21
			END

---------------------------------------------------------------------------------------------------------

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_PHQ9_GAD7]'