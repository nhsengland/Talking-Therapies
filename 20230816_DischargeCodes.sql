SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Offset INT = -1
--------------------------
-- DECLARE @Max_Offset INT = -1
---------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
---------------------------------------|

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Discharge Codes ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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