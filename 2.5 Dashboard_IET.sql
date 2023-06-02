SET NOCOUNT ON
SET ANSI_WARNINGS ON

-- Refresh updates for [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_IET] -----------------------------------------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create base table: [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_IET] --------------------------------------------------

IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_IET]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_IET]

SELECT	PathwayId
		,IntEnabledTherProg, SUM(DurationIntEnabledTher) AS TotalTime
		,row_Number() OVER( PARTITION BY [PathwayID] ORDER BY  SUM(DurationIntEnabledTher)  desc) AS ROWID 
		
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_IET] FROM (

SELECT DISTINCT PathwayId
				,StartDateIntEnabledTherLog
				,EndDateIntEnabledTherLog
				,IntEnabledTherProg
				,DurationIntEnabledTher

FROM [dbo].[IDS205_InternetEnabledTherapyCareProfessionalActivityLog])_

GROUP BY PathwayId, IntEnabledTherProg

----------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_IET]

SELECT	@MonthYear AS 'Month'
 		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
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
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_IET] iet ON r.PathwayId = iet.PathwayId AND ROWID = 1
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,[IntEnabledTherProg]

-------------------------------------------------------------------------------

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[Dashboard_IET]'