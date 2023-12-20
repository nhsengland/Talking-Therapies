/*					SOCIAL PERSONAL CIRCUMSTANCE DASHBOARD						*/
--------Early stage metrics for selected Social Personal Circumstance to flow to the policy team-------------
-- DELETE MAX(Month) -----------------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]
 
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance])
GO
--------------------
SET DATEFIRST 1
SET NOCOUNT ON
--------------
DECLARE @Offset INT = 0
-------------------------
DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))
PRINT @PeriodStart
----------------------------------------------------------------------------------------------------------------------------------------
---- Base Table ------------------------------------------------------------------------------------------------------------------
----------------Social Personal Circumstance Ranked Table------------------------------------
----There are instances of different sexual orientations listed for the same Person_ID and RecordNumber so this table ranks each sexual orientation code based on the SocPerCircumstanceRecDate
----so that the latest record of a sexual orientation is labelled as 1. Only records with a SocPerCircumstanceLatest=1 are used in the queries to produce
----[MHDInternal].[TEMP_TTAD_PDT_Inequalities_Base] table

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_SocPerCircumstance_SocPerCircRank]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_SocPerCircumstance_SocPerCircRank]
SELECT *
	,ROW_NUMBER() OVER(PARTITION BY Person_ID,TermGroup,PathwayID ORDER BY [SocPerCircumstanceRecDate] desc) as SocPerCircumstanceLatest
	--ranks each SocPerCircumstance with the same Person_ID and TermGroup by the date so that the latest record is labelled as 1
INTO [MHDInternal].[TEMP_TTAD_SocPerCircumstance_SocPerCircRank]
FROM(
	SELECT DISTINCT
		i.AuditID
		,sp.SocPerCircumstance
		,sp.SocPerCircumstanceRecDate
		,sp.Person_ID
		,r.PathwayID
		,sp.RecordNumber
		,sp.UniqueID_IDS011
		,sp.OrgID_Provider
		,i.UniqueSubmissionID
		,sp.Unique_MonthID
		,s2.Term
		,CASE WHEN SocPerCircumstance IN ('15167005','66590003','1129201000000100','1129201000000100','1129201000000101')
					THEN 'Addiction - Alcohol'

				WHEN SocPerCircumstance IN ('191816009','112891000000107','228367002','26416006')
					THEN 'Addiction - Drugs'

				WHEN SocPerCircumstance IN ('405746006','8517006','266919005','77176002')
					THEN 'Addiction - Smoking'

				WHEN SocPerCircumstance = '18085000'
					THEN 'Addiction - Gambling'

				WHEN SocPerCircumstance = '160933000'
					THEN 'Debt'

				WHEN SocPerCircumstance IN ('405746006','77176002','225786009','138008005','138009002','8517006','160624000','266919005') THEN 'Addiction - Smoking'

				WHEN SocPerCircumstance IN ('390790000','728611000000100','728621000000106','729851000000109','728631000000108','446654005','748241000000103')
					THEN 'Asylum / Refugee'

				WHEN SocPerCircumstance IN ('1322631000000100','1322381000000100','1322581000000100','1322621000000100','1322641000000100','1322601000000100','1322591000000100','1322571000000100',
							'1322631000000106','1322381000000103','1322581000000109','1322621000000109','1322641000000102','1322591000000106','1322571000000107'	)
					THEN 'Occupational Exposure to COVID'

				WHEN SocPerCircumstance IN ('224123004','1128911000000100','224122009','1127321000000100','704502000','77386006','1127321000000100','1127321000000108')
					THEN 'Perinatal'

				WHEN SocPerCircumstance IN ('42035005','89217008','20430005','699042003','38628009','76102007','766822004','440583007','765288000','1064711000000100','1064711000000108')
					THEN 'Sexual Orientation'

				WHEN SocPerCircumstance IN ('160539008','427963008','368001000000101','160567004','428815009','271448006','373831000000102','367831000000100','444870008','298025008',
				'344141000000104','81918007','428347009','367851000000107','81706006','160542002','429732005','160557009','367861000000105','367871000000103','373911000000103','33822009',
				'309687009','368061000000102','429539003','276120001','368071000000109','368081000000106','368091000000108','367881000000101','368101000000100','160566008','368121000000109',
				'160544001','160544001','428504005','160549006','368131000000106','309887007','368141000000102','13439009','160561003','344171000000105','367901000000103','38052003','427874000',
				'428373004','368351000000102','428506007','368361000000104','428376007','368151000000104','427729003','368161000000101','344151000000101','344211000000108','344091000000105',
				'344361000000101','373871000000100','368191000000107','429158002','62458008','304041000000105','160545000','303721000000103','373881000000103','373891000000101','368341000000100',
				'271390004','428801007','429787006','80587008','160543007','368201000000109','367911000000101','427754003','367921000000107','427755002','368421000000104','160558004','160551005',
				'344081000000108','309884000','368511000000109','367941000000100','429527006','428666001','276119007','160552003','367951000000102','368241000000107','298019009','428503004',
				'429644000','55248004','205141000000101','368381000000108','298047008','205081000000105','160562005','160565007','344261000000105','160560002','298020003','309885004','309886003',
				'248544006','429509008','368251000000105','763896000','312865007','312864006','429379008','366740002','160538000','160540005','368281000000104','429544005','160234004',
				'367961000000104','344071000000106','371351000000101','373851000000109','344321000000109','298024007','428821008','298026009','28010004','429547003','298037005','1400009',
				'205061000000101','429171004','298030007','64988008','429543004','428407001','428496003','368411000000105','429708003','368401000000108','429511004','368011000000104','298034003',
				'428408006','368021000000105','427981006','429790000')
				THEN 'Religion' ELSE 'Unknown/Not Stated' END AS TermGroup


	FROM [mesh_IAPT].[IDS101referral] r
		-------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1 
		-------------------------
		INNER JOIN [mesh_IAPT].[IDS011socpercircumstances] sp ON r.recordnumber = sp.recordnumber AND r.AuditID = sp.AuditId AND r.UniqueSubmissionID = sp.UniqueSubmissionID AND SocPerCircumstanceRecDate IS NOT NULL AND sp.Person_ID IS NOT NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD] s2 ON SocPerCircumstance = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
)_



--Base Table
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_SocPerCirc_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_SocPerCirc_Base]
SELECT DISTINCT
		i.ReportingPeriodStartDate AS 'Month'
        ,r.PathwayID
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.STP_Name ELSE 'Other' END AS 'ICBName'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'RegionNameComm'
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'
		,TermGroup
		,[Term]

		,CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, i.[ReportingPeriodEndDate])  <61 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferralLessThan61DaysNoContact
		,CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, i.[ReportingPeriodEndDate])  BETWEEN 61 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'OpenReferral61-90DaysNoContact'
		,CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, i.[ReportingPeriodEndDate])  between 91 and 120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'OpenReferral91-120DaysNoContact'
		,CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, i.[ReportingPeriodEndDate])  >120 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferralOver120daysNoContact
		,CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OpenReferral

		,CASE WHEN ServDischDate IS NOT NULL AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS Discharges
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Finished Treatment - 2 or more Apps'
		,CASE WHEN ReferralRequestReceivedDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Referrals'
		,CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS EnteringTreatment

		,CASE WHEN Assessment_FirstDate IS NULL AND ServDischDate IS NULL AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Waiting for Assessment'
		,CASE WHEN Assessment_FirstDate IS NULL AND ServDischDate IS NULL AND DATEDIFF(DD,ReferralRequestReceivedDate, i.[ReportingPeriodEndDate]) >90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'WaitingForAssessmentOver90days'
		,CASE WHEN Assessment_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) < 29 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment28days'
		,CASE WHEN Assessment_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) BETWEEN 29 AND 56 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment29to56days'
		,CASE WHEN Assessment_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) BETWEEN 57 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessment57to90days'
		,CASE WHEN Assessment_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,Assessment_FirstDate) > 90  AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstAssessmentOver90days'

		,CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) < 29 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment28days'
		,CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) BETWEEN 29 AND 56 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment29to56days'
		,CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) BETWEEN 57 AND 90 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatment57to90days'
		,CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) > 90  AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'FirstTreatmentOver90days'

		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '10' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Not Suitable'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '11' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Signposted'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '12' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Mutual Agreement'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '13' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Referred Elsewhere'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '14' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Declined'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE is not null and ENDCODE not in ('10','11','12','13','14','50','16','17','95','46','47','48','49','96') AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Invalid'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE is null AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended No Reason Recorded'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and TreatmentCareContact_Count = 0 and CareContact_Count <> 0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Seen Not Treated' -- changed from is null to = 0 and <> 0
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and TreatmentCareContact_Count = 1 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Treated Once'
		,(case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and CareContact_Count = 0 AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END)
		AS 'Ended Not Seen' -- changed from is null to = 0

		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Recovery'
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Recovery'
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  NoChange_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'No Change'
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  ReliableDeterioration_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Deterioration'
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Reliable Improvement'
		,CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'NotCaseness'

		,CASE WHEN ReferralRequestReceivedDate  BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND (SourceOfReferralMH = 'B1' OR SourceOfReferralIAPT = 'B1') AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS SelfReferral
		,CASE WHEN ReferralRequestReceivedDate  BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND (SourceOfReferralMH = 'A1' OR SourceOfReferralIAPT = 'A1') AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS GPReferral
		,CASE WHEN ReferralRequestReceivedDate  BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND (SourceOfReferralMH NOT IN ('B1','A1') OR SourceOfReferralIAPT NOT IN ('B1','A1')) AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS OtherReferral

		,CASE WHEN R.TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
					AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS FirstToSecond28Days
		,CASE WHEN R.TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
					AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS FirstToSecond28To56Days
		,CASE WHEN R.TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
					AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS FirstToSecond57To90Days
		,CASE WHEN R.TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
					AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS FirstToSecondMoreThan90Days

		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '50' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Not Assessed'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '16' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Incomplete Assessment'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '17' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Deceased (Seen but not taken on for a course of treatment)'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '95' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Not Known (Seen but not taken on for a course of treatment)'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '46' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Mutually agreed completion of treatment'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '47' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Termination of treatment earlier than Care Professional planned'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '48' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Termination of treatment earlier than patient requested'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '49' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Deceased (Seen and taken on for a course of treatment)'
		,case when ServDischDate between i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] and ENDCODE = '96' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
		AS 'Ended Not Known (Seen and taken on for a course of treatment)'

		,CASE WHEN Gender = '1' THEN	'Male' 
			WHEN  GENDER = '2' THEN	'Female'
			WHEN  GENDER = '9' THEN	'Indeterminate (unable to be classified as either male or female)'
			WHEN  GENDER = 'X' THEN 'Not Known (PERSON STATED GENDER CODE not recorded)' ELSE 'Other' END
		AS Gender
INTO [MHDInternal].[TEMP_TTAD_SocPerCirc_Base]
FROM [mesh_IAPT].[IDS101referral] r
		--------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1
		--------------------------
		---------------------------------
		--Should it be this:
		LEFT JOIN [MHDInternal].[TEMP_TTAD_SocPerCircumstance_SocPerCircRank] spc ON spc.PathwayID = r.PathwayID AND spc.SocPerCircumstanceLatest = 1

		--------------------------------
		------------------------------
	--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL


WHERE	UsePathway_Flag = 'True'
		AND i.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart
GO

-- SocPerCircumstance Dashboard Output----------------------------------------------------------------------------------------------------------------------------------------


INSERT INTO [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]

SELECT  
	Month

	,'Refresh' AS DataSource
	,'England' AS GroupType

	,[Sub-ICBCode]
	,[Sub-ICBName]
	,[ICBCode]
	,[ICBName]
	,[RegionNameComm]
	,[RegionCodeComm]
	,[ProviderCode]
	,[ProviderName]

	,'Social Personal Circumstance' AS Category
	,TermGroup AS 'Grouping'
	,Term AS Variable

	,SUM(OpenReferralLessThan61DaysNoContact) AS OpenReferralLessThan61DaysNoContact
	,SUM([OpenReferral61-90DaysNoContact]) AS 'OpenReferral61-90DaysNoContact'
	,SUM([OpenReferral91-120DaysNoContact]) AS 'OpenReferral91-120DaysNoContact'
	,SUM(OpenReferralOver120daysNoContact) AS OpenReferralOver120daysNoContact
	,SUM(OpenReferral) AS OpenReferral

	,SUM(Discharges) AS Discharges
	,SUM([Finished Treatment - 2 or more Apps]) AS 'Finished Treatment - 2 or more Apps'
	,SUM(Referrals) AS 'Referrals'
	,SUM(EnteringTreatment) AS EnteringTreatment

	,SUM([Waiting for Assessment]) AS 'Waiting for Assessment'
	,SUM(WaitingForAssessmentOver90days) AS 'WaitingForAssessmentOver90days'
	,SUM(FirstAssessment28days) AS 'FirstAssessment28days'
	,SUM(FirstAssessment29to56days) AS 'FirstAssessment29to56days'
	,SUM(FirstAssessment57to90days) AS 'FirstAssessment57to90days'
	,SUM(FirstAssessmentOver90days) AS 'FirstAssessmentOver90days'

	,SUM(FirstTreatment28days) AS 'FirstTreatment28days'
	,SUM(FirstTreatment29to56days) AS 'FirstTreatment29to56days'
	,SUM(FirstTreatment57to90days) AS 'FirstTreatment57to90days'
	,SUM(FirstTreatmentOver90days) AS 'FirstTreatmentOver90days'

	,SUM([Ended Not Suitable]) AS 'Ended Not Suitable'
	,SUM([Ended Signposted]) AS 'Ended Signposted'
	,SUM([Ended Mutual Agreement]) AS 'Ended Mutual Agreement'
	,SUM([Ended Referred Elsewhere]) AS 'Ended Referred Elsewhere'
	,SUM([Ended Declined]) AS 'Ended Declined'
	,SUM([Ended Invalid]) AS 'Ended Invalid'
	,SUM([Ended No Reason Recorded]) AS 'Ended No Reason Recorded'
	,SUM([Ended Seen Not Treated]) AS 'Ended Seen Not Treated'
	,SUM([Ended Treated Once]) AS 'Ended Treated Once'
	,SUM([Ended Not Seen]) AS 'Ended Not Seen'

	,SUM(Recovery) AS 'Recovery'
	,SUM([Reliable Recovery]) AS 'Reliable Recovery'
	,SUM([No Change]) AS 'No Change'
	,SUM([Reliable Deterioration]) AS 'Reliable Deterioration'
	,SUM([Reliable Improvement]) AS 'Reliable Improvement'
	,SUM(NotCaseness) AS 'NotCaseness'
	,SUM(SelfReferral) AS SelfReferral
	,SUM(GPReferral) AS GPReferral
	,SUM(OtherReferral) AS OtherReferral
	,SUM(FirstToSecond28Days) AS FirstToSecond28Days
	,SUM(FirstToSecond28To56Days) AS FirstToSecond28To56Days
	,SUM(FirstToSecond57To90Days) AS FirstToSecond57To90Days
	,SUM(FirstToSecondMoreThan90Days) AS FirstToSecondMoreThan90Days
	,SUM([Ended Not Assessed]) AS 'Ended Not Assessed'
	,SUM([Ended Incomplete Assessment]) AS 'Ended Incomplete Assessment'
	,SUM([Ended Deceased (Seen but not taken on for a course of treatment)]) AS 'Ended Deceased (Seen but not taken on for a course of treatment)'
	,SUM([Ended Not Known (Seen but not taken on for a course of treatment)]) AS 'Ended Not Known (Seen but not taken on for a course of treatment)'
	,SUM([Ended Mutually agreed completion of treatment]) AS 'Ended Mutually agreed completion of treatment'
	,SUM([Ended Termination of treatment earlier than Care Professional planned]) AS 'Ended Termination of treatment earlier than Care Professional planned'
	,SUM([Ended Termination of treatment earlier than patient requested]) AS 'Ended Termination of treatment earlier than patient requested'
	,SUM([Ended Deceased (Seen and taken on for a course of treatment)]) AS 'Ended Deceased (Seen and taken on for a course of treatment)'
	,SUM([Ended Not Known (Seen and taken on for a course of treatment)]) AS 'Ended Not Known (Seen and taken on for a course of treatment)'

	,'Gender' AS PCCategory
	,[Gender] AS PCVariable

FROM [MHDInternal].[TEMP_TTAD_SocPerCirc_Base]
WHERE TermGroup IS NOT NULL
GROUP BY 
	[Month]
	,RegionCodeComm
	,RegionNameComm
	,ICBCode
	,ICBName
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ProviderCode
	,ProviderName
	,Term
	,TermGroup
	,Gender

-------Delete Temporary Table for Soc/Personal Rank
DROP TABLE [MHDInternal].[TEMP_TTAD_SocPerCircumstance_SocPerCircRank]
DROP TABLE [MHDInternal].[TEMP_TTAD_SocPerCirc_Base]
----------------------------------------------------------------------------------------------------------------------------------
Print CHAR(10) + 'Updated - [MHDInternal].[DASHBOARD_TTAD_SocPersCircumstance]'


