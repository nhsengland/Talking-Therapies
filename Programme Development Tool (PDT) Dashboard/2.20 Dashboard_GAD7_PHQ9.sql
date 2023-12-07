SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- DELETE MAX(Month) -----------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PHQ9_GAD7]
 
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PHQ9_GAD7])

-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_PHQ9_GAD7] -----------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

--Base Table
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]

SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
	,r.PathwayID
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
	,r.PHQ9_FirstScore
	,r.GAD_FirstScore
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN 1 ELSE 0 END AS Discharge

INTO [MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE
	r.UsePathway_Flag = 'True' 
	AND l.IsLatest = 1
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart

-----------------------------------------------------------
--Final Aggregate Table
--This table aggregates the base table created above ([MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]) to produce the final table used in the dashboard

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PHQ9_GAD7]

SELECT
	Month
	,'Refresh' AS 'DataSource'
	,'PHQ-9' AS 'Indicator'
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,PHQ9_FirstScore AS Score
	,SUM(Discharge) AS Count

FROM [MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,PHQ9_FirstScore
GO

SELECT
	Month
	,'Refresh' AS 'DataSource'
	,'GAD7' AS 'Indicator'
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,GAD_FirstScore AS Score
	,SUM(Discharge) AS Count

FROM [MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,GAD_FirstScore

-- Drop Temporary Table ---------------------------------------------------------------------------------------------------------

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_PHQ9GAD7Base]

-----------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PHQ9_GAD7]'
