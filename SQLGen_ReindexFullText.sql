/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to perform a script generation to reindex all FULL TEXT rebuild commands for all databases that have full text indexes
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
USE master;
GO
PRINT '--------------------------------------------------------------------------------';
PRINT '-- START OF SQL FULLTEXT REBUILD SCRIPT';
PRINT '-- Generated: '+CONVERT(VARCHAR(25), GETDATE(), 121)+' on '+@@SERVERNAME;
PRINT '-- Server   : '+@@SERVERNAME;
PRINT '-- Operator : '+SUSER_SNAME();
PRINT '--';
PRINT '';
PRINT 'use master';
PRINT 'GO';
PRINT 'set nocount on';
PRINT 'GO';
PRINT '';
GO
BEGIN
	SET NOCOUNT ON;
	DECLARE
		@DBName    SYSNAME,
		@Filename  VARCHAR(8000),
		@SQLString NVARCHAR(4000);
	DECLARE curs CURSOR FORWARD_ONLY READ_ONLY STATIC LOCAL
	FOR SELECT [name]
		FROM   [master].[dbo].[sysdatabases] AS [sd]
		ORDER BY 1;
	OPEN curs;
	FETCH curs INTO
		@DBName;
	WHILE(@@fetch_status = 0)
		BEGIN
			PRINT 'print	''''';
			PRINT 'print	''--------------------------------------------------------------------------------''';
			PRINT 'print	''-- Database: '+@DBName+'''';
			PRINT 'USE ['+@DBName+']';
			SELECT @SQLString = '';
			SELECT @SQLString = @SQLString+'select ''USE ['+@DBName+'] ALTER FULLTEXT CATALOG ['' + name + ''] REBUILD'' ';
			SELECT @SQLString = @SQLString+'from	['+@DBName+'].sys.fulltext_catalogs ';
			SELECT @SQLString = @SQLString+'order	by name';
			PRINT @SQLString;
			PRINT 'GO';
			PRINT '';
			FETCH NEXT FROM curs INTO
				@DBName;
		END;
	CLOSE curs;
	DEALLOCATE curs;
END;
GO
PRINT '';
PRINT '--';
PRINT '-- END OF SCRIPT';
PRINT '--------------------------------------------------------------------------------';
GO