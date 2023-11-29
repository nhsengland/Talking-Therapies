---------Outcome Measures For Appointment Dosage of those finishing a Course of Treatment Within the Period------------

------------------------Breakdown by Months, Geographies and Presenting Complaints-------------------------------------

-----------------------SET TIME PERIOD------------------------------------			
DECLARE @Period_Start DATE			
DECLARE @Period_End DATE 			
			
SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])			
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])			
SET DATEFIRST 1			
			
PRINT @Period_Start			
PRINT @Period_End			
			
-------------------------------------------------------------------------	
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]
SELECT 
    DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month		
    ,'England' AS 'GroupType'
    ,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
    ,'Problem Descriptor' AS Category	
    ,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR [PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
                WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR [PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
                WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR [PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
                WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR [PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
                WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR [PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
                ELSE 'Other' 
        END AS 'Variable'
    ,'Refresh' AS DataSource			
    ,TreatmentCareContact_Count			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Finished Treatment - 2 or more Apps'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Recovery'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  NoChange_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'No Change'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Deterioration'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND  ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Reliable Improvement'			
    ,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'NotCaseness'			

INTO [MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]
FROM [mesh_IAPT].[IDS101referral] r			
			
INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber					
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId	

--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
    AND ch.Effective_To IS NULL
 
LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
    AND ph.Effective_To IS NULL	
			
WHERE UsePathway_Flag = 'True' 			
        AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start			
        AND IsLatest = 1 
        AND [CompletedTreatment_Flag] = 1			
			
			
GROUP BY  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar),TreatmentCareContact_Count,
            CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR [PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
                WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR [PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
                WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR [PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
                WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR [PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
                WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR [PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
                WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR [PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
                ELSE 'Other' 
        END
			,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END
			,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
			,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
			,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
			,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
GO			
