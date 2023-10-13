
SET NOCOUNT ON

-- Refresh updates for : [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities] -------------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Refresh AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

DECLARE @PeriodStart2 AS DATE = (SELECT DATEADD(MONTH,+1,MAX(@PeriodStart)) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd2 AS DATE = (SELECT EOMONTH(DATEADD(MONTH,+1,MAX(@PeriodEnd))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Primary AS VARCHAR(50) = (DATENAME(M, @PeriodStart2) + ' ' + CAST(DATEPART(YYYY, @PeriodStart2) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@Refresh AS VARCHAR(50)) + CHAR(10)

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

-----------------------------------------------------------------------------------------------------------------------------------------------
SET ANSI_WARNINGS OFF -------------------------------------------------------------------------------------------------------------------------

-- Sexual Orientation --------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Sexual Orientation' AS Category
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS [Month]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND SocPerCircumstance IN('20430005', '89217008', '76102007', '38628009', '42035005', '1064711000000100', '699042003', '765288000', '440583007', '766822004')
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
			WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
			WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
			WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
			WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
			WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
			WHEN SocPerCircumstance = '699042003' THEN 'Declined'
			WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
			WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
			WHEN SocPerCircumstance = '766822004' THEN 'Confusion' END

-- Ethnicity -----------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Ethnicity' AS Category
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' 
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd 
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END

-- Age ---------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Age' AS Category
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
		ELSE 'Unknown'
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1 

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd 
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown' END

-- Gender --------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Gender' AS Category
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender IN ('x','X') THEN 'Not Known'
			WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Unspecified' 
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd	
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN [Gender] IN ('1','01') THEN 'Male'
			  WHEN [Gender] IN ('2','02') THEN 'Female'
			  WHEN [Gender] IN ('9','09') THEN 'Indeterminate'
			  WHEN [Gender] IN ('x','X') THEN 'Not Known'
			  WHEN [Gender] NOT IN ('1','01','2','02','9','09','x','X') OR [Gender] IS NULL THEN 'Unspecified' END

-- GenderIdentity --------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'GenderIdentity' AS Category
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
			WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
			WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd	
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
			  WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
			  WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			  WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			  WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
			  WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
			  WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified' END
		
-- Problem Descriptor --------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Problem Descriptor' AS Category
		,CASE WHEN PresentingComplaintHigherCategory = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PresentingComplaintHigherCategory = 'Unspecified' THEN 'Unspecified'
			WHEN PresentingComplaintHigherCategory = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PresentingComplaintHigherCategory = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PresentingComplaintHigherCategory = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory IS NULL THEN 'No Code' ELSE 'Other' 
		END AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd 
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CASE WHEN PresentingComplaintHigherCategory = 'Depression' THEN 'F32 or F33 - Depression'
				WHEN PresentingComplaintHigherCategory = 'Unspecified' THEN 'Unspecified'
				WHEN PresentingComplaintHigherCategory = 'Other recorded problems' THEN 'Other recorded problems'
				WHEN PresentingComplaintHigherCategory = 'Other Mental Health problems' THEN 'Other Mental Health problems'
				WHEN PresentingComplaintHigherCategory = 'Invalid Data supplied' THEN 'Invalid Data supplied'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
				WHEN PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' AND PresentingComplaintLowerCategory IS NULL THEN 'No Code' 
				ELSE 'Other' END

-- IMD ---------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'IMD' AS Category
		,CAST([IMD_Decile] AS Varchar) AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1
		---------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code] AND [Effective_Snapshot_Date] = '2015-12-31' -- to match reference table used in NCDR
	
WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd 
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END 
		,CAST([IMD_Decile] AS Varchar)

-- Total ----------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

SELECT  @PeriodStart AS [Month1]
		,'Refresh' AS DataSource
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  <61 THEN r.PathwayID ELSE NULL END) AS OpenReferralLessThan61DaysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  BETWEEN 61 AND 90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral61-90DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  between 91 and 120 THEN r.PathwayID ELSE NULL END) AS 'OpenReferral91-120DaysNoContact'
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, @PeriodEnd)  >120 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver120daysNoContact
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'ended Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS EnteringTreatment
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
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd THEN r.PathwayID END)) AS 'ended Referral'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '10' THEN r.PathwayID END)) AS 'ended Not Suitable'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '11' THEN r.PathwayID END)) AS 'ended Signposted'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '12' THEN r.PathwayID END)) AS 'ended Mutual Agreement'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '13' THEN r.PathwayID END)) AS 'ended Referred Elsewhere'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '14' THEN r.PathwayID END)) AS 'ended Declined'
		,NULL AS 'ended Deceased Assessed Only'
		,NULL AS 'ended Unknown Assessed Only'
		,NULL AS 'ended Stepped Up'
		,NULL AS 'ended Stepped Down'
		,NULL AS 'ended Completed'
		,NULL AS 'ended Dropped Out'
		,NULL AS 'ended Referred Non IAPT'
		,NULL AS 'ended Deceased Treated'
		,NULL AS 'ended Unknown Treated'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS not NULL and endCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') THEN r.PathwayID END)) AS 'ended Invalid'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE IS NULL THEN r.PathwayID END)) AS 'ended No Reason Recorded'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 THEN r.PathwayID END)) AS 'ended Seen Not Treated' -- changed FROM IS NULL to = 0 and <> 0
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and TreatmentCareContact_Count = 1 THEN r.PathwayID END)) AS 'ended Treated Once'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and CareContact_Count = 0 THEN r.PathwayID END)) AS 'ended Not Seen' -- changed FROM IS NULL to = 0
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
		,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True' AND
		(pc.Validated_PresentingComplaint = 'F400' OR pc.Validated_PresentingComplaint = 'F401' OR pc.Validated_PresentingComplaint = 'F410' OR pc.Validated_PresentingComplaint like 'F42%'
		OR pc.Validated_PresentingComplaint = 'F431' OR pc.Validated_PresentingComplaint = 'F452')
		THEN r.PathwayID ELSE NULL END) AS 'ADSMFinishedTreatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND CompletedTreatment_Flag = 'True'
			AND (([Validated_PresentingComplaint] = 'F400' AND ADSM = 'AgoraAlone')
			OR ([Validated_PresentingComplaint] = 'F401' AND ADSM = 'SocialPhobia')
			OR ([Validated_PresentingComplaint] = 'F410' AND ADSM = 'PanicDisorder')
			OR ([Validated_PresentingComplaint] LIKE 'F42%' AND ADSM = 'OCD')
			OR ([Validated_PresentingComplaint] = 'F431' AND ADSM = 'PTSD')
			OR ([Validated_PresentingComplaint] = 'F452' AND ADSM = 'AnxietyInventory')) THEN r.PathwayID ELSE NULL END) AS 'CountAppropriatePairedADSM'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT = 'A1' THEN r.PathwayID ELSE NULL END) AS 'GPReferral'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN @PeriodStart AND @PeriodEnd AND SourceOfReferralIAPT NOT IN ('B1','A1') THEN r.PathwayID ELSE NULL END) AS 'OtherReferral'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To56Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond57To90Days'
		,COUNT(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN @PeriodStart AND @PeriodEnd AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
		THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '50' THEN r.PathwayID END)) AS 'ended Not Assessed'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '16' THEN r.PathwayID END)) AS 'ended Incomplete Assessment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '17' THEN r.PathwayID END)) AS 'ended Deceased (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '95' THEN r.PathwayID END)) AS 'ended Not Known (Seen but not taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '46' THEN r.PathwayID END)) AS 'ended Mutually agreed completion of treatment'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '47' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than Care Professional planned'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '48' THEN r.PathwayID END)) AS 'ended Termination of treatment earlier than patient requested'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '49' THEN r.PathwayID END)) AS 'ended Deceased (Seen and taken on for a course of treatment)'
		,COUNT(DISTINCT(CASE WHEN ServDischDate between @PeriodStart AND @PeriodEnd and endCODE = '96' THEN r.PathwayID END)) AS 'ended Not Known (Seen and taken on for a course of treatment)'

		,DATENAME(m, @PeriodStart) + ' ' + CAST(DATEPART(yyyy, @PeriodStart) AS VARCHAR) AS Month 

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS011socpercircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [MHDInternal].[TTAD_PRES_COMP_BASE_TABLE] pc ON pc.PathwayID = r.PathwayID AND pc.rank = 1

WHERE	UsePathway_Flag = 'True' 
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd 
		AND IsLatest = 1

GROUP BY CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

------------------------------------------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]'