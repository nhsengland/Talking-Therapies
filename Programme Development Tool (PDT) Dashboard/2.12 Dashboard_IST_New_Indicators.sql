
-- DELETE MAX(Month) -----------------------------------------------------------------------

DELETE FROM [MHDInternal].[STAGING_TTAD_PDT_InequalitiesNewIndicators] 

WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[STAGING_TTAD_PDT_InequalitiesNewIndicators])

--------------------------------------------------------------------------------------------
	
-- Refresh updates for [MHDInternal].[STAGING_TTAD_PDT_InequalitiesNewIndicators] ------------------------

DECLARE @Offset AS INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear DATE = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-------------------------------------------------------------------------
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]

-- First Part of the Base Table

SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS 'Month'

	,r.PathwayID
	,a.Unique_CareContactID

	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

	,CASE WHEN a.[CareContDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND a.[Unique_CareContactID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'Appointments'
	,CASE WHEN a.[CareContDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND a.[AttendOrDNACode] IN ('3', '03', ' 3', '3 ', ' 03', '03 ') AND a.[Unique_CareContactID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'ApptDNA'
	--These are calculated in the second part of the base table as rely on just the PathwayID and not the Unique_CareContactID
	,0 AS [SelfReferral]
	,0 AS [EndedBeforeTreatment]
	,0 AS [FirstTreatment2Weeks]
	,0 AS [FirstTreatment6Weeks]
	,0 AS [FirstTreatment12Weeks]
	,0 AS [FirstTreatment18Weeks]
	,0 AS [WaitingForTreatment]
	,0 AS [ReferralsEnded]
	,0 AS [EndedTreatedOnce]
	,0 AS [Waiting2Weeks]
	,0 AS [Waiting4Weeks]
	,0 AS [Waiting6Weeks]
	,0 AS [Waiting12Weeks]
	,0 AS [Waiting18Weeks]
	,0 AS [FinishedCourseTreatmentWaited6Weeks]
	,0 AS [FinishedCourseTreatmentWaited18Weeks]
	,0 AS [FirstToSecond28Days]
	,0 AS [FirstToSecond28To90Days]
	,0 AS [FirstToSecondMoreThan90Days]

INTO [MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart
		AND a.Unique_CareContactID IS NOT NULL

-- Second Part of the Base Table

INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]

SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS 'Month'

	,r.PathwayID
	,NULL AS Unique_CareContactID -- this part of the base table only needs PathwayIDs but the column is needed for the first part of the base table

	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'

	,0 AS Appointments -- this is based on Unique_CareContactIDs rather than PathwayIDs so it is calculated in the first part of the base table
	,0 AS ApptDNA -- this is based on Unique_CareContactIDs rather than PathwayIDs so it is calculated in the first part of the base table
	,CASE WHEN r.[ReferralRequestReceivedDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.[SourceOfReferralMH] = 'B1' OR r.SourceOfReferralIAPT = 'B1') AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'SelfReferral' --SourceOfReferralMH is used in v2.1 and SourceOfReferralIAPT is used in v2.0
	,CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[TherapySession_FirstDate] IS NULL AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'EndedBeforeTreatment'
	,CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=14 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'FirstTreatment2Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=42 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'FirstTreatment6Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=84 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'FirstTreatment12Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=126 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'FirstTreatment18Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'WaitingForTreatment'
	,CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'ReferralsEnded'
	,CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.[TreatmentCareContact_Count] = 1 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'EndedTreatedOnce'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], l.[ReportingPeriodEndDate]) <=14 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END 
	AS 'Waiting2Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], l.[ReportingPeriodEndDate]) <=28 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'Waiting4Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], l.[ReportingPeriodEndDate]) <=42 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'Waiting6Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], l.[ReportingPeriodEndDate]) <=84 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'Waiting12Weeks'
	,CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], l.[ReportingPeriodEndDate]) <=126 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'Waiting18Weeks'
	,CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=42 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'FinishedCourseTreatmentWaited6Weeks'
	,CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CompletedTreatment_Flag = 'True' AND DATEDIFF(DD, r.[ReferralRequestReceivedDate], r.[TherapySession_FirstDate]) <=126 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'FinishedCourseTreatmentWaited18Weeks'
	,CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[TherapySession_FirstDate], r.[TherapySession_SecondDate]) <=28 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'FirstToSecond28Days'
	,CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[TherapySession_FirstDate], r.[TherapySession_SecondDate]) BETWEEN 29 AND 90 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'FirstToSecond28To90Days'
	,CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.[TherapySession_FirstDate], r.[TherapySession_SecondDate]) > 90 AND r.[PathwayID] IS NOT NULL THEN 1 ELSE 0 END
	AS 'FirstToSecondMoreThan90Days'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart

----------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[STAGING_TTAD_PDT_InequalitiesNewIndicators]

SELECT 
	Month
	,'Refresh' AS 'DataSource'
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
	,SUM(SelfReferral) AS SelfReferral
	,SUM(EndedBeforeTreatment) AS EndedBeforeTreatment
	,SUM(FirstTreatment2Weeks) AS FirstTreatment2Weeks
	,SUM(FirstTreatment6Weeks) AS FirstTreatment6Weeks
	,SUM(FirstTreatment12Weeks) AS FirstTreatment12Weeks
	,SUM(FirstTreatment18Weeks) AS FirstTreatment18Weeks
	,SUM(WaitingForTreatment) AS WaitingForTreatment
	,SUM(Appointments) AS Appointments
	,SUM(ApptDNA) AS ApptDNA
	,SUM(ReferralsEnded) AS ReferralsEnded
	,SUM(EndedTreatedOnce) AS EndedTreatedOnce
	,SUM(Waiting2Weeks) AS Waiting2Weeks
	,SUM(Waiting4Weeks) AS Waiting4Weeks
	,SUM(Waiting6Weeks) AS Waiting6Weeks
	,SUM(Waiting12Weeks) AS Waiting12Weeks
	,SUM(Waiting18Weeks) AS Waiting18Weeks
	,SUM(FinishedCourseTreatmentWaited6Weeks) AS FinishedCourseTreatmentWaited6Weeks
	,SUM(FinishedCourseTreatmentWaited18Weeks) AS FinishedCourseTreatmentWaited18Weeks
	,SUM(FirstToSecond28Days) AS FirstToSecond28Days
	,SUM(FirstToSecond28To90Days) AS FirstToSecond28To90Days
	,SUM(FirstToSecondMoreThan90Days) AS FirstToSecondMoreThan90Days

FROM [MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]

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

-- Drop Temporary Table ------------------------------------------------
------------------------------------------------------------------------
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesNewIndicators_Base]
----------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[STAGING_TTAD_PDT_InequalitiesNewIndicators]'
