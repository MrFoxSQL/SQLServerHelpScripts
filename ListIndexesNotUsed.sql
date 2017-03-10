/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List all indexes NOT used in a database relevant to when the DMV stats where updated
First part will list the indexes not used
Second part will create a DROP script you can copy and run to drop the indexes

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

IF EXISTS
(
	SELECT 1
	FROM   [tempdb].[sys].[objects]
	WHERE  [type] = 'U'
		   AND [name] LIKE '#UnusedIndexes%'
)
	DROP TABLE [#unusedindexes];
GO
SELECT OBJECT_SCHEMA_NAME([i].object_id) AS [schemaname],
	   OBJECT_NAME([i].object_id) AS [objectname],
	   [i].[name] AS [unused index],
	   [s].[user_updates],
	   [s].[user_seeks],
	   [s].[user_scans],
	   [s].[user_lookups],
	   [i].[is_unique],
	   [i].[is_primary_key],
	   [i].[is_unique_constraint],
	   [i].[is_disabled],
	   [i].[fill_factor],
	   [i].[type_desc],
	   [ps].[row_count],
	   CAST(
			   (
				   [ps].[usedpages] * 8.0 / 1024.0
			   ) AS DECIMAL(20, 2)) AS [mbsize]
INTO [#unusedindexes]
FROM   [sys].[indexes] AS [i]
	   INNER JOIN
(
	SELECT object_id,
		   [index_id],
		   SUM([used_page_count]) AS [usedpages],
		   SUM([row_count]) AS [row_count]
	FROM   [sys].[dm_db_partition_stats]
	GROUP BY object_id,
			 [index_id]
) AS [ps] ON [i].[index_id] = [ps].[index_id]
			 AND [i].object_id = [ps].object_id
	   LEFT JOIN [sys].[dm_db_index_usage_stats] AS [s] ON [i].object_id = [s].object_id
														   AND [i].[index_id] = [s].[index_id]
														   AND [s].[database_id] = DB_ID()
WHERE  OBJECTPROPERTY([i].object_id, 'IsIndexable') = 1
	   AND OBJECTPROPERTY([i].object_id, 'IsIndexed') = 1
	   AND [ps].[row_count] > 0
	   AND [i].[is_unique] = 0
	   AND [i].[is_primary_key] = 0
	   AND [i].[is_unique_constraint] = 0
	   AND ([s].[user_updates] > 0
			AND [s].[user_seeks] = 0
			AND [s].[user_scans] = 0
			AND [s].[user_lookups] = 0 -- index is being updated, but not used by seeks/scans/lookups
			OR [s].[index_id] IS NULL -- and dm_db_index_usage_stats has no reference to this index
	   )
ORDER BY OBJECT_NAME([i].object_id) ASC;
GO
SELECT *
FROM   [#unusedindexes]
ORDER BY [schemaname],
		 [objectname],
		 [unused index];
GO
SELECT 'DROP INDEX '+[unused index]+' ON '+[schemaname]+'.'+[objectname]+';'+CHAR(13)+CHAR(10)+'GO'
FROM   [#unusedindexes]
ORDER BY [schemaname],
		 [objectname],
		 [unused index];
GO