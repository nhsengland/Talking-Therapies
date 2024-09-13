
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

-- Rounds full time series for the [RepeatReferrals2] column in [DASHBOARD_TTAD_PDT_InequalitiesRounded] ----------------------
-- Creates temporary table [TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded] to round figures then these are inserted back into [DASHBOARD_TTAD_PDT_InequalitiesRounded]  
---------------------------------------------------------------------------------------------

-- DELETE MAX(Month)s -----------------------------------------------------------------------
 
--DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded])
--DELETE FROM [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesNewIndicatorsRounded] WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesNewIndicatorsRounded])
	
-------------------------------------------------------------------------------------------
	
--DECLARE @Offset AS INT = 0 --Not used in script
--Period start and end in this script identify the entire time period in the [DASHBOARD_TTAD_PDT_InequalitiesRounded] 
DECLARE @PeriodStart DATE = (SELECT MIN(CAST(MONTH AS DATE)) FROM MHDInternal.DASHBOARD_TTAD_PDT_InequalitiesRounded)
DECLARE @PeriodEnd DATE = (SELECT MAX(CAST(MONTH AS DATE)) FROM MHDInternal.DASHBOARD_TTAD_PDT_InequalitiesRounded)

PRINT @PeriodStart
PRINT @PeriodEnd

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded] ------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('[MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded]
CREATE TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded](
	[Month] DATE
	,[DataSource] VARCHAR(255)
	,[GroupType] VARCHAR(255)
	,[Region Code] VARCHAR(255)
	,[Region Name] VARCHAR(255)
	,[CCG Code] VARCHAR(255)
	,[CCG Name] VARCHAR(255)
	,[Provider Code] VARCHAR(255)
	,[Provider Name] VARCHAR(255)
	,[STP Code] VARCHAR(255)
	,[STP Name] VARCHAR(255)
	,Category VARCHAR(255)
	,Variable VARCHAR(255)
	,[RepeatReferrals2] INT
	,Level VARCHAR(255)

)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded] ------------------------------------------------------------------------------------------------------------
-- Ran for entire time period from most recent month to September 2020 

INSERT INTO [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded]

SELECT * FROM (

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		SUM([RepeatReferrals2]) AS 'RepeatReferrals2',
		'National' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY Month

UNION -------------------------------------------------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		[Region Code] AS 'Region Code',
		[Region Name] AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		CASE WHEN SUM([RepeatReferrals2])< 5 THEN NULL ELSE CAST(ROUND((SUM([RepeatReferrals2])+2) /5,0)*5 AS INT)  END AS [RepeatReferrals2],
		'Region' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd

GROUP BY Month, [Region Code], [Region Name]

UNION ----------------------------------------------------------------

SELECT Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		[STP Code] AS 'STP Code',
		[STP Name] AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		CASE WHEN SUM([RepeatReferrals2])< 5 THEN NULL ELSE CAST(ROUND((SUM([RepeatReferrals2])+2) /5,0)*5 AS INT)  END AS [RepeatReferrals2],
		'STP' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd 

GROUP BY Month, [STP Code], [STP Name]

UNION -------------------------------------------------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		'All' AS 'Provider Code',
		'All' AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		CASE WHEN SUM([RepeatReferrals2])< 5 THEN NULL ELSE CAST(ROUND((SUM([RepeatReferrals2])+2) /5,0)*5 AS INT)  END AS [RepeatReferrals2],
		'CCG' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd 

GROUP BY Month, [CCG Code], [CCG Name]

UNION -------------------------------------------------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		'All' AS 'CCG Code',
		'All' AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		CASE WHEN SUM([RepeatReferrals2])< 5 THEN NULL ELSE CAST(ROUND((SUM([RepeatReferrals2])+2) /5,0)*5 AS INT)  END AS [RepeatReferrals2],
		'Provider' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd 

GROUP BY Month,  [Provider Code], [Provider Name]

UNION -------------------------------------------------------------------------------------------------

SELECT	Month, 
		'Refresh' AS DataSource,
		'England' AS GroupType,
		'All' AS 'Region Code',
		'All' AS 'Region Name',
		[CCG Code] AS 'CCG Code',
		[CCG Name] AS 'CCG Name',
		[Provider Code] AS 'Provider Code',
		[Provider Name] AS 'Provider Name',
		'All' AS 'STP Code',
		'All' AS 'STP Name',
		'Total' AS Category,
		'Total' AS Variable,
		CASE WHEN SUM([RepeatReferrals2])< 5 THEN NULL ELSE CAST(ROUND((SUM([RepeatReferrals2])+2) /5,0)*5 AS INT)  END AS [RepeatReferrals2],
		'CCG/ Provider' AS 'Level'

FROM	[MHDInternal].[DASHBOARD_TTAD_PDT_Inequalities]

WHERE	Category = 'Total' AND MONTH BETWEEN @PeriodStart AND @PeriodEnd 

GROUP BY Month, [CCG Code], [CCG Name], [Provider Code], [Provider Name]
)_

-- Update [RepeatReferrals2] in [DASHBOARD_TTAD_PDT_InequalitiesRounded] from [TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded] -------------------

UPDATE [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded] SET [RepeatReferrals2] = NULL
UPDATE [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded] SET [RepeatReferrals2] = b.[RepeatReferrals2]

FROM [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded] b

INNER JOIN [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded] a ON a.[Month] = b.[Month]
			AND a.[Region Code] = b.[Region Code] 
			AND a.[CCG Code] = b.[CCG Code] AND a.[Provider Code] = b.[Provider Code]
			AND a.[STP Code] = b.[STP Code] AND a.[Category] = b.[Category] 
			AND (a.[Variable] = b.[Variable] OR a.[Variable] IS NULL AND b.[Variable] IS NULL)

PRINT 'Updated - [RepeatReferrals2] into [MHDInternal].[DASHBOARD_TTAD_PDT_InequalitiesRounded]'

------------------------------------------------------------------------------------------------------------------------------------
--Drop Temporary Tables
DROP TABLE [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded]
-------------------------------------------------------------------------------------
PRINT 'Dropped - [MHDInternal].[TEMP_TTAD_PDT_InequalitiesRepeatReferralsRounded]'

