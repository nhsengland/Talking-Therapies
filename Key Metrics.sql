

--DELETE FROM  [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot]
--WHERE [Month] = 'March 2022'


DECLARE @MonthString VARCHAR(50)
SET @MonthString = 'May 2022'


SELECT *
FROM [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot]
WHERE Month = 'May 2022'

INSERT INTO [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded_Unpivot]
select [Month]
      ,[DataSource]
      ,[GroupType]
	  ,Level
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[Category]
      ,[Variable], Measure, Value
from [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Region_Monthly_Test_2_Rounded] s
unpivot
(
  Value
  for Measure in ([Finished Treatment - 2 or more Apps]
      ,[Referrals]
      ,[EnteringTreatment])
) u
WHERE Level <> 'CCG/ Provider' AND Month = @MonthString

UNION

select [Month]
      ,[DataSource]
      ,[GroupType]
	  ,Level
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[Category]
      ,[Variable], Measure, Value

from [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Dashboard_Monthly_IST_New_Indicators_Rounded] s
unpivot
(
  Value
  for Measure in ([FinishedCourseTreatment6WeeksRate]
      ,[FinishedCourseTreatment18WeeksRate],[RecoveryRate]
      ,[ReliableImprovementRate], OpenReferral90daysRate, FirsttoSecond90daysRate)
) u
WHERE Level <> 'CCG/ Provider' AND Month = @MonthString

UNION

select [Month]
      ,[DataSource]
      ,[GroupType]
	  ,Level
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[Category]
      ,[Variable], Measure, Value

from [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Intensive_Support_Dashboard_BAME] s
unpivot
(
  Value
  for Measure in ([RecRate])
) u
WHERE Level <> 'CCG/ Provider' AND Month = @MonthString

UNION

select [Month]
      ,[DataSource]
      ,[GroupType]
	  ,Level
      ,[Region Code]
      ,[Region Name]
      ,[CCG Code]
      ,[CCG Name]
      ,[Provider Code]
      ,[Provider Name]
      ,[STP Code]
      ,[STP Name]
      ,[Category]
      ,[Variable], Measure, Value

from [NHSE_Sandbox_MentalHealth].[dbo].[IAPT_Over_65_Metrics] s
unpivot
(
  Value
  for Measure in ([EnteringTreatment])
) u
WHERE Level <> 'CCG/ Provider' AND Month = @MonthString;


