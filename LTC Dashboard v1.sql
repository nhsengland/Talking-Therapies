


DECLARE @Period_Start DATE
DECLARE @Period_End DATE 

SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET DATEFIRST 1

PRINT @Period_Start
PRINT @Period_End



-- Monthly Breakdown 
	-- LongTerm Conditions
	-- Integrated Pathways
	-- Geographies
	-- Referrals/Access/Completion
		-- Refferal Type
	-- Outcome Measures
	-- Waits
	-- Apoointment Types

INSERT INTO [MHDInternal].[TTAD_Dashboard_LTC_Monthly]
SELECT DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'England' AS 'GroupType'
			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
			,'Total' AS Category
			,'Total' as 'Variable',
CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
		,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
			,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Referrals'
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS EnteringTreatment

			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'
			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) 'Reliable Recovery'
			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'
			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'
			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'
			,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'
			
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'A1' THEN r.PathwayID ELSE NULL END)	AS	'Primary Health Care: General Medical Practitioner Practice'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'A2' THEN r.PathwayID ELSE NULL END)	AS	'Primary Health Care: Health Visitor'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'A3' THEN r.PathwayID ELSE NULL END)	AS	'Other Primary Health Care'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'A4' THEN r.PathwayID ELSE NULL END)	AS	'Primary Health Care: Maternity Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'B1' THEN r.PathwayID ELSE NULL END)	AS	'Self Referral: Self'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'B2' THEN r.PathwayID ELSE NULL END)	AS	'Self Referral: Carer/Relative'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'C1' THEN r.PathwayID ELSE NULL END)	AS	'Local Authority and Other Public Services: Social Services'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'C2' THEN r.PathwayID ELSE NULL END)	AS	'Local Authority and Other Public Services: Education Service / Educational Establishment'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'C3' THEN r.PathwayID ELSE NULL END)	AS	'Local Authority and Other Public Services: Housing Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'D1' THEN r.PathwayID ELSE NULL END)	AS	'Employer'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'D2' THEN r.PathwayID ELSE NULL END)	AS	'Employer: Occupational Health'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E1' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Police'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E2' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Courts'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E3' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Probation Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E4' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Prison'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E5' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Court Liaison and Diversion Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'E6' THEN r.PathwayID ELSE NULL END)	AS	'Justice System: Youth Offending Team'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'F1' THEN r.PathwayID ELSE NULL END)	AS	'Child Health: School Nurse'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'F2' THEN r.PathwayID ELSE NULL END)	AS	'Child Health: Hospital-based Paediatrics'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'F3' THEN r.PathwayID ELSE NULL END)	AS	'Child Health: Community-based Paediatrics'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'G1' THEN r.PathwayID ELSE NULL END)	AS	'Independent sector - Medium Secure Inpatients'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'G2' THEN r.PathwayID ELSE NULL END)	AS	'Independent Sector - Low Secure Inpatients'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'G3' THEN r.PathwayID ELSE NULL END)	AS	'Other Independent Sector Mental Health Services'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'G4' THEN r.PathwayID ELSE NULL END)	AS	'Voluntary Sector'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'H1' THEN r.PathwayID ELSE NULL END)	AS	'Acute Secondary Care: Emergency Care Department'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'H2' THEN r.PathwayID ELSE NULL END)	AS	'Other secondary care specialty'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'I1' THEN r.PathwayID ELSE NULL END)	AS	'Temporary transfer from another Mental Health NHS Trust'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'I2' THEN r.PathwayID ELSE NULL END)	AS	'Permanent transfer from another Mental Health NHS Trust'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M1' THEN r.PathwayID ELSE NULL END)	AS	'Other: Asylum Services'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M2' THEN r.PathwayID ELSE NULL END)	AS	'Other: Telephone or Electronic Access Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M3' THEN r.PathwayID ELSE NULL END)	AS	'Other: Out of Area Agency'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M4' THEN r.PathwayID ELSE NULL END)	AS	'Other: Drug Action Team / Drug Misuse Agency'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M5' THEN r.PathwayID ELSE NULL END)	AS	'Other: Jobcentre Plus'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M6' THEN r.PathwayID ELSE NULL END)	AS	'Other SERVICE or agency'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M7' THEN r.PathwayID ELSE NULL END)	AS	'Other: Single Point of Access Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'M8' THEN r.PathwayID ELSE NULL END)	AS	'Debt agency'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'N1' THEN r.PathwayID ELSE NULL END)	AS	'Stepped up from low intensity Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'N2' THEN r.PathwayID ELSE NULL END)	AS	'Stepped down from high intensity Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'N4' THEN r.PathwayID ELSE NULL END)	AS	'Other Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'P1' THEN r.PathwayID ELSE NULL END)	AS	'Internal Referral'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND SourceOfReferralMH = 'Q1' THEN r.PathwayID ELSE NULL END)	AS	'Mental Health Drop In Service'



			,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) <=28
			THEN r.PathwayID ELSE NULL END) AS FirstToSecond28Days
			,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 29 AND 56
			THEN r.PathwayID ELSE NULL END) AS FirstToSecond28To56Days
			,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) BETWEEN 57 AND 90
			THEN r.PathwayID ELSE NULL END) AS FirstToSecond57To90Days
			,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) > 90
			THEN r.PathwayID ELSE NULL END) AS FirstToSecondMoreThan90Days
			,COUNT( DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS FirstToSecond
			

			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '5' THEN CareContactId ELSE NULL END) AS 'Attended on time or, if late, before the relevant professional was ready to see the patient'
			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '6' THEN CareContactId ELSE NULL END) AS 'Arrived late, after the relevant professional was ready to see the patient, but was seen'
			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '7' THEN CareContactId ELSE NULL END) AS 'Patient arrived late and could not be seen'
			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '2' THEN CareContactId ELSE NULL END) AS 'Appointment cancelled by, or on behalf of the patient'
			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '3' THEN CareContactId ELSE NULL END) AS 'Did not attend, no advance warning given'
			,COUNT( DISTINCT CASE WHEN CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode = '4' THEN CareContactId ELSE NULL END) AS 'Appointment cancelled or postponed by the health care provider'

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar),
		CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
		,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END


 --Monthly Averages

INSERT INTO [MHDInternal].[TTAD_Dashboard_LTC_Monthly_Averages]
SELECT *
FROM
(

---National 
--	(Non)/Intergrated
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'England' AS 'GroupType'

			,'England' AS 'Code'
			,'England' AS 'Name'
			,'All Regions' AS 'Region'
			,'All ICBs'	AS 'ICB'
			
			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
			
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END


UNION 

--	Regional 
--	(Non)/Intergrated
--	LTC Applied


SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Region' AS 'GroupType'

			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,'All ICBs'	AS 'ICB'

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
UNION 

---Sub-ICB 
--	(Non)/Intergrated
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Sub-ICB' AS 'GroupType'

			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

UNION 

---	Provider 
--	(Non)/Intergrated
--	LTC Applied


SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Provider' AS 'GroupType'

			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
UNION 

---	ICB 
--	(Non)/Intergrated
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'ICB' AS 'GroupType'
			
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

			,CASE WHEN [IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 

UNION

---	National 
--	All Pathways
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'England' AS 'GroupType'

			,'England' AS 'Code'
			,'England' AS 'Name'
			,'All Regions' AS 'Region'
			,'All ICBs'	AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
			
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END


UNION 

---	Regional 
--	All Pathways
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Region' AS 'GroupType'

			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,'All ICBs'	AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
UNION 


---	Sub-ICB 
--	All Pathways
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Sub-ICB' AS 'GroupType'

			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END


UNION 

---	Provider 
--	All Pathways
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Provider' AS 'GroupType'

			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

UNION 

---	ICB 
--	All Pathways
--	LTC Applied

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'ICB' AS 'GroupType'
			
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END



UNION

---	National 
--	All Pathways
--	All Terms

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'England' AS 'GroupType'
			
			,'England' AS 'Code'
			,'England' AS 'Name'
			,'All Regions' AS 'Region'
			,'All ICBs'	AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,'All Terms' AS Term
			
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)


UNION 

---	Regional 
--	All Pathways
--	All Terms

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Region' AS 'GroupType'

			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,'All ICBs'	AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,'All Terms' AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst


FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
UNION 

---	Sub-ICB 
--	All Pathways
--	All Terms

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Sub-ICB' AS 'GroupType'

			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,'All Terms' AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END


UNION 

---	Provider 
--	All Pathways
--	All Terms

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'Provider' AS 'GroupType'

			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,'All Terms' AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

UNION 

---	ICB 
--	All Pathways
--	All Terms

SELECT		DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month ,
			'Refresh' AS DataSource
			,'ICB' AS 'GroupType'
			
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'Name'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB'

			,'All Pathways' AS 'Integrated LTC'
			,'All Terms' AS Term
--Average Appointments
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN EmploymentSupport_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average EA Apps'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN TreatmentCareContact_Count ELSE NULL END) AS DECIMAL(10,1)) AS 'Average Care Contacts Apps'
			

--Average WSAS Score
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_FirstScore IS NOT NULL THEN WASAS_Work_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Work_LastScore IS NOT NULL THEN WASAS_Work_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_FirstScore IS NOT NULL THEN WASAS_HomeManagement_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Home Management First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_HomeManagement_LastScore IS NOT NULL THEN WASAS_HomeManagement_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Home Management Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN WASAS_PrivateLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Private Leisure Activities Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_FirstScore IS NOT NULL THEN WASAS_Relationships_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Relationships First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_Relationships_LastScore IS NOT NULL THEN WASAS_Relationships_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Relationships Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN WASAS_SocialLeisureActivities_FirstScore ELSE NULL END) AS DECIMAL(10,1))  AS 'Average WSAS Social Leisure Activities First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN WASAS_SocialLeisureActivities_LastScore ELSE NULL END) AS DECIMAL(10,1)) AS 'Average WSAS Social Leisure Activities Last Score'


--Average Inventory Scores
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_FirstScore IS NOT NULL THEN DDS_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DDS_LastScore IS NOT NULL THEN DDS_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Diabetes Distress Score Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_FirstScore IS NOT NULL THEN BPI_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND BPI_LastScore IS NOT NULL THEN BPI_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average Brief Pain Inventory Work Last Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_FirstScore IS NOT NULL THEN CAT_FirstScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work First Score'
			,CAST(AVG(CASE WHEN CompletedTreatment_Flag = 'True' AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CAT_LastScore IS NOT NULL THEN CAT_LastScore ELSE NULL END) AS DECIMAL(10,1)) 'Average COPD Assessment Test Work Last Score'
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,TherapySession_FirstDate,TherapySession_SecondDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgFirstSecond
			,CAST(AVG(DISTINCT CASE WHEN R.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD,ReferralRequestReceivedDate,TherapySession_FirstDate) ELSE NULL END) AS DECIMAL(10,1)) AS AvgRefFirst

FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON [Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
	LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE UsePathway_Flag = 'True'
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, l.[ReportingPeriodStartDate]) AND l.[ReportingPeriodStartDate]
AND IsLatest = 1
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)			
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 

)_
