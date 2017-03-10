/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
 Kill datbaase connections for a specific or all databases, and then change the setting 
 of the database to OFFLINE, SINGLE USER, etc

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

USE master;
GO
BEGIN
	SET NOCOUNT ON;
	DECLARE
		@SQLString NVARCHAR(4000),
		@DBName    SYSNAME,
		@Option    TINYINT;
	SELECT @DBName = 'MyDatabaseNameHere', -- PUT DB NAME HERE, <NULL> MEANS DO ALL DATABASES
		   @Option = 0; -- 0 = KILL / 1 = KILL & OFFLINE / 2 = KILL & SINGLE / 3 = KILL & DETACH

	DECLARE dbcurs CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR SELECT [name]
		FROM   [master].[dbo].[sysdatabases](nolock)
		WHERE  [name] NOT IN('tempdb', 'master', 'model', 'msdb')
			   AND [name] = ISNULL(@DBName, [name]);
	OPEN dbcurs;
	FETCH FROM dbcurs INTO
		@DBName;
	WHILE(@@fetch_status = 0)
		BEGIN
			PRINT '';
			PRINT @DBName;
			-- KILL CONNECTIONS
			SELECT @SQLString = '';
			SELECT @SQLString = @SQLString+'kill '+CONVERT( VARCHAR(10), [spid])+' '
			FROM   [master].[sys].[sysprocesses]
			WHERE  [dbid] = DB_ID(@DBName);
			PRINT @SQLString;
			EXECUTE [dbo].[sp_executesql]
				@SQLString;
		
			-- ALTER DATABASES
			SELECT @SQLString = '';
			IF(@Option = 1)
				SELECT @SQLString = 'alter database ['+@DBName+'] set OFFLINE';
			IF(@Option = 2)
				SELECT @SQLString = 'alter database ['+@DBName+'] set SINGLE_USER';
			IF(@Option = 3)
				SELECT @SQLString = 'execute dbo.sp_detach_db '''+@DBName+''', ''TRUE'', ''TRUE''';
			PRINT @SQLString;
			EXECUTE [dbo].[sp_executesql]
				@SQLString;
		
			-- USE DATABASE
			SELECT @SQLString = '';
			IF(@Option = 2)
				SELECT @SQLString = 'use ['+@DBName+']';
			PRINT @SQLString;
			EXECUTE [dbo].[sp_executesql]
				@SQLString;
			FETCH NEXT FROM dbcurs INTO
				@DBName;
		END; -- while
	CLOSE dbcurs;
	DEALLOCATE dbcurs;
END;
GO