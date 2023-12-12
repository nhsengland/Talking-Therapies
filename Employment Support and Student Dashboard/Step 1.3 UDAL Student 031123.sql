--Prior to November 2023, this script produced the output table used in the Student Dashboard.
--From November 2023, the Student Dashboard was added into the Employment Support Dashboard.

-- DELETE MAX(Month) -----------------------------------------------------------------------
--Delete the latest month from the following table so that the refreshed version of that month can be added.
--Only one table in this script requires this.

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student])

-- Postcode Ranking -----------------------------
--Trust sites have more than one postcode so these are ranked alphabetically so only one postcode is used
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Postcodes]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Postcodes]
SELECT	
    [SiteCode]
    ,[Postcode1]
    ,[Grid Reference]
    ,[X (easting)]
    ,[Y (northing)]
    ,[Latitude]
    ,[Longitude]
    ,[Address4]
    ,ROW_NUMBER() OVER(PARTITION BY SiteCode ORDER BY Postcode1 ASC) AS PostcodeRank
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Postcodes]
FROM [MHDInternal].[REFERENCE_ODS_All_Sites]
GO

-----------------------------------
--Employment Status Ranking
--There are instances of one RecordNumber and AuditID having more than one employment status so these are ranked based on the latest EmployStatusRecDate 
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_EmployStatusRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmployStatusRank]
SELECT
*
,ROW_NUMBER() OVER(PARTITION BY RecordNumber, AuditId, Unique_MonthID ORDER BY EmployStatusRecDate DESC) AS EmployStatusRank
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_EmployStatusRank]
FROM [mesh_IAPT].[IDS004empstatus]
GO

---------------------------------------------------------
--Base Table
--This produces a table with one PathwayID per month per row
DECLARE @Offset INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear DATE = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]
SELECT DISTINCT
    CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS 'Month'
    ,r.PathwayID

    ,CASE WHEN ph.Organisation_Code IS NOT NULL THEN ph.Organisation_Code ELSE 'Other' END AS 'Provider Code'
    ,CASE WHEN ph.Organisation_Name IS NOT NULL THEN ph.Organisation_Name ELSE 'Other' END AS 'Provider Name'

    ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'TotalReferrals'
    ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentReferralsTotal'
    ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentReferrals1825'
    ,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentReferrals25Plus'
    ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'TotalEnteringTreatment'
    ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentEnteringTreatmentTotal'
    ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentEnteringTreatment1825'
    ,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND e.EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'StudentEnteringTreatment25Plus'

    ,pc.[Postcode1] AS 'Postcode'
    ,pc.[Grid Reference] AS 'GridRef'
    ,pc.[X (easting)] AS 'Eastings'
    ,pc.[Y (northing)] AS 'Northings'
    ,pc.[Latitude] AS 'Lat'
    ,pc.[Longitude] AS 'Long'
    ,pc.[Address4] AS 'City'

    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'RecoveredTotal'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'FinishingTreatmentTotal'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate and r.CompletedTreatment_Flag='True' AND r.NotCaseness_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'NotCasenessTotal'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND e.EmployStatus = '03' AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'RecoveredStudent'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND e.EmployStatus = '03' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'FinishingTreatmentStudent'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate and r.CompletedTreatment_Flag='True' AND r.NotCaseness_Flag = 'True' AND e.EmployStatus = '03' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'NotCasenessStudent'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.ReliableImprovement_Flag = 'True' AND e.EmployStatus = '03' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'Reliable Improvement STUDENT'
    ,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.ReliableImprovement_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
    AS 'Reliable Improvement'

INTO [MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]
FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[recordnumber] = mpi.[recordnumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		------------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_EmployStatusRank] e ON r.[RecordNumber] = e.[RecordNumber]  AND e.AuditId = l.AuditId and EmployStatusRank=1
		------------------------------
        LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL

        LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_Postcodes] pc ON ph.[Organisation_Code]= pc.[SiteCode] AND PostcodeRank=1
WHERE 
    l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart ---for monthly refresh the offset should be -1 as we want the data for the latest 2 months month (i.e. to refresh the previous month's primary data)
    AND r.UsePathway_Flag = 'True' 
    AND l.IsLatest = 1

--------------------------------------Final Table-----------------------------------------------------------------------------------
--This table aggregates the base table ([MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]) and is used in the dashboard.
--The number of referrals, number entering treatment and clinical outcomes for students and totals are summed for each provider code and post code

--IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]
SELECT	
    Month
    ,'Refresh' AS 'DataSource'
    ,'England' AS 'GroupType'
    ,[Provider Code]
    ,[Provider Name]

    ,SUM(TotalReferrals) AS 'TotalReferrals'
    ,SUM(StudentReferralsTotal) AS 'StudentReferralsTotal'
    ,SUM(StudentReferrals1825) AS 'StudentReferrals1825'
    ,SUM(StudentReferrals25Plus) AS 'StudentReferrals25Plus'
    ,SUM(TotalEnteringTreatment) AS 'TotalEnteringTreatment'
    ,SUM(StudentEnteringTreatmentTotal) AS 'StudentEnteringTreatmentTotal'
    ,SUM(StudentEnteringTreatment1825) AS 'StudentEnteringTreatment1825'
    ,SUM(StudentEnteringTreatment25Plus) AS 'StudentEnteringTreatment25Plus'

    ,Postcode
    ,GridRef
    ,Eastings
    ,Northings
    ,Lat
    ,Long
    ,City

    ,SUM(RecoveredTotal) AS 'RecoveredTotal'
    ,SUM(FinishingTreatmentTotal) AS 'FinishingTreatmentTotal'
    ,SUM(NotCasenessTotal) AS 'NotCasenessTotal'
    ,SUM(RecoveredStudent) AS 'RecoveredStudent'
    ,SUM(FinishingTreatmentStudent) AS 'FinishingTreatmentStudent'
    ,SUM(NotCasenessStudent) AS 'NotCasenessStudent'
    ,SUM([Reliable Improvement STUDENT]) AS 'Reliable Improvement STUDENT'
    ,SUM([Reliable Improvement]) AS 'Reliable Improvement'
--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]

GROUP BY
    Month
	,[Provider Code]
	,[Provider Name]
    ,Postcode
    ,GridRef
    ,Eastings
    ,Northings
    ,Lat
    ,Long
    ,City

-- --Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Postcodes]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmployStatusRank]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_StudentBase]

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Student]' + CHAR(10)
