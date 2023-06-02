SET ANSI_WARNINGS OFF
SET DATEFIRST 1
SET NOCOUNT ON

-- Refresh updates for: [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Intensive_Support_Dashboard_BAME] ---------------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create base table ------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Base') IS NOT NULL DROP TABLE #Base

SELECT  @MonthYear AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Ethnic Category' AS 'Category'
		,CASE WHEN EthnicCategory IN ('A') THEN 'White British'
			WHEN EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'BAME'
			WHEN EthnicCategory NOT IN ('A', 'B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Not known/Not stated/Unspecified/Invalid data supplied' ELSE 'Other' END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'EnteringTreatment'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'TRUE' THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND Recovery_Flag = 'TRUE' THEN r.PathwayID else NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd and r.TreatmentCareContact_Count>=2 AND NotCaseness_Flag = 'TRUE' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'

INTO #Base 

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND UsePathway_Flag = 'TRUE'  AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN EthnicCategory IN ('A') THEN 'White British'
			WHEN EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'BAME'
			WHEN EthnicCategory NOT IN ('A', 'B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Not known/Not stated/Unspecified/Invalid data supplied' ELSE 'Other' END

--- ROUNDING AND PROPORTIONS ----------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Intensive_Support_Dashboard_BAME]

SELECT	[Month] AS 'Month', 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'National' AS 'Level',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,SUM(Referrals) AS Referrals
		,SUM([EnteringTreatment]) AS EnteringTreatment
		,SUM([Finished Treatment]) AS 'Finished Treatment'
		,SUM([Recovery]) AS 'Recovery'
		,SUM([NotCaseness]) AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM(NotCaseness)) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 3) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [Category], [Variable]

UNION ---------------------------------------------------------------------

SELECT	Month AS Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'Region' AS 'Level',
		[Region Code] AS 'Region Code' ,
		[Region Name] AS 'Region Name' ,
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END AS 'Referrals'
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END AS 'EnteringTreatment'
		,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END AS 'Finished Treatment'
		,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END AS 'Recovery'
		,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [Region Code], [Region Name], [Category], [Variable]

UNION ---------------------------------------------------------------------

SELECT	[Month] AS 'Month', 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'STP' AS 'Level',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		[STP Code] AS 'STP Code',
		[STP Name] AS 'STP Name',
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END AS 'Referrals'
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END AS 'EnteringTreatment'
		,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END AS 'Finished Treatment'
		,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END AS 'Recovery'
		,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [STP Code], [STP Name], [Category], [Variable]

UNION ---------------------------------------------------------------------

SELECT	[Month] AS 'Month', 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'CCG' AS 'Level',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',		
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END AS 'Referrals'
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END AS 'EnteringTreatment'
		,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END AS 'Finished Treatment'
		,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END AS 'Recovery'
		,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [CCG Code], [CCG Name], [Category], [Variable]

UNION ---------------------------------------------------------------------

SELECT	[Month] AS 'Month', 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'Provider' AS 'Level',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',		
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END AS 'Referrals'
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END AS 'EnteringTreatment'
		,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END AS 'Finished Treatment'
		,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END AS 'Recovery'
		,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [Provider Code], [Provider Name], [Category], [Variable]

UNION ---------------------------------------------------------------------

SELECT	[Month] AS 'Month', 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'CCG / Provider' AS 'Level',
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		[Category] AS 'Category',
		[Variable] AS 'Variable'
		,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END AS 'Referrals'
		,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END AS 'EnteringTreatment'
		,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END AS 'Finished Treatment'
		,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END AS 'Recovery'
		,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END AS 'NotCaseness'
		,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2) AS 'RecRate'

FROM #Base 

GROUP BY [Month], [CCG Code], [CCG Name], [Provider Code], [Provider Name], [Category], [Variable]

------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Intensive_Support_Dashboard_BAME]'
