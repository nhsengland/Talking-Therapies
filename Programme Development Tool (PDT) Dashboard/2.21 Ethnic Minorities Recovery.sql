SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities] -----------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Create base table ------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase]
SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS 'Month'
	,r.PathwayID
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
	,CASE WHEN mpi.EthnicCategory IN ('A') THEN 'White British'
		WHEN mpi.EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
		WHEN mpi.EthnicCategory NOT IN ('A', 'B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Not known/Not stated/Unspecified/Invalid data supplied' ELSE 'Other' 
	END AS 'Ethnicity'
	,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END 
	AS 'Referrals'
	,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END 
	AS 'EnteringTreatment'
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag = 'TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END 
	AS 'Finished Treatment'
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.Recovery_Flag = 'TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END 
	AS 'Recovery'
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate and r.TreatmentCareContact_Count>=2 AND r.NotCaseness_Flag = 'TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END 
	AS 'NotCaseness'

INTO [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase]

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

WHERE	l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart --For monthly refresh, the offset should be 0 to get the latest month
		AND r.UsePathway_Flag = 'TRUE'  AND l.IsLatest = 1


--- ROUNDING AND PROPORTIONS ----------------------------------------------------------------------------

--IF OBJECT_ID ('[MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities]') IS NOT NULL DROP TABLE [MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities]
INSERT INTO [MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities]
SELECT * 
--INTO [MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities]
FROM(
--National
SELECT	
	[Month] 
	,'Refresh' AS 'DataSource'
	,'England' AS 'GroupType'
	,'National' AS 'Level'
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,SUM(Referrals) AS 'Referrals'
	,SUM([EnteringTreatment]) AS 'EnteringTreatment'
	,SUM([Finished Treatment]) AS 'Finished Treatment'
	,SUM([Recovery]) AS 'Recovery'
	,SUM([NotCaseness]) AS 'NotCaseness'
	,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM(NotCaseness)) <5 THEN NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 3)
	AS 'RecRate'

FROM [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase] 

GROUP BY 
	[Month]
	,[Ethnicity]

UNION ---------------------------------------------------------------------
--Region
SELECT 
	Month
	,'Refresh' AS 'DataSource'
	,'England' AS 'GroupType'
	,'Region' AS 'Level'
	,[Region Code] AS 'Region Code'
	,[Region Name] AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
	AS 'Referrals'
	,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
	AS 'EnteringTreatment'
	,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END
	AS 'Finished Treatment'
	,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END
	AS 'Recovery'
	,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END
	AS 'NotCaseness'
	,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 THEN NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2)
	AS 'RecRate'

FROM [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase] 

GROUP BY 
	[Month]
	,[Region Code]
	,[Region Name]
	,[Ethnicity]

UNION ---------------------------------------------------------------------
--ICB
SELECT	
	[Month]
	,'Refresh' AS 'DataSource'
	,'England' AS 'GroupType'
	,'STP' AS 'Level'
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,[STP Code] AS 'STP Code'
	,[STP Name] AS 'STP Name'
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
	AS 'Referrals'
	,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
	AS 'EnteringTreatment'
	,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END
	AS 'Finished Treatment'
	,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END
	AS 'Recovery'
	,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END
	AS 'NotCaseness'
	,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2)
	AS 'RecRate'

FROM [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase] 

GROUP BY
	[Month]
	,[STP Code]
	,[STP Name]
	,[Ethnicity]

UNION ---------------------------------------------------------------------
--Sub-ICB
SELECT
	[Month] 
	,'Refresh' AS 'DataSource'
	,'England' AS 'GroupType'
	,'CCG' AS 'Level'
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,[CCG Code] AS 'CCG Code'
	,[CCG Name] AS 'CCG Name'
	,'All' AS 'Provider Code'
	,'All' AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'	
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
	AS 'Referrals'
	,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
	AS 'EnteringTreatment'
	,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END
	AS 'Finished Treatment'
	,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END
	AS 'Recovery'
	,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END
	AS 'NotCaseness'
	,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2)
	AS 'RecRate'

FROM [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase] 

GROUP BY
	[Month]
	,[CCG Code]
	,[CCG Name]
	,[Ethnicity]

UNION ---------------------------------------------------------------------
--Provider
SELECT
	[Month] 
	,'Refresh' AS 'DataSource'
	,'England' AS 'GroupType'
	,'Provider' AS 'Level'
	,'All' AS 'Region Code'
	,'All' AS 'Region Name'
	,'All' AS 'CCG Code'
	,'All' AS 'CCG Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,'All' AS 'STP Code'
	,'All' AS 'STP Name'	
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,CASE WHEN SUM([Referrals])< 5 THEN NULL ELSE CAST(ROUND((SUM([Referrals])+2) /5,0)*5 AS INT) END
	AS 'Referrals'
	,CASE WHEN SUM([EnteringTreatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([EnteringTreatment])+2) /5,0)*5 AS INT) END
	AS 'EnteringTreatment'
	,CASE WHEN SUM([Finished Treatment])< 5 THEN NULL ELSE CAST(ROUND((SUM([Finished Treatment])+2) /5,0)*5 AS INT) END
	AS 'Finished Treatment'
	,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE CAST(ROUND((SUM([Recovery])+2) /5,0)*5 AS INT) END
	AS 'Recovery'
	,CASE WHEN SUM([NotCaseness])< 5 THEN NULL ELSE CAST(ROUND((SUM([NotCaseness])+2) /5,0)*5 AS INT) END
	AS 'NotCaseness'
	,ROUND(CASE WHEN SUM([Recovery]) <5 OR (SUM([Finished Treatment])-SUM([NotCaseness])) <5 then NULL ELSE (CAST(SUM([Recovery])AS FLOAT)/CAST((SUM([Finished Treatment])-SUM(NotCaseness))AS FLOAT)) END, 2)
	AS 'RecRate'

FROM [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase] 

GROUP BY
	[Month]
	,[Provider Code]
	,[Provider Name]
	,[Ethnicity]

)_

-----------------------------------------------
--Drop Temporary Table
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_EthnicMinoritiesBase]
------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[STAGING_TTAD_PDT_EthnicMinorities]'


