USE [NHSE_IAPT_v2]
----------------
SET NOCOUNT ON
SET DATEFIRST 1
SET ANSI_WARNINGS OFF
----------------
DECLARE @Offset INT = -1
--------------------

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])

PRINT CHAR(10) + CAST(@PeriodStart AS VARCHAR(50))
PRINT CAST(@PeriodEnd AS VARCHAR(50))

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Main Table ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'
		
		,'Ethnicity - Broad' AS 'Category'
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		END AS 'Variable'

		-- PEQs
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747891000000106'  THEN csa.[PersScore] END) AS 'PEQ Satisfaction Q1'

		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747861000000100'  THEN csa.[PersScore] END) AS 'PEQ Assessment Q1'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747871000000107'  THEN csa.[PersScore] END) AS 'PEQ Assessment Q2'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747881000000109'  THEN csa.[PersScore] END) AS 'PEQ Assessment Q3'

		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747901000000107'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q1'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747911000000109'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q2'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747921000000103'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q3'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747931000000101'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q4'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747941000000105'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q5'
		,COUNT(CASE WHEN csa.[CodedAssToolType] = '747951000000108'  THEN csa.[PersScore] END) AS 'PEQ Treatment Q6'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd


GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		 END

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PEQs Table ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar) AS 'Month'

		,CASE WHEN csa.[CodedAssToolType] = '747891000000106' THEN 'PEQ Satisfaction Q1'
			
			WHEN csa.[CodedAssToolType] = '747861000000100' THEN 'PEQ Assessment Q1'
			WHEN csa.[CodedAssToolType] = '747871000000107' THEN 'PEQ Assessment Q2'
			WHEN csa.[CodedAssToolType] = '747881000000109' THEN 'PEQ Assessment Q3'

			WHEN csa.[CodedAssToolType] = '747901000000107' THEN 'PEQ Treatment Q1'
			WHEN csa.[CodedAssToolType] = '747911000000109' THEN 'PEQ Treatment Q2'
			WHEN csa.[CodedAssToolType] = '747921000000103' THEN 'PEQ Treatment Q3'
			WHEN csa.[CodedAssToolType] = '747931000000101' THEN 'PEQ Treatment Q4'
			WHEN csa.[CodedAssToolType] = '747941000000105' THEN 'PEQ Treatment Q5'
			WHEN csa.[CodedAssToolType] = '747951000000108' THEN 'PEQ Treatment Q6'

		 END AS 'Coded Assessment'

		,(CAST(COUNT(CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN r.[PathwayID] END) AS DECIMAL)/(COUNT(r.[PathwayID]))) AS 'Ethnic Minorities %'
		,(CAST(COUNT(CASE WHEN Validated_EthnicCategory IN ('A') THEN r.[PathwayID] END) AS DECIMAL)/COUNT(r.[PathwayID])) AS 'White British %'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747891000000106','747861000000100','747871000000107','747881000000109','747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108')

GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)
		
		,CASE WHEN csa.[CodedAssToolType] = '747891000000106' THEN 'PEQ Satisfaction Q1'
			
			WHEN csa.[CodedAssToolType] = '747861000000100' THEN 'PEQ Assessment Q1'
			WHEN csa.[CodedAssToolType] = '747871000000107' THEN 'PEQ Assessment Q2'
			WHEN csa.[CodedAssToolType] = '747881000000109' THEN 'PEQ Assessment Q3'

			WHEN csa.[CodedAssToolType] = '747901000000107' THEN 'PEQ Treatment Q1'
			WHEN csa.[CodedAssToolType] = '747911000000109' THEN 'PEQ Treatment Q2'
			WHEN csa.[CodedAssToolType] = '747921000000103' THEN 'PEQ Treatment Q3'
			WHEN csa.[CodedAssToolType] = '747931000000101' THEN 'PEQ Treatment Q4'
			WHEN csa.[CodedAssToolType] = '747941000000105' THEN 'PEQ Treatment Q5'
			WHEN csa.[CodedAssToolType] = '747951000000108' THEN 'PEQ Treatment Q6'

		 END

ORDER BY [Coded Assessment] 
