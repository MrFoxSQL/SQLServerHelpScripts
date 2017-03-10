/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to recreate all indexes for one or more tables
Takes parameter @ObjectName.  When NULL will review all tables.  When SCHEMA.OBJECT will assess just that table
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
************************************************************************************************/

BEGIN
	SET NOCOUNT ON;
	DECLARE
		@ObjectName SYSNAME = NULL, -- 'base.DimBrand' -- NULL = All tables  --  Format = SCHEMA.OBJECT
		@ObjectType SYSNAME = 'U'; -- NULL = All types  --  U = User Tables / V = User Views / S = System / IT = Internal Table

	DECLARE curs CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR SELECT DISTINCT
			   [s].[name]+'.'+[o].[name] AS [tablename]
		FROM   [sys].[objects] AS [o]
			   INNER JOIN [sys].[schemas] AS [s] ON [o].schema_id = [s].schema_id
			   LEFT JOIN [sys].[indexes] AS [i] ON [o].object_id = [i].object_id
			   INNER JOIN [sys].[filegroups] AS [f] ON [i].[data_space_id] = [f].[data_space_id]
		WHERE  [o].[type] = ISNULL(@ObjectType, [o].[type])
			   AND [o].object_id = isnull(OBJECT_ID(@ObjectName), [o].object_id)
		ORDER BY [s].[name]+'.'+[o].[name];
	OPEN curs;
	FETCH FROM curs INTO
		@ObjectName;
	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			SELECT 'PRINT ''Rebuilding Indexes : '+@ObjectName+' : '' + convert(varchar(25), getdate(), 121)'+CHAR(13)+CHAR(10)+'GO ';
			SELECT                        ' CREATE '+CASE
														 WHEN [i].[is_unique] = 1
														 THEN ' UNIQUE '
														 ELSE ''
													 END+[i].[type_desc] COLLATE database_default+' INDEX ['+[i].[name]+']'+' ON ['+SCHEMA_NAME([t].schema_id)+'].['+[t].[name]+'] ( '+[keycolumns]+' )  '+ISNULL(' INCLUDE ('+[includedcolumns]+' ) ', '')+ISNULL(' WHERE  '+[i].[filter_definition], '')+' WITH ( '+CASE
																																																																														  WHEN [i].[is_padded] = 1
																																																																														  THEN ' PAD_INDEX = ON '
																																																																														  ELSE ' PAD_INDEX = OFF '
																																																																													  END+','+'FILLFACTOR = '+CONVERT( CHAR(5),
																																																																																							 CASE
																																																																																								 WHEN [i].[fill_factor] = 0
																																																																																								 THEN 100
																																																																																								 ELSE [i].[fill_factor]
																																																																																							 END)+','+ 
										  -- default value 
										  'SORT_IN_TEMPDB = ON '+','+CASE
																		 WHEN [i].[ignore_dup_key] = 1
																		 THEN ' IGNORE_DUP_KEY = ON '
																		 ELSE ' IGNORE_DUP_KEY = OFF '
																	 END+','+CASE
																				 WHEN [st].[no_recompute] = 0
																				 THEN ' STATISTICS_NORECOMPUTE = OFF '
																				 ELSE ' STATISTICS_NORECOMPUTE = ON '
																			 END+','+ 
										  -- default value  
										  ' DROP_EXISTING = ON '+','+ 
										  -- default value  
										  ' ONLINE = OFF '+','+'DATA_COMPRESSION='+[p].[data_compression_desc]+','+CASE
																													   WHEN [i].[allow_row_locks] = 1
																													   THEN ' ALLOW_ROW_LOCKS = ON '
																													   ELSE ' ALLOW_ROW_LOCKS = OFF '
																												   END+','+CASE
																															   WHEN [i].[allow_page_locks] = 1
																															   THEN ' ALLOW_PAGE_LOCKS = ON '
																															   ELSE ' ALLOW_PAGE_LOCKS = OFF '
																														   END+' ) '+' ON ['+[ds].[name]+'] '+CHAR(13)+CHAR(10)+'GO '
			FROM                          [sys].[indexes] AS [i]
										  JOIN [sys].[objects] AS [t] ON [t].object_id = [i].object_id
										  JOIN [sys].[partitions] AS [p] ON [t].object_id = [p].object_id
																			AND [p].[index_id] = [i].[index_id]
										  JOIN [sys].[sysindexes] AS [si] ON [i].object_id = [si].[id]
																			 AND [i].[index_id] = [si].[indid]
										  JOIN
			(
				SELECT                    *
				FROM
				(
					SELECT                [ic2].object_id,
										  [ic2].[index_id],
										  STUFF(
											   (
												   SELECT ' , '+[c].[name]+CASE
																			   WHEN MAX(CONVERT( INT, [ic1].[is_descending_key])) = 1
																			   THEN ' DESC '
																			   ELSE ' ASC '
																		   END
												   FROM    [sys].[index_columns] AS [ic1]
														   JOIN [sys].[columns] AS [c] ON [c].object_id = [ic1].object_id
																						  AND [c].[column_id] = [ic1].[column_id]
																						  AND [ic1].[is_included_column] = 0
												   WHERE  [ic1].object_id = [ic2].object_id
														  AND [ic1].[index_id] = [ic2].[index_id]
												   GROUP BY [ic1].object_id,
															[c].[name],
															[index_id]
												   ORDER BY MAX([ic1].[key_ordinal])
												   FOR XML PATH('')
											   ), 1, 2, '') AS [keycolumns]
					FROM [sys].[index_columns] AS [ic2]
					GROUP BY [ic2].object_id,
							 [ic2].[index_id]
				) AS [tmp3]
			) AS [tmp4] ON [i].object_id = [tmp4].object_id
						   AND [i].[index_id] = [tmp4].[index_id]
										  JOIN [sys].[stats] AS [st] ON [st].object_id = [i].object_id
																		AND [st].[stats_id] = [i].[index_id]
										  JOIN [sys].[data_spaces] AS [ds] ON [i].[data_space_id] = [ds].[data_space_id]
										  JOIN [sys].[filegroups] AS [fg] ON [i].[data_space_id] = [fg].[data_space_id]
										  LEFT JOIN
			(
				SELECT                    *
				FROM
				(
					SELECT                [ic2].object_id,
										  [ic2].[index_id],
										  STUFF(
											   (
												   SELECT ' , '+[c].[name]
												   FROM    [sys].[index_columns] AS [ic1]
														   JOIN [sys].[columns] AS [c] ON [c].object_id = [ic1].object_id
																						  AND [c].[column_id] = [ic1].[column_id]
																						  AND [ic1].[is_included_column] = 1
												   WHERE  [ic1].object_id = [ic2].object_id
														  AND [ic1].[index_id] = [ic2].[index_id]
												   GROUP BY [ic1].object_id,
															[c].[name],
															[index_id]
												   FOR XML PATH('')
											   ), 1, 2, '') AS [includedcolumns]
					FROM [sys].[index_columns] AS [ic2]
					GROUP BY [ic2].object_id,
							 [ic2].[index_id]
				) AS [tmp1]
				WHERE [includedcolumns] IS NOT NULL
			) AS [tmp2] ON [tmp2].object_id = [i].object_id
						   AND [tmp2].[index_id] = [i].[index_id]
			WHERE 1 = 1
				  AND [i].object_id = isnull(OBJECT_ID(@ObjectName), [i].object_id);
			--AND schema_name(t.schema_id) not in ('sys')

			FETCH NEXT FROM curs INTO
				@ObjectName;
		END;
	CLOSE curs;
	DEALLOCATE curs;
END;
GO