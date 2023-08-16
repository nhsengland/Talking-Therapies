SET ANSI_WARNINGS OFF
SET NOCOUNT ON
SET DATEFIRST 1

--------------------------
DECLARE @Offset INT = -1
--------------------------
DECLARE @Max_Offset INT = -1
---------------------------------------|
WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Top 20 languages ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Referrals --------------------------------------------------------
IF OBJECT_ID ('tempdb..#Referrals') IS NOT NULL DROP TABLE #Referrals

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	#Referrals

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd

-- Accessed treatment ---------------------------------------------------------------
IF OBJECT_ID ('tempdb..#AccessedTreatment') IS NOT NULL DROP TABLE #AccessedTreatment

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,r.TherapySession_FirstDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'

INTO	#AccessedTreatment

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND CareContDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CareContDate = TherapySession_FirstDate

-- Finished treatment ---------------------------------------------------------------
IF OBJECT_ID ('tempdb..#FinishedTreatment') IS NOT NULL DROP TABLE #FinishedTreatment

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,TreatmentCareContact_Count
		,CompletedTreatment_Flag
		,Recovery_Flag
		,NotCaseness_Flag

INTO	#FinishedTreatment

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		AND CareContact_Count > 2

-- Calculate Counts --------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Referrals_p') IS NOT NULL DROP TABLE #Referrals_p
IF OBJECT_ID ('tempdb..#AccessedTreatment_p') IS NOT NULL DROP TABLE #AccessedTreatment_p
IF OBJECT_ID ('tempdb..#FinishedTreatment_p') IS NOT NULL DROP TABLE #FinishedTreatment_p
IF OBJECT_ID ('tempdb..#Recovery_p') IS NOT NULL DROP TABLE #Recovery_p
IF OBJECT_ID ('tempdb..#NotCaseness_p') IS NOT NULL DROP TABLE #NotCaseness_p

SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Referrals' INTO #Referrals_p FROM #Referrals WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Accessed' INTO #AccessedTreatment_p FROM #AccessedTreatment WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Finished' INTO #FinishedTreatment_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_Recovery' INTO #Recovery_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL AND CompletedTreatment_flag = 'TRUE' AND  Recovery_Flag = 'True' GROUP BY [PreferredLang]
SELECT PreferredLang, COUNT(DISTINCT PathwayID) AS 'Count_NotCaseness' INTO #NotCaseness_p FROM #FinishedTreatment WHERE [PreferredLang] IS NOT NULL AND NotCaseness_Flag = 'TRUE' GROUP BY [PreferredLang]

-- Insert data -------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]

SELECT TOP(20) 

		@MonthYear AS 'Month'
		,rp.PreferredLang
		,Count_Referrals
		,Count_Accessed
		,Count_Finished
		,Count_Recovery
		,Count_NotCaseness

FROM	#Referrals_p rp
		---------------
		INNER JOIN #AccessedTreatment_p atp ON rp.PreferredLang = atp.PreferredLang
		INNER JOIN #FinishedTreatment_p ftp ON rp.PreferredLang = ftp.PreferredLang
		INNER JOIN #Recovery_p rec ON rp.PreferredLang = rec.PreferredLang
		INNER JOIN #NotCaseness_p nc ON rp.PreferredLang = nc.PreferredLang 

GROUP BY rp.PreferredLang, Count_Referrals, Count_Accessed, Count_Finished, Count_Recovery, Count_NotCaseness

ORDER BY Count_Referrals DESC

----------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_Top20]'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Average Waits ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create base table of care contacts (Preferred language not = English) -----------------

IF OBJECT_ID ('tempdb..#CareContacts_NotEng') IS NOT NULL DROP TABLE #CareContacts_NotEng

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,ReferralRequestReceivedDate
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'

INTO #CareContacts_NotEng

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode
		

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND LanguageCodePreferred <> 'en'

-- Create base table of care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#CareContacts_Eng') IS NOT NULL DROP TABLE #CareContacts_Eng

SELECT DISTINCT	

		r.PathwayID
		,a.Unique_CareContactID
		,ReferralRequestReceivedDate
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'

INTO #CareContacts_Eng

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.[PathwayID] = a.[PathwayID] AND a.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') -- treatment based appt
		AND LanguageCodePreferred = 'en'

-- Create table of 1st care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#FirstCareContacts_NotEng') IS NOT NULL DROP TABLE #FirstCareContacts_NotEng

SELECT * INTO #FirstCareContacts_NotEng

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_NotEng )_

WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language not = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#SecondCareContacts_NotEng') IS NOT NULL DROP TABLE #SecondCareContacts_NotEng

SELECT * INTO #SecondCareContacts_NotEng

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_NotEng )_

WHERE countAppts = 2

-- Create table of 1st care contacts (Preferred language = English) -----------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#FirstCareContacts') IS NOT NULL DROP TABLE #FirstCareContacts

SELECT * INTO #FirstCareContacts

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToFirstTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_Eng )_

WHERE countAppts = 1

-- Create table of 2nd care contacts (Preferred language = English) -------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#SecondCareContacts') IS NOT NULL DROP TABLE #SecondCareContacts

SELECT * INTO #SecondCareContacts

FROM (SELECT PathwayID
		,ReferralRequestReceivedDate
		,Unique_CareContactID
		,CareContDate
		,DATEDIFF(D, ReferralRequestReceivedDate, CareContDate) AS 'WaitToSecondTreatment'
		,PreferredLang
		,ROW_NUMBER() OVER(PARTITION BY [PathwayID] ORDER BY [CareContDate] ASC) AS 'countAppts' FROM #CareContacts_Eng )_

WHERE countAppts = 2

-- Averages --------------------------------------------------------------------------------------------------------------------------------

Declare @AVG_WaitToFirst_Eng AS FLOAT = (SELECT(AVG(WaitToFirstTreatment)) AS 'Avg_WaitToFirstTreatment' FROM #FirstCareContacts WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)
Declare @AVG_WaitToFirst_NotEng AS FLOAT = (SELECT(AVG(WaitToFirstTreatment)) AS 'Avg_WaitToFirstTreatment_NotEng' FROM #FirstCareContacts_NotEng WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)

DECLARE @AVG_WaitToSecond_Eng AS FLOAT = (SELECT(AVG(WaitToSecondTreatment)) AS 'Avg_WaitToSecondTreatment' FROM #SecondCareContacts WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)
DECLARE @AVG_WaitToSecond_NotEng AS FLOAT = (SELECT(AVG(WaitToSecondTreatment)) AS 'Avg_WaitToSecondTreatment_NotEng' FROM #SecondCareContacts_NotEng WHERE CareContDate BETWEEN @PeriodStart AND @PeriodEnd)

-- Insert data ---------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_AvgWaits]

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'
		,@AVG_WaitToFirst_NotEng AS 'AVG_WaitToFirst_NotEng'
		,(@AVG_WaitToSecond_NotEng - @AVG_WaitToFirst_NotEng) AS 'AVG_WaitToSecond_NotEng'
		,@AVG_WaitToFirst_Eng AS 'AVG_WaitToFirst_Eng' 
		,(@AVG_WaitToSecond_Eng - @AVG_WaitToFirst_Eng) AS 'AVG_WaitToSecond_Eng'

------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_AvgWaits]'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Interpreter present ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create base table of care contacts (Preferred language not = Treatment language) -----------

IF OBJECT_ID ('tempdb..#InterpreterPresent') IS NOT NULL DROP TABLE #InterpreterPresent

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,CareContDate
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,InterpreterPresentInd

INTO #InterpreterPresent

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND CareContDate BETWEEN @PeriodStart AND @PeriodEnd
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')
		AND LanguageCodePreferred <> LanguageCodeTreat

-- Insert data -------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_InterpreterPresent]

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Professional interpreter' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('1') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Family member or friend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('2') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'Yes - Another Person' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('3') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter not required' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('4') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

UNION ------------------------------------ 

SELECT @MonthYear as 'Month'
		,'National' AS 'Level'
		,'No - Interpreter was required but did not attend' AS 'Variable'
		,COUNT(CASE WHEN InterpreterPresentInd IN ('5') THEN PathwayID ELSE NULL END) AS 'Count'
		
FROM #InterpreterPresent

------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_InterpreterPresent]'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Discharge Codes ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Treatnment language not = preferred ---------------------------------------------------------------
IF OBJECT_ID ('tempdb..#CareContacts_TreatNotPref') IS NOT NULL DROP TABLE #CareContacts_TreatNotPref

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,r.EndCode

INTO #CareContacts_TreatNotPref

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5')
		AND LanguageCodeTreat <> LanguageCodePreferred

-- Treatnment language = preferred ------------------------------------------------------------
IF OBJECT_ID ('tempdb..#CareContacts_PrefTreat') IS NOT NULL DROP TABLE #CareContacts_PrefTreat

SELECT DISTINCT	

		r.PathwayID
		,cc.Unique_CareContactID
		,lcp.LanguageName AS 'PreferredLang'
		,lct.LanguageName AS 'TreatmentLang'
		,r.EndCode

INTO #CareContacts_PrefTreat

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	UsePathway_Flag = 'TRUE' AND IsLatest = 1
		-------------------------------------------
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND CompletedTreatment_Flag = 'TRUE'
		-------------------------------------------
		AND AttendOrDNACode IN ('5','05','6','06')
		AND AppType IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') 
		AND LanguageCodeTreat = LanguageCodePreferred

-- Create table of end codes for each PathwayID (no duplicates) ----------------------------------

IF OBJECT_ID ('tempdb..#EndCodes_TreatNotPref') IS NOT NULL DROP TABLE #EndCodes_TreatNotPref
IF OBJECT_ID ('tempdb..#EndCodes_PrefTreat') IS NOT NULL DROP TABLE #EndCodes_PrefTreat

SELECT DISTINCT	PathwayID, EndCode INTO #EndCodes_TreatNotPref FROM #CareContacts_TreatNotPref WHERE EndCode IS NOT NULL
SELECT DISTINCT	PathwayID, EndCode INTO #EndCodes_PrefTreat FROM #CareContacts_PrefTreat WHERE EndCode IS NOT NULL

-- Return all EndCodes from within the period (including percentage of all codes)  ------------------

DECLARE @Total_EndCodes_TreatNotPref AS FLOAT = (SELECT COUNT(EndCode) FROM #EndCodes_TreatNotPref)
DECLARE @Total_EndCodes_PrefTreat AS FLOAT = (SELECT COUNT(EndCode) FROM #EndCodes_PrefTreat)

-- Insert data -----------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_DischargeCodes]

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'
		,'Treatment language not preferred' AS 'Variable'
		,EndCode
		,CASE
			-- Referred but not seen
			WHEN Endcode = '50' THEN 'Not assessed'
			-- Seen but not taken on for a course of treatment
			WHEN Endcode = '10' THEN 'Not suitable for IAPT service - no action taken or directed back to referrer'
			WHEN Endcode = '11' THEN 'Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient'
			WHEN Endcode = '12' THEN 'Discharged by mutual agreement following advice and support'
			WHEN Endcode = '13' THEN 'Referred to another therapy service by mutual agreement'
			WHEN Endcode = '14' THEN 'Suitable for IAPT service, but patient declined treatment that was offered'
			WHEN Endcode = '16' THEN 'Incomplete Assessment (Patient dropped out)'
			WHEN Endcode = '17' THEN 'Deceased (Seen but not taken on for a course of treatment)'
			WHEN Endcode = '95' THEN 'Not Known (Seen but not taken on for a course of treatment)'
			-- Seen and taken on for a course of treatment
			WHEN Endcode = '46' THEN 'Mutually agreed completion of treatment'
			WHEN Endcode = '47' THEN 'Termination of treatment earlier than Care Professional planned'
			WHEN Endcode = '48' THEN 'Termination of treatment earlier than patient requested'
			WHEN Endcode = '49' THEN 'Deceased (Seen and taken on for a course of treatment)'
			WHEN Endcode = '96' THEN 'Not Known (Seen and taken on for a course of treatment)'
			-- v1.5 (Not used)
			WHEN Endcode IN ('40','42','43','44') THEN 'Other'
			ELSE NULL
		END AS 'Definition'
		,(COUNT(EndCode)/@Total_EndCodes_TreatNotPref) AS 'Percentage'
		
FROM #EndCodes_TreatNotPref WHERE EndCode IN ('10','11','12','13','14','16','17','46','47','48','49','50','96','40','42','43','44') GROUP BY [EndCode]

UNION

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'
		,'Treatment language = preferred' AS 'Variable'
		,EndCode
		,CASE
			-- Referred but not seen
			WHEN Endcode = '50' THEN 'Not assessed'
			-- Seen but not taken on for a course of treatment
			WHEN Endcode = '10' THEN 'Not suitable for IAPT service - no action taken or directed back to referrer'
			WHEN Endcode = '11' THEN 'Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient'
			WHEN Endcode = '12' THEN 'Discharged by mutual agreement following advice and support'
			WHEN Endcode = '13' THEN 'Referred to another therapy service by mutual agreement'
			WHEN Endcode = '14' THEN 'Suitable for IAPT service, but patient declined treatment that was offered'
			WHEN Endcode = '16' THEN 'Incomplete Assessment (Patient dropped out)'
			WHEN Endcode = '17' THEN 'Deceased (Seen but not taken on for a course of treatment)'
			WHEN Endcode = '95' THEN 'Not Known (Seen but not taken on for a course of treatment)'
			-- Seen and taken on for a course of treatment
			WHEN Endcode = '46' THEN 'Mutually agreed completion of treatment'
			WHEN Endcode = '47' THEN 'Termination of treatment earlier than Care Professional planned'
			WHEN Endcode = '48' THEN 'Termination of treatment earlier than patient requested'
			WHEN Endcode = '49' THEN 'Deceased (Seen and taken on for a course of treatment)'
			WHEN Endcode = '96' THEN 'Not Known (Seen and taken on for a course of treatment)'
			-- v1.5 (Not used)
			WHEN Endcode IN ('40','42','43','44') THEN 'Other'
			ELSE NULL
		END AS 'Definition'
		,(COUNT(EndCode)/@Total_EndCodes_PrefTreat) AS 'Percentage'
		
FROM #EndCodes_PrefTreat WHERE EndCode IN ('10','11','12','13','14','16','17','46','47','48','49','50','96','40','42','43','44') GROUP BY [EndCode]

---------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_DischargeCodes]'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Outcome measures ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PrefLang_Outcomes]

SELECT	@MonthYear AS 'Month'
		,'National' AS 'Level'

		,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
			WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
		ELSE 'Other' END AS 'Language_Treated'
 
		--------------------------
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Recovery'
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Improvement'
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Reliable_Recovery'
		--------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END)
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'   AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float)
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END
		AS 'Percentage_Recovery'
		--------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float))) END
		AS 'Percentage_Improvement'
		-----------------------------

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) = 0 THEN NULL
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 
		
		ELSE 

		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND r.ServDischDate BETWEEN ReportingPeriodStartDate AND ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS float))) END
		AS 'Percentage_Reliable_Recovery'
		-----------------------------------

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.[PathwayID] = cc.[PathwayID] AND cc.[AuditId] = l.[AuditId]
		----------------------------------------
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lct ON cc.LanguageCodeTreat = lct.LanguageCode
		LEFT JOIN [MHDInternal].[ISO_LanguageCodes] lcp ON mpi.LanguageCodePreferred = lcp.LanguageCode

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodendDate]
		AND l.IsLatest = '1' AND UsePathway_Flag = 'True'
		AND CompletedTreatment_Flag = 'TRUE'
		AND LanguageCodePreferred <> 'en'

GROUP BY	DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR)
			,CASE WHEN LanguageCodeTreat <> LanguageCodePreferred THEN 'Non-Preferred Language'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '4' THEN 'Interpreter not required'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '3' THEN 'Interpreter - Another Person'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '2' THEN 'Interpreter - Family member or friend'
				WHEN LanguageCodeTreat = LanguageCodePreferred AND InterpreterPresentInd = '1' THEN 'Interpreter - Professional Interpreter'
				ELSE 'Other' END

------------------------------|
SET @Offset = @Offset-1 END --| <-- End loop
------------------------------|

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PrefLang_Outcomes]' + CHAR(10)