/*
Ethnicity - recovery summary.  **PROVIDER DATA ONLY**
Prepared by Becky Musgrove, 06  2021
Adapted by Alex Macdonald, 11 2023
Adapted by Sarah Blincko 12 2023
*/

-- Postcode Ranking -----------------------------
--Trust sites have more than one postcode so these are ranked alphabetically so only one postcode is used
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_Postcodes]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes]
SELECT	
    [SiteCode]
    ,[Postcode1]
    ,[Grid Reference]
    ,[X (easting)]
    ,[Y (northing)]
    ,[Latitude]
    ,[Longitude]
    ,[Address4]
    ,ROW_NUMBER() OVER(PARTITION BY SiteCode ORDER BY Postcode1 ASC) AS PostcodeRank
INTO [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes]
FROM [MHDInternal].[REFERENCE_ODS_All_Sites]

---------------------------------------------------------------------------------------------------------------------------------
/* Setting parameters for rolling 12 months */

DECLARE @Offset AS INT = -1

DECLARE @PeriodEnd DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodStart DATE = (SELECT DATEADD(DAY,1, EOMONTH(DATEADD(MONTH,-12,@PeriodEnd))))

PRINT @PeriodEnd
PRINT @PeriodStart

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
SELECT DISTINCT
	@PeriodStart AS PeriodStart
	,@PeriodEnd AS PeriodEnd
	,r.PathwayID
	,CASE WHEN ph.[Organisation_Code] IS NOT NULL THEN ph.[Organisation_Code] ELSE 'Other' END AS ProviderCode
	,CASE WHEN ph.[Organisation_Name] IS NOT NULL THEN ph.[Organisation_Name] ELSE 'Other' END AS ProviderName
	,CASE WHEN ph.Region_Name IS NOT NULL THEN ph.Region_Name ELSE 'Other' END AS Region

    ,pc.[Postcode1] AS 'Postcode'
    ,pc.[Grid Reference] AS 'GridRef'
    ,pc.[X (easting)] AS 'Eastings'
    ,pc.[Y (northing)] AS 'Northings'
    ,pc.[Latitude] AS 'Lat'
    ,pc.[Longitude] AS 'Long'
    ,pc.[Address4] AS 'City'

-- Ethnicity - Broad		
	,CASE WHEN Validated_EthnicCategory IN ('A') THEN 'White British'
		WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Ethnic Minorities'
		WHEN Validated_EthnicCategory NOT IN ('A', 'B','C','D','E','F','G','H','J','K','L','M','N','P','R','S') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END
	AS 'Ethnicity - Broad'

--Ethnicity - High-level
	,CASE WHEN Validated_EthnicCategory IN ('A','B','C') THEN 'White'
		WHEN Validated_EthnicCategory IN ('D','E','F','G') THEN 'Mixed'
		WHEN Validated_EthnicCategory IN ('H','J','K','L') THEN 'Asian or Asian British'
		WHEN Validated_EthnicCategory IN ('M','N','P') THEN 'Black or Black British'
		WHEN Validated_EthnicCategory IN ('R','S') THEN 'Other Ethnic Groups'
		WHEN Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END 
	AS 'Ethnicity - High-level'

-- Ethnicity - Detailed
	,CASE WHEN mpi.Validated_EthnicCategory IN ('A') THEN 'White British'
		WHEN mpi.Validated_EthnicCategory IN ('B') THEN 'White Irish'
		WHEN mpi.Validated_EthnicCategory IN ('C') THEN 'White Other'
		WHEN mpi.Validated_EthnicCategory IN ('D') THEN 'White AND Black Caribbean'
		WHEN mpi.Validated_EthnicCategory IN ('E') THEN 'White AND Black African'
		WHEN mpi.Validated_EthnicCategory IN ('F') THEN 'White AND Asian'
		WHEN mpi.Validated_EthnicCategory IN ('G') THEN 'Any Other Mixed Background'
		WHEN mpi.Validated_EthnicCategory IN ('H') THEN 'Asian - Indian'
		WHEN mpi.Validated_EthnicCategory IN ('J') THEN 'Asian - Pakistani'
		WHEN mpi.Validated_EthnicCategory IN ('K') THEN 'Asian - Bangladeshi'
		WHEN mpi.Validated_EthnicCategory IN ('L') THEN 'Any Other Asian Background'
		WHEN mpi.Validated_EthnicCategory IN ('M') THEN 'Black Caribbean'
		WHEN mpi.Validated_EthnicCategory IN ('N') THEN 'Black African'
		WHEN mpi.Validated_EthnicCategory IN ('P') THEN 'Any Other Black Background'
		WHEN mpi.Validated_EthnicCategory IN ('R') THEN 'Chinese'
		WHEN mpi.Validated_EthnicCategory IN ('S') THEN 'Any Other Ethnic Group'
		WHEN mpi.Validated_EthnicCategory IN ('99', 'Z', '-1','-3') THEN 'Not known/Not stated/Unspecified/Invalid data supplied'
		ELSE 'Other' END
	AS 'Ethnicity - Detailed'

	,CASE WHEN r.ReferralRequestReceivedDate BETWEEN @PeriodStart AND @PeriodEnd AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS Referrals

	,CASE WHEN r.TherapySession_FirstDate BETWEEN @PeriodStart AND @PeriodEnd AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS Access

	,CASE WHEN r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS FinishedTreatment

	,CASE WHEN r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.Recovery_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS Recovery

	,CASE WHEN r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.ReliableImprovement_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS ReliableImprovement

	,CASE WHEN r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.NotCaseness_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	AS NotCaseness

	-- ,CASE WHEN mpi.Validated_EthnicCategory IN ('A') AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	-- AS WBFinishedTreatment

	-- ,CASE WHEN mpi.Validated_EthnicCategory IN ('A') AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.Recovery_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	-- AS WBRecovery

	-- ,CASE WHEN mpi.Validated_EthnicCategory IN ('A') AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.ReliableImprovement_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	-- AS WBReliableImprovement

	-- ,CASE WHEN mpi.Validated_EthnicCategory IN ('A') AND r.ServDischDate BETWEEN @PeriodStart AND @PeriodEnd AND r.CompletedTreatment_Flag='True' AND r.NotCaseness_Flag='True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 END
	-- AS WBNotCaseness

INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
FROM	[mesh_IAPT].[IDS101referral] r
		-----------------------------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		-----------------------------------------------
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default AND ph.Effective_To IS NULL

		LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes] pc ON ph.[Organisation_Code]= pc.[SiteCode] AND PostcodeRank=1

WHERE	r.UsePathway_Flag = 'TRUE' AND l.IsLatest = 1
GO

---------------This doesn't seem to fix the issue of missing postcodes:
-- -- Updating where sites are missing - where it is a site code rather than a full provider code.
-- IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_Postcodes2]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes2]

-- SELECT	prov.[Organisation_Code]
-- 		,prov.[PostCode]
-- 		,post.[Grid_Ref_Easting]
-- 		,post.[Grid_Ref_Northing]
-- 		,post.[Latitude_1m]
-- 		,post.[Longitude_1m]
-- 		,prov.[Address_Line_4]

-- INTO [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes2]

-- FROM	[UKHD_ODS].[Care_Trust_Sites_SCD] prov
-- LEFT JOIN [UKHD_ODS].[Postcode_Grid_Refs_Eng_Wal_Sco_And_NI_SCD] post ON prov.[PostCode] = post.Postcode_8_chars

-- /*Update the base table where the postcode information is missing*/
-- UPDATE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]

-- SET		Postcode = b.[PostCode],
-- 		Eastings = b.[Grid_Ref_Easting],
-- 		Northings = b.[Grid_Ref_Northing],
-- 		Lat = b.[Latitude_1m],
-- 		Long = b.[Longitude_1m],
-- 		City = b.[Address_Line_4]

-- FROM	[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase] a
-- LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_Postcodes2] b ON a.[ProviderCode]= b.[Organisation_Code]

-- WHERE a.Postcode IS NULL

--------------------------------------
--Aggregate

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
--Ethnicity - Broad
SELECT
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,CAST('Ethnicity - Broad' AS VARCHAR(100)) AS Category
	,CAST([Ethnicity - Broad] AS VARCHAR(255)) AS Ethnicity

--Organisation, Category and Ethnicity Level
	,SUM([Referrals]) AS Referrals
	,SUM([Access]) AS Access
	,SUM([FinishedTreatment]) AS FinishedTreatment
	,SUM([Recovery]) AS Recovery
	,SUM([ReliableImprovement]) AS ReliableImprovement
	,SUM([NotCaseness]) AS NotCaseness
	,CASE WHEN SUM([Recovery])>0 AND (SUM([FinishedTreatment])-SUM([NotCaseness]))>0 THEN CAST(CAST(SUM([Recovery]) AS FLOAT)/(SUM([FinishedTreatment])-SUM([NotCaseness])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Recovery rate' 
	,CASE WHEN SUM([ReliableImprovement])>0 AND SUM([FinishedTreatment])>0 THEN CAST(CAST(SUM([ReliableImprovement]) AS FLOAT)/(SUM([FinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Reliable rate'

--Organisation and Category Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Referral proportion'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Access proportion'

--Organisation Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Recovery rate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Reliable rate'
	,CAST(NULL AS INT) AS 'Org NotCaseness'
	,CAST(NULL AS INT) AS 'Org FinishedTreatment'
	,CAST(NULL AS INT) AS 'Org Referrals'
	,CAST(NULL AS INT) AS 'Org Access'

--% of referrals in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% referrals no ethnicity'
--% of access in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% access no ethnicity'

	-- ,SUM(WBFinishedTreatment) AS WBFinishedTreatment
	-- ,SUM(WBNotCaseness) AS WBNotCaseness

	-- ,CASE WHEN SUM(WBRecovery)>0 AND (SUM(WBFinishedTreatment)-SUM(WBNotCaseness))>0 THEN CAST(CAST(SUM(WBRecovery) AS FLOAT)/(SUM(WBFinishedTreatment)-SUM(WBNotCaseness)) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBRecoveryRate
	-- ,CASE WHEN SUM([WBReliableImprovement])>0 AND SUM([WBFinishedTreatment])>0 THEN CAST(CAST(SUM([WBReliableImprovement]) AS FLOAT)/(SUM([WBFinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBReliableRate
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBRecoveryRate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBReliableRate'


	,CAST(NULL AS DECIMAL(10,2)) AS 'Recover diff'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Reliable diff'
INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
GROUP BY 	
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,[Ethnicity - Broad]
GO

--Ethnicity - High-Level
INSERT INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
SELECT
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,'Ethnicity - High-Level' AS Category
	,[Ethnicity - High-Level] AS Ethnicity

--Organisation, Category and Ethnicity Level
	,SUM([Referrals]) AS Referrals
	,SUM([Access]) AS Access
	,SUM([FinishedTreatment]) AS FinishedTreatment
	,SUM([Recovery]) AS Recovery
	,SUM([ReliableImprovement]) AS ReliableImprovement
	,SUM([NotCaseness]) AS NotCaseness
	,CASE WHEN SUM([Recovery])>0 AND (SUM([FinishedTreatment])-SUM([NotCaseness]))>0 THEN CAST(CAST(SUM([Recovery]) AS FLOAT)/(SUM([FinishedTreatment])-SUM([NotCaseness])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Recovery rate' 
	,CASE WHEN SUM([ReliableImprovement])>0 AND SUM([FinishedTreatment])>0 THEN CAST(CAST(SUM([ReliableImprovement]) AS FLOAT)/(SUM([FinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Reliable rate'

--Organisation and Category Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Referral proportion'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Access proportion'

--Organisation Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Recovery rate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Reliable rate'
	,CAST(NULL AS INT) AS 'Org NotCaseness'
	,CAST(NULL AS INT) AS 'Org FinishedTreatment'
	,CAST(NULL AS INT) AS 'Org Referrals'
	,CAST(NULL AS INT) AS 'Org Access'

--% of referrals in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% referrals no ethnicity'
--% of access in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% access no ethnicity'

	-- ,SUM(WBFinishedTreatment) AS WBFinishedTreatment
	-- ,SUM(WBNotCaseness) AS WBNotCaseness

	-- ,CASE WHEN SUM(WBRecovery)>0 AND (SUM(WBFinishedTreatment)-SUM(WBNotCaseness))>0 THEN CAST(CAST(SUM(WBRecovery) AS FLOAT)/(SUM(WBFinishedTreatment)-SUM(WBNotCaseness)) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBRecoveryRate
	-- ,CASE WHEN SUM([WBReliableImprovement])>0 AND SUM([WBFinishedTreatment])>0 THEN CAST(CAST(SUM([WBReliableImprovement]) AS FLOAT)/(SUM([WBFinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBReliableRate
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBRecoveryRate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBReliableRate'

	,CAST(NULL AS DECIMAL(10,2)) AS 'Recover diff'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Reliable diff'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
GROUP BY 	
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,[Ethnicity - High-Level]

--Ethnicity - Detailed
INSERT INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
SELECT
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,'Ethnicity - Detailed' AS Category
	,[Ethnicity - Detailed] AS Ethnicity

--Organisation, Category and Ethnicity Level
	,SUM([Referrals]) AS Referrals
	,SUM([Access]) AS Access
	,SUM([FinishedTreatment]) AS FinishedTreatment
	,SUM([Recovery]) AS Recovery
	,SUM([ReliableImprovement]) AS ReliableImprovement
	,SUM([NotCaseness]) AS NotCaseness
	,CASE WHEN SUM([Recovery])>0 AND (SUM([FinishedTreatment])-SUM([NotCaseness]))>0 THEN CAST(CAST(SUM([Recovery]) AS FLOAT)/(SUM([FinishedTreatment])-SUM([NotCaseness])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Recovery rate' 
	,CASE WHEN SUM([ReliableImprovement])>0 AND SUM([FinishedTreatment])>0 THEN CAST(CAST(SUM([ReliableImprovement]) AS FLOAT)/(SUM([FinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Reliable rate'

--Organisation and Category Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Referral proportion'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Access proportion'

--Organisation Level
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Recovery rate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Org Reliable rate'
	,CAST(NULL AS INT) AS 'Org NotCaseness'
	,CAST(NULL AS INT) AS 'Org FinishedTreatment'
	,CAST(NULL AS INT) AS 'Org Referrals'
	,CAST(NULL AS INT) AS 'Org Access'

--% of referrals in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% referrals no ethnicity'
--% of access in a provider that have no ethnicity stated
	,CAST(NULL AS DECIMAL(10,2)) AS '% access no ethnicity'

	-- ,SUM(WBFinishedTreatment) AS WBFinishedTreatment
	-- ,SUM(WBNotCaseness) AS WBNotCaseness

	-- ,CASE WHEN SUM(WBRecovery)>0 AND (SUM(WBFinishedTreatment)-SUM(WBNotCaseness))>0 THEN CAST(CAST(SUM(WBRecovery) AS FLOAT)/(SUM(WBFinishedTreatment)-SUM(WBNotCaseness)) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBRecoveryRate
	-- ,CASE WHEN SUM([WBReliableImprovement])>0 AND SUM([WBFinishedTreatment])>0 THEN CAST(CAST(SUM([WBReliableImprovement]) AS FLOAT)/(SUM([WBFinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	-- AS WhiteBReliableRate
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBRecoveryRate'
	,CAST(NULL AS DECIMAL(10,2)) AS 'WhiteBReliableRate'

	,CAST(NULL AS DECIMAL(10,2)) AS 'Recover diff'
	,CAST(NULL AS DECIMAL(10,2)) AS 'Reliable diff'

FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
GROUP BY 	
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,[Ethnicity - Detailed]



--Aggregating Referrals, Access, Recovery Rate and Reliable Improvement Rate at Provider Code level only
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Org]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Org]
SELECT
	[ProviderCode]
	,SUM([Referrals]) AS 'Org Referrals'
	,SUM([Access]) AS 'Org Access'

	,SUM(NotCaseness) AS 'Org NotCaseness'
	,SUM(FinishedTreatment) AS 'Org FinishedTreatment'
	,CASE WHEN SUM([Recovery])>0 AND (SUM([FinishedTreatment])-SUM([NotCaseness]))>0 THEN CAST(CAST(SUM([Recovery]) AS FLOAT)/(SUM([FinishedTreatment])-SUM([NotCaseness])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Org Recovery rate' 
	,CASE WHEN SUM([ReliableImprovement])>0 AND SUM([FinishedTreatment])>0 THEN CAST(CAST(SUM([ReliableImprovement]) AS FLOAT)/(SUM([FinishedTreatment])) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Org Reliable rate'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Org]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapBase]
GROUP BY [ProviderCode]

--Updating Aggregate table for Referrals, Access, Recovery Rate and Reliable Improvement Rate at Provider Code level only
UPDATE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]

SET	
	[Org Recovery rate]= b.[Org Recovery rate]
	,[Org Reliable rate]= b.[Org Reliable rate]
	,[Org NotCaseness]= b.[Org NotCaseness]
	,[Org FinishedTreatment] = b.[Org FinishedTreatment]
	,[Org Referrals]=b.[Org Referrals]
	,[Org Access]=b.[Org Access]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Org] b ON a.[ProviderCode]= b.[ProviderCode]

--Referral and Access Proportions Calculation
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Prop]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Prop]
SELECT
	ProviderCode
	,Category
	,Ethnicity
	,CASE WHEN SUM(Referrals)>0 AND SUM([Org Referrals])>0 THEN CAST(CAST(SUM(Referrals) AS FLOAT)/SUM([Org Referrals]) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Referral proportion'
	,CASE WHEN SUM([Access])>0 AND SUM([Org Access]) >0 THEN CAST(CAST(SUM([Access]) AS FLOAT)/SUM([Org Access]) AS DECIMAL(10,2)) ELSE NULL END
	AS 'Access proportion'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Prop]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
GROUP BY ProviderCode,Category,Ethnicity

--Updating Aggregate Table for Referral and Access Proportions
UPDATE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]

SET	
	[Referral proportion]= b.[Referral proportion]
	,[Access proportion]= b.[Access proportion]
	
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Prop] b ON a.[ProviderCode]= b.[ProviderCode] AND a.Category=b.Category AND a.Ethnicity=b.Ethnicity

--Updating Aggregate Table for Referral and Access Proportions for those with no ethnicity data stated
UPDATE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]

SET	
	[% referrals no ethnicity]= b.[Referral proportion]
	,[% access no ethnicity]= b.[Access proportion]
	
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_Prop] b ON a.[ProviderCode]= b.[ProviderCode] AND a.Category=b.Category
WHERE b.Ethnicity ='Not known/Not stated/Unspecified/Invalid data supplied'

--White British Recovery and Reliable Rates
IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_RecRel]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_RecRel]
SELECT DISTINCT
	ProviderCode
	,Category
	,CASE WHEN (FinishedTreatment-NotCaseness)<5 THEN NULL ELSE [Recovery rate] END
	AS 'Recovery rate'
	,CASE WHEN FinishedTreatment<5 THEN NULL ELSE [Reliable rate] END
	AS 'Reliable rate'

INTO [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_RecRel]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]
WHERE Ethnicity IN ('White','White British')


--WB Recovery and Reliable Rates
UPDATE [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]

SET	
	[WhiteBRecoveryRate]= b.[Recovery rate]
	,[WhiteBReliableRate]= b.[Reliable rate]
	
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate_RecRel] b ON a.[ProviderCode]= b.[ProviderCode]



-- Rounding of variables ---------------------------------------------------------------
--This is the final table used in the dashboard. The table is re-run each month so it only contains the data for latest 12 months
IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_ProtChar_Ethnicity_Map_Rounded]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_Ethnicity_Map_Rounded]
SELECT	
	[PeriodStart]
	,[PeriodEnd]
	,[ProviderCode]
	,[ProviderName]
	,[Region]
	,[Postcode]
	,[GridRef]
	,[Eastings]
	,[Northings]
	,[Lat]
	,[Long]
	,[City]
	,[Category]
	,[Ethnicity]

	,CASE WHEN Referrals < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND((Referrals+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	AS [Referrals]
	,CASE WHEN Access < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND((Access+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	AS [Access]
	,CASE WHEN [FinishedTreatment] < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND(([FinishedTreatment]+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	AS [Finished Treatment]

--Checking in tableau but pretty sure these aren't needed in tableau:
	-- ,CASE WHEN [Recovery] < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND(([Recovery]+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	-- AS [Recovery]
	-- ,CASE WHEN [ReliableImprovement] < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND(([ReliableImprovement]+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	-- AS [Reliable Improvement]
	-- ,CASE WHEN [NotCaseness] < 5 THEN '*' ELSE ISNULL(CAST(CAST(ROUND(([NotCaseness]+2) /5,0)*5 AS INT) AS VARCHAR), '*') END
	-- AS [NotCaseness]

	,CASE WHEN (FinishedTreatment-NotCaseness) < 5 THEN NULL ELSE [Recovery rate] END
	AS [Recovery rate]
	,CASE WHEN FinishedTreatment < 5 THEN NULL ELSE [Reliable rate] END
	AS [Reliable rate]

	,CASE WHEN [Org Referrals] < 5 THEN NULL ELSE [Referral proportion] END
	AS [Referral proportion]
	,CASE WHEN [Org Access] < 5 THEN NULL ELSE [Access proportion] END
	AS [Access proportion]

	,CASE WHEN ([Org FinishedTreatment]-[Org NotCaseness]) < 5 THEN NULL ELSE [Org Recovery rate] END
	AS 'Org Recovery rate'
	,CASE WHEN [Org FinishedTreatment] < 5 THEN NULL ELSE [Org Reliable rate] END
	AS 'Org Reliable rate'
	,CASE WHEN [Org Referrals] < 5 THEN NULL ELSE [Org Referrals] END
	AS 'Org Referrals'
	,CASE WHEN [Org Access] < 5 THEN NULL ELSE [Org Access] END
	AS 'Org Access'

	,CASE WHEN [Org Referrals] < 5 THEN NULL ELSE [% referrals no ethnicity] END
	AS '% referrals no ethnicity'
	,CASE WHEN [Org Access] < 5 THEN NULL ELSE [% access no ethnicity] END
	AS '% access no ethnicity'

	,WhiteBRecoveryRate --Already had suppression rules applied
	,WhiteBReliableRate --Already had suppression rules applied

--not sure if these are right:
	,CASE WHEN (FinishedTreatment-NotCaseness) < 5 THEN NULL ELSE [WhiteBRecoveryRate]-[Recovery rate] END
	AS [Recover diff]
    ,CASE WHEN FinishedTreatment < 5 THEN NULL ELSE [WhiteBReliableRate]-[Reliable rate] END
	AS [Reliable diff]

INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_Ethnicity_Map_Rounded]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_EthnicityMapAggregate]