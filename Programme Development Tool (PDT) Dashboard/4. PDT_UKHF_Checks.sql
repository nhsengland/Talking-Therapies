 /* UKHF Data checks for IAPT v2 data (Sept 2020 onwards)
 
 Highlights any discrepancies between refresh data and the UKHF table (0 denotes a mismatch)
 
 The script will return 4 tables with discrepancies in the following order:

 - Test 2 
 - New Indicators 
 - Averages 
 - Consultation Mediums 

 */

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Due to the collation conflict between the databases, the temporary table is a work around
IF OBJECT_ID ('tempdb..#UKHF') IS NOT NULL DROP TABLE #UKHF

SELECT Group_Type
		,Provider_code
		,Commissioner_Code
		,Measure_ID
		,Measure_Value

INTO #UKHF

FROM [NHSE_UKHF].[IAPT].[vw_Activity_Data1]

WHERE Effective_Snapshot_Date = @PeriodEnd AND Commissioner_Code IS NOT NULL

-- Alter collation conflict
ALTER TABLE #UKHF ALTER COLUMN [Group_Type] VARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL
ALTER TABLE #UKHF ALTER COLUMN [Commissioner_Code] VARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL
ALTER TABLE #UKHF ALTER COLUMN [Provider_Code] VARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL

-- Pivot the date
IF OBJECT_ID ('tempdb..#UKHFPivot') IS NOT NULL DROP TABLE #UKHFPivot

SELECT * INTO #UKHFPIVOT

FROM #UKHF

PIVOT(

SUM(Measure_Value) FOR Measure_ID IN ([M001],[M031],[M076],[M019],[M020],[M021],[M029],[M030],[M024],[M025],[M026],[M027],[M032],[M033],[M034],[M035],[M056],[M057],[M058],[M059],[M060],[M061],[M071],
[M072],[M074],[M075],[M073],[M191],[M193],[M187],[M189],[M185],[M179],[M203],[M204],[M002],[M003],[M047],[M342],[M340],[M062],[M063],[M066],[M344],[M341],[M069],[M070],[M153],[M036],[M037],[M038],
[M082],[M084],[M039],[M040],[M041],[M042],[M052],[M054],[M046],[M192],[M186],[M1010],[M180],[M053],[M055],[M205],[M043],[M142],[M048],[M049],[M141],[M050],[M083],[M085],[M086],[M087],[M088])

) AS pivot_table 

IF OBJECT_ID ('tempdb..#UKHFPivot') IS NULL PRINT 'No UKHF Data'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Test 2 -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM 

(

SELECT DISTINCT [Month]
		,[Level]
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[Referrals]
	  ,[M001] AS 'Count_ReferralsReceived'
	  ,CASE WHEN  [Referrals] = [M001] OR ([Referrals] IS NULL AND [M001] IS NULL) THEN '1' ELSE '0' END AS 'Referrals Match'
	  ,[EnteringTreatment]
	  ,[M031] AS Count_FirstTreatment
	  ,CASE WHEN  [EnteringTreatment] = [M031] OR ([EnteringTreatment] IS NULL AND [M031] IS NULL) THEN '1' ELSE '0' END AS 'First Treatment Match'
	  ,[Finished Treatment - 2 or more Apps]
	  ,[M076] AS Count_FinishedCourseTreatment
	  ,CASE WHEN  [Finished Treatment - 2 or more Apps] = [M076] OR ([Finished Treatment - 2 or more Apps] IS NULL AND [M076] IS NULL) THEN '1' ELSE '0' END AS 'Finished Treatment Match'
	  ,[OpenReferralLessThan61DaysNoContact]
	  ,[M019] AS Count_OpenReferralNoActivity60days
	  ,CASE WHEN  [OpenReferralLessThan61DaysNoContact] = [M019] OR ([OpenReferralLessThan61DaysNoContact] IS NULL AND [M019] IS NULL) THEN '1' ELSE '0' END AS 'OpenReferralLessThan61DaysNoContact Match'
	  ,[OpenReferral61-90DaysNoContact]
	  ,[M020] AS Count_OpenReferralNoActivity61to90days
	  ,CASE WHEN  [OpenReferral61-90DaysNoContact] = [M020] OR ([OpenReferral61-90DaysNoContact] IS NULL AND [M020] IS NULL) THEN '1' ELSE '0' END AS 'OpenReferral61-90DaysNoContact Match'
	  ,[OpenReferral9100DaysNoContact]
	  ,[M021] AS Count_OpenReferralNoActivity91to120days
	  ,CASE WHEN  [OpenReferral9100DaysNoContact] = [M021] OR ([OpenReferral9100DaysNoContact] IS NULL AND [M021] IS NULL) THEN '1' ELSE '0' END AS 'OpenReferral9100DaysNoContact Match'
	  ,[Waiting for Assessment]
	  ,[M029] AS Count_WaitingForAssessment
	  ,CASE WHEN  [Waiting for Assessment] = [M029] OR ([Waiting for Assessment] IS NULL AND [M029] IS NULL) THEN '1' ELSE '0' END AS 'Waiting for Assessment Match'
	  ,[WaitingForAssessmentOver90Days]
	  ,[M030] AS Count_WaitingForAssessmentOver90days
	  ,CASE WHEN  [WaitingForAssessmentOver90Days] = M030 OR ([WaitingForAssessmentOver90Days] IS NULL AND M030 IS NULL) THEN '1' ELSE '0' END AS 'WaitingForAssessmentOver90Days Match'
	  ,[FirstAssessment28Days]
	  ,[M024] AS Count_FirstAssessment28days
	  ,CASE WHEN  [FirstAssessment28Days] = [M024] OR ([FirstAssessment28Days] IS NULL AND [M024] IS NULL) THEN '1' ELSE '0' END AS 'FirstAssessment28Days Match'
	  ,[FirstAssessment29to56Days]
	  ,[M025] AS Count_FirstAssessment29to56days
	  ,CASE WHEN  [FirstAssessment29to56Days] = [M025] OR ([FirstAssessment29to56Days] IS NULL AND [M025] IS NULL) THEN '1' ELSE '0' END AS 'FirstAssessment29to56Days Match'
	  ,[FirstAssessment57to90Days]
	  ,[M026] AS Count_FirstAssessment57to90days
	  ,CASE WHEN  [FirstAssessment57to90Days] = [M026] OR ([FirstAssessment57to90Days] IS NULL AND [M026] IS NULL) THEN '1' ELSE '0' END AS 'FirstAssessment57to90Days Match'
	  ,[FirstAssessmentOver90Days]	 
	  ,[M027] AS Count_FirstAssessmentOver90days
	  ,CASE WHEN  [FirstAssessmentOver90Days] = [M027] OR ([FirstAssessmentOver90Days] IS NULL AND [M027] IS NULL) THEN '1' ELSE '0' END AS 'FirstAssessmentOver90Days Match'
	  ,[FirstTreatment28days]	
	  ,[M032] AS Count_FirstTreatment28days
	  ,CASE WHEN  [FirstTreatment28days] = [M032] OR ([FirstTreatment28days] IS NULL AND [M032] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatment28days Match'
      ,[FirstTreatment29to56days]	
	  ,[M033] AS Count_FirstTreatment29to56days
	  ,CASE WHEN  [FirstTreatment29to56days] = [M033] OR ([FirstTreatment29to56days] IS NULL AND [M033] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatment29to56days Match'
      ,[FirstTreatment57to90days]	
	  ,[M034] AS Count_FirstTreatment57to90days
	  ,CASE WHEN  [FirstTreatment57to90days] = [M034] OR ([FirstTreatment57to90days] IS NULL AND [M034] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatment57to90days Match'
      ,[FirstTreatmentOver90days]	
	  ,[M035] AS Count_FirstTreatmentOver90days
	  ,CASE WHEN  [FirstTreatmentOver90days] = [M035] OR ([FirstTreatmentOver90days] IS NULL AND [M035] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatmentOver90days Match'
	  ,[Ended Referral]	
	  ,[M056] AS Count_EndedReferrals
	  ,CASE WHEN  [Ended Referral] = [M056] OR ([Ended Referral] IS NULL AND [M056] IS NULL) THEN '1' ELSE '0' END AS 'Ended Referral Match'
      ,[Ended Not Suitable]	
	  ,[M057] AS Count_EndedNotSuitable
	  ,CASE WHEN  [Ended Not Suitable] = [M057] OR ([Ended Not Suitable] IS NULL AND [M057] IS NULL) THEN '1' ELSE '0' END AS 'Ended Not Suitable Match'
      ,[Ended Signposted]	
	  ,[M058] AS Count_EndedSignposted
	  ,CASE WHEN  [Ended Signposted] = [M058] OR ([Ended Signposted] IS NULL AND [M058] IS NULL) THEN '1' ELSE '0' END AS 'Ended Signposted Match'
      ,[Ended Mutual Agreement]	
	  ,[M059] AS Count_EndedMutualAgreement
	  ,CASE WHEN  [Ended Mutual Agreement] = [M059] OR ([Ended Mutual Agreement] IS NULL AND [M059] IS NULL) THEN '1' ELSE '0' END AS 'Ended Mutual Agreement Match'
      ,[Ended Referred Elsewhere]	
	  ,[M060] AS Count_EndedReferredElsewhere
	  ,CASE WHEN  [Ended Referred Elsewhere] = [M060] OR ([Ended Referred Elsewhere] IS NULL AND [M060] IS NULL) THEN '1' ELSE '0' END AS 'Ended Referred Elsewhere Match'
      ,[Ended Declined]	
	  ,[M061] AS Count_EndedDeclined
	  ,CASE WHEN  [Ended Declined] = [M061] OR ([Ended Declined] IS NULL AND [M061] IS NULL) THEN '1' ELSE '0' END AS 'Ended Declined Match'
      ,[Ended Invalid]	
	  ,[M071] AS Count_EndedInvalid
	  ,CASE WHEN  [Ended Invalid] = [M071] OR ([Ended Invalid] IS NULL AND [M071] IS NULL) THEN '1' ELSE '0' END AS 'Ended Invalid Match'
      ,[Ended No Reason Recorded]	
	  ,[M072] AS Count_EndedNoReasonRecorded
	  ,CASE WHEN  [Ended No Reason Recorded] = [M072] OR ([Ended No Reason Recorded] IS NULL AND [M072] IS NULL) THEN '1' ELSE '0' END AS 'Ended No Reason Recorded Match'
      ,[Ended Seen Not Treated]	
	  ,[M074] AS Count_EndedSeenNotTreated
	  ,CASE WHEN  [Ended Seen Not Treated] = [M074] OR ([Ended Seen Not Treated] IS NULL AND [M074] IS NULL) THEN '1' ELSE '0' END AS 'Ended Seen Not Treated Match'
      ,[Ended Treated Once]	
	  ,[M075] AS Count_EndedTreatedOnce
	  ,CASE WHEN  [Ended Treated Once] = [M075] OR ([Ended Treated Once] IS NULL AND [M075] IS NULL) THEN '1' ELSE '0' END AS 'Ended Treated Once Match'
      ,[Ended Not Seen]	
	  ,[M073] AS Count_EndedNotSeen
	  ,CASE WHEN  [Ended Not Seen] = [M073] OR ([Ended Not Seen] IS NULL AND [M073] IS NULL) THEN '1' ELSE '0' END AS 'Ended Not Seen Match'
      ,[Recovery]	
	  ,[M191] AS Count_Recovery
	  ,CASE WHEN  [Recovery] = [M191] OR ([Recovery] IS NULL AND [M191] IS NULL) THEN '1' ELSE '0' END AS 'Recovery Match'
      ,[Reliable Recovery]	
	  ,[M193] AS Count_ReliableRecovery
	  ,CASE WHEN  [Reliable Recovery] = [M193] OR ([Reliable Recovery] IS NULL AND [M193] IS NULL) THEN '1' ELSE '0' END AS 'Reliable Recovery Match'
      ,[No Change]	
	  ,[M187] AS Count_NoReliableChange
	  ,CASE WHEN  [No Change] = [M187] OR ([No Change] IS NULL AND [M187] IS NULL) THEN '1' ELSE '0' END AS 'No Change Match'
      ,[Reliable Deterioration]	
	  ,[M189] AS Count_Deterioration
	  ,CASE WHEN  [Reliable Deterioration] = [M189] OR ([Reliable Deterioration] IS NULL AND [M189] IS NULL) THEN '1' ELSE '0' END AS 'Reliable Deterioration Match'
      ,[Reliable Improvement]	
	  ,[M185] AS Count_Improvement
	  ,CASE WHEN  [Reliable Improvement] = [M185] OR ([Reliable Improvement] IS NULL AND [M185] IS NULL) THEN '1' ELSE '0' END AS 'Reliable Improvement Match'
      ,[NotCaseness]	
	  ,[M179] AS Count_NotAtCaseness
	  ,CASE WHEN  [NotCaseness] = [M179] OR ([NotCaseness] IS NULL AND [M179] IS NULL) THEN '1' ELSE '0' END AS 'NotCaseness Match'
      ,[ADSMFinishedTreatment]	
	  ,[M203] AS Count_ADSMFinishedTreatment
	  ,CASE WHEN  [ADSMFinishedTreatment] = [M203] OR ([ADSMFinishedTreatment] IS NULL AND [M203] IS NULL) THEN '1' ELSE '0' END AS 'ADSMFinishedTreatment Match'
      ,[CountAppropriatePairedADSM]	
	  ,[M204] AS Count_AppropriatePairedADSM
	  ,CASE WHEN  [CountAppropriatePairedADSM] = [M204] OR ([CountAppropriatePairedADSM] IS NULL AND [M204] IS NULL) THEN '1' ELSE '0' END AS 'CountAppropriatePairedADSM Match'
      ,[SelfReferral]	
	  ,[M002] AS Count_SelfReferrals
	  ,CASE WHEN  [SelfReferral] = [M002] OR ([SelfReferral] IS NULL AND [M002] IS NULL) THEN '1' ELSE '0' END AS 'SelfReferral Match'
      ,[GPReferral]	
	  ,[M003] AS Count_GPReferrals
	  ,CASE WHEN  [GPReferral] = [M003] OR ([GPReferral] IS NULL AND [M003] IS NULL) THEN '1' ELSE '0' END AS 'GPReferral Match'
	  ,[FirstToSecondMoreThan90Days]	
	  ,[M047] AS Count_FirstToSecondTreatmentOver90days
	  ,CASE WHEN  [FirstToSecondMoreThan90Days] = [M047] OR ([FirstToSecondMoreThan90Days] IS NULL AND [M047] IS NULL) THEN '1' ELSE '0' END AS 'FirstToSecondMoreThan90Days Match'
      ,[Ended Not Assessed]	
	  ,[M342] AS Count_EndedNotAssessed
	  ,CASE WHEN  [Ended Not Assessed] = [M342] OR ([Ended Not Assessed] IS NULL AND [M342] IS NULL) THEN '1' ELSE '0' END AS 'Ended Not Assessed Match'
      ,[Ended Incomplete Assessment]	
	  ,[M340] AS Count_EndedIncompleteAssessment
	  ,CASE WHEN  [Ended Incomplete Assessment] = [M340] OR ([Ended Incomplete Assessment] IS NULL AND [M340] IS NULL) THEN '1' ELSE '0' END AS 'Ended Incomplete Assessment Match'
      ,[Ended Deceased (Seen but not taken on for a course of treatment)]	
	  ,[M062] AS Count_EndedDeceasedAssessedOnly
	  ,CASE WHEN  [Ended Deceased (Seen but not taken on for a course of treatment)] = [M062] OR ([Ended Deceased (Seen but not taken on for a course of treatment)] IS NULL AND [M062] IS NULL) THEN '1' ELSE '0' END AS 'Ended Deceased (Seen but not taken on for a course of treatment) Match'
      ,[Ended Not Known (Seen but not taken on for a course of treatment)]	
	  ,[M063] AS Count_EndedUnknownAssessedOnly
	  ,CASE WHEN  [Ended Not Known (Seen but not taken on for a course of treatment)] = [M063] OR ([Ended Not Known (Seen but not taken on for a course of treatment)] IS NULL AND [M063] IS NULL) THEN '1' ELSE '0' END AS 'Ended Not Known (Seen but not taken on for a course of treatment) Match'
      ,[Ended Mutually agreed completion of treatment]	
	  ,[M066] AS Count_EndedCompleted
	  ,CASE WHEN  [Ended Mutually agreed completion of treatment] = [M066] OR ([Ended Mutually agreed completion of treatment] IS NULL AND [M066] IS NULL) THEN '1' ELSE '0' END AS 'Ended Mutually agreed completion of treatment Match'
      ,[Ended Termination of treatment earlier than Care Professional planned]	
	  ,[M344] AS Count_EndedBeforeCareProfessionalPlanned
	  ,CASE WHEN  [Ended Termination of treatment earlier than Care Professional planned] = [M344] OR ([Ended Termination of treatment earlier than Care Professional planned] IS NULL AND [M344] IS NULL) THEN '1' ELSE '0' END AS 'Ended Termination of treatment earlier than Care Professional planned Match'
      ,[Ended Termination of treatment earlier than patient requested]	
	  ,[M341] AS Count_EndedBeforePatientRequested
	  ,CASE WHEN  [Ended Termination of treatment earlier than patient requested] = [M341] OR ([Ended Termination of treatment earlier than patient requested] IS NULL AND [M341] IS NULL) THEN '1' ELSE '0' END AS 'Ended Termination of treatment earlier than patient requested Match'
      ,[Ended Deceased (Seen and taken on for a course of treatment)]	
	  ,[M069] AS Count_EndedDeceasedTreated
	  ,CASE WHEN  [Ended Deceased (Seen and taken on for a course of treatment)] = [M069] OR ([Ended Deceased (Seen and taken on for a course of treatment)] IS NULL AND [M069] IS NULL) THEN '1' ELSE '0' END AS 'Ended Deceased (Seen and taken on for a course of treatment) Match'
      ,[Ended Not Known (Seen and taken on for a course of treatment)]	
	  ,[M070] AS Count_EndedUnknownTreated
	  ,CASE WHEN  [Ended Not Known (Seen and taken on for a course of treatment)] = [M070] OR ([Ended Not Known (Seen and taken on for a course of treatment)] IS NULL AND [M070] IS NULL) THEN '1' ELSE '0' END AS 'Ended Not Known (Seen and taken on for a course of treatment) Match'
	  ,[Ended Treatment]
	  ,[M056] AS Count_EndedReferrals2
	  ,CASE WHEN  [Ended Treatment] = [M056] OR ([Ended Treatment] IS NULL AND [M056] IS NULL) THEN '1' ELSE '0' END AS 'Ended Treatment Match'

FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded] a
		-----------------------------------------------------------------------------------
		JOIN #UKHFPivot b ON (a.Level = Group_Type OR (a.Level = 'National' AND Group_Type = 'England') OR (a.Level = 'CCG/ Provider' AND Group_Type = 'CCG/Provider')) AND [CCG Code] = Commissioner_Code  AND [Provider Code] = Provider_Code 

WHERE Month = @MonthYear

)_ 

WHERE	[Referrals Match] = '0' OR [First Treatment Match] = '0' OR [Finished Treatment Match] = '0' OR [OpenReferralLessThan61DaysNoContact Match] = '0'
		OR [OpenReferral61-90DaysNoContact Match] = '0' OR [OpenReferral9100DaysNoContact Match] = '0' OR [Waiting for Assessment Match] = '0'
		OR [WaitingForAssessmentOver90Days Match] = '0' OR [FirstAssessment28Days Match] = '0' OR [FirstAssessment29to56Days Match] = '0'
		OR [FirstAssessment57to90Days Match] = '0' OR [FirstAssessmentOver90Days Match] = '0' OR [FirstTreatment28days Match] = '0'
		OR [FirstTreatment29to56days Match] = '0' OR [FirstTreatment57to90days Match] = '0' OR [FirstTreatmentOver90days Match] = '0'
		OR [Ended Referral Match] = '0' OR [Ended Not Suitable Match] = '0' OR [Ended Signposted Match] = '0' OR [Ended Mutual Agreement Match] = '0'
		OR [Ended Referred Elsewhere Match] = '0' OR [Ended Declined Match] = '0' OR [Ended Invalid Match] = '0' OR [Ended No Reason Recorded Match] = '0'
		OR [Ended Seen Not Treated Match] = '0' OR [Ended Treated Once Match] = '0' OR [Ended Not Seen Match] = '0' OR [Recovery Match] = '0'
		OR [Reliable Recovery Match] = '0' OR [No Change Match] = '0' OR [Reliable Deterioration Match] = '0' OR [Reliable Improvement Match] = '0'
		OR [NotCaseness Match] = '0' OR [ADSMFinishedTreatment Match] = '0' OR [CountAppropriatePairedADSM Match] = '0' OR [SelfReferral Match] = '0'
		OR [GPReferral Match] = '0' OR [FirstToSecondMoreThan90Days Match] = '0' OR [Ended Not Assessed Match] = '0' OR [Ended Incomplete Assessment Match] = '0'
		OR [Ended Deceased (Seen but not taken on for a course of treatment) Match] = '0' OR [Ended Not Known (Seen but not taken on for a course of treatment) Match] = '0'
		OR [Ended Mutually agreed completion of treatment Match] = '0' OR [Ended Termination of treatment earlier than Care Professional planned Match] = '0'
		OR [Ended Termination of treatment earlier than patient requested Match] = '0' OR [Ended Deceased (Seen and taken on for a course of treatment) Match] = '0'
		OR [Ended Not Known (Seen and taken on for a course of treatment) Match] = '0' OR [Ended Treatment Match] = '0'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- New indicators -----------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM 

(

SELECT DISTINCT [Month],
		[Level]
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[SelfReferral]	
	  ,[M002] AS	Count_SelfReferrals
	  ,CASE WHEN  [SelfReferral] = [M002] OR ([SelfReferral] IS NULL AND [M002] IS NULL) THEN '1' ELSE '0' END AS 'SelfReferral Match'
      ,[EndedBeforeTreatment]	
	  ,[M153] AS	Count_EndedBeforeTreatment
	  ,CASE WHEN  [EndedBeforeTreatment] = [M153] OR ([EndedBeforeTreatment] IS NULL AND [M153] IS NULL) THEN '1' ELSE '0' END AS 'EndedBeforeTreatment Match'
      ,[FirstTreatment6Weeks]	
	  ,[M036] AS	Count_FirstTreatment6Weeks
	  ,CASE WHEN  [FirstTreatment6Weeks] = [M036] OR ([FirstTreatment6Weeks] IS NULL AND [M036] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatment6Weeks Match'
      ,[FirstTreatment18Weeks]	
	  ,[M037] AS	Count_FirstTreatment18Weeks
	  ,CASE WHEN  [FirstTreatment18Weeks] = [M037] OR ([FirstTreatment18Weeks] IS NULL AND [M037] IS NULL) THEN '1' ELSE '0' END AS 'FirstTreatment18Weeks Match'
      ,[WaitingForTreatment]	
	  ,[M038] AS	Count_WaitingForTreatment
	  ,CASE WHEN  [WaitingForTreatment] = [M038] OR ([WaitingForTreatment] IS NULL AND [M038] IS NULL) THEN '1' ELSE '0' END AS 'WaitingForTreatment Match'
      ,[Appointments]	
	  ,[M082] AS	Count_Appointments
	  ,CASE WHEN  [Appointments] = [M082] OR ([Appointments] IS NULL AND [M082] IS NULL) THEN '1' ELSE '0' END AS 'Appointments Match'
      ,[Appointments DNA]	
	  ,[M084] AS	Count_ApptsDNA
	  ,CASE WHEN  [Appointments DNA] = [M084] OR ([Appointments DNA] IS NULL AND [M084] IS NULL) THEN '1' ELSE '0' END AS 'Appointments DNA Match'
      ,[ReferralsEnded]	
	  ,[M056] AS	Count_EndedReferrals
	  ,CASE WHEN  [ReferralsEnded] = [M056] OR ([ReferralsEnded] IS NULL AND [M056] IS NULL) THEN '1' ELSE '0' END AS 'ReferralsEnded Match'
      ,[EndedTreatedOnce]	
	  ,[M075] AS	Count_EndedTreatedOnce
	  ,CASE WHEN  [EndedTreatedOnce] = [M075] OR ([EndedTreatedOnce] IS NULL AND [M075] IS NULL) THEN '1' ELSE '0' END AS 'EndedTreatedOnce Match'
      ,[Waiting2Weeks]	
	  ,[M039] AS	Count_WaitingForTreatment0to2weeks
	  ,CASE WHEN  [Waiting2Weeks] = [M039] OR ([Waiting2Weeks] IS NULL AND [M039] IS NULL) THEN '1' ELSE '0' END AS 'Waiting2Weeks Match'
      ,[Waiting4Weeks]	
	  ,[M040] AS	Count_WaitingForTreatment0to4weeks
	  ,CASE WHEN  [Waiting4Weeks] = [M040] OR ([Waiting4Weeks] IS NULL AND [M040] IS NULL) THEN '1' ELSE '0' END AS 'Waiting4Weeks Match'
      ,[Waiting6Weeks]	
	  ,[M041] AS	Count_WaitingForTreatment0to6weeks
	  ,CASE WHEN  [Waiting6Weeks] = [M041] OR ([Waiting6Weeks] IS NULL AND [M041] IS NULL) THEN '1' ELSE '0' END AS 'Waiting6Weeks Match'
      ,[Waiting12Weeks]	
	  ,[M042] AS	Count_WaitingForTreatment0to12weeks
	  ,CASE WHEN  [Waiting12Weeks] = [M042] OR ([Waiting12Weeks] IS NULL AND [M042] IS NULL) THEN '1' ELSE '0' END AS 'Waiting12Weeks Match'
      ,[Waiting18Weeks]	
	  ,[M043] AS	Count_WaitingForTreatment0to18weeks
	  ,CASE WHEN  [Waiting18Weeks] = [M043] OR ([Waiting18Weeks] IS NULL AND [M043] IS NULL) THEN '1' ELSE '0' END AS 'Waiting18Weeks Match'
      ,[FinishedCourseWait6Weeks]	
	  ,[M052] AS	Count_FirstTreatment6WeeksFinishedCourseTreatment
	  ,CASE WHEN  [FinishedCourseWait6Weeks] = [M052] OR ([FinishedCourseWait6Weeks] IS NULL AND [M052] IS NULL) THEN '1' ELSE '0' END AS 'FinishedCourseWait6Weeks Match'
      ,[FinishedCourseWait18Weeks]	
	  ,[M054] AS	Count_FirstTreatment18WeeksFinishedCourseTreatment
	  ,CASE WHEN  [FinishedCourseWait18Weeks] = [M054] OR ([FinishedCourseWait18Weeks] IS NULL AND [M054] IS NULL) THEN '1' ELSE '0' END AS 'FinishedCourseWait18Weeks Match'
      ,[FirstToSecondOver90Days]	
	  ,[M047] AS	Count_FirstToSecondTreatmentOver90days
	  ,CASE WHEN  [FirstToSecondOver90Days] = [M047] OR ([FirstToSecondOver90Days] IS NULL AND [M047] IS NULL) THEN '1' ELSE '0' END AS 'FirstToSecondOver90Days Match'
      ,[RecoveryRate]	
	  ,[M192] AS	Percentage_Recovery
	  ,CASE WHEN  [RecoveryRate] = [M192]/100 OR ([RecoveryRate] IS NULL AND [M192] IS NULL) THEN '1' ELSE '0' END AS 'RecoveryRate Match'
      ,[ReliableImprovementRate]
	  ,[M186]AS	Percentage_Improvement
	  ,CASE WHEN [ReliableImprovementRate] = [M186]/100 OR ([ReliableImprovementRate] IS NULL AND [M186] IS NULL) THEN '1' ELSE '0' END AS 'ReliableImprovementRate Match'
      ,[DeteriorationRate]	
	  ,[M1010] AS	Percentage_Deterioration
	  ,CASE WHEN  [DeteriorationRate] = [M1010]/100 OR ([DeteriorationRate] IS NULL AND [M1010] IS NULL) THEN '1' ELSE '0' END AS 'DeteriorationRate Match'
      ,[NotCaseness]	
	  ,[M180] AS	Percentage_NotAtCaseness
	  ,CASE WHEN  [NotCaseness] = [M180]/100 OR ([NotCaseness] IS NULL AND [M180] IS NULL) THEN '1' ELSE '0' END AS 'NotCasenes Match'
      ,[FinishedCourseTreatment6WeeksRate]	
	  ,[M053] AS	Percentage_FirstTreatment6WeeksFinishedCourseTreatment
	  ,CASE WHEN  [FinishedCourseTreatment6WeeksRate] = [M053]/100 OR ([FinishedCourseTreatment6WeeksRate] IS NULL AND [M053] IS NULL) THEN '1' ELSE '0' END AS 'FinishedCourseTreatment6WeeksRate Match'
      ,[FinishedCourseTreatment18WeeksRate]	
	  ,[M055] AS	Percentage_FirstTreatment18WeeksFinishedCourseTreatment
	  ,CASE WHEN  [FinishedCourseTreatment18WeeksRate] = [M055]/100 OR ([FinishedCourseTreatment18WeeksRate] IS NULL AND [M055] IS NULL) THEN '1' ELSE '0' END AS 'FinishedCourseTreatment18WeeksRate Match'
      ,[ADSMCompletenessRate]	
	  ,[M205] AS	Percentage_AppropriatePairedADSM
	  ,CASE WHEN  [ADSMCompletenessRate] = [M205]/100 OR ([ADSMCompletenessRate] IS NULL AND [M205] IS NULL) THEN '1' ELSE '0' END AS 'ADSMCompletenessRate Match'


FROM	[NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Monthly_IST_New_Indicators_Rounded] a
		-----------------------------------------------------------------------------------------
		JOIN #UKHFPivot b ON (a.Level = Group_Type OR (a.Level = 'National' AND Group_Type = 'England') OR (a.Level = 'CCG/ Provider' AND Group_Type = 'CCG/Provider')) AND [CCG Code] = Commissioner_Code  AND [Provider Code] = Provider_Code 

WHERE Month = @MonthYear

)_ 

WHERE	[SelfReferral Match] = '0' OR [EndedBeforeTreatment Match] = '0' OR [FirstTreatment6Weeks Match] = '0' OR [FirstTreatment18Weeks Match] = '0' OR [WaitingForTreatment Match] = '0' 
		OR [Appointments Match] = '0' OR [Appointments DNA Match] = '0' OR [ReferralsEnded Match] = '0'-- OR [EndedSeenNotTreated Match] = '0' 
		OR [EndedTreatedOnce Match] = '0' OR [Waiting2Weeks Match] = '0' OR [Waiting4Weeks Match] = '0' OR [Waiting6Weeks Match] = '0' OR [Waiting12Weeks Match] = '0' OR [Waiting18Weeks Match] = '0' 
		OR [FinishedCourseWait6Weeks Match] = '0' OR [FinishedCourseWait18Weeks Match] = '0' OR [FirstToSecondOver90Days Match] = '0' OR [RecoveryRate Match] = '0' OR [ReliableImprovementRate Match] = '0' 
		OR [DeteriorationRate Match] = '0' OR [NotCasenes Match] = '0' OR [FinishedCourseTreatment6WeeksRate Match] = '0' OR [FinishedCourseTreatment18WeeksRate Match] = '0' OR [ADSMCompletenessRate Match] = '0'

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Averages Table ------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM 

(

SELECT DISTINCT [Month]
		,[Level]
		,[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		,[MedianApps]
		,[M142] AS	Median_ApptsFinishedCourseTreatment
		,CASE WHEN  [MedianApps] = [M142] OR ([MedianApps] IS NULL AND [M142] IS NULL) THEN '1' ELSE '0' END AS 'MedianApps Match'
		,[MeanWait]	
		,[M048] AS	Mean_WaitEnteredTreatment
		,CASE WHEN  [MeanWait] = [M048] OR ([MeanWait] IS NULL AND [M048] IS NULL) THEN '1' ELSE '0' END AS 'MeanWait Match'
		,[MedianWait]	
		,[M049] AS	Median_WaitEnteredTreatment
		,CASE WHEN  [MedianWait] = [M049] OR ([MedianWait] IS NULL AND [M049] IS NULL) THEN '1' ELSE '0' END AS 'MedianWait Match'
		,[MeanApps]	
		,[M141] AS	Mean_ApptsFinishedCourseTreatment
		,CASE WHEN  [MeanApps] = [M141] OR ([MeanApps] IS NULL AND [M141] IS NULL) THEN '1' ELSE '0' END AS 'MeanApps Match'
		,[MeanFirstWaitFinished]	
		,[M050] AS	Mean_WaitFinishedCourseTreatment
		,CASE WHEN  [MeanFirstWaitFinished] = [M050] OR ([MeanFirstWaitFinished] IS NULL AND [M050] IS NULL) THEN '1' ELSE '0' END AS 'MeanFirstWaitFinished Match'

FROM	[NHSE_Sandbox_MentalHealth].dbo.IAPT_Dashboard_Averages_IST a
		--------------------------------------------------------------
		JOIN #UKHFPivot b ON (a.Level = Group_Type OR (a.Level = 'National' AND Group_Type = 'England') OR (a.Level = 'CCG/ Provider' AND Group_Type = 'CCG/Provider')) AND [CCG Code] = Commissioner_Code  AND [Provider Code] = Provider_Code 

WHERE	Month = @MonthYear AND Category = 'Total'

)_ 

WHERE [MedianApps Match] = '0' OR [MeanWait Match] = '0' OR [MedianWait Match] = '0' OR [MeanApps Match] = '0' OR [MeanFirstWaitFinished Match] = '0'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Consultation Medium - Total Appointment numbers -----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#AptsRounded') IS NOT NULL DROP TABLE #AptsRounded

SELECT * INTO #AptsRounded FROM 

(

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'National' AS 'Level'
		,[Attendence Type]
		,SUM([Face to face communication])+SUM([Telephone])+SUM([Telemedicine web camera])+SUM([Talk type for a Person unable to speak])+SUM([Email])+SUM([Short Message Service (SMS)])+SUM([Other])+SUM([Online Instant Messaging]) AS Appointments

FROM [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Regions_ConsMed_Ethnicity2]

WHERE Month = @MonthYear

GROUP BY Month,[Attendence Type]

UNION -----------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'CCG' AS 'Level'
		,[Attendence Type]
		,CASE WHEN SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])< 5 THEN NULL ELSE CAST(ROUND((SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])+2) /5,0)*5 AS INT) END AS Appointments

FROM [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Regions_ConsMed_Ethnicity2]

WHERE Month = @MonthYear

GROUP BY Month,[CCG Code],[CCG Name],[Attendence Type]

UNION -----------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Provider' AS 'Level'
		,[Attendence Type]
		,CASE WHEN SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])< 5 THEN NULL ELSE CAST(ROUND((SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])+2) /5,0)*5 AS INT) END AS Appointments

FROM [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Regions_ConsMed_Ethnicity2]

WHERE Month = @MonthYear

GROUP BY Month,[Provider Code],[Provider Name],[Attendence Type]

UNION -----------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'CCG/ Provider' AS 'Level'
		,[Attendence Type]
		,CASE WHEN SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])< 5 THEN NULL ELSE CAST(ROUND((SUM([Face to face communication]+[Telephone]+[Telemedicine web camera]+[Talk type for a Person unable to speak]+[Email]+[Short Message Service (SMS)]+[Other]+[Online Instant Messaging])+2) /5,0)*5 AS INT) END AS Appointments

FROM [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Apps_Regions_ConsMed_Ethnicity2]

WHERE Month = @MonthYear

GROUP BY Month,[Provider Code],[Provider Name],[CCG Code],[CCG Name],[Attendence Type] 

)_

-----------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#AptsRoundedPivot') IS NOT NULL DROP TABLE #AptsRoundedPivot

SELECT * INTO #AptsRoundedPivot

FROM #AptsRounded

PIVOT(SUM(Appointments) FOR [Attendence Type] IN(AptCancelledPatient,AptAttended,AptAttendedLate,AptLateNotSeen,AptDNA,AptCancelledProvider,Other)) AS pivot_table 

SELECT * FROM 

(

SELECT DISTINCT [Month]
		,[Level]
		,[Region Code]
		,[Region Name]
		,[CCG Code]
		,[CCG Name]
		,[Provider Code]
		,[Provider Name]
		,[STP Code]
		,[STP Name]
		,AptCancelledPatient
		,[M083] AS Count_ApptsCancelledPatient
		,CASE WHEN AptCancelledPatient = [M083] OR (AptCancelledPatient IS NULL AND [M083] IS NULL) THEN '1' ELSE '0' END AS 'AptCancelledPatient Match'
		,AptAttended
		,[M086] AS [Count_ApptsAttended]
		,CASE WHEN AptAttended = [M086] OR (AptAttended IS NULL AND [M086] IS NULL) THEN '1' ELSE '0' END AS 'AptAttended Match'
		, AptAttendedLate
		,[M087] AS Count_ApptsAttendedLate
		,CASE WHEN AptAttendedLate = [M087] OR (AptAttendedLate IS NULL AND [M087] IS NULL) THEN '1' ELSE '0' END AS 'AptAttendedLate Match'
		,AptLateNotSeen
		,[M088] AS	Count_ApptsLateNotSeen
		,CASE WHEN AptLateNotSeen = [M088] OR (AptLateNotSeen IS NULL AND [M088] IS NULL) THEN '1' ELSE '0' END AS 'AptLateNotSeen Match'
		,AptDNA
		,[M084]	AS Count_ApptsDNA
		,CASE WHEN AptDNA = [M084] OR (AptDNA IS NULL AND [M084] IS NULL) THEN '1' ELSE '0' END AS 'AptDNA Match'
		,AptCancelledProvider
		,[M085] AS	Count_ApptsCancelledProvider
		,CASE WHEN AptCancelledProvider = [M085] OR (AptCancelledProvider IS NULL AND [M085] IS NULL) THEN '1' ELSE '0' END AS 'AptCancelledProvider Match'

FROM	#AptsRoundedPivot a
		JOIN #UKHFPivot b ON (a.Level = Group_Type OR (a.Level = 'National' AND Group_Type = 'England') OR (a.Level = 'CCG/ Provider' AND Group_Type = 'CCG/Provider')) AND [CCG Code] = Commissioner_Code  AND [Provider Code] = Provider_Code 

)_ 

WHERE [AptCancelledPatient Match] = '0' OR [AptAttended Match] = '0' OR [AptAttendedLate Match] = '0' OR [AptLateNotSeen Match] = '0' OR [AptDNA Match] = '0' OR [AptCancelledProvider Match] = '0'
