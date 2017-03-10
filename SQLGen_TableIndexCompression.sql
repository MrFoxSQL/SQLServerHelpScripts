/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to set the compression level on tables and indexes
The purpose of this script is to dynamically generate another SQL script based on 
the content of the target server/database on which this script is executed.
The output of the execution of this script will be a seperate generated SQL script.
The generated script can be used to perform the actual function on your database/platform.
(1) Change result output to TEXT
(2) Execute the script on your target server/database
(3) Copy the result output as the new script to apply


HISTORY:
--------------------------------------------------------------------------------
Date:		Developer:			Description:
--------------------------------------------------------------------------------
*			Rolf Tesmer			Created
--------------------------------------------------------------------------------

NOTES:
--------------------------------------------------------------------------------
DISCLAIMER - https://mrfoxsql.wordpress.com/notes-and-disclaimers/
THIS SCRIPT/CODE ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
LIMITED TESTING HAS BEEN PERFORMED ON THIS SCRIPT/CODE AND THEREFORE THE AUTHOR DOES NOT WARRANT
THAT ANY SCRIPT/CODE IS BUG OR ERROR-FREE.  IT IS EXPECTED THAT ANY SCRIPT/CODE UNDERGO YOUR OWN 
TESTING AND/OR VALIDATION BEFORE USAGE ON ANY CRITICAL SQL SERVER PLATFORM.
THIS SCRIPT MAY BE A COLLECTION OF MY OWN CODE COLLATED OVER MANY YEARS, OR OTHER CODE I HAVE 
LOCATED ON THE WEB WITH AN UNKNOWN ORIGIN.  WHERE CODE HAS BEEN IDENTIFIED IT WILL BE CITED.
************************************************************************************************/

SET NOCOUNT ON;
GO
PRINT 'set nocount on';
PRINT 'set statistics io on';
PRINT '--set statistics time on';
PRINT 'GO';
PRINT '';
GO
SELECT    '-- '+[o].[type_desc]+' | '+[i].[type_desc]+' | '+CASE [ds].[type]
																WHEN 'PS'
																THEN 'PARTITIONED'
																ELSE 'NONPARTITIONED'
															END+' : '+[s].[name]+'.'+[o].[name]+' | Rows: '+CAST([p].[rows] AS VARCHAR(10))+' | SizeMB: '+CAST([pst].[usedmb] AS VARCHAR(20))+CHAR(13)+CHAR(10)+'SELECT ''Compressing: ['+[s].[name]+'].['+[o].[name]+']'+' | Rows: '+CAST([p].[rows] AS VARCHAR(10))+' | SizeMB: '+CAST([pst].[usedmb] AS VARCHAR(20))+' | DateTime: '' + CONVERT(varchar(25), getdate(), 121) + '''''+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)+CASE
																																																																																																																					 WHEN [o].[type] = 'V'
																																																																																																																					 THEN 'ALTER INDEX '-- indexed view
																																																																																																																					 WHEN [i].[type] IN(0, 1)
																																																																																																																					 THEN 'ALTER TABLE '-- heap & clustered
																																																																																																																					 WHEN [i].[type] = 2
																																																																																																																					 THEN 'ALTER INDEX '-- index
																																																																																																																					 ELSE '*UNKNOWN*'
																																																																																																																				 END+CASE -- Object name
																																																																																																																						 WHEN [o].[type] = 'V'
																																																																																																																						 THEN '['+[i].[name]+'] ON ['+[s].[name]+'].['+[o].[name]+']'
																																																																																																																						 WHEN [i].[type] IN(0, 1)
																																																																																																																						 THEN '['+[s].[name]+'].['+[o].[name]+']'
																																																																																																																						 WHEN [i].[type] = 2
																																																																																																																						 THEN '['+[i].[name]+'] ON ['+[s].[name]+'].['+[o].[name]+']'
																																																																																																																						 ELSE '*UNKNOWN*'
																																																																																																																					 END+' 
REBUILD PARTITION = '+CASE [ds].[type]
						  WHEN 'PS'
						  THEN CAST([p].[partition_number] AS VARCHAR(5))
						  ELSE 'ALL'
					  END+CASE -- Command
							  WHEN [i].[type] = 0
							  THEN '
WITH 
(
	ONLINE = '+
	(CASE CHARINDEX('Enterprise', CAST(
										  (SERVERPROPERTY('edition')
										  ) AS VARCHAR(50)))
		 WHEN 0
		 THEN 'OFF  /* ON */'
		 ELSE 'ON  /* OFF */'
	 END
	)+',
	MAXDOP = '+
(
	SELECT CAST(value AS VARCHAR(3))
	FROM    [sys].[sysconfigures]
	WHERE  [comment] = 'maximum degree of parallelism'
)+',
	SORT_IN_TEMPDB = ON  /* OFF */,
	DATA_COMPRESSION = '+[p].[data_compression_desc] COLLATE latin1_general_ci_as+'  /* NONE | PAGE | ROW */
)
GO
	'
							  WHEN [i].[type] IN(1, 2)
							  THEN '
WITH
(
	--PAD_INDEX  = OFF  /* ON */, 
	--STATISTICS_NORECOMPUTE  = OFF  /* ON */, 
	--ALLOW_ROW_LOCKS  = '+CASE [i].[allow_row_locks]
							   WHEN 1
							   THEN 'ON  /* OFF */'
							   ELSE 'OFF  /* ON */'
						   END+', 
	--ALLOW_PAGE_LOCKS  = '+CASE [i].[allow_page_locks]
								WHEN 1
								THEN 'ON  /* OFF */'
								ELSE 'OFF  /* ON */'
							END+', 
	--FILLFACTOR = '+CASE [i].[fill_factor]
						 WHEN 0
						 THEN '100  /* 0 | 100 */'
						 ELSE CAST([i].[fill_factor] AS VARCHAR(3))+'  /* 0 | 100 */'
					 END+', 
	ONLINE = '+
	(CASE CHARINDEX('Enterprise', CAST(
										  (SERVERPROPERTY('edition')
										  ) AS VARCHAR(50)))
		 WHEN 0
		 THEN 'OFF  /* ON */'
		 ELSE 'ON  /* OFF */'
	 END
	)+',
	MAXDOP = '+
(
	SELECT CAST(value AS VARCHAR(3))
	FROM   [sys].[sysconfigures]
	WHERE  [comment] = 'maximum degree of parallelism'
)+'  /* 0 */,
	SORT_IN_TEMPDB = ON /* OFF */,
	DATA_COMPRESSION = '+[p].[data_compression_desc] COLLATE latin1_general_ci_as+'  /* NONE | PAGE | ROW */
)
GO
	'
							  ELSE 'UNKNOWN'
						  END
FROM [sys].[indexes] AS [i]
	 INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [i].object_id
	 INNER JOIN [sys].[data_spaces] AS [ds] ON [ds].[data_space_id] = [i].[data_space_id]
	 LEFT JOIN [sys].[schemas] AS [s] ON [o].schema_id = [s].schema_id
	 LEFT JOIN [sys].[partitions] AS [p] ON [i].[index_id] = [p].[index_id]
											AND [i].object_id = [p].object_id
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
WHERE 1 = 1
	  AND [s].[name] NOT IN('sys', 'cdc') -- system or cdc schema
	  AND [o].[name] NOT LIKE 'sys%' -- system tables (dbo)
	  AND [o].[name] NOT LIKE 'MSpub%' -- replication tables (dbo)
	  AND [o].[name] NOT LIKE 'MSpeer%' -- replication tables (dbo)
--AND		o.name in ('MyIncloudeObject')
--AND		s.name in ('MyIncludeSchema')
--AND		p.data_compression_desc = 'NONE' -- NONE|ROW|PAGE
ORDER BY
--o.type,
[usedmb] ASC,
[i].[type],
[s].[name],
[o].[name],
[i].[name];
GO