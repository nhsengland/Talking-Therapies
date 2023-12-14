-- DELETE MAX(Month) -----------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes])

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes])

GO

-----------------------------------
--Preferred Language Top 20 List
-----------------------------------
DECLARE @Offset INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

-- Base Table -------------------------------------------------------------------------------------------------------------
--This produces a table with one PathwayID per month per row
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Base]

SELECT DISTINCT	
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,r.PathwayID
	,lcp.LanguageName AS 'PreferredLang'
	,CASE WHEN r.ReferralRequestReceivedDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN 1 ELSE 0 END
	AS Referrals
	,CASE WHEN r.TherapySession_FirstDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN 1 ELSE 0 END
	AS Access
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.TreatmentCareContact_Count > 2 AND r.Recovery_Flag='True' THEN 1 ELSE 0 END 
	AS Recovery
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.TreatmentCareContact_Count > 2 AND r.NotCaseness_Flag='True'THEN 1 ELSE 0 END 
	AS NotCaseness
	,CASE WHEN r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.CompletedTreatment_Flag='True' AND r.TreatmentCareContact_Count > 2 THEN 1 ELSE 0 END 
	AS FinishedTreatment
	
INTO	[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Base]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		-------------------------------------------
		AND l.ReportingPeriodStartDate BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart --For monthly refresh the offset should be set to -1

--Aggregate and Rank
--Aggregates the number of referrals, accessing, finishing treatment, recovering and not caseness nationally
--Then the preferred languages are ranked base on the number of referrals
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AggregateAndRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AggregateAndRank]
SELECT
	*
	,ROW_NUMBER() OVER(PARTITION BY Month ORDER BY Count_Referrals desc) as Rank --Ranks based on Referrals so that only the top 20 preferred languages are shown in the dashboard
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AggregateAndRank]
FROM(
	SELECT
		Month
		,PreferredLang
		,SUM(Referrals) AS Count_Referrals
		,SUM(Access) AS Count_Accessed
		,SUM(FinishedTreatment) AS Count_Finished
		,SUM([Recovery]) AS Count_Recovery
		,SUM(NotCaseness) AS Count_NotCaseness	
	FROM[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Base]
	WHERE PreferredLang IS NOT NULL
	GROUP BY 
		Month
		,PreferredLang
)_

-- Insert data -------------------------------------------------------------------------------------------------------------------
--This is the final table used in the dashboard
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]
SELECT
	Month
	,PreferredLang
	,Count_Referrals
	,Count_Accessed
	,Count_Finished
	,Count_Recovery
	,Count_NotCaseness
--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]
FROM[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_AggregateAndRank]
WHERE Rank<=20 --Only the top 20 preferred languages are shown in the dashboard

--Drop Temporary Table
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_Base]
----------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Top20]'
GO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------
--Average Waits
--------------------------------------

-- Create base table of care contacts (Preferred language not = English) -----------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng]

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,r.ReferralRequestReceivedDate
		,a.CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,l.ReportingPeriodStartDate
		,l.ReportingPeriodEndDate
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode
		

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		-------------------------------------------
		AND a.AttendOrDNACode IN ('5','05','6','06')
		AND a.AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND mpi.LanguageCodePreferred <> 'en'

-- Create base table of care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,r.ReferralRequestReceivedDate
		,a.CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,l.ReportingPeriodStartDate
		,l.ReportingPeriodEndDate
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		-------------------------------------------
		AND a.AttendOrDNACode IN ('5','05','6','06')
		AND a.AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND mpi.LanguageCodePreferred = 'en'

-- Create table of 1st care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_NotEng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_NotEng]

SELECT * 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_NotEng]
FROM (
	SELECT 
		PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts'
		,ReportingPeriodStartDate
		,ReportingPeriodEndDate
	FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng] 
)_
WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_NotEng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_NotEng]

SELECT * 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_NotEng]
FROM (
	SELECT 
		PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts'
		,ReportingPeriodStartDate
		,ReportingPeriodEndDate
	FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng]
)_
WHERE countAppts = 2

-- Create table of 1st care contacts (Preferred language = English) -----------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_Eng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_Eng]

SELECT * 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_Eng]
FROM (
	SELECT
		PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts'
		,ReportingPeriodStartDate
		,ReportingPeriodEndDate
	FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]
)_
WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_Eng]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_Eng]

SELECT * 
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_Eng]
FROM (
	SELECT
		PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts'
		,ReportingPeriodStartDate
		,ReportingPeriodEndDate
	FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]
)_
WHERE countAppts = 2

-- Calculate Averages------------------------------------------------------------
DECLARE @Offset INT = 0 --For monthly refresh this should be set to 0.

DECLARE @OffsetFilter INT = -1 --This is the Offset used in the filtering of each average calculation table so that more than one month can be run at once. 
--For monthly refresh this should be set to -1.

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--First Treatment English
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstEngAvg]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstEngAvg]

SELECT
	CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,'National' AS 'Level'
	,ROUND(AVG(CAST(WaitToFirstTreatment AS FLOAT)),0) AS AVG_WaitToFirst_Eng
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstEngAvg]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_Eng]
WHERE CareContDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate
AND ReportingPeriodStartDate BETWEEN DATEADD(MONTH, @OffsetFilter, @PeriodStart) AND @PeriodStart
GROUP BY CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE)

-----First Treatment Not English
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstNotEngAvg]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstNotEngAvg]
SELECT
	CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,'National' AS 'Level'
	,ROUND(AVG(CAST(WaitToFirstTreatment AS FLOAT)),0) AS AVG_WaitToFirst_NotEng
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstNotEngAvg]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_NotEng]
WHERE CareContDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate
AND ReportingPeriodStartDate BETWEEN DATEADD(MONTH, @OffsetFilter, @PeriodStart) AND @PeriodStart
GROUP BY CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE)

-----Second Treatment English
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondEngAvg]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondEngAvg]
SELECT
	CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,'National' AS 'Level'
	,ROUND(AVG(CAST(WaitToSecondTreatment AS FLOAT)),0) AS AVG_WaitToSecond_Eng
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondEngAvg]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_Eng]
WHERE CareContDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate
AND ReportingPeriodStartDate BETWEEN DATEADD(MONTH, @OffsetFilter, @PeriodStart) AND @PeriodStart
GROUP BY CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE)

-----Second Treatment Not English
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondNotEngAvg]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondNotEngAvg]
SELECT
	CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,'National' AS 'Level'
	,ROUND(AVG(CAST(WaitToSecondTreatment AS FLOAT)),0) AS AVG_WaitToSecond_NotEng
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondNotEngAvg]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_NotEng]
WHERE CareContDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate
AND ReportingPeriodStartDate BETWEEN DATEADD(MONTH, @OffsetFilter, @PeriodStart) AND @PeriodStart
GROUP BY CAST(DATENAME(m, ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, ReportingPeriodStartDate) AS VARCHAR) AS DATE)

--Insert Data------------------------------------------------------------------
--This is the final table used in the dashboard
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]
SELECT
	fe.Month
	,fe.Level
	,fn.AVG_WaitToFirst_NotEng
	,(sn.AVG_WaitToSecond_NotEng-fn.AVG_WaitToFirst_NotEng) AS 'AVG_WaitToSecond_NotEng'
	,fe.AVG_WaitToFirst_Eng
	,(se.AVG_WaitToSecond_Eng-fe.AVG_WaitToFirst_Eng) AS 'AVG_WaitToSecond_Eng'
--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstEngAvg] fe
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstNotEngAvg] fn ON fn.Month = fe.Month AND fn.Level = fe.Level
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondEngAvg] se ON se.Month = fe.Month AND se.Level = fe.Level
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondNotEngAvg] sn ON sn.Month = fe.Month AND sn.Level = fe.Level

--Drop Temporary Tables----------------------------------------------
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_NotEng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_CareContacts_Eng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_NotEng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_NotEng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstCareContacts_Eng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondCareContacts_Eng]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstEngAvg]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_FirstNotEngAvg]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondEngAvg]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_SecondNotEngAvg]
------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_AvgWaits]'
GO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------
--Interpreter Present
---------------------------------
DECLARE @Offset INT = 0 --For monthly refresh this should be set to 0.

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

-- Create base table of care contacts (Preferred language not = Treatment language) -----------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_InterpreterPresent]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_InterpreterPresent]

SELECT DISTINCT

		CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
		,r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,cc.InterpreterPresentInd
		,CASE WHEN cc.InterpreterPresentInd='1' THEN 'Yes - Professional interpreter'
			WHEN cc.InterpreterPresentInd='2' THEN 'Yes - Family member or friend'
			WHEN cc.InterpreterPresentInd='3' THEN 'Yes - Another Person'
			WHEN cc.InterpreterPresentInd='4' THEN 'No - Interpreter not required'
			WHEN cc.InterpreterPresentInd='5' THEN 'No - Interpreter was required but did not attend'
			WHEN cc.InterpreterPresentInd='X' THEN 'Not Known (Not Recorded)'
			ELSE NULL END
		AS InterpreterPresentDesc

INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_InterpreterPresent]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		-------------------------------------------
		AND l.ReportingPeriodStartDate BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart --For monthly refresh the offset should be set to -1.
		AND cc.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
		AND cc.AttendOrDNACode IN ('5','05','6','06')
		AND cc.AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')
		AND mpi.LanguageCodePreferred <> cc.LanguageCodeTreat

-- Insert data -------------------------------------------------------------------------------------------------------------
--This is the final table used in the dashboard
--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]') IS NOT NULLDROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]
SELECT
	MONTH
	,'National' AS Level
	,InterpreterPresentDesc AS Variable
	,COUNT(Unique_CareContactID) AS Count
--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_InterpreterPresent]
WHERE InterpreterPresentInd IN ('1','2','3','4','5')
GROUP BY
	Month
	,InterpreterPresentDesc

--Drop Temporary Table
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_InterpreterPresent]	
------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_InterpreterPresent]'
GO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------
--Discharge Codes
------------------------------
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodes_CareContacts]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodes_CareContacts]
SELECT
	*
	,ROW_NUMBER() OVER(PARTITION BY PathwayID ORDER BY NumberOfContacts DESC, LanguagePrefOrNotPref ASC) AS Rank
	--This ranking allows us to define whether a PathwayID has the majority of their care contacts with their preferred language or without. 
	--The LanguagePrefOrNotPref category with the highest number of care contacts is ranked as 1
	--If the number of contacts in the preferred language and number of contacts not in the preferred language is equal, then 'Not Preferred Language' is ranked as 1
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodes_CareContacts]
FROM(
	SELECT
		PathwayID
		,LanguagePrefOrNotPref
		,COUNT(Unique_CareContactID) AS NumberOfContacts

	FROM(
		SELECT DISTINCT
			cc.PathwayID
			,cc.Unique_CareContactID
			,cc.CareContDate
			,lcp.LanguageName AS 'PreferredLang'
			,lct.LanguageName AS 'TreatmentLang'
			,CASE WHEN lcp.LanguageName <> lct.LanguageName THEN 'Not Preferred Language'
				WHEN lcp.LanguageName=lct.LanguageName THEN 'Preferred Language'
				ELSE NULL END
			AS LanguagePrefOrNotPref
		FROM [mesh_IAPT].[IDS201carecontact] cc
			INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON cc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND cc.[AuditId] = l.[AuditId]
			INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON cc.[RecordNumber] = mpi.[RecordNumber]
			LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
			LEFT JOIN [MHDInternal].[REFERENCE_ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

		WHERE	l.IsLatest = 1
				AND cc.AttendOrDNACode IN ('5','05','6','06')
				AND cc.AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')
                AND lcp.LanguageCode IS NOT NULL
                AND lct.LanguageCode IS NOT NULL
	)_
	GROUP BY
		PathwayID
		,LanguagePrefOrNotPref
)_

---Discharge Codes Base Table
--This table has one PathwayID per row and only looks at PathwayIDs finishing a course of treatment in the period 
--and who have at least one care contact with a valid treatment language 
--and who have a valid preferred language
DECLARE @Offset INT = 0 --For monthly refresh this should be set to 0.

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodesBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodesBase]

SELECT DISTINCT
		CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
		,r.PathwayID
		,c.LanguagePrefOrNotPref
		,r.EndCode
		,CASE
			-- Referred but not seen
			WHEN r.EndCode = '50' THEN 'Not assessed'
			-- Seen but not taken on for a course of treatment
			WHEN r.EndCode = '10' THEN 'Not suitable for IAPT service - no action taken or directed back to referrer'
			WHEN r.EndCode = '11' THEN 'Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient'
			WHEN r.EndCode = '12' THEN 'Discharged by mutual agreement following advice and support'
			WHEN r.EndCode = '13' THEN 'Referred to another therapy service by mutual agreement'
			WHEN r.EndCode = '14' THEN 'Suitable for IAPT service, but patient declined treatment that was offered'
			WHEN r.EndCode = '16' THEN 'Incomplete Assessment (Patient dropped out)'
			WHEN r.EndCode = '17' THEN 'Deceased (Seen but not taken on for a course of treatment)'
			WHEN r.EndCode = '95' THEN 'Not Known (Seen but not taken on for a course of treatment)'
			-- Seen and taken on for a course of treatment
			WHEN r.EndCode = '46' THEN 'Mutually agreed completion of treatment'
			WHEN r.EndCode = '47' THEN 'Termination of treatment earlier than Care Professional planned'
			WHEN r.EndCode = '48' THEN 'Termination of treatment earlier than patient requested'
			WHEN r.EndCode = '49' THEN 'Deceased (Seen and taken on for a course of treatment)'
			WHEN r.EndCode = '96' THEN 'Not Known (Seen and taken on for a course of treatment)'
			-- v1.5 (Not used)
			WHEN r.EndCode IN ('40','42','43','44') THEN 'Other'
			ELSE NULL
		END AS 'Definition'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodesBase]

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		INNER JOIN [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodes_CareContacts] c ON c.PathwayID = r.PathwayID AND Rank=1 
		--Inner join so the table only has PathwayIDs completing tretament in the reporting period AND with a valid Language Preference AND Treatment Language 

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
		-------------------------------------------
		AND l.ReportingPeriodStartDate BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart --For monthly refresh, this offset should be set to -1.
		AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate
		AND r.CompletedTreatment_Flag = 'TRUE'
		AND r.EndCode IN ('10','11','12','13','14','16','17','46','47','48','49','50','96','40','42','43','44') 

---Insert Data
--This is the final table used in the dashboard
--IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes]
SELECT
	Month
	,'National' AS Level
	,LanguagePrefOrNotPref AS Variable
	,EndCode
	,Definition
	,COUNT(PathwayID) AS NumberFinishingACourseOfTreatment
--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_DischargeCodes]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodesBase]
GROUP BY
	Month
	,LanguagePrefOrNotPref
	,EndCode
	,Definition

--Drop Temporary tables
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodes_CareContacts]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_DischCodesBase]
---------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_DischargeCodes]'
GO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------
--Outcomes
------------------------

--Outcomes Base
--This table has one PathwayID per row
DECLARE @Offset INT = 0 --For monthly refresh this should be set to 0.

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
--------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_OutcomesBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_OutcomesBase]
SELECT	
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
	,r.PathwayID
	,CASE WHEN cc.LanguageCodeTreat <> mpi.LanguageCodePreferred THEN 'Non-Preferred Language'
		WHEN cc.LanguageCodeTreat = mpi.LanguageCodePreferred AND cc.InterpreterPresentInd = '4' THEN 'Interpreter not required'
		WHEN cc.LanguageCodeTreat = mpi.LanguageCodePreferred AND cc.InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
		WHEN cc.LanguageCodeTreat = mpi.LanguageCodePreferred AND cc.InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
		WHEN cc.LanguageCodeTreat = mpi.LanguageCodePreferred AND cc.InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
		ELSE 'Other' END
	AS 'Language_Treated'
	--------------------------
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS Recovery
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.ReliableImprovement_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS ReliableImprovement
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.Recovery_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS ReliableRecovery
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.NotCaseness_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS NotCaseness
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS FinishedTreatment
		--------------------------
INTO [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_OutcomesBase]
FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]

WHERE	l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart --For monthly refresh the offset should be set to -1.
		AND r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]
		AND l.IsLatest = '1' 
		AND r.UsePathway_Flag = 'True'
		AND r.CompletedTreatment_Flag = 'TRUE'
		AND mpi.LanguageCodePreferred <> 'en'

--Insert data
--This is the final table used in the dashboard

--IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]
SELECT
	Month
	,'National' AS 'Level'
	,Language_Treated
	
	,SUM([Recovery]) AS Count_Recovery
	,SUM(ReliableImprovement) AS Count_Improvement
	,SUM(ReliableRecovery) AS Count_Reliable_Recovery

	,CASE WHEN SUM(FinishedTreatment)-SUM(NotCaseness) = 0 THEN NULL
		WHEN SUM(Recovery) = 0 THEN NULL 
		ELSE (CAST(SUM(Recovery) AS FLOAT)/(CAST(SUM(FinishedTreatment) AS FLOAT)-CAST(SUM(NotCaseness) AS FLOAT))) END
	AS 'Percentage_Recovery'
	--------------------------

	,CASE WHEN SUM(FinishedTreatment) = 0 THEN NULL
		WHEN SUM(ReliableImprovement) = 0 THEN NULL 
		ELSE (CAST(SUM(ReliableImprovement) AS FLOAT)/(CAST(SUM(FinishedTreatment) AS FLOAT))) END
	AS 'Percentage_Improvement'
	-----------------------------
	,CASE WHEN SUM(FinishedTreatment) = 0 THEN NULL
		WHEN SUM(ReliableRecovery) = 0 THEN NULL 
		ELSE (CAST(SUM(ReliableRecovery) AS FLOAT)/(CAST(SUM(FinishedTreatment) AS FLOAT))) END
	AS 'Percentage_Reliable_Recovery'
--INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_PrefLang_OutcomesBase]
GROUP BY
	Month
	,Language_Treated

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_PrefLang_Outcomes]'
GO
