SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop] -----------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-------------------------------------------------------------------------------------------------------------------------
--Base Table
--This produces a table with one Unique_CareContactID per row so that this table can be aggregated below to produce [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]
SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
	,a.Unique_CareContactID
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
	,CASE WHEN a.AttendOrDNACode in ('2','02') THEN 'AptCancelledPatient'
		WHEN a.AttendOrDNACode in ('3','03') THEN 'AptDNA'
		WHEN a.AttendOrDNACode in ('4','04') THEN 'AptCancelledProvider'
		WHEN a.AttendOrDNACode in ('5','05') THEN 'AptAttended'
		WHEN a.AttendOrDNACode in ('6','06') THEN 'AptAttendedLate'
		WHEN a.AttendOrDNACode in ('7','07') THEN 'AptLateNotSeen' ELSE 'Other' 
	END AS 'Attendence Type'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '748051000000105' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'GuideSelfHelpBookApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '748101000000105' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'NonGuideSelfHelpBookApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '748041000000107' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'GuideSelfHelpCompApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '748091000000102' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'NonGuideSelfHelpCompApts'

	,0 AS 'BehavActLIApts' --Only in v1.5 so set to 0 for v2 onwards

	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '748061000000108'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'StructPhysActApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '199314001' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'AntePostNatalCounselApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '702545008' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'PsychoEducPeerSuppApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '1026111000000108'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'OtherLIApts'

	,0 AS 'EmploySuppLIApts' --Only in v1.5 so set to 0 for v2 onwards

	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '1127281000000100'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'AppRelaxApts'

	,0 AS 'BehavActHIApts' --Only in v1.5 so set to 0 for v2 onwards

	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '1129471000000105'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'CoupleTherapyDepApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '842901000000108'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'CollabCareApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '286711000000107'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'CounselDepApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '314034001'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'BPDApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '449030000'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'EyeMoveDesenReproApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '933221000000107' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'MindfulApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '1026131000000100' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'OtherHIApts'

	,0 AS 'EmploySuppHIApts' --Only in v1.5 so set to 0 for v2 onwards

	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '304891004' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'CBTApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '443730003' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'IPTApts'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '1098051000000103' AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'ESApts' 
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND c.CodeProcAndProcStatus = '975131000000104'  AND a.Unique_CareContactID IS NOT NULL THEN 1 ELSE 0
	END AS 'Signposting'
INTO [MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = l.AuditId AND c.Unique_MonthID = l.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True'
		AND l.IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart --For monthly refresh the offset should be 0 so only the latest month is added
		AND a.APPTYPE IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')


----------------------------------------------------------------------------------------
--Final Aggregate Table
--This table aggregates the base table created above ([MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]) to produce the table used in the dashboard
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]
SELECT  
	Month
	,'England' AS 'GroupType'
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Total' AS 'Category'
	,'Total' AS 'Variable'
	,'Refresh' AS DataSource
	,[Attendence Type]
	,SUM([GuideSelfHelpBookApts]) AS [GuideSelfHelpBookApts]
	,SUM([NonGuideSelfHelpBookApts]) AS [NonGuideSelfHelpBookApts]
	,SUM([GuideSelfHelpCompApts]) AS [GuideSelfHelpCompApts]
	,SUM([NonGuideSelfHelpCompApts]) AS [NonGuideSelfHelpCompApts]
	,SUM([BehavActLIApts]) AS [BehavActLIApts]
	,SUM([StructPhysActApts]) AS [StructPhysActApts]
	,SUM([AntePostNatalCounselApts]) AS [AntePostNatalCounselApts]
	,SUM([PsychoEducPeerSuppApts]) AS [PsychoEducPeerSuppApts]
	,SUM([OtherLIApts]) AS [OtherLIApts]
	,SUM([EmploySuppLIApts]) AS [EmploySuppLIApts]
	,SUM([AppRelaxApts]) AS [AppRelaxApts]
	,SUM([BehavActHIApts]) AS [BehavActHIApts]
	,SUM([CoupleTherapyDepApts]) AS [CoupleTherapyDepApts]
	,SUM([CollabCareApts]) AS [CollabCareApts]
	,SUM([CounselDepApts]) AS [CounselDepApts]
	,SUM([BPDApts]) AS [BPDApts]
	,SUM([EyeMoveDesenReproApts]) AS [EyeMoveDesenReproApts]
	,SUM([MindfulApts]) AS [MindfulApts]
	,SUM([OtherHIApts]) AS [OtherHIApts]
	,SUM([EmploySuppHIApts]) AS [EmploySuppHIApts]
	,SUM([CBTApts]) AS [CBTApts]
	,SUM([IPTApts]) AS [IPTApts]
	,SUM([ESApts]) AS [ESApts]
	,SUM([Signposting]) AS [Signposting]
--INTO [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]
FROM [MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]
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
	,[Attendence Type]
------------------------------------------------------
--Drop Temporary Table
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_PrimaryLoopBase]

-------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrimaryLoop]'
