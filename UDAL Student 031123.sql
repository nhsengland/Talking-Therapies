--Prior to November 2023, this script produced the output table used in the Student Dashboard.
--From November 2023, the Student Dashboard was added into the Employment Support Dashboard.

SET ANSI_WARNINGS OFF
SET DATEFIRST 1
SET NOCOUNT ON
--------------
DECLARE @Offset INT = -1
-------------------------
--DECLARE @Max_Offset INT = -1
-------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
-------------------------------------|

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear DATE = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Insert into [MHDInternal].[DASHBOARD_TTAD_Student] ------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_Student]

 SELECT	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS 'Month'
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.Organisation_Name IS NOT NULL THEN ph.Organisation_Name ELSE 'Other' END AS 'Provider Name'

		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'TotalReferrals'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'StudentReferralsTotal'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS 'StudentReferrals1825'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS 'StudentReferrals25Plus'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'TotalEnteringTreatment'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatmentTotal'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate BETWEEN 18 AND 25 THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatment1825'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND EmployStatus = '03' AND mpi.Age_RP_EndDate > 25 THEN r.PathwayID ELSE NULL END) AS 'StudentEnteringTreatment25Plus'

		, NULL AS 'Postcode'
		, NULL AS 'GridRef'
		, NULL AS 'Eastings'
		, NULL AS 'Northings'
		, NULL AS 'Lat'
		, NULL AS 'Long'
		, NULL AS 'City'

		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND Recovery_Flag = 'True' THEN r.PathwayID else NULL END) AS 'RecoveredTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 THEN r.PathwayID ELSE NULL END) AS 'FinishingTreatmentTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd and r.TreatmentCareContact_Count >= 2 AND NotCaseness_Flag = 'true' THEN r.PathwayID ELSE NULL END) AS 'NotCasenessTotal'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND EmployStatus = '03' AND Recovery_Flag = 'true' THEN r.PathwayID else NULL END) AS 'RecoveredStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND EmployStatus = '03' AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'FinishingTreatmentStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd and r.TreatmentCareContact_Count >= 2 AND NotCaseness_Flag = 'true' AND EmployStatus = '03' THEN r.PathwayID ELSE NULL END) AS 'NotCasenessStudent'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND ReliableImprovement_Flag = 'True' AND EmployStatus = '03' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement STUDENT'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.TreatmentCareContact_Count >= 2 AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[recordnumber] = mpi.[recordnumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		------------------------------
		LEFT JOIN [mesh_IAPT].[IDS004empstatus] e ON r.[RecordNumber] = e.[RecordNumber]
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.[OrgID_Provider] = ph.[Organisation_Code] AND ph.[Effective_To] IS NULL

WHERE l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND UsePathway_Flag = 'True' 
		AND IsLatest = 1

GROUP BY CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE)
		,CASE WHEN r.[OrgID_Provider] IS NOT NULL THEN r.[OrgID_Provider] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END 

-- Create temp table for geographical data -----------------------------

IF OBJECT_ID ('tempdb..#Postcodes') IS NOT NULL DROP TABLE #Postcodes

SELECT	[SiteCode]
		,[Postcode1]
		,[Grid Reference]
		,[X (easting)]
		,[Y (northing)]
		,[Latitude]
		,[Longitude]
		,[Address4]

INTO #Postcodes FROM [MHDInternal].[ODS_All_Sites]

-- Update [MHDInternal].[DASHBOARD_TTAD_Student] with values from temp table  ---------------

UPDATE [MHDInternal].[DASHBOARD_TTAD_Student]

SET		[Postcode] = pc.[Postcode1],
		[GridRef] = pc.[Grid Reference],
		[Eastings] = pc.[X (easting)],
		[Northings] = pc.[Y (northing)],
		[Lat] = pc.[Latitude],
		[Long] = pc.[Longitude],
		[City] = pc.[Address4]

FROM	[MHDInternal].[DASHBOARD_TTAD_Student] a
		----------------------------------------
		LEFT JOIN #Postcodes pc ON a.[Provider Code]= pc.[SiteCode]

------------------------------|
--SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_Student]' + CHAR(10)