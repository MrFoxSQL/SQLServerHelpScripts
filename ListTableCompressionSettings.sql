/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
list all of the database tables and indexes along with the compression status of
that object, rows, and data sizing

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

SELECT [s].[name] AS 'schema',
	   [o].[name] AS 'table',
	   CASE [o].[type]
		   WHEN 'v'
		   THEN 'View'
		   WHEN 'u'
		   THEN 'Table'
		   ELSE [o].[type]
	   END AS [objecttype],
	   [i].object_id,
	   [i].[name] AS [indexname],
	   [i].[index_id],
	   [i].[type],
	   [i].[type_desc],
	   [p].[data_compression_desc],
	   [p].[rows],
	   [i].[is_unique],
	   [i].[data_space_id],
	   [i].[ignore_dup_key],
	   [i].[is_primary_key],
	   [i].[is_unique_constraint],
	   [i].[fill_factor],
	   [i].[is_padded],
	   [i].[is_disabled],
	   [i].[is_hypothetical],
	   [i].[allow_row_locks],
	   [i].[allow_page_locks],
	   [i].[has_filter],
	   [i].[filter_definition],
	CASE
		WHEN [ps].[usedpages] > [ps].[pages]
		THEN
	(
		[ps].[usedpages] - [ps].[pages]
	)
		ELSE 0
	END * 8 AS [indexsizekb],
	CASE
		WHEN [ps].[usedpages] > [ps].[pages]
		THEN
	(
		[ps].[usedpages] - [ps].[pages]
	)
		ELSE 0
	END * 8 / 1024 AS [indexsizemb]
FROM   [sys].[indexes] AS [i]
	   INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [i].object_id
	   LEFT JOIN [sys].[schemas] AS [s] ON [o].schema_id = [s].schema_id
	   LEFT JOIN [sys].[partitions] AS [p] ON [i].[index_id] = [p].[index_id]
											  AND [i].object_id = [p].object_id
	   INNER JOIN
(
	SELECT object_id,
		   [index_id],
		   SUM([used_page_count]) AS [usedpages],
		   SUM(CASE
				   WHEN([index_id] < 2)
				   THEN
				  (
					  [in_row_data_page_count] + [lob_used_page_count] + [row_overflow_used_page_count]
				  )
				   ELSE
		[lob_used_page_count] + [row_overflow_used_page_count]
			   END) AS [pages]
	FROM   [sys].[dm_db_partition_stats]
	GROUP BY object_id,
			 [index_id]
) AS [ps] ON [i].[index_id] = [ps].[index_id]
			 AND [i].object_id = [ps].object_id
WHERE  1 = 1
	   AND [o].[type] <> 's'; 
--and p.data_compression_desc 
--and s.name as 'schema' , 
--and o.name like '%invmove%'