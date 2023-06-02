SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Primary_Loop] -----------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Primary_Loop]

SELECT  @MonthYear AS 'Month' 
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,'Refresh' AS DataSource
		,CASE WHEN a.AttendOrDNACode in ('2','02') THEN 'AptCancelledPatient'
			WHEN a.AttendOrDNACode in ('3','03') THEN 'AptDNA'
			WHEN a.AttendOrDNACode in ('4','04') THEN 'AptCancelledProvider'
			WHEN a.AttendOrDNACode in ('5','05') THEN 'AptAttended'
			WHEN a.AttendOrDNACode in ('6','06') THEN 'AptAttendedLate'
			WHEN a.AttendOrDNACode in ('7','07') THEN 'AptLateNotSeen' ELSE 'Other' 
		END AS 'Attendence Type'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '748051000000105' THEN a.Unique_CareContactID END)) AS 'GuideSelfHelpBookApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '748101000000105' THEN a.Unique_CareContactID END)) AS 'NonGuideSelfHelpBookApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '748041000000107' THEN a.Unique_CareContactID END)) AS 'GuideSelfHelpCompApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '748091000000102' THEN a.Unique_CareContactID END)) AS 'NonGuideSelfHelpCompApts'
		,0 AS 'BehavActLIApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '748061000000108'  THEN a.Unique_CareContactID END)) AS 'StructPhysActApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '199314001' THEN a.Unique_CareContactID END)) AS 'AntePostNatalCounselApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '702545008' THEN a.Unique_CareContactID END)) AS 'PsychoEducPeerSuppApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '1026111000000108'  THEN a.Unique_CareContactID END)) AS 'OtherLIApts'
		,0 AS 'EmploySuppLIApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '1127281000000100'  THEN a.Unique_CareContactID END)) AS 'AppRelaxApts'
		,0 AS 'BehavActHIApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '1129471000000105'  THEN a.Unique_CareContactID END)) AS 'CoupleTherapyDepApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '842901000000108'  THEN a.Unique_CareContactID END)) AS 'CollabCareApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '286711000000107'  THEN a.Unique_CareContactID END)) AS 'CounselDepApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '314034001'  THEN a.Unique_CareContactID END)) AS 'BPDApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '449030000'  THEN a.Unique_CareContactID END)) AS 'EyeMoveDesenReproApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '933221000000107' THEN a.Unique_CareContactID END)) AS 'MindfulApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '1026131000000100' THEN a.Unique_CareContactID END)) AS 'OtherHIApts'
		,0 AS 'EmploySuppHIApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '304891004' THEN a.Unique_CareContactID END)) AS 'CBTApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '443730003' THEN a.Unique_CareContactID END)) AS 'IPTApts'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '1098051000000103' THEN a.Unique_CareContactID END)) AS 'ESApts' 
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND c.CodeProcAndProcStatus = '975131000000104'  THEN a.Unique_CareContactID END)) AS 'Signposting'

FROM	[dbo].[IDS101_Referral] r
		--------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		--------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId AND a.Unique_MonthID = l.Unique_MonthID
		LEFT JOIN [dbo].[IDS202_CareActivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = l.AuditId AND c.Unique_MonthID = l.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True'
		AND IsLatest = 1
		AND h.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND a.APPTYPE IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN a.AttendOrDNACode in ('2','02') THEN 'AptCancelledPatient'
			WHEN a.AttendOrDNACode in ('3','03') THEN 'AptDNA'
			WHEN a.AttendOrDNACode in ('4','04') THEN 'AptCancelledProvider'
			WHEN a.AttendOrDNACode in ('5','05') THEN 'AptAttended'
			WHEN a.AttendOrDNACode in ('6','06') THEN 'AptAttendedLate'
			WHEN a.AttendOrDNACode in ('7','07') THEN 'AptLateNotSeen' ELSE 'Other' END

-------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Primary_Loop]'