USE [NHSE_IAPT_v2]
----------------
SET NOCOUNT ON
SET DATEFIRST 1
----------------
DECLARE @Offset INT = -1
--------------------

--------------------------------
--DECLARE @Max_Offset INT = -31
-----------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
-----------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [IDS000_Header])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50)) + CHAR(10)

------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardPEQsTable]

------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Ethnicity - Broad' AS 'Category'
		,CASE 
			WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
			WHEN Validated_EthnicCategory = 'A' THEN 'White British'
			ELSE 'Other' 
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Ethnicity - High-level' AS 'Category'
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other'
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S','99','Z') THEN 'Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('-1','-3') THEN 'Unspecified/Invalid data supplied' 
			ELSE 'Other'
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN Validated_EthnicCategory = 'A' THEN 'White British'
				WHEN Validated_EthnicCategory = 'B' THEN 'White Irish'
				WHEN Validated_EthnicCategory = 'C' THEN 'Any other White background'
				
				WHEN Validated_EthnicCategory = 'D' THEN 'White and Black Caribbean'
				WHEN Validated_EthnicCategory = 'E' THEN 'White and Black African'
				WHEN Validated_EthnicCategory = 'F' THEN 'White and Asian'
				WHEN Validated_EthnicCategory = 'G' THEN 'Any other mixed background'

				WHEN Validated_EthnicCategory = 'H' THEN 'Indian'
				WHEN Validated_EthnicCategory = 'J' THEN 'Pakistani'
				WHEN Validated_EthnicCategory = 'K' THEN 'Bangladeshi'
				WHEN Validated_EthnicCategory = 'L' THEN 'Any other Asian background'

				WHEN Validated_EthnicCategory = 'M' THEN 'Caribbean'
				WHEN Validated_EthnicCategory = 'N' THEN 'African'
				WHEN Validated_EthnicCategory = 'P' THEN 'Any other Black background'

				WHEN Validated_EthnicCategory = 'R' THEN 'Chinese'
				WHEN Validated_EthnicCategory = 'S' THEN 'Any other ethnic group'
				WHEN Validated_EthnicCategory = 'Z' THEN 'Not stated'
				WHEN Validated_EthnicCategory = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN Validated_EthnicCategory = 'A' THEN 'White British'
				WHEN Validated_EthnicCategory = 'B' THEN 'White Irish'
				WHEN Validated_EthnicCategory = 'C' THEN 'Any other White background'
				
				WHEN Validated_EthnicCategory = 'D' THEN 'White and Black Caribbean'
				WHEN Validated_EthnicCategory = 'E' THEN 'White and Black African'
				WHEN Validated_EthnicCategory = 'F' THEN 'White and Asian'
				WHEN Validated_EthnicCategory = 'G' THEN 'Any other mixed background'

				WHEN Validated_EthnicCategory = 'H' THEN 'Indian'
				WHEN Validated_EthnicCategory = 'J' THEN 'Pakistani'
				WHEN Validated_EthnicCategory = 'K' THEN 'Bangladeshi'
				WHEN Validated_EthnicCategory = 'L' THEN 'Any other Asian background'

				WHEN Validated_EthnicCategory = 'M' THEN 'Caribbean'
				WHEN Validated_EthnicCategory = 'N' THEN 'African'
				WHEN Validated_EthnicCategory = 'P' THEN 'Any other Black background'

				WHEN Validated_EthnicCategory = 'R' THEN 'Chinese'
				WHEN Validated_EthnicCategory = 'S' THEN 'Any other ethnic group'
				WHEN Validated_EthnicCategory = 'Z' THEN 'Not stated'
				WHEN Validated_EthnicCategory = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Sexual Orientation' AS 'Category'
		,CASE WHEN spc.SocPerCircumstance = '20430005' THEN 'Heterosexual'
				WHEN spc.SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
				WHEN spc.SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
				WHEN spc.SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
				WHEN spc.SocPerCircumstance = '42035005' THEN 'Bisexual'
				WHEN spc.SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
				WHEN spc.SocPerCircumstance = '699042003' THEN 'Declined'
				WHEN spc.SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
				WHEN spc.SocPerCircumstance = '440583007' THEN 'Unknown'
				WHEN spc.SocPerCircumstance = '766822004' THEN 'Confusion'
				ELSE 'Unspecified'
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN spc.SocPerCircumstance = '20430005' THEN 'Heterosexual'
				WHEN spc.SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
				WHEN spc.SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
				WHEN spc.SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
				WHEN spc.SocPerCircumstance = '42035005' THEN 'Bisexual'
				WHEN spc.SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
				WHEN spc.SocPerCircumstance = '699042003' THEN 'Declined'
				WHEN spc.SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
				WHEN spc.SocPerCircumstance = '440583007' THEN 'Unknown'
				WHEN spc.SocPerCircumstance = '766822004' THEN 'Confusion'
				ELSE 'Unspecified'
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Age' AS 'Category'
		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unspecified'
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN r.Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
			WHEN r.Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
			WHEN r.Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
			ELSE 'Unspecified'
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @MonthYear AS 'Month'

		,'Gender' AS 'Category'
		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN mpi.Gender IN ('1','01') THEN 'Male'
			WHEN mpi.Gender IN ('2','02') THEN 'Female'
			WHEN mpi.Gender IN ('9','09') THEN 'Indeterminate'
			WHEN mpi.Gender IN ('x','X') THEN 'Not Known'
			WHEN mpi.Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT @MonthYear AS 'Month'

		,'Gender Identity' AS 'Category'
		,CASE WHEN (GenderIdentity IN ('1') or (Gender IN ('1') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Male (including trans men)'
			WHEN (GenderIdentity IN ('2') or (Gender IN ('2') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Female (including trans women)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN (GenderIdentity NOT IN ('1','2','3','4','x') OR GenderIdentity IS NULL) AND Gender = '9' then 'Indeterminate'
			ELSE 'Not Known/Not Stated'
		END AS 'Variable'
		,s2.[Term] AS 'Question'
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
		END AS 'Answer'
		,COUNT(r.PathwayID) AS 'Count'

FROM	[dbo].[IDS101_Referral] r
		-------------------------
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [NHSE_IAPT_V2].[dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-------------------------
		LEFT JOIN [NHSE_IAPT_V2].[dbo].[IDS607_CodedScoredAssessmentCareActivity] csa ON r.PathwayID = csa.PathwayID AND l.AuditId = csa.AuditId
		-------------------------
		LEFT JOIN [NHSE_UKHF].[SNOMED].[vw_Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
		-------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND IsLatest = 1
		AND ServDischDate BETWEEN @PeriodStart AND @PeriodEnd
		AND l.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [CodedAssToolType] IN('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108','747891000000106','747861000000100','747871000000107','747881000000109','904691000000103')
		
GROUP BY DATENAME(m, l.[ReportingPeriodStartDate]) + ' ' + CAST(DATEPART(yyyy, l.[ReportingPeriodStartDate]) AS varchar)

		,CASE WHEN (GenderIdentity IN ('1') or (Gender IN ('1') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Male (including trans men)'
			WHEN (GenderIdentity IN ('2') or (Gender IN ('2') and (GenderIdentity is null or GenderIdentity not in ('1', '2', '3', '4')))) then 'Female (including trans women)'
			WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
			WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
			WHEN (GenderIdentity NOT IN ('1','2','3','4','x') OR GenderIdentity IS NULL) AND Gender = '9' then 'Indeterminate'
			ELSE 'Not Known/Not Stated'
		END
		,s2.[Term]
		,CASE 
			-- Treatment
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
			WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Assessment
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
			WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'

			--Satifaction
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
			WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'

		END

---------------------------------|
--SET @Offset = @Offset -1 END --| <-- End loop
---------------------------------|

------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardPEQsTable]'
