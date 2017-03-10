/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List the datasbes and the last time they were accessed
This is relevant to the last time the server was restarted as such this is a guide as to last accessed
Databases never accessed arent listed

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

SELECT [databasename],
	   MAX([lastaccessdate]) AS [lastaccessdate]
FROM
(
	SELECT DB_NAME([database_id]) AS [databasename],
		   [last_user_seek],
		   [last_user_scan],
		   [last_user_lookup],
		   [last_user_update]
	FROM   [sys].[dm_db_index_usage_stats]
) AS [pivottable] UNPIVOT([lastaccessdate] FOR [last_user_access] IN([last_user_seek],
																	 [last_user_scan],
																	 [last_user_lookup],
																	 [last_user_update])) AS [unpivottable]
GROUP BY [databasename]
HAVING [databasename] NOT IN('master', 'tempdb', 'model', 'msdb')
ORDER BY 2;