/****** Script for Employment Support Dashboard to produce the Presenteeism Table******/

--Base Table
--This table produces a version of the IDS606 table filtered for the three assessment questions (questions 7, 8 and 9) about presenteeism from the Institute for Medical Technology Assessment Productivity Cost Questionnaire,
--filtered for the latest audit IDs and the first and last responses to these questions labelled (through ranking) for use later in the query

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral]
SELECT DISTINCT	
--this step of the query produces a table with all fields in the IDS606 table, filtered for the three assessment questions of interest,
--first and last responses to these questions are labelled (through ranking) for use later in the query, and provider codes are matched to provider names and corresponding region name
	sub.*
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
	,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS 'RegionNameProv'

	--This labels each record so that the last response to each assessment question has a value of 1. This is based on ordering each record with the same pathway ID and coded assessment tool type (i.e. assessment question) 
	--by the assessment tool completion date
	,ROW_NUMBER() OVER (PARTITION BY sub.PathwayID, sub.[CodedAssToolType] ORDER BY sub.[AssToolCompDate] desc,[AssToolCompTime] desc) AS ROWID1
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral]
FROM
	(SELECT DISTINCT --this subquery produces a table with all fields in the IDS606 table, filtered for the three assessment questions of interest and first responses to these questions have a value of 1
		a.*
		--This labels each record so that the first response to each assessment question has a value of 1. This is based on ordering each record with the same pathway ID and coded assessment tool type (i.e. assessment question) 
		--by the assessment tool completion date, time and unique ID for the IDS606 table
		,row_Number() OVER(PARTITION BY a.[PathwayID],a.[CodedAssToolType] ORDER BY a.[AssToolCompDate], a.[AssToolCompTime], a.[UniqueID_IDS606] desc) AS ROWID
		FROM
			(SELECT DISTINCT --this subquery produces a table with just the latest audit ID,the key fields for joining in the next part of the subquery and is filtered for the three assessment questions of interest
				MAX(c.AUDITID) AS AuditID
				,c.[AssToolCompDate]
				,c.[PathwayID]
				,c.[Unique_ServiceRequestID]
				,c.AssToolCompTime
			FROM [mesh_IAPT].[IDS606codedscoreassessmentrefer] c
			INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.AuditId = l.AuditId
			WHERE (CodedAssToolType IN ('748161000000109','760741000000102','761051000000105'))	--The SNOMED CT concept IDs for question 7, 8 and 9 of the Institute for Medical Technology Assessment Productivity Cost Questionnaire
				AND IsLatest = 1	--for getting the latest data
			GROUP BY [AssToolCompDate], [PathwayID], [Unique_ServiceRequestID], AssToolCompTime, OrgID_Provider
			) x
		INNER JOIN [mesh_IAPT].[IDS606codedscoreassessmentrefer] a ON a.PathwayId = x.PathwayId AND a.[Unique_ServiceRequestID] = x.[Unique_ServiceRequestID] 
			AND a.AuditId = x.AuditID AND a.[AssToolCompDate] = x.[AssToolCompDate] AND a.AssToolCompTime = x.AssToolCompTime
		--inner join of the IDS606 table with table x leads to the IDS606 table with just the records with the latest audit ID
		WHERE (CodedAssToolType IN ('748161000000109','760741000000102','761051000000105'))	--The SNOMED CT concept IDs for question 7, 8 and 9 of the Institute for Medical Technology Assessment Productivity Cost Questionnaire
		) sub
	LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON sub.OrgID_Provider = ps.Prov_original COLLATE database_default
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, sub.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
		AND ph.Effective_To IS NULL
	--For getting the up-to-date Provider names/codes
-------------------------------------------------------------------------------------------------------------------------------------------------------
--Period start and period end are defined for the next part of the query:
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be 0 to get the latest month
SET @PeriodStart = (SELECT DATEADD(MONTH,0,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,0,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

DECLARE @PeriodStart2 DATE
SET @PeriodStart2='2020-09-01' --this should always be September 2020

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

--------------------------------------------------------------------------------------------------------------------------------------------------------
--Question 7: During the last 2 weeks have there been days in which you worked but during this time were bothered by physical or psychological problems?	
--Question 7 Base Table
--This table creates separate columns for the assessment score and assessment completion date for the first and last responses for question 7.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]
SELECT 
	a.PathwayID
	,a.[ProviderName] AS [Provider Name]
	,a.ProviderCode AS [Provider Code]
	,a.[RegionNameProv] AS [Region Name]
	,a.CodedAssToolType
	,a.PersScore AS FirstPersScore
	,b.PersScore AS LastPersScore
	,b.AuditID
	,DATENAME(m, b.AssToolCompDate) + ' ' + CAST(DATEPART(yyyy, b.AssToolCompDate) AS varchar) as Month
	,a.AssToolCompDate AS FirstDate
	,b.AssToolCompDate AS LastDate
	,a.ROWID
	,b.ROWID1
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] a 
	INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] b ON a.PathwayID = b.PathwayID
WHERE (a.CodedAssToolType = '748161000000109' AND a.ROWID = 1) AND (B.CodedAssToolType = '748161000000109' AND b.ROWID1 = 1 AND b.ROWID > 1)
AND b.AssToolCompDate BETWEEN @PeriodStart2 AND @PeriodStart
--Both table a and b are filtered for the coded assessment tool type of question 7 from the Institute for Medical Technology Assessment Productivity Cost Questionnaire.
--Table a is filtered to just have pathwayIDs where RowID is 1 i.e. the first appoinment to get a.PerScore as FirstPerScore.
--The same table is then inner joined as b. This is to then filter it on different conditions (RowID1 is 1 i.e. latest appointment and RowID is more than 1, meaning they have had more than 1 appointment).
--This means b.PerScore is LastPersScore

--Question 7 First Score	
--This table counts the distinct pathway IDs that have the same first response score to question 7, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]) 
--This table is re-run each month as the full time period needs to be used for the rankings to work correctly
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'FirstPersScore' as ScoreType
	,FirstPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]
GROUP BY FirstPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

--Question 7 Last Score
--This table counts the distinct pathway IDs that have the same last response score to question 7, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]) 
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'LastPersScore' as ScoreType
	,LastPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]
GROUP BY LastPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

------------------------------------------------------------------------------------------
--Question 8: How many days at work were you bothered by physical or psychological problems?
--Question 8 Base Table
--This table creates separate columns for the assessment score and assessment completion date for the first and last responses for question 8.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]
SELECT 
	a.PathwayID
	,a.ProviderName AS [Provider Name]
	,a.ProviderCode AS [Provider Code]
	,a.RegionNameProv AS [Region Name]
	,a.CodedAssToolType
	,a.PersScore AS FirstPersScore
	,b.PersScore AS LastPersScore
	,b.AuditID
	,DATENAME(m, b.AssToolCompDate) + ' ' + CAST(DATEPART(yyyy, b.AssToolCompDate) AS varchar) as Month
	,a.AssToolCompDate AS FirstDate
	,b.AssToolCompDate AS LastDate
	,a.ROWID
	,b.ROWID1
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] a 
	INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] b ON a.PathwayID = b.PathwayID
WHERE (a.CodedAssToolType = '760741000000102' AND a.ROWID = 1) AND (B.CodedAssToolType = '760741000000102' AND b.ROWID1 = 1 AND b.ROWID > 1)
	AND b.AssToolCompDate BETWEEN @PeriodStart2 AND @PeriodStart	
--Both table a and b are filtered for the coded assessment tool type of question 8 from the Institute for Medical Technology Assessment Productivity Cost Questionnaire.
--Table a is filtered to just have pathwayIDs where RowID is 1 i.e. the first appoinment to get a.PerScore as FirstPerScore.
--The same table is then inner joined as b. This is to then filter it on different conditions (RowID1 is 1 i.e. latest appointment and RowID is more than 1, meaning they have had more than 1 appointment).
--This means b.PerScore is LastPersScore

--Question 8 First Score
--This table counts the distinct pathway IDs that have the same first response score to question 8, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]) 
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'FirstPersScore' as ScoreType
	,FirstPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]
GROUP BY FirstPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

--Question 8 Last Score
--This table counts the distinct pathway IDs that have the same last response score to question 8, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]) 
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'LastPersScore' as ScoreType
	,LastPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]
GROUP BY LastPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Question 9: On the days that you were bothered by these problems, was it perhaps difficult to get as much work finished as you normally do? On these days how much work could you on average?
--Question 9 Base Table
--This table creates separate columns for the assessment score and assessment completion date for the first and last responses for question 9.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]
SELECT 
	a.PathwayID
	,a.[ProviderName] AS [Provider Name]
	,a.ProviderCode AS [Provider Code]
	,a.[RegionNameProv] AS [Region Name]
	,a.CodedAssToolType
	,a.PersScore AS FirstPersScore
	,b.PersScore AS LastPersScore
	,b.AuditID
	,DATENAME(m, b.AssToolCompDate) + ' ' + CAST(DATEPART(yyyy, b.AssToolCompDate) AS varchar) as Month
	,a.AssToolCompDate AS FirstDate
	,b.AssToolCompDate AS LastDate
	,a.ROWID,b.ROWID1
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] a 
	INNER JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral] b ON a.PathwayID = b.PathwayID
WHERE (a.CodedAssToolType = '761051000000105' AND a.ROWID = 1) AND (B.CodedAssToolType = '761051000000105' AND b.ROWID1 = 1 AND b.ROWID > 1)
	AND b.AssToolCompDate BETWEEN @PeriodStart2 AND @PeriodStart
--Both table a and b are filtered for the coded assessment tool type of question 9 from the Institute for Medical Technology Assessment Productivity Cost Questionnaire.
--Table a is filtered to just have pathwayIDs where RowID is 1 i.e. the first appoinment to get a.PerScore as FirstPerScore.
--The same table is then inner joined as b. This is to then filter it on different conditions (RowID1 is 1 i.e. latest appointment and RowID is more than 1, meaning they have had more than 1 appointment).
--This means b.PerScore is LastPersScore

--Question 9 First Score
--This table counts the distinct pathway IDs that have the same first response score to question 9, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]) 
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'FirstPersScore' as ScoreType
	,FirstPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]
GROUP BY FirstPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

--Question 9 Last Score
--This table counts the distinct pathway IDs that have the same last response score to question 9, using the record level base table above ([MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]) 
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCounts]
SELECT 
	CodedAssToolType
	,'LastPersScore' as ScoreType
	,LastPersScore as Score
	,COUNT(DISTINCT PathwayID) AS Count_Referrals
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]
GROUP BY LastPersScore
	,CodedAssToolType
	,Month
	,[Provider Name]
	,[Provider Code]
	,[Region Name]

GO

-----------------------------------------------------------------------------
--Presenteeism Coverage: In the latest month how many referrals have 0 presenteeism assessments, just 1 assessment or 2+ assessments

--This table counts the number of presenteeism assessments per PathwayID
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage]
SELECT 
	PathwayID
	,COUNT(AssToolCompDate) AS NumberOfPresenteeismAssessments
	,CodedAssToolType
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral]
GROUP BY PathwayID,CodedAssToolType
GO

-----------
--This produces a base table with one row per referral with the number of presenteeism assessments
--Period start and period end are defined for the next part of the query:
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be 0 to get the latest month
SET @PeriodStart = (SELECT DATEADD(MONTH,0,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,0,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

DECLARE @PeriodStart2 DATE
SET @PeriodStart2='2020-09-01' --this should always be September 2020

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2]
SELECT DISTINCT
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS DATE) as Month
	,r.PathwayID
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
	,CASE WHEN ph.[Region_Name] IS NOT NULL THEN ph.[Region_Name] ELSE 'Other' END AS 'RegionNameProv'
	,CASE WHEN (p.NumberOfPresenteeismAssessments=0 OR p.NumberOfPresenteeismAssessments IS NULL) THEN 'No Presenteeism Assessments'
		WHEN p.NumberOfPresenteeismAssessments=1 THEN 'One Presenteeism Assessment'
		WHEN p.NumberOfPresenteeismAssessments>=2 THEN 'Two Or More Presenteeism Assessments'
		ELSE NULL END
	AS PresenteeismCoverage
	,CodedAssToolType
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2]
FROM [mesh_IAPT].[IDS101referral] r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId

LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage] p ON r.PathwayID=p.PathwayID
LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
	AND ph.Effective_To IS NULL

WHERE ((r.ServDischDate IS NULL AND r.ReferralRequestReceivedDate<=l.ReportingPeriodEndDate) --open referrals
	OR (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate)) --discharges
	AND UsePathway_Flag = 'True' 
	AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodStart
	AND IsLatest = 1	
GO

--This table aggregates [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2] to count the number of PathwayIDs in each 
--ProviderName, DWPProviders and PresenteeismCoverage grouping
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCoverage]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCoverage]
SELECT
	Month
	,ProviderName
	,ProviderCode
	,RegionNameProv
	,PresenteeismCoverage
	,CodedAssToolType
	,COUNT(PathwayID) AS NumberOfReferrals
INTO [MHDInternal].[DASHBOARD_TTAD_EmpSupp_PresenteeismCoverage]
FROM [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2]
GROUP BY 
	Month
	,ProviderName
	,ProviderCode
	,RegionNameProv
	,PresenteeismCoverage
	,CodedAssToolType

--Drop temporary tables created to produce the final output tables
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_CodedAssessReferral]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ7]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ8]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismQ9]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_PresenteeismCoverage2]
