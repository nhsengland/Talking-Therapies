SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for: [MHDInternal].[DASHBOARD_TTAD_PDT_IET] ----------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------
-- DELETE MAX(Month) ----------------------------------------------------------------------------------------------------

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET] 

WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET])

----------------------------------------------------------------------------------------------

DECLARE @Offset INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear DATE = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create initial base table: [MHDInternal].[TEMP_TTAD_PDT_IET] --------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_IET]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IET]

SELECT	[PathwayId]
		,[IntEnabledTherProg]
		,SUM([DurationIntEnabledTher]) AS 'TotalTime'
		,row_Number() OVER( PARTITION BY [PathwayID] ORDER BY  SUM([DurationIntEnabledTher])  DESC, MAX([StartDateIntEnabledTherLog]) DESC, MIN([IntEnabledTherProg]) ASC) AS 'ROWID'
		--Ranking is based on the longest IET duration time, followed by the latest start date, followed by alphabetical order of the IET Programme
		--There are instances where a PathwayID has more than one IET Programme with the same start date and same duration time so in these cases they are ranked in alphabetical order
		
INTO [MHDInternal].[TEMP_TTAD_PDT_IET] FROM (

SELECT DISTINCT PathwayId
				,StartDateIntEnabledTherLog
				,EndDateIntEnabledTherLog
				,IntEnabledTherProg
				,DurationIntEnabledTher

FROM [mesh_IAPT].[IDS205internettherlog])_

GROUP BY PathwayId, IntEnabledTherProg

-- Create secondary base table: [MHDInternal].[TEMP_TTAD_PDT_IETBase] --------------------------------------------

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_IETBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IETBase]

SELECT	DISTINCT CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS DATE) AS 'Month'
 		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,r.[PathwayId]
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,CASE WHEN [IntEnabledTherProg] LIKE '%slvrcld%' OR [IntEnabledTherProg] LIKE '%Silvercloud%' OR [IntEnabledTherProg] LIKE '%Silver Cloud%' THEN 'Silver Cloud'
			WHEN [IntEnabledTherProg] LIKE '%Mnddstrct%' THEN 'Mind District'
			WHEN [IntEnabledTherProg] IN ('iCT-PTSD','iCT-SAD') THEN 'iCT' 
			WHEN [IntEnabledTherProg] IN ('OCD.NET','OCD-NET') THEN 'OCD-NET'
			WHEN [IntEnabledTherProg] = 'CHANGE ME' THEN 'Unknown'
			WHEN [IntEnabledTherProg] IS NULL THEN 'No IET'
			ELSE [IntEnabledTherProg] END AS 'Online Platform'
		,CASE WHEN [IntEnabledTherProg] IN ('OCD.NET','OCD-NET') THEN 'OCD-NET'
			WHEN [IntEnabledTherProg] LIKE '%Silvercloud%' OR [IntEnabledTherProg] LIKE '%Silver Cloud%' OR [IntEnabledTherProg] = 'Slvrcld' THEN 'Silver Cloud'
			WHEN [IntEnabledTherProg] = 'Slvrcld Deprss HE' THEN 'Slvrcld Deprss'
			WHEN [IntEnabledTherProg] = 'Slvrcld Pos Body HE' OR [IntEnabledTherProg] = 'Slvrcld Pos Body im' THEN 'Slvrcld Pos Body img' 
			WHEN [IntEnabledTherProg] = 'Slvrcld Rslnce HE' THEN 'Slvrcld Rslnce'
			WHEN [IntEnabledTherProg] = 'Slvrcld Stress HE' THEN 'Slvrcld Stress' 
			WHEN [IntEnabledTherProg] = 'Slvrcld Chronic Pai' THEN 'Slvrcld Chronic Pain'
			WHEN [IntEnabledTherProg] = 'Slvrcld Anx HE' THEN 'Slvrcld Anx'
			WHEN [IntEnabledTherProg] = 'CHANGE ME' THEN 'Unknown'
			WHEN [IntEnabledTherProg] IS NULL THEN 'No IET'
			ELSE [IntEnabledTherProg] END AS 'Internet Enabled Therapy'
		,[IntEnabledTherProg]
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'Finished Treatment - 2 or more Apps'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND Recovery_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'Recovery'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'Reliable Recovery'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND NoChange_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'No Change'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND ReliableDeterioration_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'Reliable Deterioration'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND ReliableImprovement_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'Reliable Improvement'
		,CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.[PathwayId] IS NOT NULL THEN 1 ELSE 0 END AS 'NotCaseness'

INTO 	[MHDInternal].[TEMP_TTAD_PDT_IETBase]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[recordnumber] = mpi.[recordnumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		--------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_IET] iet ON r.[PathwayId] = iet.[PathwayId] AND ROWID = 1
				---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
 
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL	

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1 
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart

---- Create aggregate table: [MHDInternal].[TEMP_TTAD_PDT_IETAggregate] ----------------------------------------------------

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_IETAggregate]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IETAggregate]

SELECT	[Month]
 		,'Refresh' AS [DataSource]
		,'England' AS [GroupType]
		,[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		
		,[Online Platform]
		,[Internet Enabled Therapy]
		
		,SUM([Finished Treatment - 2 or more Apps]) AS 'Finished Treatment - 2 or more Apps'
		,SUM([Recovery]) AS 'Recovery'
		,SUM([Reliable Recovery]) AS 'Reliable Recovery'
		,SUM([No Change]) AS 'No Change'
		,SUM([Reliable Deterioration]) AS 'Reliable Deterioration'
		,SUM([Reliable Improvement]) AS 'Reliable Improvement'
		,SUM([NotCaseness]) AS 'NotCaseness'

INTO 	[MHDInternal].[TEMP_TTAD_PDT_IETAggregate]

FROM 	[MHDInternal].[TEMP_TTAD_PDT_IETBase]

GROUP BY [Month]
		,[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		
		,[Online Platform]
		,[Internet Enabled Therapy]

---- Insert into final sandbox table: [MHDInternal].[DASHBOARD_TTAD_PDT_IET] ----------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_IET] 

SELECT * FROM [MHDInternal].[TEMP_TTAD_PDT_IETAggregate]

--Drop Temporary Tables----
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IET]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IETBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_IETAggregate]
--------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_IET]' + CHAR(10)
