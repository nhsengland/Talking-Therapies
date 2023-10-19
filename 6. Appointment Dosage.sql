
-- CCG to Region

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_CCGtoRegion]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_CCGtoRegion]
SELECT DISTINCT 
    CCG21 AS 'CCG Code'
    ,CCG20merged AS CCG20merged
    ,CASE WHEN CCG21 = 'M1J4Y' THEN 'NHS BEDFORDSHIRE, LUTON AND MILTON KEYNES CCG'
        WHEN CCG21 = 'D9Y0V' THEN 'NHS HAMPSHIRE, SOUTHAMPTON AND ISLE OF WIGHT CCG'
        WHEN CCG21 = 'A3A8R' THEN 'NHS NORTH EAST LONDON CCG'
        WHEN CCG21 = 'W2U3Z' THEN 'NHS NORTH WEST LONDON CCG'
        WHEN CCG21 = 'M2L0M' THEN 'NHS SHROPSHIRE, TELFORD AND WREKIN CCG'
        WHEN CCG21 = 'D2P2L' THEN 'NHS BLACK COUNTRY AND WEST BIRMINGHAM CCG'
        WHEN CCG21 = 'B2M3M' THEN 'NHS COVENTRY AND WARWICKSHIRE CCG'
        WHEN CCG21 = 'X2C4Y' THEN 'NHS KIRKLEES CCG'
        WHEN CCG21 = 'D4U1Y' THEN 'NHS FRIMLEY CCG'
        ELSE s.CCG_Name END 
    AS 'CCG Name'
    ,s.STP_Code AS 'STP Code'
    ,s.STP_Name AS 'STP Name'
    ,[Region Code]
    ,Region_Name AS 'Region Name' 
INTO [MHDInternal].[TEMP_TTAD_PDT_CCGtoRegion]
FROM (
    SELECT CCG21, CCG20merged,
    CASE WHEN CCG21 IN ('W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','93C','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','72Q','36L') THEN 'Y56'							
        WHEN CCG21 IN ('11N','15N','11X','15C','92G','11J','11M')	THEN 'Y58'																			
        WHEN CCG21 IN ('91Q','D4U1Y','D4U1Y','D4U1Y','D9Y0V','D9Y0V','D9Y0V','10R','D9Y0V','D9Y0V','D9Y0V','10Q','15A','14Y','92A','09D','97R','70F') THEN 'Y59'										
        WHEN CCG21 IN ('71E','52R','04Y','05D','05G','05Q','05V','05W','M2L0M','M2L0M','15M','03W','04C','04V','D2P2L','D2P2L','D2P2L','D2P2L','15E','B2M3M','B2M3M','B2M3M','18C','78H') THEN 'Y60'				
        WHEN CCG21 IN ('06H','26A','06L','06T','07K','M1J4Y','M1J4Y','M1J4Y','06K','06N','07H','99E','99F','06Q','99G','07G') THEN 'Y61'												
        WHEN CCG21 IN ('00T','00V','01D','00Y','01G','01W','01Y','02A','02H','14L','01F','01J','99A','01T','01V','01X','02E','12F','27D','00Q','00R','00X','01A','02G','02M','01E','01K') THEN 'Y62'	
        WHEN CCG21 IN ('02P','02Q','02X','03L','03N','99C','00L','00N','00P','13T','01H','84H','16C','02Y','03F','03H','03K','03Q','42D','02T','X2C4Y','X2C4Y','03R','15F','36J') THEN 'Y63'	
        ELSE NULL END AS 'Region Code'	

        FROM [MHDInternal].[REFERENCE_CCG_2020_Lookup]
)_
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ON [Region Code] = Region_Code 
LEFT JOIN [Internal_Reference].[CCGToSTP] s ON CCG20merged = s.CCG_Code
WHERE CCG20merged IS NOT NULL

-----------------------------------------------------------			
DECLARE @Period_Start DATE			
DECLARE @Period_End DATE 			
			
SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])			
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])			
SET DATEFIRST 1			
			
PRINT @Period_Start			
PRINT @Period_End			
			
--Base Table for Paired ADSM			
-- Do not alter these time frames below			
  DECLARE  @Period_End2 DATE 			
 SET @Period_End2 = (SELECT eomonth(DATEADD(MONTH,+1,MAX(@Period_End))) FROM [mesh_IAPT].[IDS000header])			
 PRINT @Period_End2			
			
  DECLARE  @Period_Start2 DATE 			
 SET @Period_Start2 = (SELECT DATEADD(MONTH,+1,MAX(@Period_Start)) FROM [mesh_IAPT].[IDS000header])			
 PRINT @Period_Start2			
			
 IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_ADSM]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_ADSM]			
 SELECT * 
 INTO [MHDInternal].[TEMP_TTAD_PDT_ADSM]
 FROM(			
    SELECT pc.* 			
    FROM [mesh_IAPT].[IDS603presentingcomplaints] pc			
    INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND pc.AuditId = l.AuditId AND pc.Unique_MonthID = l.Unique_MonthID			
    WHERE 			
    IsLatest = 1 AND [ReportingPeriodStartDate] <= @Period_End	

    UNION

    SELECT pc.* 			
    FROM [mesh_IAPT].[IDS603presentingcomplaints] pc			
    INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND pc.AuditId = l.AuditId AND pc.Unique_MonthID = l.Unique_MonthID			
    WHERE File_Type = 'Primary' 
    AND [ReportingPeriodStartDate] BETWEEN @Period_Start2 AND @Period_End2			
)_			
			
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_PresComp]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_PresComp]			
SELECT DISTINCT 
    pc.PathwayID
    ,Validated_PresentingComplaint			
    ,row_number() over(partition by pc.PathwayID order by case when Validated_PresentingComplaint is null then 2 else 1 end			
    ,PresCompCodSig, PresCompDate desc, UniqueID_IDS603 desc) as rank			
INTO [MHDInternal].[TEMP_TTAD_PDT_PresComp]			
FROM [MHDInternal].[TEMP_TTAD_PDT_ADSM]	 pc	
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON pc.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND pc.AuditId = l.AuditId AND pc.Unique_MonthID = l.Unique_MonthID			

-------------------------------------------------------------------------	
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]
--INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_AppointmentDosage]
SELECT 
    DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS Month		
    ,'England' AS 'GroupType'
    ,[Region Code] AS 'Region Code'
    ,[Region Name] AS 'Region Name'
    ,c.CCG21 AS 'CCG Code'
    ,[CCG Name] AS 'CCG Name'
    ,r.OrgID_Provider AS 'Provider Code'
    ,o1.Organisation_Name AS 'Provider Name'
    ,[STP Code] AS 'STP Code'
    ,[STP Name] AS 'STP Name'	
    ,'Problem Descriptor' AS Category	
    ,CASE WHEN [PresentingComplaintHigherCategory] = 'Depression' THEN 'F32 or F33 - Depression'
        WHEN [PresentingComplaintHigherCategory] = 'Unspecified' THEN 'Unspecified'
        WHEN [PresentingComplaintHigherCategory] = 'Other recorded problems' THEN 'Other recorded problems'
        WHEN [PresentingComplaintHigherCategory] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
        WHEN [PresentingComplaintHigherCategory] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
        WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] IS NULL THEN 'No Code' 
        ELSE 'Other' END 
    AS 'Variable'
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
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] o1 ON r.OrgID_Provider = o1.Organisation_Code
LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG
LEFT JOIN [MHDInternal].[TEMP_TTAD_PDT_CCGtoRegion] s ON c.CCG21 = s.[CCG Code]		
			
WHERE UsePathway_Flag = 'True' 			
AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start			
AND IsLatest = 1 AND [CompletedTreatment_Flag] = 1			
			
			
GROUP BY  DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar),TreatmentCareContact_Count,CASE WHEN [PresentingComplaintHigherCategory] = 'Depression' THEN 'F32 or F33 - Depression'			
			WHEN [PresentingComplaintHigherCategory] = 'Unspecified' THEN 'Unspecified'
			WHEN [PresentingComplaintHigherCategory] = 'Other recorded problems' THEN 'Other recorded problems'
			WHEN [PresentingComplaintHigherCategory] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
			WHEN [PresentingComplaintHigherCategory] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = '83482000 Body Dysmorphic Disorder' THEN '83482000 Body Dysmorphic Disorder'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F400 - Agoraphobia' THEN 'F400 - Agoraphobia'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F401 - Social phobias' THEN 'F401 - Social Phobias'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F402 - Specific (isolated) phobias' THEN 'F402 care- Specific Phobias'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F410 - Panic disorder [episodic paroxysmal anxiety' THEN 'F410 - Panic Disorder'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F411 - Generalised Anxiety Disorder' THEN 'F411 - Generalised Anxiety'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F412 - Mixed anxiety and depressive disorder' THEN 'F412 - Mixed Anxiety'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F42 - Obsessive-compulsive disorder' THEN 'F42 - Obsessive Compulsive'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F431 - Post-traumatic stress disorder' THEN 'F431 - Post-traumatic Stress'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'F452 Hypochondriacal Disorders' THEN 'F452 - Hypochondrial disorder'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] = 'Other F40-F43 code' THEN 'Other F40 to 43 - Other Anxiety'
			WHEN [PresentingComplaintHigherCategory] = 'Anxiety and stress related disorders (Total)' AND [PresentingComplaintLowerCategory] IS NULL THEN 'No Code' 
			ELSE 'Other' END,
			[Region Code], [Region Name], c.CCG21 ,[CCG Name] ,r.OrgID_Provider ,o1.Organisation_Name ,[STP Code] ,[STP Name]
GO			
