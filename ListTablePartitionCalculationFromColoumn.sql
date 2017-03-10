/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
See this blog post for more information
https://mrfoxsql.wordpress.com/2015/11/24/calculating-table-partition-sizes-in-advance/

HISTORY:
--------------------------------------------------------------------------------
Date:		Developer:			Description:
--------------------------------------------------------------------------------
24 Nov 2015	Rolf Tesmer			Created
--------------------------------------------------------------------------------

NOTES:
--------------------------------------------------------------------------------
Disclaimer: https://mrfoxsql.wordpress.com/notes-and-disclaimers/
THIS SCRIPT/CODE ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
LIMITED TESTING HAS BEEN PERFORMED ON THIS SCRIPT/CODE AND THEREFORE THE AUTHOR DOES NOT WARRANT
THAT ANY SCRIPT/CODE IS BUG OR ERROR-FREE.  IT IS EXPECTED THAT ANY SCRIPT/CODE UNDERGO YOUR OWN 
TESTING AND/OR VALIDATION BEFORE USAGE ON ANY CRITICAL SQL SERVER PLATFORM.
THIS SCRIPT MAY BE A COLLECTION OF MY OWN CODE COLLATED OVER MANY YEARS, OR OTHER CODE I HAVE 
LOCATED ON THE WEB WITH AN UNKNOWN ORIGIN.  WHERE CODE HAS BEEN IDENTIFIED IT WILL BE CITED.
================================================================================
************************************************************************************************/

BEGIN
	SET NOCOUNT ON;

	-- ********************************************************************************
	-- Declare user variables
	DECLARE
		@PartitionTableName    SYSNAME = 'fact.Movement', -- The name of the table in format SCHEMA.OBJECT
		@PartitionKeyName      SYSNAME = '[Date Key]', -- The name of the table key partitioning coloumn on which to partition the table / indexes
		@PartitionFunctionName SYSNAME = 'PF_Date', -- The name of the partition function on which to test the partitioning
		@PartitionCompression  SYSNAME = 'PAGE';					-- The type of compression; NONE / ROW / PAGE
	-- ********************************************************************************
	-- Declare system variables
	DECLARE
		@ObjectSchemaName SYSNAME,
		@ObjectID         INT,
		@ObjectName       SYSNAME,
		@FullSQLString    NVARCHAR(4000) = '',
		@IndexMBSize      BIGINT,
		@TableMBSize      BIGINT,
		@TableRows        BIGINT;

	-- drop temp tables
	IF EXISTS
	(
		SELECT 1
		FROM   [tempdb].[sys].[objects] WITH (nolock)
		WHERE  [name] LIKE '#TableData%'
	)
		DROP TABLE [#tabledata];
	IF EXISTS
	(
		SELECT 1
		FROM   [tempdb].[sys].[objects] WITH (nolock)
		WHERE  [name] LIKE '##RangeRows%'
	)
		DROP TABLE [##rangerows];
	IF EXISTS
	(
		SELECT 1
		FROM   [tempdb].[sys].[objects] WITH (nolock)
		WHERE  [name] LIKE '#CompressionSavings%'
	)
		DROP TABLE [#compressionsavings];

	-- create work tables
	CREATE TABLE [#compressionsavings]
	(
		[objectname]                                     SYSNAME NOT NULL,
		[schemaname]                                     SYSNAME NOT NULL,
		[indexid]                                        INT NOT NULL,
		[partitionnumber]                                INT NOT NULL,
		[size_with_current_compression_setting]          BIGINT NOT NULL,
		[size_with_requested_compression_setting]        BIGINT NOT NULL,
		[sample_size_with_current_compression_setting]   BIGINT NOT NULL,
		[sample_size_with_requested_compression_setting] BIGINT NOT NULL
	);

	-- set variables
	SET @ObjectSchemaName = OBJECT_SCHEMA_NAME(OBJECT_ID(@PartitionTableName));
	SET @ObjectName = OBJECT_NAME(OBJECT_ID(@PartitionTableName));
	SET @ObjectID = OBJECT_ID(@PartitionTableName);

	-- get compression data for table
	INSERT INTO [#compressionsavings]
	([objectname],
	 [schemaname],
	 [indexid],
	 [partitionnumber],
	 [size_with_current_compression_setting],
	 [size_with_requested_compression_setting],
	 [sample_size_with_current_compression_setting],
	 [sample_size_with_requested_compression_setting]
	)
	EXECUTE [dbo].[sp_estimate_data_compression_savings]
		@schema_name = @ObjectSchemaName,
		@object_name = @ObjectName,
		@index_id = NULL,
		@partition_number = NULL,
		@data_compression = @PartitionCompression;

	-- Get existing data for table and indexes
	SELECT DISTINCT
		   [s].[name] AS 'schema',
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
		   [i].[index_id] AS [indexid],
		   [i].[type],
		   [i].[type_desc],
		   [p].[data_compression_desc] AS [current_data_compression_desc],
		   @PartitionCompression AS [requested_data_compression_desc],
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
		   [pst].[row_count],
		   [pst].[currentkb],
		   [comp].[compressedkb]
	INTO [#tabledata]
	FROM   [sys].[indexes] AS [i]
		   INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [i].object_id
		   INNER JOIN [sys].[schemas] AS [s] ON [o].schema_id = [s].schema_id
		   INNER JOIN [sys].[partitions] AS [p] ON [i].object_id = [p].object_id
												   AND [i].[index_id] = [p].[index_id]
		   INNER JOIN
	(
		SELECT object_id,
			   [index_id],
			   SUM([row_count]) AS [row_count],
			   CAST(
					   (
						   SUM([used_page_count]) * 8.0
					   ) AS NUMERIC(18, 2)) AS [currentkb]
		FROM   [sys].[dm_db_partition_stats]
		GROUP BY object_id,
				 [index_id]
	) AS [pst] ON [i].[index_id] = [pst].[index_id]
				  AND [i].object_id = [pst].object_id
		   INNER JOIN
	(
		SELECT @ObjectID AS object_id,
			   [indexid] AS [index_id],
			   SUM([size_with_requested_compression_setting]) AS [compressedkb]
		FROM   [#compressionsavings]
		GROUP BY [indexid]
	) AS [comp] ON [i].[index_id] = [comp].[index_id]
				   AND [i].object_id = [comp].object_id
	WHERE  [s].[name] = @ObjectSchemaName
		   AND [o].[name] = @ObjectName
	ORDER BY [s].[name],
			 [o].[name],
			 [i].[name];

	-- distribute REAL table row counts by the partition function
	SET @FullSQLString = '';
	SELECT @FullSQLString = '
	SELECT p.boundary_id AS PartitionNumber
		   , COUNT(o.'+@PartitionKeyName+') AS RangeRows
		   , CAST(0 AS NUMERIC(7, 4)) AS RangePct
		   , RangeDesc
	INTO	##RangeRows
	FROM   '+@PartitionTableName+' o
		   RIGHT JOIN 
		   (
				SELECT	pf.boundary_id
						, ISNULL(CAST(l_prv.value AS VARCHAR(MAX))
						+ CASE 
							WHEN pf.boundary_value_on_right = 0 THEN '' < '' 
							ELSE '' <= '' 
						END
						, ''- '' + CHAR(236) + '' < '') + ''X''
						+ ISNULL ( 
							CASE WHEN pf.boundary_value_on_right = 0 THEN '' <= '' 
							ELSE '' < '' 
						END + CAST(r_prv.value AS NVARCHAR(MAX)), '' < '' + CHAR(236)) AS RangeDesc
				FROM   
				(
					SELECT	pf.function_id
							, boundary_id
							, boundary_value_on_right
							, value
					FROM	sys.partition_range_values prv
							INNER JOIN sys.partition_functions pf
								ON prv.function_id = pf.function_id
					WHERE	pf.NAME = '''+@PartitionFunctionName+'''
					UNION ALL
					SELECT	MAX(pf.function_id)
							, MAX(boundary_id) + 1
							, MAX(CAST(boundary_value_on_right AS INT))
							, NULL
					FROM	sys.partition_range_values prv
							INNER JOIN sys.partition_functions pf
								ON prv.function_id = pf.function_id
					WHERE  pf.NAME = '''+@PartitionFunctionName+'''
				) pf
					LEFT JOIN sys.partition_range_values r_prv
						ON r_prv.function_id = pf.function_id
						AND r_prv.boundary_id = pf.boundary_id
					LEFT JOIN sys.partition_range_values l_prv
						ON l_prv.function_id     = pf.function_id
						AND l_prv.boundary_id + 1 = pf.boundary_id
			) AS p
				  ON p.boundary_id = $PARTITION.'+@PartitionFunctionName+'(o.'+@PartitionKeyName+')
	GROUP  BY p.boundary_id, RangeDesc
	ORDER  BY PartitionNumber;';

	--PRINT @FullSQLString
	EXECUTE [dbo].[sp_executesql]
		@FullSQLString;

	-- update Range PCT with overall rows pct allocation
	SELECT @TableRows = SUM([row_count])
	FROM   [#tabledata]
	WHERE  [type] IN(0, 1); -- HEAP or CLUSTER

	IF(@TableRows IS NULL
	   OR @TableRows = 0)
		SET @TableRows = 1;
	UPDATE [##rangerows]
	SET
		[rangepct] =
		CAST([rangerows] AS NUMERIC(23, 4)) / CAST(@TableRows AS NUMERIC(23, 4));

	-- Return table and index breakdowns based on the pct allocation
	SELECT @ObjectSchemaName AS [schemaname],
		   @ObjectName AS [objectname],
		   [td].[indexname] AS [indexname],
		   [td].[type_desc] AS [indextypedesc],
		   [rr].[partitionnumber],
		   [rr].[rangepct] AS [partitionrangepct],
		   [rr].[rangedesc] AS [partitionrangedesc],
		   [rr].[rangerows] AS [partitionrangerows],
		   [td].[current_data_compression_desc] AS [currentcompressiontypedesc],
		(
			[rr].[rangepct] * [td].[currentkb]
		) AS [currentpartitionrangekb],
		   CAST(
		(
			ROUND(
					 (
						 (
							 [rr].[rangepct] * [td].[currentkb]
						 ) / 1024
					 ), 0) * 1024
		) + 1024 AS BIGINT) AS [currentpartitionrangekb1024],
		   [td].[requested_data_compression_desc] AS [requestedcompressiontypedesc],
		(
			[rr].[rangepct] * [td].[compressedkb]
		) AS [requestedpartitionrangekb],
		   CAST(
		(
			ROUND(
					 (
						 (
							 [rr].[rangepct] * [td].[compressedkb]
						 ) / 1024
					 ), 0) * 1024
		) + 1024 AS BIGINT) AS [requestedpartitionrangekb1024]
	FROM   [##rangerows] AS [rr]
		   CROSS JOIN [#tabledata] AS [td]
	ORDER BY [schemaname],
			 [objectname],
			 [indexname],
			 [partitionnumber];
END;
GO