USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50))

-----------------------------------------------------------------------------------------------------------
-- Create table: Geographies ------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Geographies') IS NOT NULL DROP TABLE #Geographies

SELECT  @MonthYear AS 'Month'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Sub ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'First Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Course Treatment'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.AttendOrDNACode in ('5','05') THEN a.Unique_CareContactID END )) AS 'Attended Appointments'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'

INTO	#Geographies

FROM	[dbo].[IDS101_Referral] r
		---------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON mpi.recordnumber = spc.recordnumber
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND UsePathway_Flag = 'True' AND IsLatest = 1 
	
GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END

-----------------------------------------------------------------------------------------------------------
-- Output -------------------------------------------------------------------------------------------------

-- National Level -----------------------------------------------------------------------------------------

SELECT  @MonthYear AS 'Month'
		,Level = 'National'
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Referrals'
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'First Treatment'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd THEN r.PathwayID ELSE NULL END) AS 'Finished Course Treatment'
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.AttendOrDNACode in ('5','05') THEN a.Unique_CareContactID END ) AS 'Attended Appointments'
		,COUNT(DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'

FROM	[dbo].[IDS101_Referral] r
		--------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--------------------------
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND UsePathway_Flag = 'True' AND IsLatest = 1

-- ICB level ------------------------------------------------------------------------------------------

SELECT	@MonthYear AS 'Month'
		,Level = 'ICB'
		,[ICB Code]
		,[ICB Name]
		,CASE WHEN SUM([Referrals]) < 5 THEN NULL ELSE (ROUND(SUM([Referrals])*2,-1)/2)  END AS 'Referrals'
		,CASE WHEN SUM([First Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([First Treatment])*2,-1)/2)  END AS 'First Treatment'
		,CASE WHEN SUM([Finished Course Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([Finished Course Treatment])*2,-1)/2) END AS 'Finished Course Treatment'
		,CASE WHEN SUM([Attended Appointments]) < 5 THEN NULL ELSE (ROUND(SUM([Attended Appointments])*2,-1)/2) END AS 'Attended Appointments'
		,CASE WHEN SUM([Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Recovery])*2,-1)/2)  END AS 'Recovery'

FROM	#Geographies 

GROUP BY [Month], [ICB Code], [ICB Name]

-- Sub ICB level ------------------------------------------------------------------------------------------

SELECT	@MonthYear AS 'Month'
		,Level = 'Sub ICB'
		,[Sub ICB Code]
		,[Sub ICB Name]
		,CASE WHEN SUM([Referrals]) < 5 THEN NULL ELSE (ROUND(SUM([Referrals])*2,-1)/2)  END AS 'Referrals'
		,CASE WHEN SUM([First Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([First Treatment])*2,-1)/2)  END AS 'First Treatment'
		,CASE WHEN SUM([Finished Course Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([Finished Course Treatment])*2,-1)/2) END AS 'Finished Course Treatment'
		,CASE WHEN SUM([Attended Appointments]) < 5 THEN NULL ELSE (ROUND(SUM([Attended Appointments])*2,-1)/2) END AS 'Attended Appointments'
		,CASE WHEN SUM([Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Recovery])*2,-1)/2)  END AS 'Recovery'

FROM	#Geographies 

GROUP BY [Month], [Sub ICB Code], [Sub ICB Name]

-- Provider level -----------------------------------------------------------------------------------------

SELECT	@MonthYear AS 'Month'
		,Level = 'Provider'
		,[Provider Code]
		,[Provider Name]
		,CASE WHEN SUM([Referrals]) < 5 THEN NULL ELSE (ROUND(SUM([Referrals])*2,-1)/2)  END AS 'Referrals'
		,CASE WHEN SUM([First Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([First Treatment])*2,-1)/2)  END AS 'First Treatment'
		,CASE WHEN SUM([Finished Course Treatment]) < 5 THEN NULL ELSE (ROUND(SUM([Finished Course Treatment])*2,-1)/2) END AS 'Finished Course Treatment'
		,CASE WHEN SUM([Attended Appointments]) < 5 THEN NULL ELSE (ROUND(SUM([Attended Appointments])*2,-1)/2) END AS 'Attended Appointments'
		,CASE WHEN SUM([Recovery]) < 5 THEN NULL ELSE (ROUND(SUM([Recovery])*2,-1)/2)  END AS 'Recovery'

FROM	#Geographies 

GROUP BY [Month], [Provider Code], [Provider Name]