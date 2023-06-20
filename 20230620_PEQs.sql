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

-- PEQs ----------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardPEQsTable]

-- 'Ethnicity - Broad'

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

---------------------------------|
--SET @Offset = @Offset -1 END --| <-- End loop
---------------------------------|

------------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardPEQsTable]'
