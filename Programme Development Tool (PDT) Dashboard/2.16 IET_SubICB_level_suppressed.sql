-- Refresh updates for:
----------------------------------------------------------------------
-- [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FSplit]
-- [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages] 
-- [MHDInternal].[DASHBOARD_TTAD_PDT_IETAcuteReferrals]

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DELETE MAX(Month)s -----------------------------------------------------------------------------------------------------------------------------------------

DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FSplit] WHERE [Month] = (SELECT MAX(CAST([Month] AS DATE)) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FSplit])
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages] WHERE [Month] = (SELECT MAX(CAST([Month] AS DATE)) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages])
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IETAcuteReferrals] WHERE [Month] = (SELECT MAX(CAST([Month] AS DATE)) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_IETAcuteReferrals])

----------------------------------------------------------------------------------------------------------------------------

DECLARE @Offset INT = 0

DECLARE @Period_Start DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @Period_End DATE = (SELECT eomonth(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

PRINT @Period_Start
PRINT @Period_End

---- CREATE BASE CARE CONTACT COUNTS TABLE ----------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_CareContactBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactBase]

SELECT DISTINCT 

		MAX(c.AUDITID) AS AuditID
		,[PathwayID]
		,COUNT (distinct(case when c.ConsMechanism IN ('01', '1', '1 ', ' 1') OR c.ConsMediumUsed IN ('01', '1', '1 ', ' 1') then c.Unique_CareContactID END )) as 'Face to face communication'
		,COUNT (distinct(case when c.ConsMechanism IN ('02', '2', '2 ', ' 2','03', '3', '3 ', ' 3','04', '4', '4 ', ' 4','05', '5', '5 ', ' 5','06', '6', '6 ', ' 6','98', '98 ', ' 98','08', '8', '8 ', ' 8','09', '9', '9 ', ' 9','10', '10', '10 ', ' 10','11', '11', '11 ', ' 11','12', '12', '12 ', ' 12','13', '13', '13 ', ' 13') OR c.ConsMediumUsed IN ('02', '2', '2 ', ' 2','03', '3', '3 ', ' 3','04', '4', '4 ', ' 4','05', '5', '5 ', ' 5','06', '6', '6 ', ' 6','98', '98 ', ' 98','08', '8', '8 ', ' 8','09', '9', '9 ', ' 9','10', '10', '10 ', ' 10','11', '11', '11 ', ' 11','12', '12', '12 ', ' 12','13', '13', '13 ', ' 13') then c.Unique_CareContactID END )) as 'Other'

INTO [MHDInternal].[TEMP_TTAD_PDT_CareContactBase]

FROM	[mesh_IAPT].[IDS201carecontact] c
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.AuditId = l.AuditId

WHERE ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05') and IsLatest = 1

GROUP BY [PathwayID]

-----------------------------------------------------------------------------------------------------------------------------------------------
SET ANSI_WARNINGS OFF -------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FSplit]

SELECT * FROM

(

SELECT  DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Ethnicity' AS 'Category'
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN  'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END AS 'Variable'
		,'Refresh' AS DataSource
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL) then 'Non-F2F' END as 'F2F status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		----------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactBase] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId  
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL


WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN  'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END

UNION -----------------------------------------------------------------

SELECT  DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Age' AS 'Category'
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown'
			END AS 'Variable'
		,'Refresh' AS 'DataSource'
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END as 'F2F status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		----------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactBase] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId  
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start

GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unknown'
			END
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END

UNION -----------------------------------------------------------------

SELECT  DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS 'Month'
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Gender' AS 'Category'
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' 
			END AS 'Variable'
		,'Refresh' AS 'DataSource'
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END as 'F2F status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		----------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactBase] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId  
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start

GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
			WHEN Gender IN ('2','02') THEN 'Female'
			WHEN Gender IN ('9','09') THEN 'Indeterminate'
			WHEN Gender NOT IN ('1','01','2','02','9','09') OR Gender IS NULL THEN 'Unspecified' END
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END

UNION ----------------------------------------------------------------- 

SELECT  DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Problem Descriptor' AS Category
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END AS 'Variable'
		,'Refresh' AS DataSource
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END as 'F2F status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		----------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactBase] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId  
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start

GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN PrimaryPresentingComplaint = 'Depression' THEN 'F32 or F33 - Depression'
			WHEN PrimaryPresentingComplaint = 'Unspecified' THEN 'Unspecified'
			WHEN PrimaryPresentingComplaint = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN PrimaryPresentingComplaint = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN PrimaryPresentingComplaint = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN PrimaryPresentingComplaint = 'Anxiety and stress related disorders (Total)' AND SecondaryPresentingComplaint IS NULL THEN 'No Code' 
			ELSE 'Other' END
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END

UNION ----------------------------------------------------------------- 

SELECT  DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'IMD' AS Category
		,CAST([IMD_Decile] AS Varchar) AS 'Variable'
		,'Refresh' AS DataSource
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL) then 'Non-F2F' END as 'F2F status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		----------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CareContactBase] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId  
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CAST([IMD_Decile] AS Varchar)
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END
		,case when [Face to face communication] > 0 then 'F2F'
			when ([Face to face communication] = 0 OR [Face to face communication] IS NULL)  then 'Non-F2F' END
)_

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FSplit]'

-----------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_IETAcuteReferrals]

SELECT	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Refresh' AS DataSource
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END as 'IET status'
		,COUNT( DISTINCT CASE WHEN Recovery_Flag = 'True' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountRecovered'
		,COUNT( DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountFinishedTreatment'
		,COUNT( DISTINCT CASE WHEN NotCaseness_Flag = 'True'  AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate THEN r.PathwayID ELSE NULL END) AS 'CountNotCaseness'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		INNER JOIN [MHDInternal].[PreProc_Referral] ppr ON mpi.[Pseudo_NHS_Number_NCDR] = ppr.[Der_Pseudo_NHS_Number] AND ppr.ReferralRequestReceivedDate >= r.ServDischDate
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,case when r.[InternetEnabledTherapy_Count] > 0 then 'IET'
			when (r.[InternetEnabledTherapy_Count] = 0 OR r.[InternetEnabledTherapy_Count] IS NULL) then 'Non-IET' END

-----------------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages]'


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages] ---------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages]

SELECT * FROM

(

SELECT	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'National' AS 'OrgType'
		,'England' AS 'OrgCode'
		,'England' AS 'OrgName'
		,'All' AS 'Region Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,AVG(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) AS AvgTherapistDurIncIET
		,AVG(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) AS AvgTherapistDurNoIET
		,AVG(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) AS AvgIETTherapistDurIncCareContact
		,AVG(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) AS AvgIETTherapistDurNoCareContact
  
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId AND ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05')
		LEFT JOIN [mesh_IAPT].[IDS205internettherlog] iet ON cc.[AuditId] = iet.[AuditId] AND cc.ServiceRequestId = iet.ServiceRequestId
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.[LSOA] = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
	
UNION ----------------------------------------------------------------- 

SELECT	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'Regional' AS 'OrgType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'OrgCode'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'OrgName'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurIncIET
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurNoIET
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurIncCareContact
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurNoCareContact
  
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId AND ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05')
		LEFT JOIN [mesh_IAPT].[IDS205internettherlog] iet ON cc.[AuditId] = iet.[AuditId] AND cc.ServiceRequestId = iet.ServiceRequestId
		-----------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 

UNION -----------------------------------------------------------------

SELECT	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'STP' AS 'OrgType'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurIncIET
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurNoIET
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurIncCareContact
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurNoCareContact
  
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId AND ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05')
		LEFT JOIN [mesh_IAPT].[IDS205internettherlog] iet ON cc.[AuditId] = iet.[AuditId] AND cc.ServiceRequestId = iet.ServiceRequestId
		-----------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code]

 WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END

UNION -----------------------------------------------------------------

SELECT	DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar) AS Month 
		,'CCG' AS 'OrgType'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'OrgCode'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'OrgName'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurIncIET
		,CASE WHEN COUNT(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [DurationIntEnabledTher] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [ClinContDurOfCareCont] ELSE NULL END) END AS AvgTherapistDurNoIET
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NOT NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurIncCareContact
		,CASE WHEN COUNT(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) < 5 THEN NULL ELSE AVG(CASE WHEN [ClinContDurOfCareCont] IS NULL AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate  THEN [DurationIntEnabledTher] ELSE NULL END) END AS AvgIETTherapistDurNoCareContact
  
FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] cc ON r.PathwayID = cc.PathwayID AND cc.AuditId = l.AuditId AND ([AttendOrDNACode] in ('5','6') or PlannedCareContIndicator = 'N') AND AppType IN ('01','02','03','05')
		LEFT JOIN [mesh_IAPT].[IDS205internettherlog] iet ON cc.[AuditId] = iet.[AuditId] AND cc.ServiceRequestId = iet.ServiceRequestId
		-----------------------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		-----------------------------------------
		LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] IMD ON mpi.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @Period_Start) AND @Period_Start
		
GROUP BY DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS varchar)
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
)_

-- Drop Temporary Table --------------------------------------

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CareContactBase]

----------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_IET_F2FAverages]'
