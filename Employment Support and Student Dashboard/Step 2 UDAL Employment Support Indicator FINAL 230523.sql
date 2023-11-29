--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Employment Support Dashboard to produce the table for the employment support indicator dashboard page ******/
--This script must be run after Employment SUpport Main Tables script

--Employment Support Indicator Base Table
--This table produces a record level table for the refresh period defined below, as a basis for the output table produced further below ([MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator])

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
SELECT DISTINCT
	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) as Month
	,r.Person_ID
	,r.PathwayID
	,emp.RecordNumber
		
	,CASE WHEN r.CompletedTreatment_Flag  = 'True' 
	AND EmpSupportInd='Y' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS FinishedTreatEmpSuppIndYes	--Flag for those who completed treatment and who are eligible for employment support
	,CASE WHEN  r.CompletedTreatment_Flag  = 'True' 
	AND EmpSupportInd='Y' AND ec.Count_EmpSupp>0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes	
	--Flag for those who completed treatment, who are eligible for employment support and have had at least one employment support appointment
		
	,CASE WHEN EmpSupportInd='Y' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS EmpSuppIndYes	--Flag for those who are eligible for employment support
	,CASE WHEN EmpSupportInd='Y' AND ec.Count_EmpSupp>0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS EmpSuppFirstAppAndEmpSuppIndYes
	--Flag for those who are eligible for employment support and have had at least one employment support appointment
	
	--Geography
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICBName'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
	,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS 'RegionNameProv'
	,CASE WHEN ph.[Region_Code] IS NOT NULL THEN ph.[Region_Code] ELSE 'Other' END AS 'RegionCodeProv'

INTO [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
FROM [mesh_IAPT].[IDS101referral] r
	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--Allows filtering for the latest data	
	LEFT JOIN [mesh_IAPT].[IDS004empstatus] emp ON r.recordnumber = emp.recordnumber AND l.AuditID=emp.AuditID
	--Provides data for employment status and other indicators

	LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount] ec ON ec.PathwayID=r.PathwayID

	LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
		AND ch.Effective_To IS NULL
	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
		AND ph.Effective_To IS NULL
	--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE r.UsePathway_Flag = 'True' 
	AND l.IsLatest = 1	--To get the latest data
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart	--for refresh, the offset should be 0 as only want the data for the latest month
	AND emp.EmpSupportInd='Y'	--Only looking at those who are eligible for employment support
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	--Only looking at discharges within the reporting period


--Employment Support Indicator Output Table
--This table sums the flags produced in the base table above at Provider, Sub-ICB, ICB and National levels. 

------------------Provider
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
SELECT
	Month
	,CAST('Provider' as varchar(max)) as [OrgType]
	,CAST([ProviderCode] AS VARCHAR(max)) AS [OrgCode]
	,CAST([ProviderName] as varchar(max)) as [OrgName]
	,CAST([RegionNameProv] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
--INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
GROUP BY 
	Month
	,[ProviderName]
	,[ProviderCode]
	,[RegionNameProv]

------------------Sub-ICB
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
SELECT
	Month
	,CAST('Sub-ICB' as varchar(max)) as [OrgType]
	,CAST([Sub-ICBCode] AS VARCHAR(max)) AS [OrgCode]
	,CAST([Sub-ICBName] as varchar(max)) as [OrgName]
	,CAST([RegionNameComm] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
GROUP BY 
	Month
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,[RegionNameComm]

------------------ICB
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
SELECT
	Month
	,CAST('ICB' as varchar(max)) as [OrgType]
	,CAST([ICBCode] AS VARCHAR(max)) AS [OrgCode]
	,CAST([ICBName] as varchar(max)) as [OrgName]
	,CAST([RegionNameComm] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
GROUP BY 
	Month
	,[ICBName]
	,[ICBCode]
	,[RegionNameComm]

------------------National
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_Indicator]
SELECT
	Month
	,CAST('National' as varchar(max)) as [OrgType]
	,CAST('ENG' AS VARCHAR(max)) AS [OrgCode]
	,CAST('England' as varchar(max)) as [OrgName]
	,CAST('All Regions' as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
GROUP BY 
	Month

--Drop temporary tables created to produce the final output table
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_Indicator_Base]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
