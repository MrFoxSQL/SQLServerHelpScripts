/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to perform a database ATTACH command change for each of the databases
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

BEGIN
	SET NOCOUNT ON;
	DECLARE
		@DBName    SYSNAME,
		@Filename  VARCHAR(8000),
		@SQLString VARCHAR(8000);
	DECLARE curs CURSOR FORWARD_ONLY READ_ONLY STATIC LOCAL
	FOR SELECT DB_NAME([dbid]),
			   [filename]
		FROM   [master].[dbo].[sysaltfiles](NOLOCK)
		WHERE  [fileid] = 1 -- mdf files
			   AND DB_NAME([dbid]) NOT IN('master', 'msdb', 'tempdb', 'model')
		ORDER BY 1;
	OPEN curs;
	FETCH curs INTO
		@DBName,
		@Filename;
	WHILE(@@fetch_status = 0)
		BEGIN
			-- MDF File
			PRINT 'print ''''';
			PRINT 'print ''--------------------------------------------------------------------------------''';
			PRINT 'print ''-- Database: '+@DBName+'''';
			SELECT @SQLString = '';
			SELECT @SQLString = 'execute dbo.sp_attach_db '''+CASE @DBName
																  WHEN 'SSLDBA'
																  THEN 'SSLDBA_PROD'
																  ELSE @DBName
															  END+''', '''+RTRIM(@Filename)+'''';
			PRINT @SQLString;

			-- Other Files
			SELECT @SQLString = '';
			SELECT @SQLString = @SQLString+','''+RTRIM([filename])+''''
			FROM   [master].[dbo].[sysaltfiles](NOLOCK)
			WHERE  DB_NAME([dbid]) = @DBName
				   AND [fileid] <> 1; -- anything except mdf files
			PRINT @SQLString;
			PRINT 'GO';

			-- Owner
			SELECT @SQLString = 'select ''***** DB OWNER NEEDS TO BE UPDATED *****''';
			SELECT @SQLString = 'use ['+[sd].[name]+']'+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)+'execute dbo.sp_changedbowner '''+[l].[name]+''''+CHAR(13)+CHAR(10)
			FROM   [master].[sys].[databases] AS [sd]
				   INNER JOIN [master].[sys].[syslogins] AS [l] ON [sd].[owner_sid] = [l].[sid]
			WHERE  [sd].[name] = @DBName;
			PRINT @SQLString;
			PRINT 'GO';
			PRINT '';
			FETCH NEXT FROM curs INTO
				@DBName,
				@Filename;
		END;
	CLOSE curs;
	DEALLOCATE curs;
END;
GO