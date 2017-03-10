/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List all indexes used in a database, their usage statistics and their particualrs
only relevant up to when the DMV info was reset

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
	   DB_ID() AS [dbid],
	   DB_NAME(DB_ID()) AS [dbname],
	   [ss].[name] AS [schemaname],
	   [o].object_id,
	   [o].[name] AS [objectname],
	   [x].[index_id],
	   [x].[name] AS [indexname],
	   [us].[user_seeks],
	   [us].[user_scans],
	   [us].[user_lookups],
	   [us].[user_updates]
FROM   [sys].[objects] AS [o]
	   INNER JOIN [sys].[indexes] AS [x] ON [o].object_id = [x].object_id
	   INNER JOIN [sys].[schemas] AS [ss] ON [o].schema_id = [ss].schema_id
	   LEFT JOIN [sys].[dm_db_index_usage_stats] AS [us] ON [us].[database_id] = DB_ID()
															AND [us].object_id = [o].object_id
															AND [us].[index_id] = [x].[index_id]
WHERE  [o].[type] = 'u'
ORDER BY 2,
		 3,
		 5,
		 7;