
DECLARE @Offset AS INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR)) 

; ---------------------------------------------------------------------------------------------------------------------------------------------------

WITH 

Commissioner_Hierarchies AS (SELECT * FROM [Reporting_UKHD_ODS].[Commissioner_Hierarchies] WHERE [Region_Name] != 'WALES REGION' AND  Effective_To IS NULL),
Provider_Hierarchies AS (SELECT * FROM [Reporting_UKHD_ODS].[Provider_Hierarchies] WHERE [Region_Name] != 'WALES REGION' AND  Effective_To IS NULL),

base_table AS (

SELECT  
	@MonthYear AS [Month]
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
	,COUNT(DISTINCT CASE WHEN [ReferralRequestReceivedDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_ReferralsReceived]
	,COUNT(DISTINCT CASE WHEN [TherapySession_FirstDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_AccessingServices]
	,COUNT(DISTINCT CASE WHEN [ServDischDate] IS NOT NULL AND [TreatmentCareContact_Count] >= 2 AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_FinishedCourseTreatment]
	,COUNT(DISTINCT(CASE WHEN a.[CareContDate] BETWEEN @PeriodStart AND @PeriodEnd AND a.[AttendOrDNACode] in ('5','05') THEN a.[Unique_CareContactID] END )) AS [Count_ApptsAttended]
	,COUNT(DISTINCT CASE WHEN [ServDischDate] IS NOT NULL AND [TreatmentCareContact_Count] >= 2 AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd AND [Recovery_Flag] = 'True' THEN  r.[PathwayID] ELSE NULL END) AS [Count_Recovery]

FROM	
	[mesh_IAPT].[IDS101referral] r
	---------------------------	
	INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--------------------------
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.PathwayID AND a.AuditId = l.AuditId
	LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON mpi.recordnumber = spc.recordnumber
	---------------------------
	LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
	LEFT JOIN [Commissioner_Hierarchies] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
	---------------------------
	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Provider_Hierarchies] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default

WHERE	
	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
	AND UsePathway_Flag = 'True' AND IsLatest = 1 
	
GROUP BY
	CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END ), 

-- National -----------------------------------------------------------------------------------------
 
national_table AS (

SELECT
	@MonthYear AS [Month]
	,[Group_Type] = 'National'
	,[Org_Code] = 'All'
	,[Org_Name] = 'England'
	,COUNT(DISTINCT CASE WHEN [ReferralRequestReceivedDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_ReferralsReceived]
	,COUNT(DISTINCT CASE WHEN [TherapySession_FirstDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_AccessingServices]
	,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND [TreatmentCareContact_Count] >= 2 AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd THEN r.[PathwayID] ELSE NULL END) AS [Count_FinishedCourseTreatment]
	,COUNT(DISTINCT CASE WHEN a.[CareContDate] BETWEEN @PeriodStart AND @PeriodEnd AND a.[AttendOrDNACode] in ('5','05') THEN a.[Unique_CareContactID] END ) AS [Count_ApptsAttended]
	,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND [TreatmentCareContact_Count] >= 2 AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd AND [Recovery_Flag] = 'True' THEN  r.[PathwayID] ELSE NULL END) AS [Count_Recovery]

FROM	
	[mesh_IAPT].[IDS101referral] r
	---------------------------	
	INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--------------------------
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.PathwayID AND a.AuditId = l.AuditId
	LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON mpi.recordnumber = spc.recordnumber
	---------------------------
	LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
	LEFT JOIN [Commissioner_Hierarchies] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
	---------------------------
	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Provider_Hierarchies] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default

WHERE	
	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
	AND UsePathway_Flag = 'True' AND IsLatest = 1 ),

-- ICB ------------------------------------------------------------------------------------------
	
ICB_table AS ( 

SELECT
	@MonthYear AS [Month]
	,[Group_Type] = 'ICB'
	,[ICB Code] AS [Org_Code]
	,[ICB Name] AS [Org_Name]
	,CASE WHEN SUM([Count_ReferralsReceived]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ReferralsReceived])*2,-1)/2) END AS [Count_ReferralsReceived]
	,CASE WHEN SUM([Count_AccessingServices]) < 5 THEN NULL ELSE (ROUND(SUM([Count_AccessingServices])*2,-1)/2) END AS [Count_AccessingServices]
	,CASE WHEN SUM([Count_FinishedCourseTreatment]) < 5 THEN NULL ELSE (ROUND(SUM([Count_FinishedCourseTreatment])*2,-1)/2) END AS [Count_FinishedCourseTreatment]
	,CASE WHEN SUM([Count_ApptsAttended]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ApptsAttended])*2,-1)/2) END AS [Count_ApptsAttended]
	,CASE WHEN SUM([Count_Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Count_Recovery])*2,-1)/2) END AS [Count_Recovery]

FROM base_table

GROUP BY [Month], [ICB Code], [ICB Name] ), 

-- Sub ICB ------------------------------------------------------------------------------------------

subICB_table AS ( 

SELECT	
	@MonthYear AS [Month]
	,[Group_Type] = 'Sub ICB'
	,[Sub ICB Code] AS [Org_Code]
	,[Sub ICB Name] AS [Org_Name]
	,CASE WHEN SUM([Count_ReferralsReceived]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ReferralsReceived])*2,-1)/2) END AS [Count_ReferralsReceived]
	,CASE WHEN SUM([Count_AccessingServices]) < 5 THEN NULL ELSE (ROUND(SUM([Count_AccessingServices])*2,-1)/2) END AS [Count_AccessingServices]
	,CASE WHEN SUM([Count_FinishedCourseTreatment]) < 5 THEN NULL ELSE (ROUND(SUM([Count_FinishedCourseTreatment])*2,-1)/2) END AS [Count_FinishedCourseTreatment]
	,CASE WHEN SUM([Count_ApptsAttended]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ApptsAttended])*2,-1)/2) END AS [Count_ApptsAttended]
	,CASE WHEN SUM([Count_Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Count_Recovery])*2,-1)/2) END AS [Count_Recovery]

FROM base_table

GROUP BY [Month], [Sub ICB Code], [Sub ICB Name] ), 

-- Provider -----------------------------------------------------------------------------------------

provider_table AS (

SELECT	
	@MonthYear AS [Month]
	,[Group_Type] = 'Provider'
	,[Provider Code] AS [Org_Code]
	,[Provider Name] AS [Org_Name]
	,CASE WHEN SUM([Count_ReferralsReceived]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ReferralsReceived])*2,-1)/2) END AS [Count_ReferralsReceived]
	,CASE WHEN SUM([Count_AccessingServices]) < 5 THEN NULL ELSE (ROUND(SUM([Count_AccessingServices])*2,-1)/2) END AS [Count_AccessingServices]
	,CASE WHEN SUM([Count_FinishedCourseTreatment]) < 5 THEN NULL ELSE (ROUND(SUM([Count_FinishedCourseTreatment])*2,-1)/2) END AS [Count_FinishedCourseTreatment]
	,CASE WHEN SUM([Count_ApptsAttended]) < 5 THEN NULL ELSE (ROUND(SUM([Count_ApptsAttended])*2,-1)/2) END AS [Count_ApptsAttended]
	,CASE WHEN SUM([Count_Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Count_Recovery])*2,-1)/2) END AS [Count_Recovery]

FROM base_table

GROUP BY [Month], [Provider Code], [Provider Name] ) 

-- Final output -----------------------------------------------------------------------------------------

SELECT * FROM national_table
UNION ------------------------
SELECT * FROM ICB_table
UNION ------------------------
SELECT * FROM subICB_table
UNION ------------------------
SELECT * FROM provider_table
