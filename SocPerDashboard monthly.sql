SET ANSI_WARNINGS OFF
SET DATEFIRST 1
SET NOCOUNT ON

-------------------------
DECLARE @Offset INT = -1
-------------------------

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

DECLARE @PeriodStart2 DATE = (SELECT DATEADD(MONTH,(@Offset +1),MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd2 DATE = (SELECT eomonth(DATEADD(MONTH,(@Offset +1),MAX([ReportingPeriodStartDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Base Table for Paired ADSM ------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TTAD_ADSM_BASE_TABLE]') IS NOT NULL DROP TABLE [MHDInternal].[TTAD_ADSM_BASE_TABLE]

SELECT * INTO [MHDInternal].[TTAD_ADSM_BASE_TABLE] FROM 

(SELECT pc.* 
	FROM [mesh_IAPT].[IDS603presentingcomplaints] pc
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] 
		AND pc.AuditId = l.AuditId 
		AND pc.Unique_MonthID = l.Unique_MonthID
	WHERE IsLatest = 1 AND [ReportingPeriodStartDate] <= @PeriodEnd

UNION -------------------------------------------------------------------------------

SELECT pc.* 
FROM [mesh_IAPT].[IDS603presentingcomplaints] pc
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] 
		AND pc.AuditId = l.AuditId 
		AND pc.Unique_MonthID = l.Unique_MonthID
	WHERE File_Type = 'Primary' AND [ReportingPeriodStartDate] BETWEEN @PeriodStart2 AND @PeriodEnd2
)_

-- Presenting Complaints -----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TTAD_PRES_COMP_BASE_TABLE]') IS NOT NULL DROP TABLE [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE]

SELECT DISTINCT pc.PathwayID
				,Validated_PresentingComplaint
				,row_number() OVER(PARTITION BY pc.PathwayID ORDER BY CASE WHEN Validated_PresentingComplaint IS NULL THEN 2 ELSE 1 END
				,PresCompCodSig
				,PresCompDate DESC, UniqueID_IDS603 DESC) AS rank

INTO	[MHDInternal].[TTAD_PRES_COMP_BASE_TABLE]

FROM	[MHDInternal].[TTAD_ADSM_BASE_TABLE] pc 
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND pc.AuditId = l.AuditId AND pc.Unique_MonthID = l.Unique_MonthID

-- SocPerCircumstance ----------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]

SELECT  @MonthYear AS 'Month'
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Social Personal Circumstance' AS 'Category'
		,[Term] AS 'Variable'
		,COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS 'OpenReferralLessThan61DaysNoContact'
		,COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferralOver120daysNoContact'
		,COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS 'OpenReferral'
		,COUNT( DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Ended Treatment'
		,COUNT( DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'EnteringTreatment'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate IS NULL AND ServDischDate IS NULL THEN r.PathwayID ELSE NULL END) AS 'Waiting for Assessment'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate IS NULL AND ServDischDate IS NULL AND DATEDIFF(DD,ReferralRequestReceivedDate, @PeriodEnd)  >90 THEN r.PathwayID ELSE NULL END) AS 'WaitingForAssessmentOver90days'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) < 29 THEN r.PathwayID ELSE NULL END)  AS 'FirstAssessment28days'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) BETWEEN 29 AND 56 THEN r.PathwayID ELSE NULL END) AS 'FirstAssessment29to56days'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) BETWEEN 57 AND 90 THEN r.PathwayID ELSE NULL END)  AS 'FirstAssessment57to90days'
		,COUNT(DISTINCT CASE WHEN Assessment_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) > 90  THEN r.PathwayID ELSE NULL END) AS 'FirstAssessmentOver90days'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) < 29 THEN r.PathwayID ELSE NULL END)  AS 'FirstTreatment28days'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) BETWEEN 29 AND 56 THEN r.PathwayID ELSE NULL END) AS 'FirstTreatment29to56days'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) BETWEEN 57 AND 90 THEN r.PathwayID ELSE NULL END)  AS 'FirstTreatment57to90days'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) > 90  THEN r.PathwayID ELSE NULL END) AS 'FirstTreatmentOver90days'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd then r.PathwayID END)) as 'Ended Referral'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '10' then r.PathwayID END)) as 'Ended Not Suitable'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '11' then r.PathwayID END)) as 'Ended Signposted'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '12' then r.PathwayID END)) as 'Ended Mutual Agreement'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '13' then r.PathwayID END)) as 'Ended Referred Elsewhere'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '14' then r.PathwayID END)) as 'Ended Declined'
		,NULL AS 'Ended Deceased Assessed Only'
		,NULL AS 'Ended Unknown Assessed Only'
		,NULL AS 'Ended Stepped Up'
		,NULL AS 'Ended Stepped Down'
		,NULL AS 'Ended Completed'
		,NULL AS 'Ended Dropped Out'
		,NULL AS 'Ended Referred Non IAPT'
		,NULL AS 'Ended Deceased Treated'
		,NULL AS 'Ended Unknown Treated'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE is not null and ENDCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') then r.PathwayID END)) as 'Ended Invalid'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE is null then r.PathwayID END)) as 'Ended No Reason Recorded'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 then r.PathwayID END)) as 'Ended Seen Not Treated' -- changed from is null to = 0 and <> 0
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 then r.PathwayID END)) as 'Ended Treated Once'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 then r.PathwayID END)) as 'Ended Not Seen' -- changed from is null to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' or pc.Validated_PresentingComplaint = 'F401' or pc.Validated_PresentingComplaint = 'F410' or pc.Validated_PresentingComplaint like 'F42%'
		or pc.Validated_PresentingComplaint = 'F431' or pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
		AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
		or ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
		or ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
		or ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
		or ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
		or ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '50' then r.PathwayID END)) as 'Ended Not Assessed'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '16' then r.PathwayID END)) as 'Ended Incomplete Assessment'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '17' then r.PathwayID END)) as 'Ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '95' then r.PathwayID END)) as 'Ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '46' then r.PathwayID END)) as 'Ended Mutually agreed completion of treatment'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '47' then r.PathwayID END)) as 'Ended Termination of treatment earlier than Care Professional planned'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '48' then r.PathwayID END)) as 'Ended Termination of treatment earlier than patient requested'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '49' then r.PathwayID END)) as 'Ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(distinct(case when ServDischDate between @PeriodStart AND @PeriodEnd and ENDCODE = '96' then r.PathwayID END)) as 'Ended Not Known (Seen and taken on for a course of treatment)'
		,NULL AS 'RepeatReferrals2'
		,'Gender' AS 'PCCategory'
		,CASE WHEN Gender = '1' THEN	'Male' 
			WHEN  GENDER = '2' THEN	'Female'
			WHEN  GENDER = '9' THEN	'Indeterminate (unable to be classified as either male or female)'
			WHEN  GENDER = 'X' THEN 'Not Known (PERSON STATED GENDER CODE not recorded)' ELSE 'Other' END AS 'PCVariable'
		,NULL AS 'Grouping'

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.[RecordNumber] = mpi.[RecordNumber]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
		------------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		------------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1 
		------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		------------------------------
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON SocPerCircumstance = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
	

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END  
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,[Term]
		,CASE WHEN Gender = '1' THEN	'Male' 
				WHEN  GENDER = '2' THEN	'Female'
				WHEN  GENDER = '9' THEN	'Indeterminate (unable to be classified as either male or female)'
				WHEN  GENDER = 'X' THEN 'Not Known (PERSON STATED GENDER CODE not recorded)' ELSE 'Other' END
			,DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]

SET Grouping = CASE WHEN Variable IN ('Family with child under one year (finding)',		
'Family with child under two years (finding)',		
'Family with children under one year (finding)',		
'Family with children under two years (finding)',		
'Partner pregnant (situation)',		
'Pregnant (finding)',
'Pregnancy (finding)') THEN 'Perinatal'
		
WHEN Variable IN ('Bisexual (finding)',		
'Female homosexual (finding)',		
'Heterosexual (finding)',		
'History taking of sexual orientation declined (situation)',		
'Homosexual (finding)',		
'Male homosexual (finding)',		
'Sexual orientation confusion (finding)',		
'Sexual orientation unknown (finding)',		
'Sexually attracted to neither male nor female sex (finding)',		
'Undecided about sexual orientation (finding)') THEN 'Sexual Orientation'
		
WHEN Variable IN ('Recently worked in a community social care setting (event)',		
'Recently worked in a healthcare setting (event)',		
'Recently worked in a hospital emergency care setting (event)',		
'Recently worked in a primary care setting (event)',		
'Recently worked in a residential care setting (event)',		
'Recently worked in an ambulance service care setting (event)',		
'Recently worked in an inpatient care setting (event)',		
'Recently worked in an intensive care setting (event)') THEN 'Occupational Exposure to COVID'
		
WHEN Variable IN ('Asylum seeker (person)',		
'Asylum seeker awaiting decision on refugee status (person)',		
'Asylum seeker with application for asylum refused (person)',		
'Asylum seeker with discretionary leave to remain (person)',		
'Asylum seeker with humanitarian protection status (person)',		
'Refugee (person)',		
'Unaccompanied child asylum seeker (person)') THEN 'Asylum / Refugee'
		
WHEN Variable IN ('Alcohol abuse (disorder)',		
'Alcohol dependence (disorder)',		
'Does not misuse alcohol (situation)') THEN 'Addiction - Alcohol'
		
WHEN Variable IN ('Does not misuse drugs (situation)',		
'Drug abuse (disorder)',		
'Drug dependence (disorder)') THEN 'Addiction - Drugs'
		
WHEN Variable = 'Compulsive gambling (disorder)' THEN 'Addiction - Gambling'
		
WHEN Variable IN ('Current non smoker but past smoking history unknown (finding)',		
'Ex-smoker (finding)',		
'Never smoked tobacco (finding)',		
'Smoker (finding)') THEN 'Addiction - Smoking'
		
WHEN Variable = 'In debt (finding)' THEN 'Debt'
		
WHEN Variable IN ('(Church of England) or (Anglican) (person)',		
'Agnostic (person)',		
'Ahmadi, follower of religion (person)',		
'Anglican, follower of religion (person)',		
'Apostolic Pentecostalist, follower of religion (person)',		
'Arminianism (religion/philosophy)',		
'Atheist (person)',		
'Bahai, follower of religion (person)',		
'Baptist, follower of religion (person)',		
'Buddhism (religion/philosophy)',		
'Buddhist, follower of religion (person)',		
'Calvinist, follower of religion (person)',		
'Catholic religion (religion/philosophy)',		
'Catholic: non Roman Catholic, follower of religion (person)',		
'Celtic Christian, follower of religion (person)',		
'Celtic pagan, follower of religion (person)',		
'Christian Humanist, follower of religion (person)',		
'Christian Spiritualist, follower of religion (person)',		
'Christian, follower of religion (person)',		
'Church of England (religion/philosophy)',		
'Church of Ireland, follower of religion (person)',		
'Church of Jesus Christ of Latter Day Saints (religion/philosophy)',		
'Church of Scotland (religion/philosophy)',		
'Church of Scotland, follower of religion (person)',		
'Congregationalist, follower of religion (person)',		
'Druid, follower of religion (person)',		
'Evangelical Christian, follower of religion (person)',		
'Follower of Church of England (person)',		
'Follower of Free Christian Church (person)',		
'Follower of United Reformed Church (person)',		
'Greek Orthodox, follower of religion (person)',		
'Has religious belief (finding)',		
'Heathen, follower of religion (person)',		
'Hindu, follower of religion (person)',		
'Humanist (person)',		
'Indian Orthodox, follower of religion (person)',		
'Infinite way, follower of religion (person)',		
'Islam (religion/philosophy)',		
'Ismaili Muslim, follower of religion (person)',		
'Jain, follower of religion (person)',		
'Jehovahs Witness, follower of religion (person)',		
'Jewish, follower of religion (person)',		
'Judaic Christian, follower of religion (person)',		
'Liberal Jew, follower of religion (person)',		
'Lutheran, follower of religion (person)',		
'Messianic Jew, follower of religion (person)',		
'Methodist, follower of religion (person)',		
'Mixed religion (religion/philosophy)',		
'Mormon, follower of religion (person)',		
'Muslim, follower of religion (person)',		
'New age practitioner (person)',		
'Nonconformist (person)',		
'Not religious (finding)',		
'Old Catholic, follower of religion (person)',		
'Orthodox Christian religion (religion/philosophy)',		
'Orthodox Christian, follower of religion (person)',		
'Orthodox Jewish Faith (religion/philosophy)',		
'Pagan, follower of religion (person)',		
'Para-religious movement (religion/philosophy)',		
'Patient religion unknown (finding)',		
'Pentecostalist, follower of religion (person)',		
'Plymouth Brethren religion (religion/philosophy)',		
'Presbyterian, follower of religion (person)',		
'Protestant religion (religion/philosophy)',		
'Protestant, follower of religion (person)',		
'Quaker, follower of religion (person)',		
'Rastafarian, follower of religion (person)',		
'Reform Jew, follower of religion (person)',		
'Reformed Christian, follower of religion (person)',		
'Refusal by patient to provide information about religion (situation)',		
'Religion not given - patient refused (finding)',		
'Religion not recorded (finding)',		
'Religious affiliation (observable entity)',		
'Roman Catholic, follower of religion (person)',		
'Romanian Orthodox, follower of religion (person)',		
'Russian Orthodox, follower of religion (person)',		
'Salvation Army member (person)',		
'Satanist (person)',		
'Seventh Day Adventist, follower of religion (person)',		
'Shiite muslim religion (religion/philosophy)',		
'Shiite muslim, follower of religion (person)',		
'Shinto, follower of religion (person)',		
'Sikh, follower of religion (person)',		
'Spiritual or religious belief (religion/philosophy)',		
'Spiritualism (religion/philosophy)',		
'Spiritualist, follower of religion (person)',		
'Sunni muslim religion (religion/philosophy)',		
'Sunni muslim, follower of religion (person)',		
'Taoist, follower of religion (person)',		
'Theravada Buddhist, follower of religion (person)',		
'Tibetan Buddhist, follower of religion (person)',		
'Unitarian Universalist, follower of religion (person)',		
'Universalist, follower of religion (person)',		
'Vodun, follower of religion (person)',		
'Western buddhist religion (religion/philosophy)',		
'Wiccan, follower of religion (person)',		
'Zoroastrian, follower of religion (person)') THEN 'Religion' ELSE 'Unknown/Not Stated' END

GO

----------------------------------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]'
