SET ANSI_WARNINGS ON
SET DATEFIRST 1
SET NOCOUNT ON

-----------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_CareContactMethod_RankedApps]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_CareContactMEthod_RankedApps]

SELECT * INTO [MHDInternal].[TEMP_TTAD_CareContactMethod_RankedApps] FROM

(

SELECT	[Care Contact Patient Therapy Mode]
		,[PathwayID]
		,[ReferralRequestReceivedDate]
		,ROW_NUMBER()OVER(PARTITION BY PathwayID,ReferralRequestReceivedDate ORDER BY Apts DESC) AS 'RowID'
		,[Apts]

FROM (

SELECT	case when CareContPatientTherMode in ('1','01') then 'Individual patient'
			when CareContPatientTherMode in ('2','02') then 'Couple'
			when CareContPatientTherMode in ('3','03') then 'Group Therapy'
			ELSE 'Other' END as 'Care Contact Patient Therapy Mode'
		,r.PathwayID
		,ReferralRequestReceivedDate
		,COUNT(distinct CASE WHEN AttendOrDNACode IN ('5','6') AND APPTYPE IN ('02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '05', '5', '5 ', ' 5') THEN Unique_CareContactID ELSE NULL END) as 'Apts'

FROM    [mesh_IAPT].[IDS101referral] r
		------------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID
		------------------------------
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]

GROUP BY case when CareContPatientTherMode in ('1','01') then 'Individual patient'
			when CareContPatientTherMode in ('2','02') then 'Couple'
			when CareContPatientTherMode in ('3','03') then 'Group Therapy'
			ELSE 'Other' END
		,r.PathwayID
		,ReferralRequestReceivedDate
	)_
)__
 
WHERE RowID = 1

-----------------------------------------------------------------------------------------------------------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

SELECT DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,'Refresh' AS DataSource
		,[Care Contact Patient Therapy Mode]
		,r.PathwayID
		,r.ReferralRequestReceivedDate
		,CompletedTreatment_Flag
		,Recovery_Flag
		,ReliableImprovement_Flag
		,NotCaseness_Flag
		,CAST(DATEDIFF(DD,r.ReferralRequestReceivedDate,TherapySession_FirstDate) AS FLOAT) AS 'FirstTreatmentWait'
		,CAST(SUM(a.Apts) AS FLOAT) AS Apts 

INTO [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IDS000header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [MHDInternal].[TEMP_TTAD_CareContactMEthod_RankedApps] a ON r.PathwayID = a.PathwayID AND r.ReferralRequestReceivedDate = a.ReferralRequestReceivedDate
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND CompletedTreatment_Flag = 'TRUE' 
		AND ServDischDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate]
		AND h.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @PeriodStart) AND @PeriodStart	

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) 
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,r.[PathwayID]
		,[Care Contact Patient Therapy Mode]
		,r.[ReferralRequestReceivedDate]
		,[TherapySession_FirstDate]
		,[CompletedTreatment_Flag]
		,[Recovery_Flag]
		,[ReliableImprovement_Flag]
		,[NotCaseness_Flag]

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSERT ----------------------------------------------------------------------------------------------------------------------------------------------------- 

 INSERT INTO [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]

SELECT * FROM (

SELECT  Month
		,'CCG' AS OrgType
		,[CCG Code] AS OrgCode
		,[CCG Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,COUNT(DISTINCT PathwayID) AS FinishedTreatment
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END)
        -COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END) = 0 THEN NULL
        WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) = 0 THEN NULL 
        
		ELSE 

        (CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND  Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) AS float)
        /(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END) AS float)
        -CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

GROUP BY Month
		,[CCG Code]
		,[CCG Name]
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]

UNION --------------------------------------------------------

SELECT   Month
		,'STP' AS OrgType
		,[STP Code] AS OrgCode
		,[STP Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,COUNT(DISTINCT PathwayID) AS FinishedTreatment
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END)
        -COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END) = 0 THEN NULL
        WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) = 0 THEN NULL 
        
		ELSE 

        (CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND  Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) AS float)
        /(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END) AS float)
        -CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

GROUP BY Month
		,[STP Code]
		,[STP Name]
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]

UNION --------------------------------------------------------

SELECT   Month
		,'Region' AS OrgType
		,[Region Code] AS OrgCode
		,[Region Name] AS OrgName
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]
		,COUNT(DISTINCT PathwayID) AS 'FinishedTreatment'
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END)
        -COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END) = 0 THEN NULL
        WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) = 0 THEN NULL 
        
		ELSE 

        (CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND  Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) AS float)
        /(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END) AS float)
        -CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,[Care Contact Patient Therapy Mode]

UNION --------------------------------------------------------

SELECT   Month
		,'England' AS OrgType
		,'England' AS OrgCode
		,'England' AS OrgName
		,'Eng' AS [Region Code]
		,'England' AS [Region Name]
		,[Care Contact Patient Therapy Mode]
		,COUNT(DISTINCT PathwayID) AS 'FinishedTreatment'
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END)
        -COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END) = 0 THEN NULL
        WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) = 0 THEN NULL 
        
		ELSE 

        (CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True'  AND  Recovery_Flag = 'True' THEN  PathwayID ELSE NULL END) AS float)
        /(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' THEN PathwayID ELSE NULL END) AS float)
        -CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND NotCaseness_Flag = 'True' THEN PathwayID ELSE NULL END)AS float))) END
        AS 'Percentage_Recovery'
		
		,TRY_CAST(AVG(Apts) AS DECIMAL(5, 2)) AS 'AvgApts'
		,TRY_CAST(AVG(FirstTreatmentWait) AS DECIMAL(5, 2)) AS 'AvgWait'

FROM [MHDInternal].[TEMP_TTAD_CareContactMethod_Phase1]

GROUP BY Month
		,[Care Contact Patient Therapy Mode]
)_

-- -----------------------------------------------------------------------------
 PRINT CHAR(10) + 'Updated - [MHDInternal].[DASHBOARD_TTAD_PDT_CareContactMode_Apts_Monthly]'