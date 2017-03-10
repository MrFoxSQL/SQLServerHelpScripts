/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to drop or recreate all of the foreign keys in a database
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

DECLARE
	@schema_name SYSNAME;
DECLARE
	@table_name SYSNAME;
DECLARE
	@constraint_name SYSNAME;
DECLARE
	@constraint_object_id INT;
DECLARE
	@referenced_object_name SYSNAME;
DECLARE
	@is_disabled BIT;
DECLARE
	@is_not_for_replication BIT;
DECLARE
	@is_not_trusted BIT;
DECLARE
	@delete_referential_action TINYINT;
DECLARE
	@update_referential_action TINYINT;
DECLARE
	@tsql NVARCHAR(4000);
DECLARE
	@tsql2 NVARCHAR(4000);
DECLARE
	@fkCol SYSNAME;
DECLARE
	@pkCol SYSNAME;
DECLARE
	@col1 BIT;
DECLARE
	@action CHAR(6);
	

--SET @action = 'DROP';

SET @action = 'CREATE';
DECLARE fkcursor CURSOR
FOR SELECT OBJECT_SCHEMA_NAME([parent_object_id]),
		   OBJECT_NAME([parent_object_id]),
		   [name],
		   OBJECT_NAME([referenced_object_id]),
		   object_id,
		   [is_disabled],
		   [is_not_for_replication],
		   [is_not_trusted],
		   [delete_referential_action],
		   [update_referential_action]
	FROM   [sys].[foreign_keys]
	ORDER BY 1,
			 2;
OPEN fkcursor;
FETCH NEXT FROM fkcursor INTO
	@schema_name,
	@table_name,
	@constraint_name,
	@referenced_object_name,
	@constraint_object_id,
	@is_disabled,
	@is_not_for_replication,
	@is_not_trusted,
	@delete_referential_action,
	@update_referential_action;
WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @action <> 'CREATE'
			SET @tsql = 'ALTER TABLE '+QUOTENAME(@schema_name)+'.'+QUOTENAME(@table_name)+' DROP CONSTRAINT '+QUOTENAME(@constraint_name)+';';
		ELSE
			BEGIN
				SET @tsql = 'ALTER TABLE '+QUOTENAME(@schema_name)+'.'+QUOTENAME(@table_name)+CASE @is_not_trusted
																								  WHEN 0
																								  THEN ' WITH CHECK '
																								  ELSE ' WITH NOCHECK '
																							  END+' ADD CONSTRAINT '+QUOTENAME(@constraint_name)+' FOREIGN KEY (';
				SET @tsql2 = '';
				DECLARE columncursor CURSOR
				FOR SELECT COL_NAME([fk].[parent_object_id], [fkc].[parent_column_id]),
						   COL_NAME([fk].[referenced_object_id], [fkc].[referenced_column_id])
					FROM   [sys].[foreign_keys] AS [fk]
						   INNER JOIN [sys].[foreign_key_columns] AS [fkc] ON [fk].object_id = [fkc].[constraint_object_id]
					WHERE  [fkc].[constraint_object_id] = @constraint_object_id
					ORDER BY [fkc].[constraint_column_id];
				OPEN columncursor;
				SET @col1 = 1;
				FETCH NEXT FROM columncursor INTO
					@fkCol,
					@pkCol;
				WHILE @@FETCH_STATUS = 0
					BEGIN
						IF(@col1 = 1)
							SET @col1 = 0;
						ELSE
							BEGIN
								SET @tsql = @tsql+',';
								SET @tsql2 = @tsql2+',';
							END;
						SET @tsql =
							@tsql + QUOTENAME(@fkCol);
						SET @tsql2 =
							@tsql2 + QUOTENAME(@pkCol);
						FETCH NEXT FROM columncursor INTO
							@fkCol,
							@pkCol;
					END;
				CLOSE columncursor;
				DEALLOCATE columncursor;
				SET @tsql = @tsql+' ) REFERENCES '+QUOTENAME(@referenced_object_name)+' ('+@tsql2+')';
				SET @tsql = @tsql+' ON UPDATE '+CASE @update_referential_action
													WHEN 0
													THEN 'NO ACTION '
													WHEN 1
													THEN 'CASCADE '
													WHEN 2
													THEN 'SET NULL '
													ELSE 'SET DEFAULT '
												END+' ON DELETE '+CASE @delete_referential_action
																	  WHEN 0
																	  THEN 'NO ACTION '
																	  WHEN 1
																	  THEN 'CASCADE '
																	  WHEN 2
																	  THEN 'SET NULL '
																	  ELSE 'SET DEFAULT '
																  END+CASE @is_not_for_replication
																		  WHEN 1
																		  THEN ' NOT FOR REPLICATION '
																		  ELSE ''
																	  END+';';
			END;
		PRINT @tsql;
		IF @action = 'CREATE'
			BEGIN
				SET @tsql = 'ALTER TABLE '+QUOTENAME(@schema_name)+'.'+QUOTENAME(@table_name)+CASE @is_disabled
																								  WHEN 0
																								  THEN ' CHECK '
																								  ELSE ' NOCHECK '
																							  END+'CONSTRAINT '+QUOTENAME(@constraint_name)+';';
				PRINT @tsql;
			END;
		FETCH NEXT FROM fkcursor INTO
			@schema_name,
			@table_name,
			@constraint_name,
			@referenced_object_name,
			@constraint_object_id,
			@is_disabled,
			@is_not_for_replication,
			@is_not_trusted,
			@delete_referential_action,
			@update_referential_action;
	END;
CLOSE fkcursor;
DEALLOCATE fkcursor;