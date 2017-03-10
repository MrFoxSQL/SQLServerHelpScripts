/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
returns the list of reports within a SSRS database
requires "ReportServerDB" database to exist

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
	   [c].[name] AS [reportname],
	   [c].path AS [reportpath],
	   isnull([u0].[username], 'Not Scheduled') AS [reportinternalowner],
	   isnull([s].[name], 'Not Scheduled') AS [scheduleinternalname],
	   isnull([u1].[username], 'Not Scheduled') AS [scheduleinternalowner],
	   CASE
		   WHEN [s].[name] IS NOT NULL
				AND [sj].[name] IS NULL
		   THEN '*** ERROR: SQL Agent Job "'+CONVERT( VARCHAR(50), [s].[scheduleid])+'" Does Not Exist ***'
		   ELSE [sj].[name]
	   END AS [sqlagentjobname],
	   [su].[name] AS [sqlagentjobowner],
	   [sj].[date_created] AS [sqlagentjobcreateddate],
	   [sjs].[next_run_date],
	   [sjs].[next_run_time],
	   AVG(CAST([timedataretrieval] AS  FLOAT)) AS [avgtimedataretrieval],
	   AVG(CAST([timeprocessing] AS  FLOAT)) AS [avgtimeprocessing],
	   AVG(CAST([timerendering] AS  FLOAT)) AS [avgtimerendering],
	   AVG(CAST([bytecount] AS  FLOAT)) AS [avgbytecount],
	   AVG(CAST([rowcount] AS  FLOAT)) AS [avgrowcount]
FROM   [dbo].[catalog] AS [c]
	   INNER JOIN [dbo].[users] AS [u0] ON [c].[createdbyid] = [u0].[userid]
	   LEFT JOIN [dbo].[reportschedule] AS [rs] ON [c].[itemid] = [rs].[reportid]
	   LEFT JOIN [dbo].[schedule] AS [s] ON [rs].[scheduleid] = [s].[scheduleid]
	   LEFT JOIN [dbo].[users] AS [u1] ON [s].[createdbyid] = [u1].[userid]
	   LEFT JOIN [msdb].[dbo].[sysjobs] AS [sj] ON CONVERT( VARCHAR(50), [s].[scheduleid]) = [sj].[name]
	   LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sjs] ON [sj].[job_id] = [sjs].[job_id]
	   LEFT JOIN [msdb].[dbo].[sysusers] AS [su] ON [sj].[owner_sid] = [su].[sid]
	   LEFT JOIN [dbo].[executionlog] AS [el] ON [el].[reportid] = [c].[itemid]
WHERE  [c].[type] = 2 -- Reports
GROUP BY [c].[name],
		 [c].path,
		 isnull([u0].[username], 'Not Scheduled'),
		 isnull([s].[name], 'Not Scheduled'),
		 isnull([u1].[username], 'Not Scheduled'),
		 CASE
			 WHEN [s].[name] IS NOT NULL
				  AND [sj].[name] IS NULL
			 THEN '*** ERROR: SQL Agent Job "'+CONVERT( VARCHAR(50), [s].[scheduleid])+'" Does Not Exist ***'
			 ELSE [sj].[name]
		 END,
		 [su].[name],
		 [sj].[date_created],
		 [sjs].[next_run_date],
		 [sjs].[next_run_time]
ORDER BY 1,
		 2,
		 3;