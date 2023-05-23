/****** Script for Employment Support Dashboard to produce the table for the employment support indicator dashboard page ******/

--Employment Support Indicator Base Table
--This table produces a record level table for the refresh period defined below, as a basis for the output table produced further below ([NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator])
USE [NHSE_IAPT_v2]

DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [dbo].[IsLatest_SubmissionID])
SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
SELECT DISTINCT
	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) as Month
	,r.Person_ID
	,r.PathwayID
	,emp.RecordNumber
		
	,CASE WHEN r.CompletedTreatment_Flag  = 'True' 
	AND EmpSupportInd='Y' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS FinishedTreatEmpSuppIndYes	--Flag for those who completed treatment and who are eligible for employment support
	,CASE WHEN  r.CompletedTreatment_Flag  = 'True' 
	AND EmpSupportInd='Y' AND EmploymentSupport_Count>0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes	
	--Flag for those who completed treatment, who are eligible for employment support and have had at least one employment support appointment
		
	,CASE WHEN EmpSupportInd='Y' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS EmpSuppIndYes	--Flag for those who are eligible for employment support
	,CASE WHEN EmpSupportInd='Y' AND EmploymentSupport_Count>0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END AS EmpSuppFirstAppAndEmpSuppIndYes
	--Flag for those who are eligible for employment support and have had at least one employment support appointment
		
	,ch.Organisation_Code as 'Sub-ICBCode'
	,ch.Organisation_Name as 'Sub-ICB Name'
	,ch.STP_Name as 'ICB Name'
	,ch.Region_Name as 'RegionNameComm'
	,ph.Organisation_Code as 'ProviderCode'
	,ph.Organisation_Name as 'Provider Name'
	,ph.Region_Name as 'RegionNameProv'
	,r.EmploymentSupport_Count
INTO [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
FROM [dbo].[IDS101_Referral] r
	INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
	--Allows filtering for the latest data	
	LEFT JOIN [NHSE_IAPT_v2].[dbo].[IDS004_EmploymentStatus] emp ON r.recordnumber = emp.recordnumber
	--Provides data for employment status and other indicators
	LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
	LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
	LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
	--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
WHERE UsePathway_Flag = 'True' 
	AND IsLatest = 1	--To get the latest data
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart	--for refresh, the offset should be 0 as only want the data for the latest month
	AND emp.EmpSupportInd='Y'	--Only looking at those who are eligible for employment support
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	--Only looking at discharges within the reporting period


--Employment Support Indicator Output Table
--This table sums the flags produced in the base table above at Provider, Sub-ICB, ICB and National levels. 

------------------Provider
--IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]') is not null drop table [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
SELECT
	Month
	,cast('Provider' as varchar(max)) as [OrgType]
	,cast([Provider Name] as varchar(max)) as [OrgName]
	,cast([RegionNameProv] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
--INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
GROUP BY Month, [Provider Name], [RegionNameProv]

------------------Sub-ICB
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
SELECT
	Month
	,cast('Sub-ICB' as varchar(max)) as [OrgType]
	,cast([Sub-ICB Name] as varchar(max)) as [OrgName]
	,cast([RegionNameComm] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
GROUP BY Month, [Sub-ICB Name], [RegionNameComm]

------------------ICB
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
SELECT
	Month
	,cast('ICB' as varchar(max)) as [OrgType]
	,cast([ICB Name] as varchar(max)) as [OrgName]
	,cast([RegionNameComm] as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
GROUP BY Month, [ICB Name], [RegionNameComm]

------------------National
INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_EmploymentSupportIndicator2]
SELECT
	Month
	,cast('National' as varchar(max)) as [OrgType]
	,cast('England' as varchar(max)) as [OrgName]
	,cast('All Regions' as varchar(max)) as [Region]
	,SUM(FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes) as FinishedTreatEmpSuppFirstAppAndEmpSuppIndYes
	,SUM(FinishedTreatEmpSuppIndYes) as FinishedTreatEmpSuppIndYes
	,SUM(EmpSuppFirstAppAndEmpSuppIndYes) as EmpSuppFirstAppAndEmpSuppIndYes
	,SUM(EmpSuppIndYes) as EmpSuppIndYes
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]
GROUP BY Month

--Drop temporary tables created to produce the final output table
DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_EmploymentSupportInd]