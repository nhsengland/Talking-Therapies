SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity] -----------------------------

DECLARE @Offset AS INT = -1

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-----------------------------------------------------------------------------------------------------------------------

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity]

SELECT  @MonthYear AS 'Month'
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
			WHEN Validated_EthnicCategory IN ('R','S') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied' ELSE 'Other' 
		END AS 'Variable'
		,'Refresh' AS DataSource
		,CASE WHEN a.AttendOrDNACode IN ('2','02') THEN 'AptCancelledPatient'
			WHEN a.AttendOrDNACode IN ('3','03') THEN 'AptDNA'
			WHEN a.AttendOrDNACode IN ('4','04') THEN 'AptCancelledProvider'
			WHEN a.AttendOrDNACode IN ('5','05') THEN 'AptAttended'
			WHEN a.AttendOrDNACode IN ('6','06') THEN 'AptAttendedLate'
			WHEN a.AttendOrDNACode IN ('7','07') THEN 'AptLateNotSeen' ELSE 'Other' 
		END AS 'Attendence Type'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('01', '1', '1 ', ' 1') THEN a.Unique_CareContactID END)) AS 'Face to face communication'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('02', '2', '2 ', ' 2') THEN a.Unique_CareContactID END)) AS 'Telephone'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('03', '3', '3 ', ' 3') THEN a.Unique_CareContactID END)) AS 'Telemedicine web camera'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('04', '4', '4 ', ' 4') THEN a.Unique_CareContactID END)) AS 'Talk type for a Person unable to speak'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('05', '5', '5 ', ' 5') THEN a.Unique_CareContactID END)) AS 'Email'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('06', '6', '6 ', ' 6') THEN a.Unique_CareContactID END)) AS 'Short Message Service (SMS)'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND (a.ConsMechanism IN ('98', '98 ', ' 98') OR a.ConsMechanism IS NULL) THEN a.Unique_CareContactID END)) AS 'Other'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('08', '8', '8 ', ' 8') THEN a.Unique_CareContactID END)) AS 'Online Instant Messaging'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMediumUsed IN ('09', '9', '9 ', ' 9')  THEN a.Unique_CareContactID END)) AS 'Text Message (Asynchronous)'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('10', '10', '10 ', ' 10') THEN a.Unique_CareContactID END)) AS 'Instant messaging (Synchronous)'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('11', '3', '11 ', ' 11') THEN a.Unique_CareContactID END)) AS 'Video consultation'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('12', '4', '12 ', ' 12') THEN a.Unique_CareContactID END)) AS 'Message Board (Asynchronous)'
		,COUNT(DISTINCT(CASE WHEN a.CareContDate BETWEEN @PeriodStart AND @PeriodEnd AND a.ConsMechanism IN ('13', '5', '13 ', ' 13') THEN a.Unique_CareContactID END)) AS 'Chat Room (Synchronous)'

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		
WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END 
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
			WHEN Validated_EthnicCategory IN ('R','S') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
			ELSE 'Other' END
		,CASE WHEN a.AttendOrDNACode IN ('2','02') THEN 'AptCancelledPatient'
			WHEN a.AttendOrDNACode IN ('3','03') THEN 'AptDNA'
			WHEN a.AttendOrDNACode IN ('4','04') THEN 'AptCancelledProvider'
			WHEN a.AttendOrDNACode IN ('5','05') THEN 'AptAttended'
			WHEN a.AttendOrDNACode IN ('6','06') THEN 'AptAttendedLate'
			WHEN a.AttendOrDNACode IN ('7','07') THEN 'AptLateNotSeen' 
			ELSE 'Other' END

-------------------------------------------------------------------------------------------------------------

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity]'
