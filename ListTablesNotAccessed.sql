/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List all of the database tables which have not been accessed.  Tables with a NULL
have not been accessed sicne the last SQL Server restart (DMV clear)

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

WITH lastactivity([objectid],
				  [lastaction])
	 AS (
	 SELECT object_id AS [tablename],
			[last_user_seek] AS [lastaction]
	 FROM     [sys].[dm_db_index_usage_stats] AS [u]
	 WHERE   [database_id] = DB_ID(DB_NAME())
	 UNION
	 SELECT object_id AS [tablename],
			[last_user_scan] AS [lastaction]
	 FROM     [sys].[dm_db_index_usage_stats] AS [u]
	 WHERE   [database_id] = DB_ID(DB_NAME())
	 UNION
	 SELECT object_id AS [tablename],
			[last_user_lookup] AS [lastaction]
	 FROM   [sys].[dm_db_index_usage_stats] AS [u]
	 WHERE  [database_id] = DB_ID(DB_NAME()))
	 SELECT OBJECT_NAME([so].object_id) AS [tablename],
			MAX([la].[lastaction]) AS [lastselect]
	 FROM   [sys].[objects] AS [so]
			LEFT JOIN [lastactivity] AS [la] ON [so].object_id = [la].[objectid]
	 WHERE  [so].[type] = 'U'
			AND [so].object_id > 100
	 GROUP BY OBJECT_NAME([so].object_id)
	 ORDER BY OBJECT_NAME([so].object_id);