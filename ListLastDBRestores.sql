/*******************************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List the database restore history captured within msdb

There are two variables, @dbname and @days

(@dbname) = the name of the database you are searching for and would need to be enclosed in single quotation marks. 
NULL = all databases 
	
(@days) = negative integer (i.e., -7) which represents how many days previously you want to search.  
NULL = default to searching for only the previous thirty days

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
*******************************************************************************************************************/

DECLARE
	@dbname SYSNAME,
	@days   INT;
SET @dbname = NULL; --substitute for whatever database name you want
SET @days = -30; --previous number of days, script will default to 30
SELECT [rsh].[destination_database_name] AS [database],
	   [rsh].user_name AS [restored by],
	   CASE
		   WHEN [rsh].[restore_type] = 'D'
		   THEN 'Database'
		   WHEN [rsh].[restore_type] = 'F'
		   THEN 'File'
		   WHEN [rsh].[restore_type] = 'G'
		   THEN 'Filegroup'
		   WHEN [rsh].[restore_type] = 'I'
		   THEN 'Differential'
		   WHEN [rsh].[restore_type] = 'L'
		   THEN 'Log'
		   WHEN [rsh].[restore_type] = 'V'
		   THEN 'Verifyonly'
		   WHEN [rsh].[restore_type] = 'R'
		   THEN 'Revert'
		   ELSE [rsh].[restore_type]
	   END AS [restore type],
	   [rsh].[restore_date] AS [restore started],
	   [bmf].[physical_device_name] AS [restored from],
	   [rf].[destination_phys_name] AS [restored to]
FROM   [msdb].[dbo].[restorehistory] AS [rsh]
	   INNER JOIN [msdb].[dbo].[backupset] AS [bs] ON [rsh].[backup_set_id] = [bs].[backup_set_id]
	   INNER JOIN [msdb].[dbo].[restorefile] AS [rf] ON [rsh].[restore_history_id] = [rf].[restore_history_id]
	   INNER JOIN [msdb].[dbo].[backupmediafamily] AS [bmf] ON [bmf].[media_set_id] = [bs].[media_set_id]
WHERE  [rsh].[restore_date] >= DATEADD([dd], ISNULL(@days, -30), GETDATE()) --want to search for previous days
	   AND [destination_database_name] = ISNULL(@dbname, [destination_database_name]) --if no dbname, then return all
ORDER BY [rsh].[restore_history_id] DESC;
GO