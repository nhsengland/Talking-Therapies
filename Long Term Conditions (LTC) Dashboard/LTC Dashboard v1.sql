DECLARE @Period_Start DATE
DECLARE @Period_End DATE 

SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET DATEFIRST 1

PRINT @Period_Start
PRINT @Period_End

IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_LTC_Monthly]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_LTC_Monthly]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_Monthly]
SELECT 
			CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS Month
			,'Refresh' AS DataSource
			,'England' AS 'GroupType'

		-- Geographies	
			,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
			,'Total' AS Category
			,'Total' as 'Variable'

		-- Integrated Pathways
			,CASE WHEN cc.[IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
			AS 'Integrated LTC'

		-- LongTerm Conditions
			,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
			AS Term

		-- Referrals/Access/Completion
			,COUNT( DISTINCT CASE WHEN  r.CompletedTreatment_Flag = 'True' AND  r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)
			AS 'Finished Treatment - 2 or more Apps'
			,COUNT( DISTINCT CASE WHEN  r.ReferralRequestReceivedDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)
			AS 'Referrals'
			,COUNT( DISTINCT CASE WHEN  r.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)
			AS EnteringTreatment

		-- Outcome Measures
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.Recovery_Flag = 'True' THEN r.PathwayID ELSE NULL END)
			AS 'Recovery'
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.ReliableImprovement_Flag = 'True' AND r.Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END)
			AS 'Reliable Recovery'
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.NoChange_Flag = 'True' THEN r.PathwayID ELSE NULL END)
			AS 'No Change'
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.ReliableDeterioration_Flag = 'True' THEN r.PathwayID ELSE NULL END)
			AS 'Reliable Deterioration'
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.ReliableImprovement_Flag = 'True' THEN r.PathwayID ELSE NULL END)
			AS 'Reliable Improvement'
			,COUNT(DISTINCT CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)
			AS 'NotCaseness'
		
		-- Referral Types
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'A1' OR r.SourceOfReferralIAPT = 'A1') THEN r.PathwayID ELSE NULL END)
			AS	'Primary Health Care: General Medical Practitioner Practice'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'A2' OR r.SourceOfReferralIAPT = 'A2') THEN r.PathwayID ELSE NULL END)
			AS	'Primary Health Care: Health Visitor'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'A3' OR r.SourceOfReferralIAPT = 'A3') THEN r.PathwayID ELSE NULL END)
			AS	'Other Primary Health Care'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'A4' OR r.SourceOfReferralIAPT = 'A4') THEN r.PathwayID ELSE NULL END)
			AS	'Primary Health Care: Maternity Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'B1' OR r.SourceOfReferralIAPT = 'B1') THEN r.PathwayID ELSE NULL END)
			AS	'Self Referral: Self'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'B2' OR r.SourceOfReferralIAPT = 'B2') THEN r.PathwayID ELSE NULL END)
			AS	'Self Referral: Carer/Relative'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'C1' OR r.SourceOfReferralIAPT = 'C1') THEN r.PathwayID ELSE NULL END)
			AS	'Local Authority and Other Public Services: Social Services'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'C2' OR r.SourceOfReferralIAPT = 'C2') THEN r.PathwayID ELSE NULL END)
			AS	'Local Authority and Other Public Services: Education Service / Educational Establishment'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'C3' OR r.SourceOfReferralIAPT = 'C3') THEN r.PathwayID ELSE NULL END)
			AS	'Local Authority and Other Public Services: Housing Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'D1' OR r.SourceOfReferralIAPT = 'D1') THEN r.PathwayID ELSE NULL END)
			AS	'Employer'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'D2' OR r.SourceOfReferralIAPT = 'D2') THEN r.PathwayID ELSE NULL END)
			AS	'Employer: Occupational Health'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E1' OR r.SourceOfReferralIAPT = 'E1') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Police'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E2' OR r.SourceOfReferralIAPT = 'E2') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Courts'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E3' OR r.SourceOfReferralIAPT = 'E3') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Probation Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E4' OR r.SourceOfReferralIAPT = 'E4') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Prison'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E5' OR r.SourceOfReferralIAPT = 'E5') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Court Liaison and Diversion Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'E6' OR r.SourceOfReferralIAPT = 'E6') THEN r.PathwayID ELSE NULL END)
			AS	'Justice System: Youth Offending Team'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'F1' OR r.SourceOfReferralIAPT = 'F1') THEN r.PathwayID ELSE NULL END)
			AS	'Child Health: School Nurse'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'F2' OR r.SourceOfReferralIAPT = 'F2') THEN r.PathwayID ELSE NULL END)
			AS	'Child Health: Hospital-based Paediatrics'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'F3' OR r.SourceOfReferralIAPT = 'F3') THEN r.PathwayID ELSE NULL END)
			AS	'Child Health: Community-based Paediatrics'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'G1' OR r.SourceOfReferralIAPT = 'G1') THEN r.PathwayID ELSE NULL END)
			AS	'Independent sector - Medium Secure Inpatients'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'G2' OR r.SourceOfReferralIAPT = 'G2') THEN r.PathwayID ELSE NULL END)
			AS	'Independent Sector - Low Secure Inpatients'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'G3' OR r.SourceOfReferralIAPT = 'G3') THEN r.PathwayID ELSE NULL END)
			AS	'Other Independent Sector Mental Health Services'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'G4' OR r.SourceOfReferralIAPT = 'G4') THEN r.PathwayID ELSE NULL END)
			AS	'Voluntary Sector'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'H1' OR r.SourceOfReferralIAPT = 'H1') THEN r.PathwayID ELSE NULL END)
			AS	'Acute Secondary Care: Emergency Care Department'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'H2' OR r.SourceOfReferralIAPT = 'H2') THEN r.PathwayID ELSE NULL END)
			AS	'Other secondary care specialty'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'I1' OR r.SourceOfReferralIAPT = 'I1') THEN r.PathwayID ELSE NULL END)
			AS	'Temporary transfer from another Mental Health NHS Trust'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'I2' OR r.SourceOfReferralIAPT = 'I2') THEN r.PathwayID ELSE NULL END)
			AS	'Permanent transfer from another Mental Health NHS Trust'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M1' OR r.SourceOfReferralIAPT = 'M1') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Asylum Services'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M2' OR r.SourceOfReferralIAPT = 'M2') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Telephone or Electronic Access Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M3' OR r.SourceOfReferralIAPT = 'M3') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Out of Area Agency'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M4' OR r.SourceOfReferralIAPT = 'M4') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Drug Action Team / Drug Misuse Agency'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M5' OR r.SourceOfReferralIAPT = 'M5') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Jobcentre Plus'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M6' OR r.SourceOfReferralIAPT = 'M6') THEN r.PathwayID ELSE NULL END)
			AS	'Other SERVICE or agency'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M7' OR r.SourceOfReferralIAPT = 'M7') THEN r.PathwayID ELSE NULL END)
			AS	'Other: Single Point of Access Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'M8' OR r.SourceOfReferralIAPT = 'M8') THEN r.PathwayID ELSE NULL END)
			AS	'Debt agency'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'N1' OR r.SourceOfReferralIAPT = 'N1') THEN r.PathwayID ELSE NULL END)
			AS	'Stepped up from low intensity Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'N2' OR r.SourceOfReferralIAPT = 'N2') THEN r.PathwayID ELSE NULL END)
			AS	'Stepped down from high intensity Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'N4' OR r.SourceOfReferralIAPT = 'N4') THEN r.PathwayID ELSE NULL END)
			AS	'Other Improving Access to Psychological Therapies Service'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'P1' OR r.SourceOfReferralIAPT = 'P1') THEN r.PathwayID ELSE NULL END)
			AS	'Internal Referral'
			,COUNT( DISTINCT CASE WHEN r.ReferralRequestReceivedDate  BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND (r.SourceOfReferralMH = 'Q1' OR r.SourceOfReferralIAPT = 'Q1') THEN r.PathwayID ELSE NULL END)
			AS	'Mental Health Drop In Service'

		-- Waits
			,COUNT( DISTINCT CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) <=28
				THEN r.PathwayID ELSE NULL END)
			AS FirstToSecond28Days
			,COUNT( DISTINCT CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) BETWEEN 29 AND 56
				THEN r.PathwayID ELSE NULL END)
			AS FirstToSecond28To56Days
			,COUNT( DISTINCT CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) BETWEEN 57 AND 90
				THEN r.PathwayID ELSE NULL END)
			AS FirstToSecond57To90Days
			,COUNT( DISTINCT CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) > 90
				THEN r.PathwayID ELSE NULL END)
			AS FirstToSecondMoreThan90Days
			,COUNT( DISTINCT CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)
			AS FirstToSecond

		-- Appointment Types		
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '5' THEN cc.CareContactId ELSE NULL END)
			AS 'Attended on time or, if late, before the relevant professional was ready to see the patient'
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '6' THEN cc.CareContactId ELSE NULL END)
			AS 'Arrived late, after the relevant professional was ready to see the patient, but was seen'
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '7' THEN cc.CareContactId ELSE NULL END)
			AS 'Patient arrived late and could not be seen'
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '2' THEN cc.CareContactId ELSE NULL END)
			AS 'Appointment cancelled by, or on behalf of the patient'
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '3' THEN cc.CareContactId ELSE NULL END)
			AS 'Did not attend, no advance warning given'
			,COUNT( DISTINCT CASE WHEN cc.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND cc.AttendOrDNACode = '4' THEN cc.CareContactId ELSE NULL END)
			AS 'Appointment cancelled or postponed by the health care provider'
INTO [MHDInternal].[DASHBOARD_TTAD_LTC_Monthly]
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON ltc.[Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1

		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId 

WHERE r.UsePathway_Flag = 'True'
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -36, @Period_Start) AND @Period_Start --For monthly refresh the offset should be 0 to get the latest month only
		AND l.IsLatest = 1
GROUP BY CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE)
		,CASE WHEN cc.[IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END
		,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

------------------------------------------------
------------------------------------------------
---Employment Support Appointment Count
--There is currently an issue with EmploymentSupport_Count field in IDS101referral table so we are calculating the number of employment support appointments in this table
--This is based on the criteria specified for this field in the Technical Output Specification
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
SELECT  
    r.PathwayID
	,COUNT(DISTINCT CASE WHEN c.CareContDate BETWEEN l.ReportingPeriodStartDate and l.ReportingPeriodEndDate THEN c.CareContactID ELSE NULL END) AS Count_EmpSupp
INTO [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
FROM [mesh_IAPT].IDS101referral r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
LEFT JOIN [mesh_IAPT].[IDS201carecontact] c ON c.RecordNumber=r.RecordNumber AND r.[UniqueSubmissionID] = c.[UniqueSubmissionID] AND r.[AuditId] = c.[AuditId]
LEFT JOIN [mesh_IAPT].[IDS202careactivity] ca on c.PathwayID = ca.PathwayID and c.RecordNumber=ca.RecordNumber and c.CareContactID=ca.CareContactID and c.AuditId=ca.AuditId 
LEFT JOIN [mesh_IAPT].[IDS004empstatus] e ON r.RecordNumber=e.RecordNumber AND r.AuditId=e.AuditId

WHERE l.IsLatest = 1 
AND (c.AttendOrDNACode IN (5,6) OR c.PlannedCareContIndicator='N') 
AND 
(
	(c.AppType<>06 AND r.ReferralRequestReceivedDate<= c.CareContDate 
	AND (c.CareContDate<=r.ServDischDate OR (r.ServDischDate IS NULL AND c.CareContDate<=l.ReportingPeriodEndDate))
	AND ca.CodeProcAndProcStatus='1098051000000103'
	)
OR
	(c.AppType=06 AND c.CareContDate>r.ServDischDate
	AND ca.CodeProcAndProcStatus='1098051000000103'
	)
OR
	((c.AppType=10 OR (ca.CodeProcAndProcStatus='1098051000000103' AND c.AppType=06)) AND 
	r.ReferralRequestReceivedDate<=c.CareContDate 
	AND (c.CareContDate<=e.EmpSupportDischargeDate OR (e.EmpSupportDischargeDate IS NULL AND c.CareContDate<=l.ReportingPeriodEndDate))
	)
)
GROUP BY r.PathwayID

--Averages Base
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS Month
	,r.PathwayID
    ,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICBCode'
    ,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub-ICBName'
    ,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICBCode'
    ,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICBName'
    ,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
    ,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
    ,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'ProviderCode'
    ,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'ProviderName'

	,CASE WHEN cc.[IAPTLTCServiceInd] = 'Y' THEN 'Integrated' ELSE 'Non-Integrated' END AS 'Integrated LTC'
	,CASE WHEN s2.term IS NOT NULL THEN s2.term ELSE 'Not Stated' END AS Term
			
--Appointments
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN ec.Count_EmpSupp ELSE NULL END AS 'EA Apps'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.TreatmentCareContact_Count ELSE NULL END AS 'Care Contacts Apps'
			
--WSAS Score
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_Work_FirstScore IS NOT NULL THEN r.WASAS_Work_FirstScore ELSE NULL END
	AS 'WSAS Work First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_Work_LastScore IS NOT NULL THEN r.WASAS_Work_LastScore ELSE NULL END
	AS 'WSAS Work Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_HomeManagement_FirstScore IS NOT NULL THEN r.WASAS_HomeManagement_FirstScore ELSE NULL END
	AS 'WSAS Home Management First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_HomeManagement_LastScore IS NOT NULL THEN r.WASAS_HomeManagement_LastScore ELSE NULL END
	AS 'WSAS Home Management Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_PrivateLeisureActivities_FirstScore IS NOT NULL THEN r.WASAS_PrivateLeisureActivities_FirstScore ELSE NULL END
	AS 'WSAS Private Leisure Activities First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_PrivateLeisureActivities_LastScore IS NOT NULL THEN r.WASAS_PrivateLeisureActivities_LastScore ELSE NULL END
	AS 'WSAS Private Leisure Activities Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_Relationships_FirstScore IS NOT NULL THEN r.WASAS_Relationships_FirstScore ELSE NULL END
	AS 'WSAS Relationships First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_Relationships_LastScore IS NOT NULL THEN r.WASAS_Relationships_LastScore ELSE NULL END
	AS 'WSAS Relationships Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_SocialLeisureActivities_FirstScore IS NOT NULL THEN r.WASAS_SocialLeisureActivities_FirstScore ELSE NULL END
	AS 'WSAS Social Leisure Activities First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.WASAS_SocialLeisureActivities_LastScore IS NOT NULL THEN r.WASAS_SocialLeisureActivities_LastScore ELSE NULL END
	AS 'WSAS Social Leisure Activities Last Score'


--Inventory Scores
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.DDS_FirstScore IS NOT NULL THEN r.DDS_FirstScore ELSE NULL END
	AS 'Diabetes Distress Score Work First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.DDS_LastScore IS NOT NULL THEN r.DDS_LastScore ELSE NULL END
	AS 'Diabetes Distress Score Work Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.BPI_FirstScore IS NOT NULL THEN r.BPI_FirstScore ELSE NULL END
	AS 'Brief Pain Inventory Work First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.BPI_LastScore IS NOT NULL THEN r.BPI_LastScore ELSE NULL END
	AS 'Brief Pain Inventory Work Last Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CAT_FirstScore IS NOT NULL THEN r.CAT_FirstScore ELSE NULL END
	AS 'COPD Assessment Test Work First Score'
	,CASE WHEN r.CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND r.CAT_LastScore IS NOT NULL THEN r.CAT_LastScore ELSE NULL END
	AS 'COPD Assessment Test Work Last Score'

--Wait Times
	,CASE WHEN r.TherapySession_SecondDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD, r.TherapySession_FirstDate, r.TherapySession_SecondDate) ELSE NULL END
	AS FirstSecond
	,CASE WHEN r.TherapySession_FirstDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN DATEDIFF(DD, r.ReferralRequestReceivedDate, r.TherapySession_FirstDate) ELSE NULL END
	AS RefFirst

INTO [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
FROM	[mesh_IAPT].[IDS101Referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [mesh_IAPT].[IDS602longtermcondition] ltc ON r.recordnumber = ltc.recordnumber AND r.AuditID = ltc.AuditId AND r.UniqueSubmissionID = ltc.UniqueSubmissionID
		LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD_1] s2 ON ltc.[Validated_LongTermConditionCode] = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		---------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId

		LEFT JOIN [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount] ec ON ec.PathwayID=r.PathwayID
		---------------------------
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cd ON r.OrgIDComm = cd.Org_Code COLLATE database_default
        LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cd.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

WHERE r.UsePathway_Flag = 'True'
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start --For monthly refresh the offset should be 0 to get the latest month only
		AND l.IsLatest = 1

----------------------
--Averages Final Table

--National, split by LTC Integrated and Non-Integrated, split by Term
--IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,CAST('England' AS VARCHAR(255)) AS GroupType
	,CAST('England' AS VARCHAR(255)) AS Code
	,CAST('England' AS VARCHAR(255)) AS 'Name'
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('All ICBs' AS VARCHAR(255)) AS ICB
	,[Integrated LTC]
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
--INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[Integrated LTC]
	,Term

--Region, split by LTC Integrated and Non-Integrated, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Region' AS GroupType
	,RegionCodeComm AS Code
	,RegionNameComm AS 'Name'
	,RegionNameComm AS Region
	,'All ICBs'	AS ICB
	,[Integrated LTC]
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,RegionCodeComm
	,RegionNameComm
	,[Integrated LTC]
	,Term

--ICB, split by LTC Integrated and Non-Integrated, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'ICB' AS GroupType
	,ICBCode AS Code
	,ICBName AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,[Integrated LTC]
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,ICBCode
	,ICBName
	,RegionNameComm
	,[Integrated LTC]
	,Term

--Sub-ICB, split by LTC Integrated and Non-Integrated, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Sub-ICB' AS GroupType
	,[Sub-ICBCode] AS Code
	,[Sub-ICBName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,[Integrated LTC]
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ICBName
	,RegionNameComm
	,[Integrated LTC]
	,Term

--Provider, split by LTC Integrated and Non-Integrated, split by Term

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Provider' AS GroupType
	,[ProviderCode] AS Code
	,[ProviderName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,[Integrated LTC]
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[ProviderCode]
	,[ProviderName]
	,ICBName
	,RegionNameComm
	,[Integrated LTC]
	,Term

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--National, All Pathways, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'England' AS GroupType
	,'England' AS Code
	,'England' AS 'Name'
	,'All Regions' AS Region
	,'All ICBs' AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,Term

--Region, All Pathways, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Region' AS GroupType
	,RegionCodeComm AS Code
	,RegionNameComm AS 'Name'
	,RegionNameComm AS Region
	,'All ICBs'	AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,RegionCodeComm
	,RegionNameComm
	,Term

--ICB, All Pathways, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'ICB' AS GroupType
	,ICBCode AS Code
	,ICBName AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,ICBCode
	,ICBName
	,RegionNameComm
	,Term

--Sub-ICB, All Pathways, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Sub-ICB' AS GroupType
	,[Sub-ICBCode] AS Code
	,[Sub-ICBName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ICBName
	,RegionNameComm
	,Term

--Provider, All Pathways, split by Term
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Provider' AS GroupType
	,[ProviderCode] AS Code
	,[ProviderName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,[Term]
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[ProviderCode]
	,[ProviderName]
	,ICBName
	,RegionNameComm
	,Term

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
--National, All Pathways, All Terms
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'England' AS GroupType
	,'England' AS Code
	,'England' AS 'Name'
	,'All Regions' AS Region
	,'All ICBs' AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,'All Terms' AS Term
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]

--Region, All Pathways, All Terms
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Region' AS GroupType
	,RegionCodeComm AS Code
	,RegionNameComm AS 'Name'
	,RegionNameComm AS Region
	,'All ICBs'	AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,'All Terms' AS Term
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,RegionCodeComm
	,RegionNameComm

--ICB, All Pathways, All Terms
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'ICB' AS GroupType
	,ICBCode AS Code
	,ICBName AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,'All Terms' AS Term
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,ICBCode
	,ICBName
	,RegionNameComm

--Sub-ICB, All Pathways, All Terms
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Sub-ICB' AS GroupType
	,[Sub-ICBCode] AS Code
	,[Sub-ICBName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,'All Terms' AS Term
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[Sub-ICBCode]
	,[Sub-ICBName]
	,ICBName
	,RegionNameComm

--Provider, All Pathways, All Terms
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_LTC_MonthlyAverages]
SELECT
	[Month]
	,'Refresh' AS DataSource
	,'Provider' AS GroupType
	,[ProviderCode] AS Code
	,[ProviderName] AS 'Name'
	,RegionNameComm AS Region
	,ICBName AS ICB
	,'All Pathways' AS 'Integrated LTC'
	,'All Terms' AS Term
	,ROUND(AVG(CAST([EA Apps] AS FLOAT)),1) AS 'Average EA Apps'
	,ROUND(AVG(CAST([Care Contacts Apps] AS FLOAT)),1) AS 'Average Care Contacts Apps'
	,ROUND(AVG(CAST([WSAS Work First Score] AS FLOAT)),1) AS 'Average WSAS Work First Score'
	,ROUND(AVG(CAST([WSAS Work Last Score] AS FLOAT)),1) AS 'Average WSAS Work Last Score'
	,ROUND(AVG(CAST([WSAS Home Management First Score] AS FLOAT)),1) AS 'Average WSAS Home Management First Score'
	,ROUND(AVG(CAST([WSAS Home Management Last Score] AS FLOAT)),1) AS 'Average WSAS Home Management Last Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Private Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Private Leisure Activities Last Score'
	,ROUND(AVG(CAST([WSAS Relationships First Score] AS FLOAT)),1) AS 'Average WSAS Relationships First Score'
	,ROUND(AVG(CAST([WSAS Relationships Last Score] AS FLOAT)),1) AS 'Average WSAS Relationships Last Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities First Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities First Score'
	,ROUND(AVG(CAST([WSAS Social Leisure Activities Last Score] AS FLOAT)),1) AS 'Average WSAS Social Leisure Activities Last Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work First Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work First Score'
	,ROUND(AVG(CAST([Diabetes Distress Score Work Last Score] AS FLOAT)),1) AS 'Average Diabetes Distress Score Work Last Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work First Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work First Score'
	,ROUND(AVG(CAST([Brief Pain Inventory Work Last Score] AS FLOAT)),1) AS 'Average Brief Pain Inventory Work Last Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work First Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work First Score'
	,ROUND(AVG(CAST([COPD Assessment Test Work Last Score] AS FLOAT)),1) AS 'Average COPD Assessment Test Work Last Score'
	,ROUND(AVG(CAST([FirstSecond] AS FLOAT)),1) AS 'AvgFirstSecond'
	,ROUND(AVG(CAST([RefFirst] AS FLOAT)),1) AS 'AvgRefFirst'
FROM [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
GROUP BY
	[Month]
	,[ProviderCode]
	,[ProviderName]
	,ICBName
	,RegionNameComm

--Drop Temporary Table
DROP TABLE [MHDInternal].[TEMP_TTAD_LTC_MonthlyBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_EmpSupp_EmpSuppCount]
