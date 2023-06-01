USE [NHSE_IAPT_v2]

DECLARE @Period_Start DATE
DECLARE @Period_End DATE 

SET @Period_Start = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [IDS000_Header])
SET @Period_End = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [dbo].[IDS000_Header])
SET DATEFIRST 1

PRINT @Period_Start
PRINT @Period_End

-- National Check

SELECT  DATENAME(m, @Period_Start) + ' ' + CAST(DATEPART(yyyy, @Period_Start) AS varchar) AS Month
			,Level = 'National'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'Referrals'
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'First Treatment'
			,COUNT( DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'Finished Course Treatment'
			,COUNT (distinct(case when  a.CareContDate between @Period_Start and @Period_End and a.AttendOrDNACode in ('5','05') then a.Unique_CareContactID END )) as 'Attended Appointments'
			,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @Period_Start AND @Period_End AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'

		FROM [dbo].[IDS101_Referral] r

INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON r.recordnumber = spc.recordnumber AND r.AuditID = spc.AuditId AND r.UniqueSubmissionID = spc.UniqueSubmissionID
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[CCG_2020_Lookup] c2 ON r.OrgIDComm = c2.IC_CCG
		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_ODS_Provider_Hierarchies o1 ON r.OrgID_Provider = o1.Organisation_Code
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId


		WHERE UsePathway_Flag = 'True' AND h.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start AND IsLatest = 1

IF OBJECT_ID ('tempdb..#CCGtoRegion') IS NOT NULL DROP TABLE #CCGtoRegion
SELECT DISTINCT CCG21 AS 'CCG Code', CCG20merged AS CCG20merged,
CASE WHEN CCG21 = 'M1J4Y' THEN 'NHS BEDFORDSHIRE, LUTON AND MILTON KEYNES CCG'
WHEN CCG21 = 'D9Y0V' THEN 'NHS HAMPSHIRE, SOUTHAMPTON AND ISLE OF WIGHT CCG'
WHEN CCG21 = 'A3A8R' THEN 'NHS NORTH EAST LONDON CCG'
WHEN CCG21 = 'W2U3Z' THEN 'NHS NORTH WEST LONDON CCG'
WHEN CCG21 = 'M2L0M' THEN 'NHS SHROPSHIRE, TELFORD AND WREKIN CCG'
WHEN CCG21 = 'D2P2L' THEN 'NHS BLACK COUNTRY AND WEST BIRMINGHAM CCG'
WHEN CCG21 = 'B2M3M' THEN 'NHS COVENTRY AND WARWICKSHIRE CCG'
WHEN CCG21 = 'X2C4Y' THEN 'NHS KIRKLEES CCG'
WHEN CCG21 = 'D4U1Y' THEN 'NHS FRIMLEY CCG'
ELSE s.CCG_Name END AS 'CCG Name', s.STP_Code AS 'STP Code', s.STP_Name AS 'STP Name', [Region Code], Region_Name AS 'Region Name' INTO #CCGtoRegion FROM (
SELECT CCG21, CCG20merged,
CASE WHEN CCG21 IN ('W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','W2U3Z','93C','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','A3A8R','72Q','36L') THEN 'Y56'							
	WHEN CCG21 IN ('11N','15N','11X','15C','92G','11J','11M')	THEN 'Y58'																			
	WHEN CCG21 IN ('91Q','D4U1Y','D4U1Y','D4U1Y','D9Y0V','D9Y0V','D9Y0V','10R','D9Y0V','D9Y0V','D9Y0V','10Q','15A','14Y','92A','09D','97R','70F') THEN 'Y59'										
	WHEN CCG21 IN ('71E','52R','04Y','05D','05G','05Q','05V','05W','M2L0M','M2L0M','15M','03W','04C','04V','D2P2L','D2P2L','D2P2L','D2P2L','15E','B2M3M','B2M3M','B2M3M','18C','78H') THEN 'Y60'				
	WHEN CCG21 IN ('06H','26A','06L','06T','07K','M1J4Y','M1J4Y','M1J4Y','06K','06N','07H','99E','99F','06Q','99G','07G') THEN 'Y61'												
	WHEN CCG21 IN ('00T','00V','01D','00Y','01G','01W','01Y','02A','02H','14L','01F','01J','99A','01T','01V','01X','02E','12F','27D','00Q','00R','00X','01A','02G','02M','01E','01K') THEN 'Y62'	
	WHEN CCG21 IN ('02P','02Q','02X','03L','03N','99C','00L','00N','00P','13T','01H','84H','16C','02Y','03F','03H','03K','03Q','42D','02T','X2C4Y','X2C4Y','03R','15F','36J') THEN 'Y63'	
	ELSE NULL END AS 'Region Code'	

	FROM [NHSE_Sandbox_MentalHealth].[dbo].[CCG_2020_Lookup] )_
	LEFT JOIN NHSE_Reference.dbo.tbl_Ref_ODS_Provider_Hierarchies ON [Region Code] = Region_Code 
	LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_CCGToSTP] s ON CCG20merged = s.CCG_Code
	WHERE CCG20merged IS NOT NULL

-- CCG and Provider Level Checks
IF OBJECT_ID ('tempdb..#Geographies') IS NOT NULL DROP TABLE #Geographies
	SELECT  DATENAME(m, @Period_Start) + ' ' + CAST(DATEPART(yyyy, @Period_Start) AS varchar) AS Month
			,CASE WHEN [Region Code]  IS NOT NULL THEN [Region Code] ELSE 'Other' END AS 'Region Code'
			,CASE WHEN [Region Name] IS NOT NULL THEN [Region Name] ELSE 'Other' END AS 'Region Name'
			,CASE WHEN c2.CCG21 IS NOT NULL THEN c2.CCG21 ELSE 'Other' END AS 'CCG Code'
			,CASE WHEN [CCG Name] IS NOT NULL THEN [CCG Name] ELSE 'Other' END AS 'CCG Name' 
			,CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END AS 'Provider Code'
			,CASE WHEN o1.Organisation_Name IS NOT NULL THEN o1.Organisation_Name ELSE 'Other' END AS 'Provider Name'
			,CASE WHEN [STP Code] IS NOT NULL THEN [STP Code] ELSE 'Other' END AS 'STP Code'
			,COUNT( DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'Referrals'
			,COUNT( DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'First Treatment'
			,COUNT( DISTINCT CASE WHEN ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @Period_Start AND @Period_End THEN r.PathwayID ELSE NULL END) AS 'Finished Course Treatment'
			,COUNT (distinct(case when  a.CareContDate between @Period_Start and @Period_End and a.AttendOrDNACode in ('5','05') then a.Unique_CareContactID END )) as 'Attended Appointments'
			,COUNT(DISTINCT CASE WHEN  ServDischDate IS NOT NULL AND TreatmentCareContact_Count >= 2 AND r.ServDischDate BETWEEN @Period_Start AND @Period_End AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Recovery'

			INTO #Geographies

FROM [dbo].[IDS101_Referral] r

		INNER JOIN [dbo].[IDS001_MPI] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [dbo].[IDS000_Header] h ON r.[UniqueSubmissionID] = h.[UniqueSubmissionID]
		INNER JOIN [dbo].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.AuditId = l.AuditId
		LEFT JOIN [dbo].[IDS011_SocialPersonalCircumstances] spc ON mpi.recordnumber = spc.recordnumber
		LEFT JOIN [NHSE_Sandbox_MentalHealth].[dbo].[CCG_2020_Lookup] c2 ON r.OrgIDComm = c2.IC_CCG
		LEFT JOIN NHSE_Reference.dbo.tbl_Ref_ODS_Provider_Hierarchies o1 ON r.OrgID_Provider = o1.Organisation_Code
		LEFT JOIN [dbo].[IDS201_CareContact] a ON r.PathwayID = a.PathwayID AND a.AuditId = l.AuditId
		LEFT JOIN #CCGtoRegion s ON c2.CCG21 = s.[CCG Code]

WHERE UsePathway_Flag = 'True' AND h.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, 0, @Period_Start) AND @Period_Start AND IsLatest = 1

		
GROUP BY CASE WHEN [Region Code]  IS NOT NULL THEN [Region Code] ELSE 'Other' END 
			,CASE WHEN [Region Name] IS NOT NULL THEN [Region Name] ELSE 'Other' END 
			,CASE WHEN c2.CCG21 IS NOT NULL THEN c2.CCG21 ELSE 'Other' END 
			,CASE WHEN [CCG Name] IS NOT NULL THEN [CCG Name] ELSE 'Other' END 
			,CASE WHEN r.OrgID_Provider IS NOT NULL THEN r.OrgID_Provider ELSE 'Other' END 
			,CASE WHEN o1.Organisation_Name IS NOT NULL THEN o1.Organisation_Name ELSE 'Other' END
			,CASE WHEN [STP Code] IS NOT NULL THEN [STP Code] ELSE 'Other' END 
			,CASE WHEN [STP Name] IS NOT NULL THEN [STP Name] ELSE 'Other' END 


			SELECT Month
			, Level = 'CCG'
			,[CCG Code]
			,[CCG Name]
			,CASE WHEN SUM(Referrals)< 5 THEN NULL ELSE (ROUND(SUM(Referrals)*2,-1)/2)  END AS Referrals
			,CASE WHEN SUM([First Treatment])< 5 THEN NULL ELSE (ROUND(SUM([First Treatment])*2,-1)/2)  END AS 'First Treatment'
			,CASE WHEN SUM([Finished Course Treatment])< 5 THEN NULL ELSE (ROUND(SUM([Finished Course Treatment])*2,-1)/2) END AS 'Finished Course Treatment'
			,CASE WHEN SUM([Attended Appointments])< 5 THEN NULL ELSE (ROUND(SUM([Attended Appointments])*2,-1)/2) END AS 'Attended Appointments'
			,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE (ROUND(SUM([Recovery])*2,-1)/2)  END AS 'Recovery'
			FROM #Geographies
			GROUP BY Month, [CCG Code], [CCG Name]


			SELECT Month
			, Level = 'Provider'
			,[Provider Code]
			,[Provider Name]
			,CASE WHEN SUM(Referrals)< 5 THEN NULL ELSE (ROUND(SUM(Referrals)*2,-1)/2)  END AS Referrals
			,CASE WHEN SUM([First Treatment])< 5 THEN NULL ELSE (ROUND(SUM([First Treatment])*2,-1)/2)  END AS 'First Treatment'
			,CASE WHEN SUM([Finished Course Treatment])< 5 THEN NULL ELSE (ROUND(SUM([Finished Course Treatment])*2,-1)/2) END AS 'Finished Course Treatment'
			,CASE WHEN SUM([Attended Appointments])< 5 THEN NULL ELSE (ROUND(SUM([Attended Appointments])*2,-1)/2) END AS 'Attended Appointments'
			,CASE WHEN SUM([Recovery])< 5 THEN NULL ELSE (ROUND(SUM([Recovery])*2,-1)/2)  END AS 'Recovery'
			FROM #Geographies
			GROUP BY Month, [Provider Code], [Provider Name]
