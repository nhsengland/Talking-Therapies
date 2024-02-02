--Please note this information is experimental and it is only intended for use for management purposes.

/****** Script for Unique Care Pathways Dashboard to produce the aggregated table for all graphs except the box plots ******/

-----------------------------------------------------------------
-------------Aggregated Table for Unique Care Pathways
--This is an aggregated table based on [MHDInternal].[DASHBOARD_TTAD_UCP_Base]
--It counts the number of PathwayIDs for each of the flags (Completion, Recovery, Not Caseness, Reliable Improvement and Reliable Deterioration)
-- used to calculate the outcome measures 
--The counts are calculated for different geographies (Provider, Sub-ICB, ICB and National), 
--categories (Problem descriptor, gender, gender identity, ethnicity, age, deprivation),
--and Unique Care Pathway

IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]
SELECT * 
INTO [MHDInternal].[DASHBOARD_TTAD_UCP_Aggregated]
FROM (

-- Problem Descriptor
SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[ProblemDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]

UNION 

-- Gender
SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[GenderDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]

UNION

-- Ethnicity
SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[EthnicityDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]

UNION 
-- Sub-query to provide aggregated data grouped by Provider & Gender Identity
	SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[GenderIdentityDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]

UNION 
-- Age
	SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[AgeDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]

UNION 
 
-- Deprivation
	SELECT
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
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
GROUP BY
	Month
	,[Region Name Comm]
	,[Region Code Comm]
	,[Region Code Prov]
	,[Region Name Prov]
	,[ICB Code]
	,[ICB Name]
	,[Sub-ICB Code]
	,[Sub-ICB Name]
	,[Provider Code]
	,[Provider Name]
	,[UniqueCarePathway]
	,[DeprivationDescriptor]
	,TreatmentCareContact_Count
	,[Numeric treatment count]
)_
