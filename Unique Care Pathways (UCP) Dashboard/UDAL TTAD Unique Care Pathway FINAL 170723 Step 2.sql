--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Unique Care Pathways Dashboard to produce the aggregated table for all graphs except the box plots ******/

-----------------------------------------------------------------
-------------Aggregated Table for Unique Care Pathways
--This is an aggregated table based on [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
--It counts the number of PathwayIDs for each of the flags (Completion, Recovery, Not Caseness, Reliable Improvement and Reliable Deterioration)
-- used to calculate the outcome measures 
--The counts are calculated for different geographies (Provider, Sub-ICB, ICB and National), 
--categories (Problem descriptor, gender, gender identity, ethnicity, age, sexual orientation, deprivation),
--and Unique Care Pathway

IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]
SELECT * 
INTO [MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]
FROM (

-- Sub-query to provide aggregated data grouped by Provider & Problem Descriptor
SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]
	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[ProblemDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 

-- Sub-query to provide aggregated data grouped by Provider & Gender
SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Gender' AS Category
	,[GenderDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration]
	
	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[GenderDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Ethnicity
SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Ethnicity' AS Category
	,[EthnicityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[EthnicityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Gender Identity
	SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Gender Identity' AS Category
	,[GenderIdentityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[GenderIdentityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Age
	SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Age' AS Category
	,[AgeDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 
	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[AgeDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Sexual Orientation
	SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Sexual Orientation' AS Category
	,[SexualOrientationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 
	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[SexualOrientationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Deprivation
	SELECT
	Month
	,'Provider' AS [OrgType]
	,[Provider Name] AS [OrgName]
	,[Region Name Prov] AS [Region]
	,[UniqueCarePathway]
	,'Deprivation' AS Category
	,[DeprivationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Provider Name], [Region Name Prov],[UniqueCarePathway],[DeprivationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Problem Descriptor
SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[ProblemDescriptor],TreatmentCareContact_Count,[Numeric treatment count]
	
UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Gender
SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Gender' AS Category
	,[GenderDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[GenderDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Ethnicity
SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Ethnicity' AS Category
	,[EthnicityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[EthnicityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Gender Identity
	SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Gender Identity' AS Category
	,[GenderIdentityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[GenderIdentityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Age
	SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Age' AS Category
	,[AgeDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[AgeDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Sexual Orientation
	SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Sexual Orientation' AS Category
	,[SexualOrientationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[SexualOrientationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Sub-ICB & Deprivation
	SELECT
	Month
	,'Sub-ICB' AS [OrgType]
	,[Sub-ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Deprivation' AS Category
	,[DeprivationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [Sub-ICB Name], [Region Name Comm],[UniqueCarePathway],[DeprivationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Problem Descriptor
SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[ProblemDescriptor],TreatmentCareContact_Count,[Numeric treatment count]
	
UNION 
-- Sub-query to provide aggregated data grouped by ICB & Gender
SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Gender' AS Category
	,[GenderDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[GenderDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Ethnicity
SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Ethnicity' AS Category
	,[EthnicityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
		,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[EthnicityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Gender Identity
	SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Gender Identity' AS Category
	,[GenderIdentityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[GenderIdentityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Age
	SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Age' AS Category
	,[AgeDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[AgeDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Sexual Orientation
	SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Sexual Orientation' AS Category
	,[SexualOrientationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[SexualOrientationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by ICB & Deprivation
	SELECT
	Month
	,'ICB' AS [OrgType]
	,[ICB Name] AS [OrgName]
	,[Region Name Comm] AS [Region]
	,[UniqueCarePathway]
	,'Deprivation' AS Category
	,[DeprivationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL
	GROUP BY Month, [ICB Name], [Region Name Comm],[UniqueCarePathway],[DeprivationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]


UNION 
-- Sub-query to provide aggregated data grouped by National & Problem Descriptor
SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Problem Descriptor' AS Category
	,[ProblemDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month,[UniqueCarePathway],[ProblemDescriptor],TreatmentCareContact_Count,[Numeric treatment count]
	
UNION 
-- Sub-query to provide aggregated data grouped by National & Gender
SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Gender' AS Category
	,[GenderDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month, [UniqueCarePathway],[GenderDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by National & Ethnicity
SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Ethnicity' AS Category
	,[EthnicityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month,[UniqueCarePathway],[EthnicityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by National & Gender Identity
	SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Gender Identity' AS Category
	,[GenderIdentityDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration]

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month, [UniqueCarePathway],[GenderIdentityDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by National & Age
	SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Age' AS Category
	,[AgeDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month,[UniqueCarePathway],[AgeDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by National & Sexual Orientation
	SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Sexual Orientation' AS Category
	,[SexualOrientationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month,[UniqueCarePathway],[SexualOrientationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by National & Deprivation
	SELECT
	Month
	,'National' AS [OrgType]
	,'England' AS [OrgName]
	,'All Regions' AS [Region]
	,[UniqueCarePathway]
	,'Deprivation' AS Category
	,[DeprivationDescriptor] AS Variable
	,TreatmentCareContact_Count
	,[Numeric treatment count]
	-- Classify [UniqueCarePathway] into 'Lower Intensity' and 'High Intensity' categories
	,CASE WHEN [UniqueCarePathway] IN ('Guide Self-Help Book'
										,'Non-Guided Self-Help Book'
										,'Guided Self-Help Computer'
										,'Non-Guided Self-Help Computer'
										,'Structured Physical Activity'
										,'Psychoeducational Peer Support'
										,'Other Low Intensity'
										,'Community Signposting'
										,'Mindfulness') THEN 'Lower Intensity' ELSE 'High Intensity' END AS [Intensity level]

	-- Aggregate results for various measures of treatment outcome
	,SUM([CompTreatFlagRecFlag]) AS [Recovered]
	,SUM([CompTreatFlag]) AS [Completed]
	,SUM([NotCaseness]) AS [Not Caseness]
	,SUM([CompTreatFlagRelImpFlag]) AS [Reliable Improvement]
	,SUM([CompTreatFlagRelDetFlag]) AS [Reliable Deterioration] 

	FROM [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
	WHERE UniqueCarePathway IS NOT NULL 

	GROUP BY Month, [UniqueCarePathway],[DeprivationDescriptor],TreatmentCareContact_Count,[Numeric treatment count]
	)_
