/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
retun a list of all tables in the database that have partitioning enabled along
with the particulars of the partitioning configuation, data ranges and sizing

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
	   [i].[name] AS [indexname],
	   [i].[type_desc],
	   [p].[data_compression_desc],
	   [ds].[type_desc] AS [dataspacetypedesc],
	   [p].[partition_number],
	   [pf].[name] AS [pf_name],
	   [ps].[name] AS [ps_name],
	   [partitionds].[name] AS [partition_fg],
	   ISNULL(CAST([left_prv].value AS VARCHAR(MAX))+CASE
														 WHEN [pf].[boundary_value_on_right] = 0
														 THEN ' < '
														 ELSE ' <= '
													 END, '- '+CHAR(236)+' < ')+'X'+ISNULL(CASE
																							   WHEN [pf].[boundary_value_on_right] = 0
																							   THEN ' <= '
																							   ELSE ' < '
																						   END+CAST([right_prv].value AS NVARCHAR(MAX)), ' < '+CHAR(236)+'') AS [range_desc],
	   [i].[is_unique],
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
	   [p].[rows],
	   [pst].[usedmb]
FROM   [sys].[indexes] AS [i]
	   INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [i].object_id
	   INNER JOIN [sys].[data_spaces] AS [ds] ON [ds].[data_space_id] = [i].[data_space_id]
	   LEFT JOIN [sys].[schemas] AS [s] ON [o].schema_id = [s].schema_id
	   LEFT JOIN [sys].[partitions] AS [p] ON [i].[index_id] = [p].[index_id]
											  AND [i].object_id = [p].object_id
	   LEFT JOIN [sys].[destination_data_spaces] AS [dds] ON [i].[data_space_id] = [dds].[partition_scheme_id]
															 AND [p].[partition_number] = [dds].[destination_id]
	   LEFT JOIN [sys].[data_spaces] AS [partitionds] ON [dds].[data_space_id] = [partitionds].[data_space_id]
	   LEFT JOIN [sys].[partition_schemes] AS [ps] ON [dds].[partition_scheme_id] = [ps].[data_space_id]
	   LEFT JOIN [sys].[partition_functions] AS [pf] ON [ps].[function_id] = [pf].[function_id]
	   LEFT JOIN [sys].[partition_range_values] AS [left_prv] ON [left_prv].[function_id] = [ps].[function_id]
																 AND
	[left_prv].[boundary_id] + 1 = [p].[partition_number]
	   LEFT JOIN [sys].[partition_range_values] AS [right_prv] ON [right_prv].[function_id] = [ps].[function_id]
																  AND [right_prv].[boundary_id] = [p].[partition_number]
	   INNER JOIN
(
	SELECT object_id,
		   [index_id],
		   [partition_id],
		   SUM([used_page_count]) AS [usedpages],
		   CAST(
				   (
					   (
						   SUM([used_page_count]) * 8.0
					   ) / 1024.0
				   ) AS NUMERIC(18, 2)) AS [usedmb]
	FROM   [sys].[dm_db_partition_stats]
	GROUP BY object_id,
			 [index_id],
			 [partition_id]
) AS [pst] ON [p].[index_id] = [pst].[index_id]
			  AND [p].object_id = [pst].object_id
			  AND [p].[partition_id] = [pst].[partition_id]
WHERE  1 = 1
	   AND [s].[name] NOT IN('sys', 'cdc')
	   AND [o].[name] NOT LIKE 'MSpub%'
	   AND [o].[name] NOT LIKE 'MSpeer%'
--AND		o.name = 'objectname'
--and		p.data_compression_desc = 'NONE' -- NONE|ROW|PAGE
ORDER BY [s].[name],
		 [o].[name],
		 [i].[name],
		 [p].[partition_number];
GO