/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
list the backup history of the databses within msdb

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

SELECT DISTINCT
	   [backup_set_id],
	   [server_name] = LEFT([server_name], 15),
	   [database_name] = LEFT([database_name], 20),
	   [backup_start_date] = CONVERT(  VARCHAR(25), [backup_start_date], 121),
	   [backup_finish_date] = CONVERT( VARCHAR(25), [backup_finish_date], 121),
	   [backup_duration_sec] = DATEDIFF([ss], [backup_start_date], [backup_finish_date]),
	   [backup_duration_min] = DATEDIFF([mi], [backup_start_date], [backup_finish_date]),
	   [backup_size],
	   [physical_device_name]
FROM   [msdb].[dbo].[backupset] AS [bs](nolock)
	   INNER JOIN [msdb].[dbo].[backupmediafamily] AS [bmf](nolock) ON [bs].[media_set_id] = [bmf].[media_set_id]
WHERE  [backup_start_date] BETWEEN DATEADD([dd], -2, GETDATE()) AND DATEADD([dd], 0, GETDATE())
ORDER BY [database_name];