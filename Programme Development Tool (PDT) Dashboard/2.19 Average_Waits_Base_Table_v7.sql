SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- DELETE MAX(Month)s ------------------------------------------------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts])

----------------------------------------------------------------------------------------------------------------------------------

-- Selects Max CareContact Record (subquery due to selection of multiple records for some carecontactIds where there are different recordings of time/apptype - still an issue with some carecontactIds having multiple dates - check with kaz) keep in for now

IF OBJECT_ID ('[MHDInternal].[TEMP_IAPT_AvgWaits_CareContact]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_IAPT_AvgWaits_CareContact]

SELECT DISTINCT x.*, AppType,CareContTime INTO [MHDInternal].[TEMP_IAPT_AvgWaits_CareContact] FROM 

(

SELECT DISTINCT MAX(c.AUDITID) AS AuditID, [CareContDate], [PathwayID], [CareContactId]

FROM [mesh_IAPT].[IDS201CareContact] c

INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.AuditId = l.AuditId

WHERE ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05') and IsLatest = 1

GROUP BY [CareContDate], [PathwayID],[CareContactId]

) x

INNER JOIN [mesh_IAPT].[IDS201CareContact] a ON a.PathwayId = x.PathwayId AND a.CareContactId = x.CareContactId AND a.AuditId = x.AuditID

--Selects a single CareActivity Record - multiple CodeProcAndProcStatus for some apts
IF OBJECT_ID ('[MHDInternal].[TEMP_IAPT_AvgWaits_CareActivity]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_IAPT_AvgWaits_CareActivity]

SELECT c.*, CodeProcAndProcStatus INTO [MHDInternal].[TEMP_IAPT_AvgWaits_CareActivity] FROM (SELECT DISTINCT MIN(UniqueID_IDS202) AS MinRecord, [PathwayID], [CareContactId], a.[AuditId]

FROM (

SELECT DISTINCT [PathwayID],[CareContactId],a.[AuditId], [UniqueID_IDS202] 

FROM 	[mesh_IAPT].[IDS202careactivity] a
		----------------------------------
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON a.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND a.AuditId = l.AuditId

WHERE 	CodeProcAndProcStatus IS NOT NULL 
		and IsLatest = 1 and (CodeProcAndProcStatus IN('1127281000000100', '1129471000000105', '842901000000108', '286711000000107', '314034001','449030000', '933221000000107', '1026131000000100', '304891004', '443730003','1098051000000103','748051000000105', '748101000000105', '748041000000107', '748091000000102', '748061000000108', '702545008', '1026111000000108', '975131000000104')
		OR CodeProcAndProcStatus IN ('228557008','409063005','440274001','786721000000109','429048003','429329005','444175001','1129491000000100','223458004','975151000000106')) -- Other SNOWMED codes assigned to LI/HI by Andy

) a

GROUP BY [PathwayID],[CareContactId], AuditId ) c
INNER JOIN [mesh_IAPT].[IDS202CareActivity] a ON MinRecord = a.UniqueID_IDS202 AND a.CareContactId = c.CareContactId AND c.PathwayId = a.PathwayID AND c.AuditId = a.AuditId

---------------------------------------------------------------------------------------------------------------------------------------------------


DECLARE @Offset AS INT = 0

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

--Selects all PathwayId's which have finished a course of treatment in the month
IF OBJECT_ID ('tempdb..#Finished') IS NOT NULL DROP TABLE #Finished

SELECT DISTINCT 
		
		@MonthYear AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		,r.PathwayID 
		,r.AuditId 
		,r.UniqueSubmissionID
		,ReferralRequestReceivedDate
		,Assessment_FirstDate

INTO #Finished 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS201CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
 
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL	

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'True'

-- Base Table ----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Base') IS NOT NULL DROP TABLE #Base

SELECT DISTINCT f.*, CareContDate, CareContTime,a.CareContactId
		,CASE WHEN AppType = 01 THEN 'Assessment'
			WHEN AppType = 02 THEN 'Treatment'
			WHEN AppType = 03 THEN 'Assessment and treatment'
			WHEN AppType = 05 THEN 'Review and treatment'
			END AS 'Appointment Type'
		,ROW_NUMBER() OVER( PARTITION BY f.[PathwayID] ORDER BY [CareContDate], [CareContTime],a.[CareContactId] DESC) AS ROWID
		,CASE WHEN (CodeProcAndProcStatus IN ('1127281000000100', '1129471000000105', '842901000000108', '286711000000107', '314034001','449030000', '933221000000107', '1026131000000100', '304891004', '443730003') 
			OR CodeProcAndProcStatus IN ('228557008','409063005','440274001','786721000000109','429048003'))
			THEN 'HI' 
			WHEN CodeProcAndProcStatus =  '1098051000000103' THEN 'ES'
			WHEN (CodeProcAndProcStatus IN ('748051000000105', '748101000000105', '748041000000107', '748091000000102', '748061000000108', '702545008', '1026111000000108', '975131000000104')
			OR CodeProcAndProcStatus IN ('429329005','444175001','1129491000000100','223458004','975151000000106')) THEN 'LI'
			ELSE 'Invalid Code/no code' END AS 'HI/LI/ES'

INTO #Base

FROM 	#Finished f
		LEFT JOIN [MHDInternal].[TEMP_IAPT_AvgWaits_CareContact] a ON a.PathwayID = f.PathwayID
		LEFT JOIN [MHDInternal].[TEMP_IAPT_AvgWaits_CareActivity] c ON a.CareContactId =c.CareContactId AND c.PathwayID = a.PathwayID  AND c.AuditId = a.AuditId

WHERE f.ReferralRequestReceivedDate > '2020-08-31'

ORDER BY f.PathwayID, CareContDate

-- Adding number of days between appointments --------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Waits') IS NOT NULL DROP TABLE #Waits

SELECT	a.[Month]
		,a.[Provider Code]
		,a.[Provider Name]
		,a.[Sub ICB Code]
		,a.[Sub ICB Name]
		,a.ReferralRequestReceivedDate
		,a.Assessment_FirstDate
		,a.CareContactId
		,a.CareContDate
		,a.CareContTime
		,a.PathwayID
		,a.ROWID
		,a.[HI/LI/ES]
		,a.[Appointment Type]
		,DATEDIFF(dd,b.CareContDate,a.CareContDate) AS 'date_Diff'

INTO	#Waits 

FROM	#Base a 
		LEFT JOIN #Base b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID = (b.ROWID +1)

ORDER BY a.PathwayID,a.CareContDate


--ASSESSMENT TO FIRST LI OR HI INDICATOR

--Counts treatment only apts per intensity for each PathwayID
IF OBJECT_ID ('tempdb..#TreatmentCount') IS NOT NULL DROP TABLE #TreatmentCount

SELECT	PathwayId, [HI/LI/ES], COUNT(CareContDate) AS 'CountTreatmentApts'
INTO #TreatmentCount FROM (SELECT * FROM #Waits w WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment'))_
GROUP BY PathwayId, [HI/LI/ES]

--Selects the first HI apt for people with 2 or more HI treatment Apts
IF OBJECT_ID ('tempdb..#FirstHI') IS NOT NULL DROP TABLE #FirstHI

SELECT PathwayId, MIN(ROWID) AS 'FirstHI' 
INTO #FirstHI FROM (SELECT w.*, CountTreatmentApts FROM #Waits w
INNER JOIN #TreatmentCount t ON w.PathwayId = t.PathwayId AND w.[HI/LI/ES] = t.[HI/LI/ES]
WHERE t.[HI/LI/ES] = 'HI' AND CountTreatmentApts >= 2 AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment'))_
GROUP BY PathwayId

--Selects all PathwayIds with both LI and HI apts
IF OBJECT_ID ('tempdb..#Lowandhigh') IS NOT NULL DROP TABLE #Lowandhigh

SELECT w.* INTO #Lowandhigh FROM (SELECT PathwayID, COUNT(DISTINCT [HI/LI/ES]) AS 'CountIntensities' FROM #Waits w 
WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] IN ('HI','LI')
GROUP BY PathwayID HAVING COUNT(DISTINCT [HI/LI/ES]) > 1) x INNER JOIN #Waits w ON w.PathwayId = x.PathwayId
WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] IN ('HI','LI')
ORDER BY PathwayId, RowId 

--Step up -- Selects only pathwayIds which have 2 LI apts before and 2 HI apts after the step-up and gives new apt order
IF OBJECT_ID ('tempdb..#StepUp') IS NOT NULL DROP TABLE #StepUp

SELECT l.*, FirstHI, ROW_NUMBER() OVER(    PARTITION BY l.[PathwayID] ORDER BY    [CareContDate], [CareContTime], [CareContactId] DESC) AS ROWID2 INTO #StepUp 
FROM (SELECT PathwayId, FirstHI, Count(CASE WHEN RowID < FirstHI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountLIbeforeHI
,Count(CASE WHEN RowID >= FirstHI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountHIafterHI FROM (
SELECT l.*, FirstHI FROM #Lowandhigh l INNER JOIN #FirstHI f ON f.PathwayId = l.PathwayId)_  GROUP BY PathwayId, FirstHI 
HAVING Count(CASE WHEN RowID < FirstHI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2 
AND Count(CASE WHEN RowID >= FirstHI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2) x
INNER JOIN #Lowandhigh l ON x.PathwayId = l.PathwayId
ORDER BY l.PathwayId, RowId

-- step up base -- Selects one row for each pathwayID where date_Diff2 = step up wait
IF OBJECT_ID ('tempdb..#StepUp2') IS NOT NULL DROP TABLE #StepUp2

SELECT * INTO #StepUp2 FROM (
SELECT a.[Month],a.[Provider Code],a.[Provider Name],a.[Sub ICB Code],a.[Sub ICB Name],a.ReferralRequestReceivedDate,a.CareContactId,a.CareContDate,a.CareContTime
,a.PathwayID,a.ROWID,a.[HI/LI/ES],a.[Appointment Type],a.FirstHI, DATEDIFF(dd,b.CareContDate,a.CareContDate) AS date_Diff2
FROM  #StepUp a LEFT JOIN #StepUp b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID2 = (b.ROWID2 +1)
)_ WHERE RowID = FirstHI ORDER BY PathwayID, CareContDate

--Selects first LI apt for people with 2 or more LI apts
IF OBJECT_ID ('tempdb..#FirstLI') IS NOT NULL DROP TABLE #FirstLI

SELECT PathwayId, MIN(ROWID) AS FirstLI INTO #FirstLI FROM (SELECT w.*, CountTreatmentApts FROM #Waits w
INNER JOIN #TreatmentCount t ON w.PathwayId = t.PathwayId AND w.[HI/LI/ES] = t.[HI/LI/ES]
WHERE t.[HI/LI/ES] = 'LI' AND CountTreatmentApts > 1 AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment'))_
GROUP BY PathwayId

-- Selects people who have 0 or 1 LIs before their first HI
IF OBJECT_ID ('tempdb..#NoLIbeforeHI') IS NOT NULL DROP TABLE #NoLIbeforeHI

SELECT w.PathwayID, COUNT(CASE WHEN  RowID < FirstHI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'LI' THEN CareContDate END ) AS CountLIbeforeFirstHI 
INTO #NoLIbeforeHI
FROM #Waits w INNER JOIN #FirstHI h ON  w.PathwayID = h.PathwayID 
GROUP BY w.PathwayID
HAVING COUNT(CASE WHEN  RowID < FirstHI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'LI' THEN CareContDate END ) IN (0,1)

-- Selects people who have 0 or 1 HIs before their first LI
IF OBJECT_ID ('tempdb..#NoHIbeforeLI') IS NOT NULL DROP TABLE #NoHIbeforeLI

SELECT w.PathwayID, COUNT(CASE WHEN  RowID < FirstLI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] = 'HI' THEN CareContDate END ) AS CountHIbeforeFirstLI 
INTO #NoHIbeforeLI
FROM #Waits w INNER JOIN #FirstLI h ON  w.PathwayID = h.PathwayID 
GROUP BY w.PathwayID
HAVING COUNT(CASE WHEN  RowID < FirstLI AND [Appointment Type]NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'HI' THEN CareContDate END ) IN (0,1)

--Step down -- Selects only pathwayIds which have 2 HI apts before and 2 LI apts after step-up and gives new apt order
IF OBJECT_ID ('tempdb..#Stepdown') IS NOT NULL DROP TABLE #Stepdown

SELECT l.*, FirstLI, ROW_NUMBER() OVER(   PARTITION BY l.[PathwayID] ORDER BY    [CareContDate], [CareContTime], [CareContactId] DESC) AS ROWID2 INTO #Stepdown 
FROM (SELECT PathwayId, FirstLI, Count(CASE WHEN RowID < FirstLI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountHIbeforeLI
,Count(CASE WHEN RowID >= FirstLI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountLIafterHI FROM (
SELECT l.*, FirstLI FROM #Lowandhigh l INNER JOIN #FirstLI f ON f.PathwayId = l.PathwayId)_  GROUP BY PathwayId, FirstLI 
HAVING Count(CASE WHEN RowID < FirstLI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2 AND Count(CASE WHEN RowID >= FirstLI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2) x
INNER JOIN #Lowandhigh l ON x.PathwayId = l.PathwayId
ORDER BY l.PathwayId, RowId

-- step down base -- Selects one row for each pathwayID where date_Diff2 = step up wait
IF OBJECT_ID ('tempdb..#Stepdown2') IS NOT NULL DROP TABLE #Stepdown2

SELECT * INTO #Stepdown2 FROM (
SELECT a.[Month],a.[Provider Code],a.[Provider Name],a.[Sub ICB Code],a.[Sub ICB Name],a.ReferralRequestReceivedDate,a.CareContactId,a.CareContDate,a.CareContTime
,a.PathwayID,a.ROWID,a.[HI/LI/ES],a.[Appointment Type],a.FirstLI, DATEDIFF(dd,b.CareContDate,a.CareContDate) AS date_Diff2
FROM  #Stepdown a LEFT JOIN #Stepdown b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID2 = (b.ROWID2 +1)
)_ WHERE RowID = FirstLI ORDER BY PathwayID, CareContDate

--Adds waits from assessment to FirstHI for people with 0 or 1 LIs before their first HI to #StepUp2 in the same format
IF OBJECT_ID ('tempdb..#WaitFirstHI') IS NOT NULL DROP TABLE #WaitFirstHI

SELECT * INTO #WaitFirstHI FROM (
SELECT w.[Month], w.[Provider Code], w.[Provider Name], w.[Sub ICB Code], w.[Sub ICB Name], w.ReferralRequestReceivedDate, w.CareContactId, w.CareContDate, w.CareContTime
, w.PathwayID, w.ROWID, w.[HI/LI/ES], w.[Appointment Type], FirstHI, DATEDIFF(dd,Assessment_FirstDate,CareContDate) AS date_Diff2
FROM #Waits w INNER JOIN #NoLIbeforeHI n ON w.PathwayID = n.PathwayID
INNER JOIN #FirstHI f ON w.PathwayID = f.PathwayID AND FirstHI = RowID
WHERE Assessment_FirstDate < CareContDate
UNION
SELECT * FROM #StepUp2 )_

--Adds waits from assessment to FirstLI for people with 0 or 1 HIs before their first LI Into #Stepdown2 in the same format
IF OBJECT_ID ('tempdb..#WaitFirstLI') IS NOT NULL DROP TABLE #WaitFirstLI

SELECT * INTO #WaitFirstLI FROM (
SELECT w.[Month], w.[Provider Code], w.[Provider Name],  w.[Sub ICB Code], w.[Sub ICB Name], w.ReferralRequestReceivedDate, w.CareContactId, w.CareContDate, w.CareContTime
, w.PathwayID, w.ROWID, w.[HI/LI/ES], w.[Appointment Type], FirstLI, DATEDIFF(dd,Assessment_FirstDate,CareContDate) AS date_Diff2
FROM #Waits w INNER JOIN #NoHIbeforeLI n ON w.PathwayID = n.PathwayID
INNER JOIN #FirstLI f ON w.PathwayID = f.PathwayID AND FirstLI = RowID
WHERE Assessment_FirstDate < CareContDate
UNION 
SELECT * FROM #Stepdown2 )_

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculations for averages ------------------------------------------------------------------------------------------------------------------------------------

-- Temp tables ----------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#NationalMedianRefToFirstLI') IS NOT NULL DROP TABLE #NationalMedianRefToFirstLI
IF OBJECT_ID ('tempdb..#NationalMedianRefToFirstHI') IS NOT NULL DROP TABLE #NationalMedianRefToFirstHI
IF OBJECT_ID ('tempdb..#NationalMeanRefToFirstLI') IS NOT NULL DROP TABLE #NationalMeanRefToFirstLI
IF OBJECT_ID ('tempdb..#NationalMeanRefToFirstHI') IS NOT NULL DROP TABLE #NationalMeanRefToFirstHI
IF OBJECT_ID ('tempdb..#SubICBMedianRefToFirstLI') IS NOT NULL DROP TABLE #SubICBMedianRefToFirstLI
IF OBJECT_ID ('tempdb..#SubICBMedianRefToFirstHI') IS NOT NULL DROP TABLE #SubICBMedianRefToFirstHI
IF OBJECT_ID ('tempdb..#SubICBMeanRefToFirstLI') IS NOT NULL DROP TABLE #SubICBMeanRefToFirstLI
IF OBJECT_ID ('tempdb..#SubICBMeanRefToFirstHI') IS NOT NULL DROP TABLE #SubICBMeanRefToFirstHI
IF OBJECT_ID ('tempdb..#ProviderMedianRefToFirstLI') IS NOT NULL DROP TABLE #ProviderMedianRefToFirstLI
IF OBJECT_ID ('tempdb..#ProviderMedianRefToFirstHI') IS NOT NULL DROP TABLE #ProviderMedianRefToFirstHI
IF OBJECT_ID ('tempdb..#ProviderMeanRefToFirstLI') IS NOT NULL DROP TABLE #ProviderMeanRefToFirstLI
IF OBJECT_ID ('tempdb..#ProviderMeanRefToFirstHI') IS NOT NULL DROP TABLE #ProviderMeanRefToFirstHI

-- National ---------------------------------------------------------------------------------------

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER() AS MedianRefToFirstLI
INTO #NationalMedianRefToFirstLI FROM #WaitFirstLI

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code' ,'All Providers' AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER() AS MedianRefToFirstHI
INTO #NationalMedianRefToFirstHI FROM #WaitFirstHI

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstLI
INTO #NationalMeanRefToFirstLI FROM #WaitFirstLI GROUP BY [Month]

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code' ,'All Providers' AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstHI
INTO #NationalMeanRefToFirstHI FROM #WaitFirstHI GROUP BY [Month]

-- Sub-ICB ---------------------------------------------------------------------------------------

SELECT DISTINCT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY [Sub ICB Code]) AS MedianRefToFirstLI
INTO #SubICBMedianRefToFirstLI FROM #WaitFirstLI

SELECT DISTINCT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code' ,'All Providers' AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Sub ICB Code]) AS MedianRefToFirstHI
INTO #SubICBMedianRefToFirstHI FROM #WaitFirstHI

SELECT DISTINCT [Month],'Sub-ICB' AS 'Level','Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code',[Sub ICB Name] AS 'Sub ICB Name','All Providers' AS 'Provider Code','All Providers' AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstLI
INTO #SubICBMeanRefToFirstLI FROM #WaitFirstLI GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

SELECT DISTINCT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource,[Sub ICB Code] AS 'Sub ICB Code',[Sub ICB Name] AS 'Sub ICB Name','All Providers' AS 'Provider Code','All Providers' AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstHI
INTO #SubICBMeanRefToFirstHI FROM #WaitFirstHI GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

-- Provider ---------------------------------------------------------------------------------------

SELECT DISTINCT [Month],'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Provider Code]) AS MedianRefToFirstLI
INTO #ProviderMedianRefToFirstLI FROM #WaitFirstLI

SELECT DISTINCT [Month],'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name'
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Provider Code]) AS MedianRefToFirstHI
INTO #ProviderMedianRefToFirstHI FROM #WaitFirstHI

SELECT DISTINCT [Month],'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstLI
INTO #ProviderMeanRefToFirstLI FROM #WaitFirstLI GROUP BY [Month], [Provider Code], [Provider Name]

SELECT DISTINCT [Month],'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name'
,AVG(date_Diff2) AS MeanRefToFirstHI
INTO #ProviderMeanRefToFirstHI FROM #WaitFirstHI GROUP BY [Month], [Provider Code], [Provider Name]

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_AssessToFirstLIHI_ICB] (1 of 3) -----------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI AS MedianAssessToFirstLI, MedianRefToFirstHI AS MedianAssessToFirstHI, MeanRefToFirstLI AS MeanAssessToFirstLI, MeanRefToFirstHI AS MeanAssessToFirstHI
FROM  #NationalMedianRefToFirstLI a
LEFT JOIN #NationalMedianRefToFirstHI b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN #NationalMeanRefToFirstLI c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN #NationalMeanRefToFirstHI d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI, MedianRefToFirstHI, MeanRefToFirstLI, MeanRefToFirstHI 
FROM  #SubICBMedianRefToFirstLI a
LEFT JOIN #SubICBMedianRefToFirstHI b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN #SubICBMeanRefToFirstLI c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN #SubICBMeanRefToFirstHI d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI, MedianRefToFirstHI, MeanRefToFirstLI, MeanRefToFirstHI 
FROM  #ProviderMedianRefToFirstLI a
LEFT JOIN #ProviderMedianRefToFirstHI b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN #ProviderMeanRefToFirstLI c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN #ProviderMeanRefToFirstHI d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code] 

)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI]'

--------------------------------------------------------------------------------------------------------------------------------------------
-- Average Maximum Waits -------------------------------------------------------------------------------------------------------------------

--Count treatment only apts per pathwayId
IF OBJECT_ID ('tempdb..#TreatmentCount2') IS NOT NULL DROP TABLE #TreatmentCount2

SELECT PathwayId, COUNT(CareContDate) AS CountTreatmentApts
INTO #TreatmentCount2 FROM
(SELECT * FROM #Waits w WHERE [Appointment Type] <> 'Assessment and treatment' AND [Appointment Type] <> 'Assessment')_
GROUP BY PathwayId

-- Base Table of Max Waits
IF OBJECT_ID ('tempdb..#MaxWaits') IS NOT NULL DROP TABLE #MaxWaits

SELECT a.[Month],a.[Provider Code],a.[Provider Name],a.[Sub ICB Code],a.[Sub ICB Name],a.PathwayID, MAX(date_Diff) AS MaxWait INTO #MaxWaits
FROM #Waits a INNER JOIN #TreatmentCount2 t ON a.PathwayID = t.PathwayID
WHERE ROWID <> 1 AND CountTreatmentApts >= 2 GROUP BY  a.[Month],a.[Provider Code],a.[Provider Name],a.[Sub ICB Code],a.[Sub ICB Name],a.PathwayID

-- Temp tables ----------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#NationalMeanMaxWait') IS NOT NULL DROP TABLE #NationalMeanMaxWait
IF OBJECT_ID ('tempdb..#NationalMedianMaxWait') IS NOT NULL DROP TABLE #NationalMedianMaxWait
IF OBJECT_ID ('tempdb..#SubICBMeanMaxWait') IS NOT NULL DROP TABLE #SubICBMeanMaxWait
IF OBJECT_ID ('tempdb..#SubICBMedianMaxWait') IS NOT NULL DROP TABLE #SubICBMedianMaxWait
IF OBJECT_ID ('tempdb..#ProviderMeanMaxWait') IS NOT NULL DROP TABLE #ProviderMeanMaxWait
IF OBJECT_ID ('tempdb..#ProviderMedianMaxWait') IS NOT NULL DROP TABLE #ProviderMedianMaxWait

-- National ---------------------------------------------------------------------------------------------------

SELECT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',
AVG(MaxWait) AS MeanMaxWait INTO #NationalMeanMaxWait FROM #MaxWaits
GROUP BY [Month]

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',  
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER() AS MedianMaxWait INTO #NationalMedianMaxWait FROM #MaxWaits

-- Sub-ICB ---------------------------------------------------------------------------------------------------

SELECT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',
AVG(MaxWait) AS MeanMaxWait INTO #SubICBMeanMaxWait FROM #MaxWaits
GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

SELECT DISTINCT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',  
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER(PARTITION BY [Sub ICB Code]) AS MedianMaxWait INTO #SubICBMedianMaxWait FROM #MaxWaits

-- PROVIDER ---------------------------------------------------------------------------------------------------
		
SELECT [Month], 'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name',
AVG(MaxWait) AS MeanMaxWait INTO #ProviderMeanMaxWait FROM #MaxWaits
GROUP BY [Month], [Provider Code], [Provider Name]

SELECT DISTINCT [Month], 'Provider' AS 'Level','Refresh' AS DataSource,'All Sub-ICBs' AS 'Sub ICB Code','All Sub-ICBs' AS 'Sub ICB Name',[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name',  
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER(PARTITION BY [Provider Code]) AS MedianMaxWait INTO #ProviderMedianMaxWait FROM #MaxWaits

------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_Max_Wait_ICB] (2 of 3) ------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  #NationalMeanMaxWait a
LEFT JOIN #NationalMedianMaxWait b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  #SubICBMeanMaxWait a
LEFT JOIN #SubICBMedianMaxWait b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  #ProviderMeanMaxWait a
LEFT JOIN #ProviderMedianMaxWait b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

)_

PRINT 'Updated - [MHDInternal].[IAPT_Avg_Max_Wait]'

-------------------------------------------------------------------------------------------------------------------------------
 -- Average Wait Per Person ---------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#MeanWaitsNational') IS NOT NULL DROP TABLE #MeanWaitsNational
IF OBJECT_ID ('tempdb..#MedianWaitsNational') IS NOT NULL DROP TABLE #MedianWaitsNational
IF OBJECT_ID ('tempdb..#MeanWaitsSubICB') IS NOT NULL DROP TABLE #MeanWaitsSubICB
IF OBJECT_ID ('tempdb..#MedianWaitsSubICB') IS NOT NULL DROP TABLE #MedianWaitsSubICB
IF OBJECT_ID ('tempdb..#MeanWaitsProvider') IS NOT NULL DROP TABLE #MeanWaitsProvider
IF OBJECT_ID ('tempdb..#MedianWaitsProvider') IS NOT NULL DROP TABLE #MedianWaitsProvider

IF OBJECT_ID ('tempdb..#Waits2') IS NOT NULL DROP TABLE #Waits2
SELECT w.* INTO #Waits2 FROM #Waits w
INNER JOIN #TreatmentCount2 t ON t.PathwayID = w.PathwayID
WHERE CountTreatmentApts >= 2

-- NATIONAL ---------------------------------------------------------------------------------------------------

SELECT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name', AVG(date_diff) AS MeanWait
INTO #MeanWaitsNational FROM #Waits2
WHERE ROWID > 1 GROUP BY [Month]

SELECT DISTINCT [Month], 'National' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER() AS MedianWait
INTO #MedianWaitsNational FROM #Waits2 WHERE ROWID > 1

-- Sub-ICB ---------------------------------------------------------------------------------------------------

SELECT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',
 AVG(date_diff) AS MeanWait
INTO #MeanWaitsSubICB FROM #Waits2
WHERE ROWID > 1 GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

SELECT [Month], 'Sub-ICB' AS 'Level', 'Refresh' AS DataSource, [Sub ICB Code] AS 'Sub ICB Code' ,[Sub ICB Name] AS 'Sub ICB Name' ,'All Providers' AS 'Provider Code','All Providers' AS 'Provider Name',
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER(PARTITION BY [Sub ICB Code]) AS MedianWait
INTO #MedianWaitsSubICB FROM #Waits2 WHERE ROWID > 1

-- PROVIDER ---------------------------------------------------------------------------------------------------

SELECT [Month], 'Provider' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name',
 AVG(date_diff) AS MeanWait
INTO #MeanWaitsProvider FROM #Waits2
WHERE ROWID > 1 GROUP BY [Month], [Provider Code], [Provider Name]

SELECT DISTINCT [Month], 'Provider' AS 'Level', 'Refresh' AS DataSource, 'All Sub-ICBs' AS 'Sub ICB Code' ,'All Sub-ICBs' AS 'Sub ICB Name' ,[Provider Code] AS 'Provider Code',[Provider Name] AS 'Provider Name',
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER(PARTITION BY [Provider Code]) AS MedianWait
INTO #MedianWaitsProvider FROM #Waits2 WHERE ROWID > 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_Wait_Between_Apts] (3 of 3) ---------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name],  MeanWait, MedianWait 
FROM  #MeanWaitsNational a
LEFT JOIN #MedianWaitsNational b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanWait, MedianWait 
FROM  #MeanWaitsSubICB a
LEFT JOIN #MedianWaitsSubICB b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanWait, MedianWait 
FROM  #MeanWaitsProvider a
LEFT JOIN #MedianWaitsProvider b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts]'
