
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Inequalities_Monthly_IST_New_Indicators_v2] ------------------------

USE [NHSE_IAPT_v2]

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

----------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Inequalities_Monthly_IST_New_Indicators_v2]

SELECT  @MonthYear AS 'Month'
		,'Refresh' AS 'DataSource'
		,'England' AS 'GroupType'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'CCG Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
		,'Total' AS 'Category'
		,'Total' AS 'Variable'
		,COUNT(DISTINCT CASE WHEN r.[ReferralRequestReceivedDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND [SourceOfReferralMH] = 'B1' THEN r.PathwayID ELSE NULL END) AS 'SelfReferral'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND [TherapySession_FirstDate] IS NULL THEN r.PathwayID ELSE NULL END) AS 'EndedBeforeTreatment'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=14 THEN r.PathwayID ELSE NULL END) AS 'FirstTreatment2Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=42 THEN r.PathwayID ELSE NULL END) AS 'FirstTreatment6Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=84 THEN r.PathwayID ELSE NULL END) AS 'FirstTreatment12Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=126 THEN r.PathwayID ELSE NULL END) AS 'FirstTreatment18Weeks'
		,COUNT(DISTINCT CASE WHEN [TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL THEN r.PathwayID ELSE NULL END) AS 'WaitingForTreatment'
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN Unique_CareContactID  ELSE NULL END) AS 'Appointments'
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND AttendOrDNACode IN ('3', '03', ' 3', '3 ', ' 03', '03 ') THEN Unique_CareContactID ELSE NULL END) AS 'ApptDNA'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'ReferralsEnded'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND [TreatmentCareContact_Count] = 1 THEN r.PathwayID ELSE NULL END) AS 'EndedTreatedOnce'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD,[ReferralRequestReceivedDate],l.[ReportingPeriodEndDate]) <=14 THEN r.PathwayID ELSE NULL END) AS 'Waiting2Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD,[ReferralRequestReceivedDate],l.[ReportingPeriodEndDate]) <=28 THEN r.PathwayID ELSE NULL END) AS 'Waiting4Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD,[ReferralRequestReceivedDate],l.[ReportingPeriodEndDate]) <=42 THEN r.PathwayID ELSE NULL END) AS 'Waiting6Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD,[ReferralRequestReceivedDate],l.[ReportingPeriodEndDate]) <=84 THEN r.PathwayID ELSE NULL END) AS 'Waiting12Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_FirstDate] IS NULL AND r.[ServDischDate] IS NULL AND DATEDIFF(DD,[ReferralRequestReceivedDate],l.[ReportingPeriodEndDate]) <=126 THEN r.PathwayID ELSE NULL END) AS 'Waiting18Weeks'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=42 THEN r.PathwayID ELSE NULL END) AS 'FinishedCourseTreatmentWaited6Weeks'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) <=126 THEN r.PathwayID ELSE NULL END) AS 'FinishedCourseTreatmentWaited18Weeks'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) <=28 THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28Days'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) BETWEEN 29 AND 90 THEN r.PathwayID ELSE NULL END) AS 'FirstToSecond28To90Days'
		,COUNT(DISTINCT CASE WHEN r.[TherapySession_SecondDate] BETWEEN l.[ReportingPeriodStartDate] AND l.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) > 90 THEN r.PathwayID ELSE NULL END) AS 'FirstToSecondMoreThan90Days'

FROM	[dbo].[IDS101_Referral] r
		--------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Code IS NOT NULL THEN ch.Organisation_Code ELSE 'Other' END 
		,CASE WHEN ch.Organisation_Name IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END 
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,[IntEnabledTherProg]

-----------------------------------------------------------------------------------------------------------------

PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Inequalities_Monthly_IST_New_Indicators_v2]'
