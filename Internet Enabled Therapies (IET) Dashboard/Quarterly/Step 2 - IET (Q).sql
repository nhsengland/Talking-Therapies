/****** Script for Internet Enabled Therapies Dashboard to produce tables for Appointments, Therapist Time and Wait Times ******/

-----------------------------Aggregated Average Wait Times-------------------------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_Base] table to get the number of PathwayIDs with the completed treatment flag,
--the average wait from referral to first assessment, the average wait from referral to first therapy and
--the average wait from first therapy to second therapy.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types 
--(1+ IET, 2+ IET and No IET) and by Quarter.
--The full table is re-run each month as the averages need recalculating for quarters

IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
--National, IET 1+
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
	,AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstAssessment
	,AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstTherapy
	,AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) AS AverageWaitFromFirstTherapyToSecondTherapy
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag

INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY
	Quarter
GO

--National, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,'No IET' AS AppointmentType
	,AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstAssessment
	,AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstTherapy
	,AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) AS AverageWaitFromFirstTherapyToSecondTherapy
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter

--National, IET 2+
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,'2+ IET' AS AppointmentType
	,AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstAssessment
	,AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) AS AverageWaitFromReferralToFirstTherapy
	,AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) AS AverageWaitFromFirstTherapyToSecondTherapy
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter

-- Regional --------------------------------------------------------------------------------------------------------------------------
	
--Region, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm AS OrgName
	,RegionCodeComm AS OrgCode
	,'1+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm

--Region, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'No IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 

--Region, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'2+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 

--ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]

--ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]

--ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]

--Provider, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]

--Provider, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'No IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]

--Provider, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_AverageWaits]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,CASE WHEN COUNT(WaitRefToFirstAssess) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstAssess AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstAssessment
	,CASE WHEN COUNT(WaitRefToFirstTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitRefToFirstTherapy AS DECIMAL(7,2))) END AS AverageWaitFromReferralToFirstTherapy
	,CASE WHEN COUNT(WaitFirstTherapyToSecondTherapy) < 5 THEN NULL ELSE AVG(CAST(WaitFirstTherapyToSecondTherapy AS DECIMAL(7,2))) END AS AverageWaitFromFirstTherapyToSecondTherapy
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]

-----------------------------Aggregated Average Appointments and Time per Treatment-------------------------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_Base] table to get the number of PathwayIDs with the completed treatment flag,
--the average number of IET appointments per treatment, the average IET therapist time per treatment and
--the average any therapist time per treatment.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types 
--(1+ IET, 2+ IET and No IET), by IET Therapy Types and by Quarter.
--The full table is re-run each month as the averages need recalculating for quarters

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
--National, IET 1+
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode	
	,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) AS AverageNumberofIETAppointmentsPerTreatment
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AverageIETTherapistTimePerTreatment
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AverageAnyTherapistTimePerTreatment
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,IntEnabledTherProg
GO

--National, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) AS AverageNumberofIETAppointmentsPerTreatment
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AverageIETTherapistTimePerTreatment
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AverageAnyTherapistTimePerTreatment
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,IntEnabledTherProg

--National, IET 2+
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode

	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) AS AverageNumberofIETAppointmentsPerTreatment
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AverageIETTherapistTimePerTreatment
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AverageAnyTherapistTimePerTreatment
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,IntEnabledTherProg

-- Regional -------------------------------------------------------------------------------------------------------

--Region, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm AS OrgName
	,RegionCodeComm AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg

--Region, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--Region, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Provider, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE (InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL) AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(InternetEnabledTherapy_Count) < 5 THEN NULL ELSE AVG(CAST(InternetEnabledTherapy_Count AS DECIMAL(7,2))) END AS AverageNumberofIETAppointmentsPerTreatment
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AverageIETTherapistTimePerTreatment
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AverageAnyTherapistTimePerTreatment
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2 AND PathwayIDRank=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

---------------------------------------------------------------------------------
--Average therapist time per contact for IETs and for any contact

----Average IET Contacts:
-------------------Base table for Average Therapist Time per IET contact---------------------------------------
--This creates a base table with one IET contact per row which is then aggregated to produce [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
SELECT DISTINCT
	b.Month
	,b.Quarter
	,b.PathwayID

	--Number of Appointments
    ,b.InternetEnabledTherapy_Count

	--Contact dates
	,i.StartDateIntEnabledTherLog

	--Therapist Time
	,i.DurationIntEnabledTher

	,b.IntEnabledTherProg

	,CASE WHEN i.LatestContactRank=1 OR i.LatestContactRank IS NULL THEN b.CompTreatFlag ELSE NULL 
	END AS CompTreatFlag --Flag for completed treatment flag, where the LatestContactRank is 1 or null so that each PathwayID is only counted once
    
    --Geography
    ,b.[Sub-ICBCode]
	,b.[Sub-ICBName]
	,b.ICBCode
	,b.ICBName
	,b.RegionNameComm
	,b.RegionCodeComm
	,b.ProviderCode
	,b.ProviderName
	,b.RegionNameProv
	,b.RegionCodeProv

INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]

FROM [MHDInternal].[TEMP_TTAD_IET_Base] b
	 -------------------------------------
	 LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_IETContacts] i ON i.PathwayID = b.PathwayID

WHERE PathwayIDRank=1

-----------------------------Aggregated Average IET Therapist Time per Contact-------------------------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase] table to get the number of PathwayIDs with the completed treatment flag
--and the average IET Therapist Time.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types 
--(1+ IET, 2+ IET and No IET), by IET Therapy Types and by Quarter.
--The full table is re-run each month as the averages need recalculating for quarters

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
--National, IET 1+
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AvgIETTherapistTime
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,IntEnabledTherProg
GO

--National, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'National' AS OrgType
	,'All Regions' AS Region
	,'England' AS OrgName
	,'ENG' AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AvgIETTherapistTime
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,IntEnabledTherProg

--National, IET 2+
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'National' AS OrgType
	,'All Regions' AS Region
	,'England' AS OrgName
	,'ENG' AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) AS AvgIETTherapistTime
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,IntEnabledTherProg

-- Regional -------------------------------------------------------------------------------------

--Region, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm AS OrgName
	,RegionCodeComm AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg

--Region, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--Region, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Provider, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(DurationIntEnabledTher) < 5 THEN NULL ELSE AVG(CAST(DurationIntEnabledTher AS DECIMAL(7,2))) END AS AvgIETTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg


----Average Any Contacts:

--------------------------Ranking Any Contacts Table-------------------------------------------------
--This table lists each contact for each PathwayID and also ranks them so the latest contact is labelled as 1.
--It is used to produce [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase].
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AllContacts]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AllContacts]
SELECT
*
,ROW_NUMBER() OVER(PARTITION BY PathwayID ORDER BY CareContDate desc) as LatestContactRank
INTO [MHDInternal].[TEMP_TTAD_IET_AllContacts]
FROM(
SELECT DISTINCT
    c.PathwayID
	,c.CareContDate
    ,ca.ClinContactDurOfCareAct
	,c.Unique_MonthID
FROM [mesh_IAPT].[IDS201carecontact] c
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.[AuditId] = l.[AuditId]
LEFT JOIN [mesh_IAPT].[IDS202careactivity] ca ON ca.PathwayID=c.PathwayID AND ca.UniqueSubmissionID=c.UniqueSubmissionID AND ca.CareContactId=c.CareContactId
AND ca.AuditId=c.AuditId
WHERE l.IsLatest = 1
)_

-------------------Base table for Average Therapist Time per Any contact---------------------------------------
--This creates a base table with one contact per row which is then aggregated to produce [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
SELECT DISTINCT
	b.Month
	,b.Quarter
	,b.PathwayID

	--Number of Appointments
    ,b.InternetEnabledTherapy_Count

	--Contact dates
	,ca.CareContDate

	--Therapist Time
	,ca.ClinContactDurOfCareAct

	,IntEnabledTherProg

	,CASE WHEN ca.LatestContactRank=1 OR ca.LatestContactRank IS NULL THEN b.CompTreatFlag ELSE NULL 
	END AS CompTreatFlag --Flag for completed treatment flag, where the LatestContactRank is 1 or null so that each PathwayID is only counted once
    
    --Geography
    ,b.[Sub-ICBCode]
	,b.[Sub-ICBName]
	,b.ICBCode
	,b.ICBName
	,b.RegionNameComm
	,b.RegionCodeComm
	,b.ProviderCode
	,b.ProviderName
	,b.RegionNameProv
	,b.RegionCodeProv
INTO [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
FROM [MHDInternal].[TEMP_TTAD_IET_Base] b
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_AllContacts] ca ON ca.PathwayID=b.PathwayID
WHERE PathwayIDRank=1

-----------------------------Aggregated Average Any Therapist Time per Contact-------------------------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase] table to get the number of PathwayIDs with the completed treatment flag
--and the average Any Therapist Time.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types 
--(1+ IET, 2+ IET and No IET), by IET Therapy Types and by Quarter.
--The full table is re-run each month as the averages need recalculating for quarters

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
--National, IET 1+
SELECT 
	Quarter
	,CAST('National' AS VARCHAR(50)) AS OrgType
	,CAST('All Regions' AS VARCHAR(255)) AS Region
	,CAST('England' AS VARCHAR(255)) AS OrgName
	,CAST('ENG' AS VARCHAR(50)) AS OrgCode
	,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AvgAnyTherapistTime
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,IntEnabledTherProg
GO

--National, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'National' AS OrgType
	,'All Regions' AS Region
	,'England' AS OrgName
	,'ENG' AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AvgAnyTherapistTime
	,CAST( SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,IntEnabledTherProg

--National, IET 2+
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'National' AS OrgType
	,'All Regions' AS Region
	,'England' AS OrgName
	,'ENG' AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) AS AvgAnyTherapistTime
	,CAST(SUM(CompTreatFlag) AS VARCHAR) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,IntEnabledTherProg

-- Regional -----------------------------------------------------------------------------------------

--Region, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm AS OrgName
	,RegionCodeComm AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg

--Region, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--Region, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Region' AS OrgType
	,RegionNameComm AS Region
	,RegionNameComm  AS OrgName
	,RegionCodeComm  AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg

--ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'ICB' AS OrgType
	,RegionNameComm AS Region
	,[ICBName] AS OrgName
	,[ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Sub-ICB' AS OrgType
	,RegionNameComm AS Region
	,[Sub-ICBName] AS OrgName
	,[Sub-ICBCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg

--Provider, 1+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'1+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, No IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'No IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

--Provider, 2+ IET
INSERT INTO [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
SELECT 
	Quarter
	,'Provider' AS OrgType
	,RegionNameProv AS Region
	,[ProviderName] AS OrgName
	,[ProviderCode] AS OrgCode
	,'2+ IET' AS AppointmentType
	,IntEnabledTherProg
	,CASE WHEN COUNT(ClinContactDurOfCareAct) < 5 THEN NULL ELSE AVG(CAST(ClinContactDurOfCareAct AS DECIMAL(7,2))) END AS AvgAnyTherapistTime
	,CASE WHEN SUM(CompTreatFlag) < 5 THEN '*' ELSE CAST(ROUND((SUM(CompTreatFlag)+2)/5,0)*5 AS VARCHAR) END AS CompTreatFlag

FROM [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Quarter
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg

---------------------------------Final Averages Table--------------------------
--Combines into one averages table that is used in the dashboard
--This table is re-run each month
IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_Averages]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_Averages]
SELECT
	a.[Quarter]
	,a.OrgType
	,a.Region
	,a.OrgCode
	,a.OrgName
	,a.AppointmentType
	,a.IntEnabledTherProg
	,a.AverageNumberofIETAppointmentsPerTreatment

	,a.AverageAnyTherapistTimePerTreatment
	,a.AverageIETTherapistTimePerTreatment
	,c.AvgAnyTherapistTime
	,b.AvgIETTherapistTime

	,a.CompTreatFlag as CompTreatFlag

INTO [MHDInternal].[DASHBOARD_TTAD_IET_Averages]
FROM [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat] a
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime] b on a.OrgType=b.OrgType AND a.OrgCode=b.OrgCode AND a.OrgName=b.OrgName AND a.Region=b.Region AND a.[Quarter]=b.[Quarter]
	AND a.AppointmentType=b.AppointmentType AND a.IntEnabledTherProg=b.IntEnabledTherProg
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime] c on a.OrgType=c.OrgType AND a.OrgCode=c.OrgCode AND a.OrgName=c.OrgName AND a.Region=c.Region AND a.[Quarter]=c.[Quarter]
	AND a.AppointmentType=c.AppointmentType AND a.IntEnabledTherProg=c.IntEnabledTherProg

-----------------------------------------
--Drop Temp Tables:
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration_Step1]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_NoIETDuration]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_Base]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_PEQRank]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_IETContacts]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_BaseAppts]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgIETContactBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AllContacts]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgAllContactBase]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgApptsAndTimePerTreat]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgIETTherapistTime]
DROP TABLE [MHDInternal].[TEMP_TTAD_IET_AvgAnyTherapistTime]
