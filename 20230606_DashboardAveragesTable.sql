USE [NHSE_IAPT_v2]
----------------
SET NOCOUNT ON
SET DATEFIRST 1
SET ANSI_WARNINGS OFF
----------------
DECLARE @Offset INT = -1
--------------------

--------------------------------
--DECLARE @Max_Offset INT = -30
-----------------------------------------|
--WHILE (@Offset >= @Max_Offset) BEGIN --| <-- Start loop 
-----------------------------------------|

DECLARE @PeriodStart AS DATE = (SELECT DATEADD([Month],@Offset,MAX([ReportingPeriodStartDate])) FROM [IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD([Month],@Offset,MAX([ReportingPeriodendDate]))) FROM [IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50))

-- Drop temp tables ----------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]
IF OBJECT_ID ('[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]') IS NOT NULL DROP TABLE [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

----------------------------------------------------------------------------------------------------------
-- Base table: Finished Treatment ------------------------------------------------------------------------

SELECT DISTINCT 
		
		@MonthYear AS 'Month'
		,r.[PathwayID] 
		,[Validated_EthnicCategory]
		,[Age_ReferralRequest_ReceivedDate]
		,[Gender]
		,[GenderIdentity]
		,[SocPerCircumstance]
		,[PrimaryPresentingComplaint]
		,[SecondaryPresentingComplaint]
		,[TreatmentCareContact_Count]
		,[PHQ9_FirstScore]
		,[GAD_FirstScore]
		,[IMD_Decile]
		,CASE WHEN [WASAS_Work_LastScore] IS NOT NULL THEN [WASAS_Work_FirstScore] END AS 'WASAS_Work_FirstScore'
		,CASE WHEN [WASAS_Work_LastScore] IS NOT NULL THEN [WASAS_Work_LastScore] END AS 'WASAS_Work_LastScore'
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS 'RefFirstWait'
		,DATEDIFF(dd,[TherapySession_FirstDate],[TherapySession_SecondDate]) AS 'FirstSecondWait' 
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

INTO	 [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

FROM	[NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		------------------------------------------
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IDS001_MPI] p ON r.recordnumber = p.recordnumber 
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID] i ON r.UniqueSubmissionID = i.UniqueSubmissionID AND r.AuditId = i.AuditId
		------------------------------------------
		LEFT JOIN [NHSE_IAPT_v2].[dbo].[IDS011_SocialPersonalCircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		------------------------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND ch.Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
		---------------------------
		LEFT JOIN [NHSE_Sandbox_Policy].[dbo].[IMD_Quintile_2015] IMD ON p.LSOA = IMD.[LSOA_Code]

WHERE	UsePathway_Flag = 'True' AND i.IsLatest = '1'
		AND CompletedTreatment_Flag = 'True' 
		AND i.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND r.[ServDischDate] BETWEEN @PeriodStart AND @PeriodEnd

----------------------------------------------------------------------------------------------------------
-- Base table: First Treatment ---------------------------------------------------------------------------

SELECT DISTINCT 

		@MonthYear AS 'Month'
		,r.[PathwayID]
		,DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate]) AS 'Reftofirst'
		,CASE WHEN ch.[Region_Code]  IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Region Code'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Region Name'
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Sub-ICB Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.Organisation_Name ELSE 'Other' END AS 'Sub-ICB Name' 
		,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS 'Provider Code'
		,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS 'Provider Name'
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'ICB Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'ICB Name'

INTO	[NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FirstTreatment]

FROM	[NHSE_IAPT_v2].[dbo].[IDS101_Referral] r
		-----------------------------------------
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IDS001_MPI] p ON r.recordnumber = p.recordnumber 
		INNER JOIN [NHSE_IAPT_v2].[dbo].[IsLatest_SubmissionID] i ON r.UniqueSubmissionID = i.UniqueSubmissionID AND r.AuditId = i.AuditId
		------------------------------------------
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] ch ON r.OrgIDComm = ch.Organisation_Code AND Effective_To IS NULL
		LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

WHERE	UsePathway_Flag = 'True' AND i.IsLatest = '1'
		AND i.[ReportingPeriodStartDate] BETWEEN @PeriodStart AND @PeriodEnd
		AND [TherapySession_FirstDate] BETWEEN @PeriodStart AND @PeriodEnd

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- National --------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardAveragesTable]

SELECT * FROM (

-- 'Ethnicity - Detailed' AS 'Category'
SELECT DISTINCT @MonthYear AS 'Month'
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'
				
FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

-- 'Ethnicity - High-level' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------


-- 'Ethnicity - Broad' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

-- 'Age' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Age' AS 'Category'
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'Gender' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Gender' AS 'Category'
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END

UNION --------------------------------------------------------------------------------------------

-- 'GenderIdentity' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'GenderIdentity' AS 'Category'
				,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'SexualOrientation' AS 'Category'
SELECT DISTINCT Month
				,'National' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Sexual Orientation' AS 'Category'
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Region ------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'
				--CASE WHEN 'WASAS_Work_LastScore' IS NOT NULL THEN 

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

-- 'Age' AS 'Category'
SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Age' AS 'Category'
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'Gender' AS 'Category'
SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Gender' AS 'Category'
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END

UNION --------------------------------------------------------------------------------------------

-- 'GenderIdentity' AS 'Category'
SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'GenderIdentity' AS 'Category'
				,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'SexualOrientation' AS 'Category'
SELECT DISTINCT Month
				,'Region' AS 'Level'
				,'Refresh' AS 'DataSource'
				,[Region Code] AS 'Region Code'
				,[Region Name] AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Sexual Orientation' AS 'Category'
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Region Code]
		,[Region Name]
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ICB ---------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'
				--CASE WHEN 'WASAS_Work_LastScore' IS NOT NULL THEN 

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[ICB Code],[ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END	

UNION --------------------------------------------------------------------------------------------

-- 'Age' AS 'Category'
SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Age' AS 'Category'
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[ICB Code]
		,[ICB Name]
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'Gender' AS 'Category'
SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Gender' AS 'Category'
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[ICB Code]
		,[ICB Name]
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END

UNION --------------------------------------------------------------------------------------------

-- 'GenderIdentity' AS 'Category'
SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'GenderIdentity' AS 'Category'
				,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[ICB Code]
		,[ICB Name]
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'SexualOrientation' AS 'Category'
SELECT DISTINCT Month
				,'ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,[ICB Code] AS 'ICB Code'
				,[ICB Name] AS 'ICB Name'
				,'Sexual Orientation' AS 'Category'
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[ICB Code]
		,[ICB Name]
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------
					
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sub-ICB -----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'
				--CASE WHEN 'WASAS_Work_LastScore' IS NOT NULL THEN 

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Sub-ICB Code],[Sub-ICB Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

-- 'Age' AS 'Category'
SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Age' AS 'Category'
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Sub-ICB Code]
		,[Sub-ICB Name]
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'Gender' AS 'Category'
SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Gender' AS 'Category'
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Sub-ICB Code]
		,[Sub-ICB Name]
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END

UNION --------------------------------------------------------------------------------------------

-- 'GenderIdentity' AS 'Category'
SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'GenderIdentity' AS 'Category'
				,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Sub-ICB Code]
		,[Sub-ICB Name]
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'SexualOrientation' AS 'Category'
SELECT DISTINCT Month
				,'Sub-ICB' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,[Sub-ICB Code] AS 'Sub-ICB Code'
				,[Sub-ICB Name] AS 'Sub-ICB Name'
				,'All' AS 'Provider Code'
				,'All' AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Sexual Orientation' AS 'Category'
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Sub-ICB Code]
		,[Sub-ICB Name]
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END


UNION --------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Provider ----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Detailed' AS 'Category'
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'
				--CASE WHEN 'WASAS_Work_LastScore' IS NOT NULL THEN 

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
		,CASE WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
				WHEN [Validated_EthnicCategory] = 'B' THEN 'White Irish'
				WHEN [Validated_EthnicCategory] = 'C' THEN 'Any other White background'
				
				WHEN [Validated_EthnicCategory] = 'D' THEN 'White and Black Caribbean'
				WHEN [Validated_EthnicCategory] = 'E' THEN 'White and Black African'
				WHEN [Validated_EthnicCategory] = 'F' THEN 'White and Asian'
				WHEN [Validated_EthnicCategory] = 'G' THEN 'Any other mixed background'

				WHEN [Validated_EthnicCategory] = 'H' THEN 'Indian'
				WHEN [Validated_EthnicCategory] = 'J' THEN 'Pakistani'
				WHEN [Validated_EthnicCategory] = 'K' THEN 'Bangladeshi'
				WHEN [Validated_EthnicCategory] = 'L' THEN 'Any other Asian background'

				WHEN [Validated_EthnicCategory] = 'M' THEN 'Caribbean'
				WHEN [Validated_EthnicCategory] = 'N' THEN 'African'
				WHEN [Validated_EthnicCategory] = 'P' THEN 'Any other Black background'

				WHEN [Validated_EthnicCategory] = 'R' THEN 'Chinese'
				WHEN [Validated_EthnicCategory] = 'S' THEN 'Any other ethnic group'
				WHEN [Validated_EthnicCategory] = 'Z' THEN 'Not stated'
				WHEN [Validated_EthnicCategory] = '99' THEN 'Not known'
			
			ELSE 'Other' 
		END

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - High-level' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
					WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
					WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
					WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
					WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
					WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
				ELSE 'Other' END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
		,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
			WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
			WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
			WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
			WHEN Validated_EthnicCategory IN ('R','S') THEN ' Other Ethnic Groups'
			WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 

UNION ----------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------

SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Ethnicity - Broad' AS 'Category'
				,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month,[Provider Code],[Provider Name]
		,CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
					WHEN [Validated_EthnicCategory] = 'A' THEN 'White British'
					ELSE 'Other' 
					END

UNION --------------------------------------------------------------------------------------------

-- 'Age' AS 'Category'
SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Age' AS 'Category'
				,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Provider Code]
		,[Provider Name]
		,CASE WHEN Age_ReferralRequest_ReceivedDate < 18 THEN 'Under 18' 
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 18 AND 25 THEN '18-25'
					WHEN Age_ReferralRequest_ReceivedDate BETWEEN 26 AND 64 THEN '26-64'
					WHEN Age_ReferralRequest_ReceivedDate >= 65 THEN '65+'
					ELSE 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'Gender' AS 'Category'
SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Gender' AS 'Category'
				,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Provider Code]
		,[Provider Name]
		,CASE WHEN Gender IN ('1','01') THEN 'Male'
					WHEN Gender IN ('2','02') THEN 'Female'
					WHEN Gender IN ('9','09') THEN 'Indeterminate'
					WHEN Gender IN ('x','X') THEN 'Not Known'
					WHEN Gender NOT IN ('1','01','2','02','9','09','x','X') OR Gender IS NULL THEN 'Other' 
				END

UNION --------------------------------------------------------------------------------------------

-- 'GenderIdentity' AS 'Category'
SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'GenderIdentity' AS 'Category'
				,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Provider Code]
		,[Provider Name]
		,CASE WHEN GenderIdentity IN ('1','01') THEN 'Male (including trans man)'
					WHEN GenderIdentity IN ('2','02') THEN 'Female (including trans woman)'
					WHEN GenderIdentity IN ('3','03') THEN 'Non-binary'
					WHEN GenderIdentity IN ('4','04') THEN 'Other (not listed)'
					WHEN GenderIdentity IN ('x','X') THEN 'Not Known'
					WHEN GenderIdentity IN ('z','Z') THEN 'Not Stated'
					WHEN GenderIdentity NOT IN ('1','01','2','02','3','03','4','04','x','X','z','Z') OR GenderIdentity IS NULL THEN 'Unspecified'
				END

UNION --------------------------------------------------------------------------------------------

-- 'SexualOrientation' AS 'Category'
SELECT DISTINCT Month
				,'Provider' AS 'Level'
				,'Refresh' AS 'DataSource'
				,'All' AS 'Region Code'
				,'All' AS 'Region Name'
				,'All' AS 'Sub-ICB Code'
				,'All' AS 'Sub-ICB Name'
				,[Provider Code] AS 'Provider Code'
				,[Provider Name] AS 'Provider Name'
				,'All' AS 'ICB Code'
				,'All' AS 'ICB Name'
				,'Sexual Orientation' AS 'Category'
				,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END AS 'Variable'
				,ROUND(AVG(CAST([TreatmentCareContact_Count] AS DECIMAL)),1) AS 'MeanApps'
				,ROUND(AVG(CAST([RefFirstWait] AS DECIMAL)),1) AS 'MeanFirstWaitFinished'
				,ROUND(AVG(CAST([FirstSecondWait] AS DECIMAL)),1) AS 'MeanSecondWaitFinished'
				,ROUND(AVG(CAST([PHQ9_FirstScore] AS DECIMAL)),1) AS 'MeanFirstPHQ9Finished'
				,ROUND(AVG(CAST([GAD_FirstScore] AS DECIMAL)),1) AS 'MeanFirstGAD7Finished'
				,ROUND(AVG(CAST([WASAS_Work_FirstScore] AS DECIMAL)),1) AS 'Mean_FirstWSASW'
				,ROUND(AVG(CAST([WASAS_Work_LastScore] AS DECIMAL)),1) AS 'Mean_LastWSASW'

FROM [NHSE_Sandbox_MentalHealth].[dbo].[TEMP_IAPT_Ethnic_Minorities_FinishedTreatment]

GROUP BY Month
		,[Provider Code]
		,[Provider Name]
		,CASE WHEN SocPerCircumstance = '20430005' THEN 'Heterosexual'
						WHEN SocPerCircumstance = '89217008' THEN 'Homosexual (Female)'
						WHEN SocPerCircumstance = '76102007' THEN 'Homosexual (Male)'
						WHEN SocPerCircumstance = '38628009' THEN 'Homosexual (Gender not specified)'
						WHEN SocPerCircumstance = '42035005' THEN 'Bisexual'
						WHEN SocPerCircumstance = '1064711000000100' THEN 'Person asked and does not know or IS not sure'
						WHEN SocPerCircumstance = '699042003' THEN 'Declined'
						WHEN SocPerCircumstance = '765288000' THEN 'Sexually attracted to neither male nor female sex'
						WHEN SocPerCircumstance = '440583007' THEN 'Unknown'
						WHEN SocPerCircumstance = '766822004' THEN 'Confusion'
						ELSE 'Unspecified'
				END
)_

---------------------------------|
--SET @Offset = @Offset -1 END --| <-- End loop
---------------------------------|

----------------------------------------------------------------------------------------------
PRINT 'Updated - [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Ethnicity_DashboardAveragesTable]'
