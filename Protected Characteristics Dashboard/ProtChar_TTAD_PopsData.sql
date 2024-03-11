/****** Script to produce populations by different protected characteristics (age, gender and ethnicity) and geographies (National, ICB and Sub-ICB) using the 2021 census data.
		This is used in the TTAD Protected Characteristics dashboard to produce the rates of open referrals per 100,000 population values. ******/

------------------------Age Group-------------------------------

--This produces a base table with the population for each age grouping for each MSOA and it is matched to the Sub-ICB, ICB and Region that MSOA belongs to.
--Age data wasn't available at LSOA level so MSOA was used instead
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_Population_Age_Base_Table]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Age_Base_Table]

SELECT DISTINCT
	l.MSOA21
	,l.ODS_SubICB_Code22 AS SubICBCode
	,r.Organisation_Name AS SubICBName
	,l.[ICBName]
	,l.[ICBCode]
	,l.[Region_Name]
	,l.[Region_Code]
	,a.Measure_Name
    ,a.[Count]

INTO [MHDInternal].[TEMP_TTAD_ProtChar_Population_Age_Base_Table]

FROM [UKHF_Census].[Age_By_Single_Year_Of_Age_V21] a
	INNER JOIN  [MHDInternal].[REFERENCE_Lookup_LSOA21_MSOA21_ICB] l ON l.MSOA21= a.Geography_Code COLLATE DATABASE_DEFAULT
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] r ON l.ODS_SubICB_Code22=r.Organisation_Code
	--Inner joins to a lookup table which matches LSOA 2021 codes with MSOA 2021 codes, Sub-ICB names, ICB names and Region names 
	--so the census populations can be aggregated to Sub-ICB and ICB levels

WHERE a.[Effective_Snapshot_Date] = '2021-03-21' and a.Geography_Type='msoa' and Geography_Code like'E%'
	and Measure_Name in 
	('Aged 4 years and under','Aged 5 to 9 years','Aged 10 to 15 years','Aged 16 years', 'Aged 17 years', 'Aged 18 years', 'Aged 19 years','Aged 20 to 24 years',
	'Aged 25 years','Aged 26 years','Aged 27 years','Aged 28 years','Aged 29 years','Aged 30 years','Aged 31 years','Aged 32 years','Aged 33 years','Aged 34 years',
	'Aged 35 to 49 years','Aged 50 to 64 years','Aged 65 to 74 years','Aged 75 to 84 years','Aged 85 years and over')
	--Filters for date (there is currently only one date available)
	--Filters for MSOAs and for English geography codes (there are Welsh codes included in the data)
	--Filters for age groupings as the data also contains a total population and populations for single year of age
	
--This table aggregates the populations to Sub-ICB, ICB and National levels based on the age base table above
--Ages are grouped into Under 65s, 65 to 74, 75 to 84 and 85+ as these are the age groupings used in the Memory Assessment Services dashboard this table is used in
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]
SELECT
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,CAST('Age' AS VARCHAR(255)) AS [Category]
	,CAST(CASE WHEN [Measure_Name] IN ('Aged 4 years and under','Aged 5 to 9 years','Aged 10 to 15 years','Aged 16 years', 'Aged 17 years') THEN 'Under 18' 
		WHEN [Measure_Name] IN ('Aged 18 years', 'Aged 19 years','Aged 20 to 24 years','Aged 25 years') THEN '18-25'
		WHEN [Measure_Name] IN ('Aged 26 years','Aged 27 years','Aged 28 years','Aged 29 years','Aged 30 years','Aged 31 years','Aged 32 years','Aged 33 years'
								,'Aged 34 years','Aged 35 to 49 years','Aged 50 to 64 years') THEN '26-64'
		WHEN [Measure_Name] IN ('Aged 65 to 74 years','Aged 75 to 84 years','Aged 85 years and over') THEN '65+'
		END AS VARCHAR(255))
	AS Variable
	,SUM([Count]) AS [Pop]
INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]
FROM [MHDInternal].[TEMP_TTAD_ProtChar_Population_Age_Base_Table]
GROUP BY 
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,CASE WHEN [Measure_Name] IN ('Aged 4 years and under','Aged 5 to 9 years','Aged 10 to 15 years','Aged 16 years', 'Aged 17 years') THEN 'Under 18' 
		WHEN [Measure_Name] IN ('Aged 18 years', 'Aged 19 years','Aged 20 to 24 years','Aged 25 years') THEN '18-25'
		WHEN [Measure_Name] IN ('Aged 26 years','Aged 27 years','Aged 28 years','Aged 29 years','Aged 30 years','Aged 31 years','Aged 32 years','Aged 33 years'
								,'Aged 34 years','Aged 35 to 49 years','Aged 50 to 64 years') THEN '26-64'
		WHEN [Measure_Name] IN ('Aged 65 to 74 years','Aged 75 to 84 years','Aged 85 years and over') THEN '65+'
		END

 ----------------------------------------Gender---------------------------------------------------------------

 --This produces a base table with the population for each gender for each LSOA and it is matched to the Sub-ICB, ICB and Region that LSOA belongs to
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_Population_Gender_Base_Table]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Gender_Base_Table] --this is the same base used for Dementia

SELECT DISTINCT
	l.LSOA21
	,l.ODS_SubICB_Code22 AS SubICBCode
	,r.Organisation_Name AS SubICBName
	,l.[ICBName]
	,l.[ICBCode]
	,l.[Region_Name]
	,l.[Region_Code]
	,g.[Sex]
    ,g.[Count]

INTO [MHDInternal].[TEMP_TTAD_ProtChar_Population_Gender_Base_Table]

FROM [UKHF_Census].[Sex1] g
	INNER JOIN [MHDInternal].[REFERENCE_Lookup_LSOA21_MSOA21_ICB] l ON l.LSOA21= g.Geography_Code COLLATE DATABASE_DEFAULT
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] r ON l.ODS_SubICB_Code22=r.Organisation_Code
	--Inner joins to a lookup table which matches LSOA 2021 codes with MSOA 2021 codes, Sub-ICB names, ICB names and Region names 
	--so the census populations can be aggregated to Sub-ICB and ICB levels

WHERE g.[Effective_Snapshot_Date] = '2021-03-21' and g.Geography_Code LIKE 'E01%' and Sex <> 'All persons'

--This table aggregates the populations to Sub-ICB, ICB and National levels based on the gender base table above
--Gender is grouped into Females, Males and Other/Not Stated/Not Known as these are the gender groups used in the Memory Assessment Services dashboard this table is used in

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]
SELECT
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,'Gender' AS [Category]
	,CASE WHEN [Sex]='Female' THEN 'Female'
		WHEN [Sex]='Male' THEN 'Male'
		ELSE 'Other' END
	AS Variable
	,SUM([Count]) AS [Pop]

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Population_Gender_Base_Table]

GROUP BY 
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,CASE WHEN [Sex]='Female' THEN 'Female'
		WHEN [Sex]='Male' THEN 'Male'
		ELSE 'Other' END

----------------------------------------------Ethnicity--------------------------------------------------------------------------

--This produces a base table with the population for each ethnicity group for each LSOA and it is matched to the Sub-ICB, ICB and Region that LSOA belongs to.
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_ProtChar_Population_Ethnicity_Base_Table]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Ethnicity_Base_Table] --this is the same base used for Dementia

SELECT DISTINCT
	l.LSOA21
	,l.ODS_SubICB_Code22 AS SubICBCode
	,r.Organisation_Name AS SubICBName
	,l.[ICBName]
	,l.[ICBCode]
	,l.[Region_Name]
	,l.[Region_Code]
	,e.Measure
    ,e.Measure_Value
INTO [MHDInternal].[TEMP_TTAD_ProtChar_Population_Ethnicity_Base_Table]

FROM [UKHF_Census].[Ethnic_Group_V21] e
	INNER JOIN [MHDInternal].[REFERENCE_Lookup_LSOA21_MSOA21_ICB] l ON l.LSOA21= e.Geography_Code COLLATE DATABASE_DEFAULT
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] r ON l.ODS_SubICB_Code22=r.Organisation_Code
	--Inner joins to a lookup table which matches LSOA 2021 codes with MSOA 2021 codes, Sub-ICB names, ICB names and Region names 
	--so the census populations can be aggregated to Sub-ICB and ICB levels

WHERE e.[Effective_Snapshot_Date] = '2021-03-21' and e.Geography_Code like 'E01%' and e.Geography_Type='lsoa' 
	and Measure IN ('Ethnic_group:_Asian_Asian_British_or_Asian_Welsh','Ethnic_group:_Black_Black_British_Black_Welsh_Caribbean_or_African','Ethnic_group:_Mixed_or_Multiple_ethnic_groups'
	,'Ethnic_group:_Other_ethnic_group','Ethnic_group:_White')

--This table aggregates the populations to Sub-ICB, ICB and National levels based on the ethnicity base table above
--Ethnicity is grouped into Asian, Black, Mixed, White and Other as these are the ethnicity groups used in the dashboard this table is used in

INSERT INTO [MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]
SELECT
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,'Ethnicity - High-level' as [Category]
	,CASE WHEN Measure like '%Asian%' THEN 'Asian or Asian British'
		WHEN Measure  like'%Black%' THEN 'Black or Black British'
		WHEN Measure like'%Mixed%' THEN 'Mixed'
		WHEN Measure like'%White%' THEN 'White'
		WHEN Measure  like '%Other%' THEN 'Other Ethnic Groups'
		ELSE 'Other'
		END AS Variable
	,ROUND(SUM(Measure_Value),0) AS [Pop]

FROM [MHDInternal].[TEMP_TTAD_ProtChar_Population_Ethnicity_Base_Table]

GROUP BY
	[SubICBName]
	,[SubICBCode]
	,[ICBName]
	,[ICBCode]
	,[Region_Name]
	,[Region_Code]
	,CASE WHEN Measure like '%Asian%' THEN 'Asian or Asian British'
		WHEN Measure  like'%Black%' THEN 'Black or Black British'
		WHEN Measure like'%Mixed%' THEN 'Mixed'
		WHEN Measure like'%White%' THEN 'White'
		WHEN Measure  like '%Other%' THEN 'Other Ethnic Groups'
		ELSE 'Other' END

------------------------------------------------------------------------------------------
--Drops temporary tables used in the query -----------------------------------------------

DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Age_Base_Table]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Gender_Base_Table]
DROP TABLE [MHDInternal].[TEMP_TTAD_ProtChar_Population_Ethnicity_Base_Table]
------------------------------------------------------------------------------------------

PRINT 'Updated - [MHDInternal].[DASHBOARD_TTAD_ProtChar_PopsData]'
