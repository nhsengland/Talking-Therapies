SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- DELETE MAX(Month)s ------------------------------------------------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts])

----------------------------------------------------------------------------------------------------------------------------------

-- Selects Max CareContact Record (subquery due to selection of multiple records for some carecontactIds where there are different recordings of time/apptype - still an issue with some carecontactIds having multiple dates - check with kaz) keep in for now

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareContact]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareContact]

SELECT DISTINCT x.*, AppType,CareContTime INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareContact] FROM 

(

SELECT DISTINCT MAX(c.AUDITID) AS AuditID, [CareContDate], [PathwayID], [CareContactId]

FROM [mesh_IAPT].[IDS201CareContact] c

INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.AuditId = l.AuditId

WHERE ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05') and IsLatest = 1

GROUP BY [CareContDate], [PathwayID],[CareContactId]

) x

INNER JOIN [mesh_IAPT].[IDS201CareContact] a ON a.PathwayId = x.PathwayId AND a.CareContactId = x.CareContactId AND a.AuditId = x.AuditID

--Selects a single CareActivity Record - multiple CodeProcAndProcStatus for some apts
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareActivity]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareActivity]

SELECT c.*, CodeProcAndProcStatus INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareActivity] FROM (SELECT DISTINCT MIN(UniqueID_IDS202) AS MinRecord, [PathwayID], [CareContactId], a.[AuditId]

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
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Finished]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Finished]

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

INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Finished] 

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
		AND ServDischDate BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart
		AND CompletedTreatment_Flag = 'True'

-- Base Table ----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base]

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

INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base]

FROM 	[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Finished] f
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareContact] a ON a.PathwayID = f.PathwayID
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareActivity] c ON a.CareContactId =c.CareContactId AND c.PathwayID = a.PathwayID  AND c.AuditId = a.AuditId

WHERE f.ReferralRequestReceivedDate > '2020-08-31'

ORDER BY f.PathwayID, CareContDate

-- Adding number of days between appointments --------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits]
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

INTO	[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] 

FROM	[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base] a 
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base] b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID = (b.ROWID +1)

ORDER BY a.PathwayID,a.CareContDate


--ASSESSMENT TO FIRST LI OR HI INDICATOR

--Counts treatment only apts per intensity for each PathwayID
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount]
SELECT 
	PathwayId
	,[HI/LI/ES]
	,COUNT(CareContDate) AS 'CountTreatmentApts'
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount]
FROM(
	SELECT * 
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w 
	WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment')
)_
GROUP BY PathwayId, [HI/LI/ES]

--Selects the first HI apt for people with 2 or more HI treatment Apts
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI]
SELECT 
	PathwayId
	,MIN(ROWID) AS 'FirstHI' 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI] 
FROM(
	SELECT 
		w.*
		,CountTreatmentApts
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount] t ON w.PathwayId = t.PathwayId AND w.[HI/LI/ES] = t.[HI/LI/ES]
	WHERE t.[HI/LI/ES] = 'HI' AND CountTreatmentApts >= 2 AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')
)_
GROUP BY PathwayId

--Selects all PathwayIds with both LI and HI apts
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh]
SELECT w.* 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh] 
FROM(
	SELECT
		PathwayID
		,COUNT(DISTINCT [HI/LI/ES]) AS 'CountIntensities'
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w 
	WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] IN ('HI','LI')
	GROUP BY PathwayID HAVING COUNT(DISTINCT [HI/LI/ES]) > 1
) x 
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w ON w.PathwayId = x.PathwayId
WHERE [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] IN ('HI','LI')
ORDER BY PathwayId, RowId 

--Step up -- Selects only pathwayIds which have 2 LI apts before and 2 HI apts after the step-up and gives new apt order
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp]
SELECT 
	l.*
	,FirstHI
	,ROW_NUMBER() OVER(PARTITION BY l.[PathwayID] ORDER BY [CareContDate], [CareContTime], [CareContactId] DESC) AS ROWID2 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp] 
FROM(
	SELECT
		PathwayId
		,FirstHI
		,Count(CASE WHEN RowID < FirstHI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountLIbeforeHI
		,Count(CASE WHEN RowID >= FirstHI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountHIafterHI 
	FROM(
		SELECT
			l.*
			,FirstHI
		FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh] l 
		INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI] f ON f.PathwayId = l.PathwayId
	)_
	GROUP BY PathwayId, FirstHI 
	HAVING Count(CASE WHEN RowID < FirstHI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2 
	AND Count(CASE WHEN RowID >= FirstHI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2
) x
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh] l ON x.PathwayId = l.PathwayId
ORDER BY l.PathwayId, RowId

-- step up base -- Selects one row for each pathwayID where date_Diff2 = step up wait
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2]
SELECT * 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2] 
FROM(
	SELECT
		a.[Month]
		,a.[Provider Code]
		,a.[Provider Name]
		,a.[Sub ICB Code]
		,a.[Sub ICB Name]
		,a.ReferralRequestReceivedDate
		,a.CareContactId
		,a.CareContDate
		,a.CareContTime
		,a.PathwayID
		,a.ROWID
		,a.[HI/LI/ES]
		,a.[Appointment Type]
		,a.FirstHI
		,DATEDIFF(dd,b.CareContDate,a.CareContDate) AS date_Diff2
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp] a 
	LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp] b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID2 = (b.ROWID2 +1)
)_ 
WHERE RowID = FirstHI
ORDER BY PathwayID, CareContDate

--Selects first LI apt for people with 2 or more LI apts
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI]
SELECT 
	PathwayId
	,MIN(ROWID) AS FirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI]
FROM(
	SELECT
		w.*
		,CountTreatmentApts
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount] t ON w.PathwayId = t.PathwayId AND w.[HI/LI/ES] = t.[HI/LI/ES]
	WHERE t.[HI/LI/ES] = 'LI' AND CountTreatmentApts > 1 AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')
)_
GROUP BY PathwayId

-- Selects people who have 0 or 1 LIs before their first HI
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoLIbeforeHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoLIbeforeHI]
SELECT
	w.PathwayID
	,COUNT(CASE WHEN  RowID < FirstHI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'LI' THEN CareContDate END ) AS CountLIbeforeFirstHI 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoLIbeforeHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI] h ON  w.PathwayID = h.PathwayID 
GROUP BY w.PathwayID
HAVING COUNT(CASE WHEN  RowID < FirstHI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'LI' THEN CareContDate END ) IN (0,1)

-- Selects people who have 0 or 1 HIs before their first LI
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoHIbeforeLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoHIbeforeLI]
SELECT
	w.PathwayID
	,COUNT(CASE WHEN  RowID < FirstLI AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') AND [HI/LI/ES] = 'HI' THEN CareContDate END ) AS CountHIbeforeFirstLI 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoHIbeforeLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w 
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI] h ON  w.PathwayID = h.PathwayID 
GROUP BY w.PathwayID
HAVING COUNT(CASE WHEN  RowID < FirstLI AND [Appointment Type]NOT IN ('Assessment and treatment','Assessment')  AND [HI/LI/ES] = 'HI' THEN CareContDate END ) IN (0,1)

--Step down -- Selects only pathwayIds which have 2 HI apts before and 2 LI apts after step-up and gives new apt order
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown]
SELECT
	l.*
	,FirstLI
	,ROW_NUMBER() OVER(PARTITION BY l.[PathwayID] ORDER BY [CareContDate], [CareContTime], [CareContactId] DESC) AS ROWID2
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown] 
FROM(
	SELECT
		PathwayId
		,FirstLI
		,Count(CASE WHEN RowID < FirstLI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountHIbeforeLI
	,Count(CASE WHEN RowID >= FirstLI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) AS CountLIafterHI
	FROM(
		SELECT
			l.*
			,FirstLI
		FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh] l
		INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI] f ON f.PathwayId = l.PathwayId
	)_
	GROUP BY PathwayId, FirstLI 
	HAVING Count(CASE WHEN RowID < FirstLI AND [HI/LI/ES] = 'HI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2 
	AND Count(CASE WHEN RowID >= FirstLI AND [HI/LI/ES] = 'LI' AND [Appointment Type] NOT IN ('Assessment and treatment','Assessment') THEN PathwayID END) >= 2
) x
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh] l ON x.PathwayId = l.PathwayId
ORDER BY l.PathwayId, RowId

-- step down base -- Selects one row for each pathwayID where date_Diff2 = step up wait
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2]
SELECT * 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2]
FROM(
	SELECT
		a.[Month]
		,a.[Provider Code]
		,a.[Provider Name]
		,a.[Sub ICB Code]
		,a.[Sub ICB Name]
		,a.ReferralRequestReceivedDate
		,a.CareContactId
		,a.CareContDate
		,a.CareContTime
		,a.PathwayID
		,a.ROWID
		,a.[HI/LI/ES]
		,a.[Appointment Type]
		,a.FirstLI
		,DATEDIFF(dd,b.CareContDate,a.CareContDate) AS date_Diff2
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown] a
	LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown] b ON a.[PathwayID] = b.[PathwayID] AND a.ROWID2 = (b.ROWID2 +1)
)_
WHERE RowID = FirstLI
ORDER BY PathwayID, CareContDate

--Adds waits from assessment to FirstHI for people with 0 or 1 LIs before their first HI to [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2] in the same format
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
SELECT * 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
FROM(
	SELECT
		w.[Month]
		,w.[Provider Code]
		,w.[Provider Name]
		,w.[Sub ICB Code]
		,w.[Sub ICB Name]
		,w.ReferralRequestReceivedDate
		,w.CareContactId
		,w.CareContDate
		,w.CareContTime
		,w.PathwayID
		,w.ROWID
		,w.[HI/LI/ES]
		,w.[Appointment Type]
		,FirstHI
		,DATEDIFF(dd,Assessment_FirstDate,CareContDate) AS date_Diff2
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoLIbeforeHI] n ON w.PathwayID = n.PathwayID
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI] f ON w.PathwayID = f.PathwayID AND FirstHI = RowID
	WHERE Assessment_FirstDate < CareContDate
	UNION
	SELECT *
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2]
)_

--Adds waits from assessment to FirstLI for people with 0 or 1 HIs before their first LI Into [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2] in the same format
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
SELECT *
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
FROM(
	SELECT
		w.[Month]
		,w.[Provider Code]
		,w.[Provider Name]
		,w.[Sub ICB Code]
		,w.[Sub ICB Name]
		,w.ReferralRequestReceivedDate
		,w.CareContactId
		,w.CareContDate
		,w.CareContTime
		,w.PathwayID
		,w.ROWID
		,w.[HI/LI/ES]
		,w.[Appointment Type]
		,FirstLI
		,DATEDIFF(dd,Assessment_FirstDate,CareContDate) AS date_Diff2
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoHIbeforeLI] n ON w.PathwayID = n.PathwayID
	INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI] f ON w.PathwayID = f.PathwayID AND FirstLI = RowID
	WHERE Assessment_FirstDate < CareContDate
	UNION 
	SELECT * FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2]
)_

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculations for averages ------------------------------------------------------------------------------------------------------------------------------------

-- National ---------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstLI]
SELECT DISTINCT 
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER() AS MedianRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER() AS MedianRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstLI]
SELECT DISTINCT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
GROUP BY [Month]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
GROUP BY [Month]

-- Sub-ICB ---------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstLI]
SELECT DISTINCT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY [Sub ICB Code]) AS MedianRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Sub ICB Code]) AS MedianRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstLI]
SELECT DISTINCT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

-- Provider ---------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstLI]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Provider Code]) AS MedianRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_Diff2) OVER(PARTITION BY[Provider Code]) AS MedianRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstLI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstLI]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstLI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstLI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
GROUP BY [Month], [Provider Code], [Provider Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstHI]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstHI]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,AVG(date_Diff2) AS MeanRefToFirstHI
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstHI]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
GROUP BY [Month], [Provider Code], [Provider Name]

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_AssessToFirstLIHI_ICB] (1 of 3) -----------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI AS MedianAssessToFirstLI, MedianRefToFirstHI AS MedianAssessToFirstHI, MeanRefToFirstLI AS MeanAssessToFirstLI, MeanRefToFirstHI AS MeanAssessToFirstHI
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstLI] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstHI] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstLI] c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstHI] d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI, MedianRefToFirstHI, MeanRefToFirstLI, MeanRefToFirstHI 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstLI] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstHI] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstLI] c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstHI] d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MedianRefToFirstLI, MedianRefToFirstHI, MeanRefToFirstLI, MeanRefToFirstHI 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstLI] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstHI] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstLI] c ON a.Level = c.Level AND a.[Month] = c.[Month] AND a.[Sub ICB Code] = c.[Sub ICB Code] AND a.[Provider Code] = c.[Provider Code] 
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstHI] d ON a.Level = d.Level AND a.[Month] = d.[Month] AND a.[Sub ICB Code] = d.[Sub ICB Code] AND a.[Provider Code] = d.[Provider Code] 

)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI]'

--------------------------------------------------------------------------------------------------------------------------------------------
-- Average Maximum Waits -------------------------------------------------------------------------------------------------------------------

--Count treatment only apts per pathwayId
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2]
SELECT
	PathwayId
	,COUNT(CareContDate) AS CountTreatmentApts
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2]
FROM(
	SELECT *
	FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
	WHERE [Appointment Type] <> 'Assessment and treatment' AND [Appointment Type] <> 'Assessment'
)_
GROUP BY PathwayId

-- Base Table of Max Waits
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
SELECT
	a.[Month]
	,a.[Provider Code]
	,a.[Provider Name]
	,a.[Sub ICB Code]
	,a.[Sub ICB Name]
	,a.PathwayID
	,MAX(date_Diff) AS MaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] a
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2] t ON a.PathwayID = t.PathwayID
WHERE ROWID <> 1 AND CountTreatmentApts >= 2
GROUP BY a.[Month],a.[Provider Code],a.[Provider Name],a.[Sub ICB Code],a.[Sub ICB Name],a.PathwayID

-- National ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanMaxWait]
SELECT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(MaxWait) AS MeanMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
GROUP BY [Month]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianMaxWait]
SELECT DISTINCT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER() AS MedianMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]

-- Sub-ICB ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanMaxWait]
SELECT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(MaxWait) AS MeanMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianMaxWait]
SELECT DISTINCT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER(PARTITION BY [Sub ICB Code]) AS MedianMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]

-- PROVIDER ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanMaxWait]	
SELECT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,AVG(MaxWait) AS MeanMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
GROUP BY [Month], [Provider Code], [Provider Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianMaxWait]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianMaxWait]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MaxWait) OVER(PARTITION BY [Provider Code]) AS MedianMaxWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianMaxWait]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]

------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_Max_Wait_ICB] (2 of 3) ------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanMaxWait] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianMaxWait] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanMaxWait] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianMaxWait] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanMaxWait, MedianMaxWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanMaxWait] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianMaxWait] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait]'

-------------------------------------------------------------------------------------------------------------------------------
 -- Average Wait Per Person ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
SELECT w.* 
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits] w
INNER JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2] t ON t.PathwayID = w.PathwayID
WHERE CountTreatmentApts >= 2

-- NATIONAL ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsNational]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsNational]
SELECT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,AVG(date_diff) AS MeanWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsNational]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
WHERE ROWID > 1
GROUP BY [Month]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsNational]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsNational]
SELECT DISTINCT
	[Month]
	,'National' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER() AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsNational]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
WHERE ROWID > 1

-- Sub-ICB ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsSubICB]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsSubICB]
SELECT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	, AVG(date_diff) AS MeanWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsSubICB]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
WHERE ROWID > 1
GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsSubICB]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsSubICB]
SELECT
	[Month]
	,'Sub-ICB' AS 'Level'
	,'Refresh' AS DataSource
	,[Sub ICB Code] AS 'Sub ICB Code'
	,[Sub ICB Name] AS 'Sub ICB Name'
	,'All Providers' AS 'Provider Code'
	,'All Providers' AS 'Provider Name'
	, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER(PARTITION BY [Sub ICB Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsSubICB]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
WHERE ROWID > 1

-- PROVIDER ---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsProvider]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsProvider]
SELECT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	,AVG(date_diff) AS MeanWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsProvider]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
WHERE ROWID > 1
GROUP BY [Month], [Provider Code], [Provider Name]

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsProvider]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsProvider]
SELECT DISTINCT
	[Month]
	,'Provider' AS 'Level'
	,'Refresh' AS DataSource
	,'All Sub-ICBs' AS 'Sub ICB Code'
	,'All Sub-ICBs' AS 'Sub ICB Name'
	,[Provider Code] AS 'Provider Code'
	,[Provider Name] AS 'Provider Name'
	, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_diff) OVER(PARTITION BY [Provider Code]) AS MedianWait
INTO [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsProvider]
FROM [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2] WHERE ROWID > 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [IAPT_Avg_Wait_Between_Apts] (3 of 3) ---------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts]

SELECT * FROM

(

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name],  MeanWait, MedianWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsNational] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsNational] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanWait, MedianWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsSubICB] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsSubICB] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

UNION

SELECT a.[Month],a.Level,a.DataSource,a.[Sub ICB Code],a.[Sub ICB Name],a.[Provider Code],a.[Provider Name], MeanWait, MedianWait 
FROM  [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsProvider] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsProvider] b ON a.Level = b.Level AND a.[Month] = b.[Month] AND a.[Sub ICB Code] = b.[Sub ICB Code] AND a.[Provider Code] = b.[Provider Code]

)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts]'

--Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareContact]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_CareActivity]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Base]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Lowandhigh]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_StepUp2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_FirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NoLIbeforeHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Stepdown2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_WaitFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstLI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanRefToFirstHI]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_TreatmentCount2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MaxWaits]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMeanMaxWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_NationalMedianMaxWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMeanMaxWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_SubICBMedianMaxWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMeanMaxWait]	
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_ProviderMedianMaxWait]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_Waits2]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsNational]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsNational]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsSubICB]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsSubICB]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MeanWaitsProvider]
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_AvgWaits_MedianWaitsProvider]
