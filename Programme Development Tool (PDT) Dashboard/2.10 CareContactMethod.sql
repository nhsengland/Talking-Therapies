SET ANSI_WARNINGS ON
SET DATEFIRST 1
SET NOCOUNT ON

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DELETE MAX(Month) ------------------------------------------------------------------------------------------------------------------------------------------

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly] 

WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly])

-----------------------------------------------------------------------------------------------------
--This table counts the number of appointments per PathwayID and Referral Request Date and then filters the PathwayID and Referral Request Date based on the number of appointments
--This produces a table with PathwayIDs and the referral request received date with the most appointments associated with it

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_RankedApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_RankedApps]

SELECT * INTO [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_RankedApps] FROM

(

SELECT	[Care Contact Patient Therapy Mode]
		,[PathwayID]
		,[ReferralRequestReceivedDate]
		,ROW_NUMBER()OVER(PARTITION BY PathwayID,ReferralRequestReceivedDate ORDER BY Apts DESC) AS 'RowID'
		,[Apts]

FROM (

SELECT	CASE WHEN a.CareContPatientTherMode IN ('1','01') THEN 'Individual patient'
			WHEN a.CareContPatientTherMode IN ('2','02') THEN 'Couple'
			WHEN a.CareContPatientTherMode IN ('3','03') THEN 'Group Therapy'
			ELSE 'Other' END as 'Care Contact Patient Therapy Mode'
		,r.PathwayID
		,r.ReferralRequestReceivedDate
		,COUNT(DISTINCT CASE WHEN a.AttendOrDNACode IN ('5','6') AND a.APPTYPE IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') THEN a.Unique_CareContactID ELSE NULL END) as 'Apts'

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID
		------------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

GROUP BY CASE WHEN CareContPatientTherMode IN ('1','01') THEN 'Individual patient'
			WHEN CareContPatientTherMode IN ('2','02') THEN 'Couple'
			WHEN CareContPatientTherMode IN ('3','03') THEN 'Group Therapy'
			ELSE 'Other' END
		,r.PathwayID
		,r.ReferralRequestReceivedDate
	)_
)__
 
WHERE RowID = 1

-----------------------------------------------------------------------------------------------------------------------------
--This produces a base table with one PathwayID per row along with columns for the month, geography, therapy mode, outcome flags, first treatment wait and number of appointments
--This table only includes PathwayIDs that have a service discharge date within the reporting period and have completed treatment
--This table is used for producing the aggregated table used in the dashboard below ([MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly])

DECLARE @Offset AS INT = 0 -- Include the most recent month

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear DATE = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

SELECT DISTINCT
		CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS DATE) AS 'Month'
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,'Refresh' AS DataSource -- Is it stil appropriate to include this?
		,a.[Care Contact Patient Therapy Mode]
		,r.PathwayID
		,r.ReferralRequestReceivedDate

		,CASE WHEN r.CompletedTreatment_Flag='TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS 'CompletedTreatment_Flag'
		,CASE WHEN r.Recovery_Flag='TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS 'Recovery_Flag'
		,CASE WHEN r.ReliableImprovement_Flag='TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS 'ReliableImprovement_Flag'
		,CASE WHEN r.NotCaseness_Flag='TRUE' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS 'NotCaseness_Flag'
	
		,CAST(DATEDIFF(DD,r.ReferralRequestReceivedDate,r.TherapySession_FirstDate) AS FLOAT) AS 'FirstTreatmentWait'
		,a.Apts

INTO [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_RankedApps] a ON r.PathwayID = a.PathwayID AND r.ReferralRequestReceivedDate = a.ReferralRequestReceivedDate
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		AND r.CompletedTreatment_Flag = 'TRUE' 
		AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart -- @Offset of 0 combined with -1 will return the required time period
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSERT ----------------------------------------------------------------------------------------------------------------------------------------------------- 

--This table aggregates the base table above ([MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]) at different geography levels (CCG, STP, Region, National)

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]

SELECT  Month
		,CAST('CCG' AS VARCHAR(255)) AS OrgType
		,[CCG Code] AS OrgCode
		,[CCG Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,SUM(CompletedTreatment_Flag) AS 'FinishedTreatment'
		,CASE WHEN SUM(CompletedTreatment_Flag)-SUM(NotCaseness_Flag) = 0 THEN NULL
        WHEN SUM(Recovery_Flag) = 0 THEN NULL 
        
		ELSE 

        (CAST(SUM(Recovery_Flag) AS float)
        /(CAST(SUM(CompletedTreatment_Flag) AS float)
        -CAST(SUM(NotCaseness_Flag)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

GROUP BY Month
		,[CCG Code]
		,[CCG Name]
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]

SELECT   Month
		,'STP' AS OrgType
		,[STP Code] AS OrgCode
		,[STP Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,SUM(CompletedTreatment_Flag) AS 'FinishedTreatment'
		,CASE WHEN SUM(CompletedTreatment_Flag)-SUM(NotCaseness_Flag) = 0 THEN NULL
        WHEN SUM(Recovery_Flag) = 0 THEN NULL 
        
		ELSE 

        (CAST(SUM(Recovery_Flag) AS float)
        /(CAST(SUM(CompletedTreatment_Flag) AS float)
        -CAST(SUM(NotCaseness_Flag)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

GROUP BY Month
		,[STP Code]
		,[STP Name]
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]

SELECT   Month
		,'Region' AS OrgType
		,[Region Code] AS OrgCode
		,[Region Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,SUM(CompletedTreatment_Flag) AS 'FinishedTreatment'
		,CASE WHEN SUM(CompletedTreatment_Flag)-SUM(NotCaseness_Flag) = 0 THEN NULL
        WHEN SUM(Recovery_Flag) = 0 THEN NULL 
        
		ELSE 

        (CAST(SUM(Recovery_Flag) AS float)
        /(CAST(SUM(CompletedTreatment_Flag) AS float)
        -CAST(SUM(NotCaseness_Flag)AS float))) END
        AS 'Percentage_Recovery'

		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
order by [Region Name],[Care Contact Patient Therapy Mode]

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]

SELECT   Month
		,'England' AS OrgType
		,'England' AS OrgCode
		,'England' AS OrgName
		,'Eng' AS [Region Code]
		,'England' AS [Region Name]
		,[Care Contact Patient Therapy Mode]
		,SUM(CompletedTreatment_Flag) AS 'FinishedTreatment'
		,CASE WHEN SUM(CompletedTreatment_Flag)-SUM(NotCaseness_Flag) = 0 THEN NULL
        WHEN SUM(Recovery_Flag) = 0 THEN NULL 
        
		ELSE 

        (CAST(SUM(Recovery_Flag) AS float)
        /(CAST(SUM(CompletedTreatment_Flag) AS float)
        -CAST(SUM(NotCaseness_Flag)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]

GROUP BY Month
		,[Care Contact Patient Therapy Mode]

-- Drop temporary tables -------------------------------------------------------
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_RankedApps]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactMethod_Base]
--------------------------------------------------------------------------------

PRINT CHAR(10) + 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]'
