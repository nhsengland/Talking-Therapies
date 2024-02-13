-- DELETE MAX(Month) -----------------------------------------------------------------------
DELETE FROM [MHDInternal].DASHBOARD_TTAD_KeyMetrics
WHERE [Month] = (SELECT MAX([Month]) FROM [MHDInternal].[DASHBOARD_TTAD_KeyMetrics])
-----------------
SET DATEFIRST 1
SET NOCOUNT ON
----------------
DECLARE @Offset INT = 0
-------------------------

DECLARE @PeriodStart AS DATE = (SELECT DATEADD(MONTH,@Offset,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @PeriodEnd AS DATE = (SELECT EOMONTH(DATEADD(MONTH,@Offset,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])
DECLARE @MonthYear AS VARCHAR(50) = (DATENAME(M, @PeriodStart) + ' ' + CAST(DATEPART(YYYY, @PeriodStart) AS VARCHAR))

PRINT CHAR(10) + 'Month: ' + CAST(@MonthYear AS VARCHAR(50))
------------------------------------------------------------------------------------------------------------------------------------------------------															

INSERT INTO MHDInternal.DASHBOARD_TTAD_KeyMetrics																					

SELECT * FROM (																					

  SELECT																					
																					
		CAST(i.[ReportingPeriodStartDate] AS DATE) AS 'Month'																
		,'England' AS 'Organisation Code'
		,'England' AS 'Organisation Name'
		,'England' AS'RegionNameComm'
		,'England' AS 'RegionCodeComm'															
		,'National' AS 'GroupType'																
		
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Count_Referrals'																		
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Count_Access'																															
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Recovery'																														
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Count_FinishedCourseTreatment'																															
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS 'Count_NotAtCaseness'		
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TherapySession_FirstDate] IS NULL THEN r.[PathwayID] ELSE NULL END) AS 'EndedBeforeTreatment'
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TreatmentCareContact_Count] = 1 THEN r.[PathwayID] ELSE NULL END) AS 'EndedTreatedOnce'
		-------------																		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS 'Percentage_Recovery'
		-------------
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS 'Percentage_ReliableRecovery'
    -------------
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																				
		AS 'Percentage_ReliableDeterioration'
    -------------
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_ReliableImprovement'
    ------------- 	  		
		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS 'Percentage_Recovery_WB'
    -------------
		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS 'Percentage_Recovery_EM'
		-------------																							
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS 'Count_FirstTreatment6WeeksFinishedCourseTreatment'																
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
		<=126 THEN r.PathwayID ELSE NULL END) AS 'Count_FirstTreatment18WeeksFinishedCourseTreatment'
		-------------												
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		
    ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_FirstTreatment6WeeksFinishedCourseTreatment'																	
		-------------																	
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		
    ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_FirstTreatment18WeeksFinishedCourseTreatment'								
		-------------																		
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >28 THEN r.PathwayID ELSE NULL END) AS 'Count_FirstToSecondTreatmentOver28days'																
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS 'Count_FirstToSecondTreatmentOver90days'																			
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS 'Count_SecondTreatment'																
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN  TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_FirstToSecondTreatmentOver90days'																		
																					
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS 'OpenReferralOver90daysNoContact'																	
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS 'OpenReferral'																	
																					
		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_OpenReferralNoActivityOver90days'

		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1  AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1 AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS 'Percentage_OpenReferralNoActivityOver90days2Apps'																				
		
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
		AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104')  AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'LIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104','1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HILIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism = '01' AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'F2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'NonF2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('01','02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'Apts'

		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_ReliableRecovery'
		
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Improvement'
		
FROM	[mesh_IAPT].[IDS101referral] r
  		--------------------------
  		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
  		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1
  		--------------------------
  		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = i.AuditId AND a.AttendOrDNACode in ('3','03','5','05','6','06')
  		LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = i.AuditId AND c.Unique_MonthID = i.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 

WHERE	UsePathway_Flag = 'True'
		  AND i.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart																		
																					
GROUP BY CAST(i.[ReportingPeriodStartDate] AS DATE)																													
																					
UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT																					
																					
		CAST(i.[ReportingPeriodStartDate] AS DATE) AS Month																			
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'Organisation Code'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'Organisation Name'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS 'RegionNameComm'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm',																			
		'Region' AS GroupType																			
		
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Referrals	
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Access																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_Recovery																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_FinishedCourseTreatment																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS Count_NotAtCaseness	
				
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TherapySession_FirstDate] IS NULL THEN r.[PathwayID] ELSE NULL END) AS 'EndedBeforeTreatment'

		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TreatmentCareContact_Count] = 1 THEN r.[PathwayID] ELSE NULL END) AS 'EndedTreatedOnce'
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		
    ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery		
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_ReliableRecovery	
  
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																				
		AS Percentage_ReliableDeterioration

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_ReliableImprovement	
			   		 	  		
		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_WB	

		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_EM
																													
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment6WeeksFinishedCourseTreatment																		
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
		<=126 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment6WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >28 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver28days																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_SecondTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN  TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver90daysNoContact																			
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral																			
																					
		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days

		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1  AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1 AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days2Apps																				
		
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
		AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104')  AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'LIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104','1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HILIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism = '01' AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'F2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'NonF2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('01','02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'Apts'
		
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_ReliableRecovery
		
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS 'Count_Improvement'
		
FROM	[mesh_IAPT].[IDS101referral] r
		--------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1

		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = i.AuditId AND a.AttendOrDNACode in ('3','03','5','05','6','06')
		LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = i.AuditId AND c.Unique_MonthID = i.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 

		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
 
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL	

WHERE	UsePathway_Flag = 'True'
		AND i.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart																		
																					
GROUP BY CAST(i.[ReportingPeriodStartDate] AS DATE)																				
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END		

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT																					
																					
		CAST(i.[ReportingPeriodStartDate] AS DATE) AS Month																			
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Organisation Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Organisation Name'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm',																			
		'Sub-ICB' AS GroupType																			
		
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Referrals	
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Access																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_Recovery																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_FinishedCourseTreatment																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS Count_NotAtCaseness	
		
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TherapySession_FirstDate] IS NULL THEN r.[PathwayID] ELSE NULL END) AS 'EndedBeforeTreatment'
		
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TreatmentCareContact_Count] = 1 THEN r.[PathwayID] ELSE NULL END) AS 'EndedTreatedOnce'
																							
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery		
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_ReliableRecovery	

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																				
		AS Percentage_ReliableDeterioration

		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_ReliableImprovement	
			   		 	  		
		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_WB	

		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_EM									
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment6WeeksFinishedCourseTreatment																		
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
		<=126 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment6WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >28 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver28days																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_SecondTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN  TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver90daysNoContact																			
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral																			
																					
		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days

		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1  AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1 AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days2Apps																				
		
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
		AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104')  AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'LIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104','1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HILIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism = '01' AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'F2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'NonF2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('01','02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'Apts'
			
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_ReliableRecovery
		
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_Improvement
																				
FROM	[mesh_IAPT].[IDS101referral] r
		--------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1

		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = i.AuditId AND a.AttendOrDNACode in ('3','03','5','05','6','06')
		LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = i.AuditId AND c.Unique_MonthID = i.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 

		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
 
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL	

WHERE	UsePathway_Flag = 'True'
		AND i.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart																		
																					
GROUP BY CAST(i.[ReportingPeriodStartDate] AS DATE)																				
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END		

UNION -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT																					
																					
		CAST(i.[ReportingPeriodStartDate] AS DATE) AS Month																			
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END AS 'Organisation Code'
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END AS 'Organisation Name'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm',																			
		'ICB' AS GroupType																			
		
		,COUNT(DISTINCT CASE WHEN ReferralRequestReceivedDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Referrals	
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_FirstDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_Access																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_Recovery																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_FinishedCourseTreatment																			
																					
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS Count_NotAtCaseness	
		
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TherapySession_FirstDate] IS NULL THEN r.[PathwayID] ELSE NULL END) AS 'EndedBeforeTreatment'
		
		,COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND r.[TreatmentCareContact_Count] = 1 THEN r.[PathwayID] ELSE NULL END) AS 'EndedTreatedOnce'
																							
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery		
		
		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_ReliableRecovery	


		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableDeterioration_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																				
		AS Percentage_ReliableDeterioration



		,CASE WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_ReliableImprovement	

			   		 	  		
		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory = 'A' AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_WB	

		,CASE WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END)																			
		-COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND  Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float)																			
		-CAST(COUNT(DISTINCT CASE WHEN Validated_EthnicCategory IN ('B','C','D','E','F','G','B','C','H','J','K','L''M','N','P','R','S') AND CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND NotCaseness_Flag = 'True' THEN r.PathwayID ELSE NULL END)AS float))) END																			
		AS Percentage_Recovery_EM
																		
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment6WeeksFinishedCourseTreatment																		
																					
		,COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
		<=126 THEN r.PathwayID ELSE NULL END) AS Count_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=42 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment6WeeksFinishedCourseTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																		
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' AND DATEDIFF(dd,[ReferralRequestReceivedDate],[TherapySession_FirstDate])																			
			<=126 THEN r.PathwayID ELSE NULL END) AS float)																		
		/(CAST(COUNT(DISTINCT CASE WHEN r.[ServDischDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND CompletedTreatment_Flag = 'True' THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstTreatment18WeeksFinishedCourseTreatment																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >28 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver28days																			
																					
		,COUNT( DISTINCT CASE WHEN R.[TherapySession_SecondDate] BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS Count_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS Count_SecondTreatment																			
																					
		,CASE WHEN COUNT(DISTINCT CASE WHEN  TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND DATEDIFF(DD,[TherapySession_FirstDate],[TherapySession_SecondDate]) >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN TherapySession_SecondDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_FirstToSecondTreatmentOver90days																			
																					
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS OpenReferralOver90daysNoContact																			
		,COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS OpenReferral																			
																					
		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT(DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days

		,CASE WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) = 0 THEN NULL																			
		WHEN COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1  AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) = 0 THEN NULL 																			
		ELSE 																			
																					
		(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TreatmentCareContact_Count > 1 AND DATEDIFF(DD ,TherapySession_LastDate, [ReportingPeriodEndDate])  >90 THEN r.PathwayID ELSE NULL END) AS float)																			
		/(CAST(COUNT( DISTINCT CASE WHEN r.ServDischDate IS NULL AND TherapySession_LastDate IS NOT NULL  THEN r.PathwayID ELSE NULL END) AS float))) END																			
		AS Percentage_OpenReferralNoActivityOver90days2Apps																				
		
		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
		AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104')  AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'LIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate 
			AND c.CodeProcAndProcStatus IN ('748051000000105','748101000000105','748041000000107','748091000000102','748061000000108','199314001','702545008','1026111000000108','975131000000104','1127281000000100','1129471000000105','842901000000108','286711000000107','314034001','449030000','933221000000107','1026131000000100','304891004','443730003') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'HILIApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism = '01' AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'F2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'NonF2FApts'

		,COUNT(DISTINCT CASE WHEN a.CareContDate BETWEEN i.ReportingPeriodStartDate AND i.ReportingPeriodEndDate AND a.ConsMechanism IN ('01','02','04','05','09','10','11','12','13','98') AND a.Unique_CareContactID IS NOT NULL THEN a.Unique_CareContactID ELSE NULL
			END) AS 'Apts'
			
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' AND Recovery_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_ReliableRecovery
		
		,COUNT(DISTINCT CASE WHEN CompletedTreatment_Flag = 'True' AND r.ServDischDate BETWEEN i.[ReportingPeriodStartDate] AND i.[ReportingPeriodEndDate] AND ReliableImprovement_Flag = 'True' THEN  r.PathwayID ELSE NULL END) AS Count_Improvement
																				
FROM	[mesh_IAPT].[IDS101referral] r
		--------------------------
		INNER JOIN [mesh_IAPT].[IDS001mpi] mpi ON r.recordnumber = mpi.recordnumber
		INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] i ON r.[UniqueSubmissionID] = i.[UniqueSubmissionID] AND r.AuditId = i.AuditId AND IsLatest = 1

		--------------------------
		LEFT JOIN [mesh_IAPT].[IDS201carecontact] a ON r.PathwayID = a.PathwayID AND a.AuditId = i.AuditId AND a.AttendOrDNACode in ('3','03','5','05','6','06')
		LEFT JOIN [mesh_IAPT].[IDS202careactivity] c ON c.PathwayID = a.PathwayID AND c.AuditId = i.AuditId AND c.Unique_MonthID = i.Unique_MonthID AND a.[CareContactId] = c.[CareContactId] 


		--Four tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
		LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON r.OrgIDComm = cc.Org_Code COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, r.OrgIDComm) = ch.Organisation_Code COLLATE database_default
			AND ch.Effective_To IS NULL
 
		LEFT JOIN [Internal_Reference].[Provider_Successor] ps ON r.OrgID_Provider = ps.Prov_original COLLATE database_default
		LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON COALESCE(ps.Prov_Successor, r.OrgID_Provider) = ph.Organisation_Code COLLATE database_default
			AND ph.Effective_To IS NULL	


WHERE	UsePathway_Flag = 'True'
		AND i.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, -1, @PeriodStart) AND @PeriodStart																		
																					
GROUP BY CAST(i.[ReportingPeriodStartDate] AS DATE)																				
		,CASE WHEN ch.[STP_Code] IS NOT NULL THEN ch.[STP_Code] ELSE 'Other' END
		,CASE WHEN ch.[STP_Name] IS NOT NULL THEN ch.[STP_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END	

)_
GO

-- Adding Average Waits and Appointments data tables (for past 12 months for ICBs)

DROP TABLE [MHDInternal].[Temp_TTAD_KeyMetrics]

IF OBJECT_ID('[MHDInternal].[Temp_TTAD_MaxMonth]') IS NOT NULL DROP TABLE [MHDInternal].[Temp_TTAD_MaxMonth]

SELECT MAX([Month]) AS MaxMonth INTO [MHDInternal].[Temp_TTAD_MaxMonth] FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait]

IF OBJECT_ID('[MHDInternal].[DASHBOARD_TTAD_KeyMetricsAvgWaits]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_KeyMetricsAvgWaits]

SELECT DISTINCT hl.Month
		,CASE WHEN ch.[Organisation_Code] IS NOT NULL THEN ch.[Organisation_Code] ELSE 'Other' END AS 'Organisation Code'
		,CASE WHEN ch.[Organisation_Name] IS NOT NULL THEN ch.[Organisation_Name] ELSE 'Other' END AS 'Organisation Name'
		,CASE WHEN ch.[Region_Name] IS NOT NULL THEN ch.[Region_Name] ELSE 'Other' END AS'RegionNameComm'
		,CASE WHEN ch.[Region_Code] IS NOT NULL THEN ch.[Region_Code] ELSE 'Other' END AS 'RegionCodeComm'
		,hl.MeanAssessToFirstHI
		,hl.MeanAssessToFirstLI
		,mw.MeanMaxWait
		,mw.MedianMaxWait
		,aw.MeanWait
		,aw.MedianWait 
		,av.MeanApps

INTO [MHDInternal].[DASHBOARD_TTAD_KeyMetricsAvgWaits]

FROM [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_AssessToFirstLIHI] hl
     -----------------------
      INNER JOIN [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Max_Wait] mw ON hl.[CCG Code] = mw.[CCG Code] AND hl.Month = mw.Month AND hl.Level = mw.Level
      INNER JOIN [MHDInternal].[DASHBOARD_TTAD_PDT_Avg_Wait_Between_Apts] aw ON hl.[CCG Code] = aw.[CCG Code] AND hl.Month = aw.Month AND hl.Level = aw.Level
      INNER JOIN [MHDInternal].[DASHBOARD_TTAD_Averages] av ON hl.[CCG Code] = av.[CCG Code] AND hl.Month = av.month AND av.Level IN ('CCG','National') AND Category = 'Total'
     -----------------------
      LEFT JOIN  [MHDInternal].[Temp_TTAD_MaxMonth] mm ON hl.Month = mm.MaxMonth AND DATEDIFF(M, hl.[Month], MaxMonth) <= 12
     -----------------------
      LEFT JOIN [Internal_Reference].[ComCodeChanges] cc ON hl.[CCG Code] = cc.Org_Code COLLATE database_default
      LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON COALESCE(cc.New_Code, hl.[CCG Code]) = ch.Organisation_Code COLLATE database_default AND ch.Effective_To IS NULL

WHERE hl.[Level] IN ('CCG','Sub-ICB','National') 
