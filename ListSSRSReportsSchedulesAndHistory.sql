/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
Returns the list of reports within a SSRS database and history from SQL AGent
NOTE - Requires "ReportServer" database to exist. Change the DB name for your SSRS DB

HISTORY:
--------------------------------------------------------------------------------
Date:		Developer:			Description:
--------------------------------------------------------------------------------
*			*					Created
--------------------------------------------------------------------------------

NOTES:
--------------------------------------------------------------------------------
THIS SCRIPT/CODE ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
LIMITED TESTING HAS BEEN PERFORMED ON THIS SCRIPT/CODE AND THEREFORE THE AUTHOR DOES NOT WARRANT
THAT ANY SCRIPT/CODE IS BUG OR ERROR-FREE.  IT IS EXPECTED THAT ANY SCRIPT/CODE UNDERGO YOUR OWN 
TESTING AND/OR VALIDATION BEFORE USAGE ON ANY CRITICAL SQL SERVER PLATFORM.
THIS SCRIPT MAY BE A COLLECTION OF MY OWN CODE COLLATED OVER MANY YEARS, OR OTHER CODE I HAVE 
LOCATED ON THE WEB WITH AN UNKNOWN ORIGIN.  WHERE CODE HAS BEEN IDENTIFIED IT WILL BE CITED.
================================================================================
************************************************************************************************/

SET NOCOUNT ON;
GO
SELECT DISTINCT
	   [c].[itemid] AS [ssrsreportid],
	   [c].[name] AS [ssrsreportname],
	   [c].path AS [ssrsreportpath],
	   isnull([s].[name], 'Not Scheduled') AS [ssrsscheduleinternalname],
	   isnull([ss].[eventtype], 'Not Scheduled') AS [ssrssubscriptiontype],
	   isnull([ss].[deliveryextension], 'Not Scheduled') AS [ssrssubscriptiondelivery],
	   isnull([ss].[laststatus], 'Not Scheduled') AS [ssrssubscriptionlastexestatus],
	   CASE
		   WHEN [s].[name] IS NOT NULL
				AND [sj].[name] IS NULL
		   THEN '*** ERROR: SQL Agent Job "'+CONVERT(   VARCHAR(50), [s].[scheduleid])+'" Does Not Exist ***'
		   ELSE isnull([sj].[name], 'Not Scheduled')
	   END AS [sqlagentjobname],
	   CASE
		   WHEN [sj].[enabled] = 1
		   THEN 'Yes'
		   WHEN [sj].[enabled] = 0
		   THEN 'No'
		   ELSE 'Not Scheduled'
	   END AS [sqlagentjobenabled],
	   isnull(CONVERT( VARCHAR(25), [sj].[date_created], 121), 'Not Scheduled') AS [sqlagentjobcreateddate],
	   isnull(CONVERT( VARCHAR(15), [sjs].[next_run_date]), 'Not Scheduled') AS [sqlagentjobnextrundate],
	   isnull(CONVERT( VARCHAR(15), [sjs].[next_run_time]), 'Not Scheduled') AS [sqlagentjobnextruntime],
	   isnull(CONVERT( VARCHAR(15), [jh].[run_duration]), 'Not Scheduled') AS [sqlagentlastrunduration],
	   CASE
		   WHEN [jh].[run_status] = 1
		   THEN 'Successful'
		   WHEN [jh].[run_status] = 0
		   THEN 'Failed'
		   WHEN [jh].[run_status] = 2
		   THEN 'Retry'
		   WHEN [jh].[run_status] = 3
		   THEN 'Cancelled'
		   ELSE 'Not Scheduled'
	   END AS [sqlagentlastrunstatus],
	   isnull(SUBSTRING([jh].[message], 1, 250), 'Not Scheduled') AS [sqlagentlastrunstatusmessage],
	   CAST(AVG(CAST([timedataretrieval] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exeavgtimedataretrieval],
	   CAST(AVG(CAST([timeprocessing] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exeavgtimeprocessing],
	   CAST(AVG(CAST([timerendering] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exeavgtimerendering],
	   CAST(AVG(CAST([bytecount] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exeavgbytecount],
	   CAST(AVG(CAST([rowcount] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exeavgrowcount],
	   CAST(MAX(CAST([timedataretrieval] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exemaxtimedataretrieval],
	   CAST(MAX(CAST([timeprocessing] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exemaxtimeprocessing],
	   CAST(MAX(CAST([timerendering] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exemaxtimerendering],
	   CAST(MAX(CAST([bytecount] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exemaxbytecount],
	   CAST(MAX(CAST([rowcount] AS   FLOAT)) AS NUMERIC(15, 2)) AS [exemaxrowcount]
FROM      [dbo].[catalog] AS [c] WITH (nolock)
		  LEFT JOIN [dbo].[reportschedule] AS [rs] WITH (nolock) ON [c].[itemid] = [rs].[reportid]
		  LEFT JOIN [dbo].[schedule] AS [s] WITH (nolock) ON [rs].[scheduleid] = [s].[scheduleid]
		  LEFT JOIN [dbo].[subscriptions] AS [ss] WITH (nolock) ON [rs].[subscriptionid] = [ss].[subscriptionid]
		  LEFT JOIN [msdb].[dbo].[sysjobs] AS [sj] WITH (nolock) ON CONVERT( VARCHAR(50), [s].[scheduleid]) = [sj].[name]
		  LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sjs] WITH (nolock) ON [sj].[job_id] = [sjs].[job_id]
		  LEFT JOIN [msdb].[dbo].[sysjobhistory] AS [jh] WITH (nolock) ON [sj].[job_id] = [jh].[job_id]
																		  AND [jh].[instance_id] =
(
	SELECT MAX([x].[instance_id])
	FROM   [msdb].[dbo].[sysjobhistory] AS [x] WITH (nolock)
	WHERE  [x].[job_id] = [jh].[job_id]
		   AND [x].[step_id] = 0 -- Summary Only
)
		  LEFT JOIN [dbo].[executionlog] AS [el] WITH (nolock) ON [el].[reportid] = [c].[itemid]
WHERE 1 = 1
	  AND [c].[type] = 2 -- Reports Only
--and		c.[name] = 'SalesSummary' -- for a specific report
GROUP BY [c].[itemid],
		 [c].[name],
		 [c].path,
		 isnull([s].[name], 'Not Scheduled'),
		 isnull([ss].[eventtype], 'Not Scheduled'),
		 isnull([ss].[deliveryextension], 'Not Scheduled'),
		 isnull([ss].[laststatus], 'Not Scheduled'),
		 CASE
			 WHEN [s].[name] IS NOT NULL
				  AND [sj].[name] IS NULL
			 THEN '*** ERROR: SQL Agent Job "'+CONVERT(   VARCHAR(50), [s].[scheduleid])+'" Does Not Exist ***'
			 ELSE isnull([sj].[name], 'Not Scheduled')
		 END,
		 CASE
			 WHEN [sj].[enabled] = 1
			 THEN 'Yes'
			 WHEN [sj].[enabled] = 0
			 THEN 'No'
			 ELSE 'Not Scheduled'
		 END,
		 isnull(CONVERT( VARCHAR(25), [sj].[date_created], 121), 'Not Scheduled'),
		 isnull(CONVERT( VARCHAR(15), [sjs].[next_run_date]), 'Not Scheduled'),
		 isnull(CONVERT( VARCHAR(15), [sjs].[next_run_time]), 'Not Scheduled'),
		 isnull(CONVERT( VARCHAR(15), [jh].[run_duration]), 'Not Scheduled'),
		 CASE
			 WHEN [jh].[run_status] = 1
			 THEN 'Successful'
			 WHEN [jh].[run_status] = 0
			 THEN 'Failed'
			 WHEN [jh].[run_status] = 2
			 THEN 'Retry'
			 WHEN [jh].[run_status] = 3
			 THEN 'Cancelled'
			 ELSE 'Not Scheduled'
		 END,
		 isnull(SUBSTRING([jh].[message], 1, 250), 'Not Scheduled')
ORDER BY 1,
		 2,
		 3,
		 4,
		 7;