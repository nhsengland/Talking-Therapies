
---------- EA DASHBOARD, EMP SUPPORT DISCHARGE DATE DQ CODE

----- Get/set reporting period

DECLARE @PeriodStart DATE
SET @PeriodStart = (SELECT DATEADD(MONTH,0,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])

DECLARE @PeriodStart2 DATE
SET @PeriodStart2 = '2021-04-01' 

DECLARE @PeriodStart3 DATE
SET @PeriodStart3 = EOMONTH(@PeriodStart,-5)

----- Get all referrals and their employment status table / employment support details

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion]

SELECT DISTINCT
l.[ReportingPeriodStartDate],
r.Person_ID,
r.PathwayID,
r.RecordNumber, -- Currently we are getting 1 row per month, per person/referral and per employment info - multple rows per referral if this info changes inc. null and not null. So, we take just the latest data and max dates in subsequent steps.
r.EmpSupport_FirstDate, -- ^
emp.EmpSupportDischargeDate, -- ^
CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode', 
CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName',
CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode',
CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICBName',
CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm',
CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm',
CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode',
CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName',
ROW_NUMBER()OVER(PARTITION BY r.Person_ID, r.PathwayID ORDER BY r.RecordNumber DESC) AS 'LatestRecord' -- To get 1 row per referral

INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion]

FROM [mesh_IAPT].[IDS101referral] r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
AND ch.Effective_To IS NULL
LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
AND ph.Effective_To IS NULL
LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.RecordNumber = emp.RecordNumber AND emp.AuditId = l.AuditId 

WHERE r.UsePathway_Flag = 'True' 
AND l.IsLatest = 1	
AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodStart
AND (emp.EmpSupportDischargeDate IS NOT NULL OR r.EmpSupport_FirstDate IS NOT NULL) 

----- Get employment support start date, access date, and discharge date, at some point, using Max

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_PerReferral]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_PerReferral]

SELECT DISTINCT
r.Person_ID,
r.PathwayID,
MAX(r.EmpSupport_FirstDate) AS Max_EmpSupport_FirstDate, -- Can't just take their latest record as sometimes this is null, so taking the Max (the access and discharge date technically shouldn't change)
MAX(r.EmpSupportDischargeDate) AS Max_EmpSupportDischargeDate -- Can't just take their latest record as sometimes this is null, so taking the Max (the access and discharge date technically shouldn't change)
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_PerReferral]

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion] r
GROUP BY r.Person_ID,
r.PathwayID

----- Add these max dates & flags to original table, take just the latest record (1 row per ep), keep only those who have accessed employment support, and identify if discharge date is present

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]

SELECT
r.*,
p.Max_EmpSupport_FirstDate,
p.Max_EmpSupportDischargeDate,
CASE WHEN p.Max_EmpSupportDischargeDate IS NOT NULL THEN 1 ELSE 0 END AS DischargeDatePresent,
EOMONTH(p.Max_EmpSupport_FirstDate) AS FirstContactMonth 
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion] r
INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_PerReferral] p ON r.Person_ID = p.Person_ID AND r.PathwayID = p.PathwayID
AND p.Max_EmpSupport_FirstDate IS NOT NULL 
WHERE r.LatestRecord = 1

----- Comparing the max dates with the latest dates: some records have a null date in their latest record, despite having an earlier record with a date, so we NEED to use max date

----- Create aggregate counts, in long format, for each geog/org type

IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupport_DischargeDateCompletion]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupport_DischargeDateCompletion]

SELECT
FirstContactMonth,
'England' AS OrgType,
'England' AS Region, 
'England' AS OrgName,
COUNT(DISTINCT PathwayID) AS NewAccess, 
SUM(DischargeDatePresent) AS DischargeDatePresent
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupport_DischargeDateCompletion]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
WHERE FirstContactMonth >= @PeriodStart2 AND FirstContactMonth < @PeriodStart3
GROUP BY FirstContactMonth

UNION ALL

SELECT
FirstContactMonth,
'Provider' AS OrgType,
RegionNameComm AS Region, 
ProviderName AS OrgName,
COUNT(DISTINCT PathwayID) AS NewAccess, 
SUM(DischargeDatePresent) AS DischargeDatePresent
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
WHERE FirstContactMonth >= @PeriodStart2 AND FirstContactMonth < @PeriodStart3
GROUP BY FirstContactMonth, ProviderName, RegionNameComm

UNION ALL

SELECT
FirstContactMonth,
'Sub-ICB' AS OrgType,
RegionNameComm AS Region, 
[Sub-ICBName] AS OrgName,
COUNT(DISTINCT PathwayID) AS NewAccess, 
SUM(DischargeDatePresent) AS DischargeDatePresent
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
WHERE FirstContactMonth >= @PeriodStart2 AND FirstContactMonth < @PeriodStart3
GROUP BY FirstContactMonth, [Sub-ICBName], RegionNameComm

UNION ALL

SELECT
FirstContactMonth,
'ICB' AS OrgType,
RegionNameComm AS Region, 
ICBName AS OrgName,
COUNT(DISTINCT PathwayID) AS NewAccess, 
SUM(DischargeDatePresent) AS DischargeDatePresent
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
WHERE FirstContactMonth >= @PeriodStart2 AND FirstContactMonth < @PeriodStart3
GROUP BY FirstContactMonth, ICBName, RegionNameComm

UNION ALL

SELECT
FirstContactMonth,
'Region' AS OrgType,
RegionNameComm AS Region,
RegionNameComm AS OrgName,
COUNT(DISTINCT PathwayID) AS NewAccess, 
SUM(DischargeDatePresent) AS DischargeDatePresent
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
WHERE FirstContactMonth >= @PeriodStart2 AND FirstContactMonth < @PeriodStart3
GROUP BY FirstContactMonth, RegionNameComm, RegionNameComm
ORDER BY OrgType, OrgName, FirstContactMonth DESC

----- Drop temporary tables

DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_PerReferral]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Discharge_Completion_EAOnly]
