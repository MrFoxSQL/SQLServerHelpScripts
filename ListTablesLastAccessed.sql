/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List the tables that have been access, along with the last date and time that access occured

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

WITH lastactivity([schemaname],
				  object_id,
				  [tablename],
				  [lastaction],
				  [type])
	 AS (
	 SELECT [ss].[name] AS [schemaname],
			[o].object_id AS object_id,
			OBJECT_NAME([o].object_id) AS [tablename],
			[last_user_seek] AS [lastaction],
			[type]
	 FROM     [sys].[dm_db_index_usage_stats] AS [u]
			  LEFT JOIN [sys].[objects] AS [o] ON [u].object_id = [o].object_id
			  LEFT JOIN [sys].[schemas] AS [ss] ON [o].schema_id = [ss].schema_id
	 WHERE   [database_id] = DB_ID(DB_NAME())
	 UNION
	 SELECT [ss].[name] AS [schemaname],
			[o].object_id AS object_id,
			OBJECT_NAME([o].object_id) AS [tablename],
			[last_user_scan] AS [lastaction],
			[type]
	 FROM     [sys].[dm_db_index_usage_stats] AS [u]
			  LEFT JOIN [sys].[objects] AS [o] ON [u].object_id = [o].object_id
			  LEFT JOIN [sys].[schemas] AS [ss] ON [o].schema_id = [ss].schema_id
	 WHERE   [database_id] = DB_ID(DB_NAME())
	 UNION
	 SELECT [ss].[name] AS [schemaname],
			[o].object_id AS object_id,
			OBJECT_NAME([o].object_id) AS [tablename],
			[last_user_lookup] AS [lastaction],
			[type]
	 FROM   [sys].[dm_db_index_usage_stats] AS [u]
			LEFT JOIN [sys].[objects] AS [o] ON [u].object_id = [o].object_id
			LEFT JOIN [sys].[schemas] AS [ss] ON [o].schema_id = [ss].schema_id
	 WHERE  [database_id] = DB_ID(DB_NAME()))
	 SELECT [la].[schemaname],
			object_id,
			[tablename],
			[la].[type],
			MAX([la].[lastaction]) AS [lastselect]
	 FROM   [lastactivity] AS [la]
	 WHERE  [la].[type] = 'U'
			AND [la].object_id > 100
	 GROUP BY [la].[schemaname],
			  object_id,
			  [tablename],
			  [la].[type]
	 ORDER BY [lastselect] ASC;