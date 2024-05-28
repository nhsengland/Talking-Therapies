
-- Refresh updates for [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity] -----------------------------

-- DELETE MAX(Month) -----------------------------------------------------------------
 
DELETE FROM [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity]
 
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity])

--------------------------------------------------------------------------------------

DECLARE @Offset AS INT = 0

DECLARE @PeriodStart DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

-- Base Table ----------------------------------------------------------------------------------------------------------------

--This table has one Unique_CareContactID per row and is used to produce [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity] 

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]

SELECT DISTINCT
	CAST(DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS VARCHAR) AS DATE) AS [Month]
	,a.Unique_CareContactID
	,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
	,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
	,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'CCG Code'
	,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'CCG Name' 
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
	,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'STP Code'
	,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'STP Name'
	,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
		WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
		WHEN Validated_EthnicCategory IN ('R','S') THEN 'Other Ethnic Groups'
		WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied' ELSE 'Other' 
	END AS 'Ethnicity'
	,CASE WHEN a.AttendOrDNACode IN ('2','02') THEN 'AptCancelledPatient'
		WHEN a.AttendOrDNACode IN ('3','03') THEN 'AptDNA'
		WHEN a.AttendOrDNACode IN ('4','04') THEN 'AptCancelledProvider'
		WHEN a.AttendOrDNACode IN ('5','05') THEN 'AptAttended'
		WHEN a.AttendOrDNACode IN ('6','06') THEN 'AptAttendedLate'
		WHEN a.AttendOrDNACode IN ('7','07') THEN 'AptLateNotSeen' ELSE 'Other' 
	END AS 'Attendence Type'
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('01', '1', '1 ', ' 1') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('01', '1', '1 ', ' 1') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		ELSE 0
	END AS 'Face to face communication' --in both v2.0 and v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('02', '2', '2 ', ' 2') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('02', '2', '2 ', ' 2') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		ELSE 0
	END AS 'Telephone' --in both v2.0 and v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('03', '3', '3 ', ' 3') AND a.Unique_CareContactID IS NOT NULL THEN 1
		--WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('03', '3', '3 ', ' 3')  AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Telemedicine web camera' --just in v2.0
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('04', '4', '4 ', ' 4') AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('04', '4', '4 ', ' 4') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Talk type for a Person unable to speak' --in both v2.0 and v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('05', '5', '5 ', ' 5') AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('05', '5', '5 ', ' 5') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Email' --in both v2.0 and v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('06', '6', '6 ', ' 6') AND a.Unique_CareContactID IS NOT NULL THEN 1
		--WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('06', '6', '6 ', ' 6') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Short Message Service (SMS)' --in just v2.0
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND (a.ConsMediumUsed IN ('98', '98 ', ' 98') OR a.ConsMediumUsed IS NULL) AND a.Unique_CareContactID IS NOT NULL THEN 1 
			WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND (a.ConsMechanism IN ('98', '98 ', ' 98') OR a.ConsMechanism IS NULL) AND a.Unique_CareContactID IS NOT NULL THEN 1 
			ELSE 0
	END AS 'Other' --in both v2.0 and v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('08', '8', '8 ', ' 8') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		--WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('08', '8', '8 ', ' 8') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		ELSE 0
	END AS 'Online Instant Messaging' --in just v2.0
	,CASE --WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('09', '9', '9 ', ' 9') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('09', '9', '9 ', ' 9') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		ELSE 0
	END AS 'Text Message (Asynchronous)' --in just v2.1
	,CASE --WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('10', '10 ', ' 10') AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('10', '10 ', ' 10') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Instant messaging (Synchronous)' --in just v2.1
	,CASE --WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('11', '11 ', ' 11') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('11', '11 ', ' 11') AND a.Unique_CareContactID IS NOT NULL THEN 1 
		ELSE 0
	END AS 'Video consultation' --in just v2.1
	,CASE --WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('12', '12 ', ' 12') AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('12', '12 ', ' 12') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Message Board (Asynchronous)' --in just v2.1
	,CASE --WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' AND a.ConsMediumUsed IN ('13', '13 ', ' 13') AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate AND l.ReportingPeriodStartDate>='2022-04-01' AND a.ConsMechanism IN ('13', '13 ', ' 13') AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Chat Room (Synchronous)' --in just v2.1
	,CASE WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate 
			AND l.ReportingPeriodStartDate BETWEEN '2020-09-01' AND '2022-03-31' 
			AND a.ConsMediumUsed NOT IN ('01', '1', '1 ', ' 1', '02', '2', '2 ', ' 2', '03', '3', '3 ', ' 3', '04', '4', '4 ', ' 4','05', '5', '5 ', ' 5', '06', '6', '6 ', ' 6', '98', '98 ', ' 98', '08', '8', '8 ', ' 8') 
			AND a.Unique_CareContactID IS NOT NULL THEN 1
		WHEN a.CareContDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate 
			AND l.ReportingPeriodStartDate>='2022-04-01' 
			AND a.ConsMechanism NOT IN ('01', '1', '1 ', ' 1', '02', '2', '2 ', ' 2', '04', '4', '4 ', ' 4','05', '5', '5 ', ' 5', '98', '98 ', ' 98', '09', '9', '9 ', ' 9', '10', '10 ', ' 10','11', '11 ', ' 11', '12', '12 ', ' 12', '13', '13 ', ' 13')  
			AND a.Unique_CareContactID IS NOT NULL THEN 1
		ELSE 0
	END AS 'Invalid'

INTO [MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]

FROM	[mesh_IAPT].[IDS101referral] r
		---------------------------	
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		---------------------------
		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default 
			AND ch.Effective_To IS NULL

		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL
		
WHERE	r.UsePathway_Flag = 'True' AND l.IsLatest = 1
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart

-- Final Aggregated Table --------------------------------------------------------------------------------------------------------------------------
--This table aggregates the base table created above ([MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]) to produce the final table used in the dashboard

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity]

SELECT  
	Month
	,'England' AS 'GroupType'
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,'Ethnicity' AS 'Category'
	,[Ethnicity] AS 'Variable'
	,'Refresh' AS DataSource
	,[Attendence Type]
	,SUM([Face to face communication]) AS 'Face to face communication'
	,SUM([Telephone]) AS 'Telephone'
	,SUM([Telemedicine web camera]) AS 'Telemedicine web camera'
	,SUM([Talk type for a Person unable to speak]) AS 'Talk type for a Person unable to speak'
	,SUM([Email]) AS 'Email'
	,SUM([Short Message Service (SMS)]) AS 'Short Message Service (SMS)'
	,SUM([Other]) AS 'Other'
	,SUM([Online Instant Messaging]) AS 'Online Instant Messaging'
	,SUM([Text Message (Asynchronous)]) AS 'Text Message (Asynchronous)'
	,SUM([Instant messaging (Synchronous)]) AS 'Instant messaging (Synchronous)'
	,SUM([Video consultation]) AS 'Video consultation'
	,SUM([Message Board (Asynchronous)]) AS 'Message Board (Asynchronous)'
	,SUM([Chat Room (Synchronous)]) AS 'Chat Room (Synchronous)'
	,SUM ([Invalid]) AS 'Invalid'

FROM [MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]

GROUP BY
	Month
	,[Region Code]
	,[Region Name]
	,[CCG Code]
	,[CCG Name]
	,[Provider Code]
	,[Provider Name]
	,[STP Code]
	,[STP Name]
	,[Ethnicity] 
	,[Attendence Type]

--Drop Temporary Table -------------------------------

DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_ConsMechBase]

---------------------------------------------------------------------
PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ConsMech_Ethnicity]'
