/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to perform a SHRINKFILE command on the database data files
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

USE master;
GO
BEGIN
	SET NOCOUNT ON;
	DECLARE
		@c INT,
		@l INT,
		@s INT,
		@d SYSNAME,
		@f SYSNAME;
	SELECT @d = 'AdventureWorksDW2016'; -- Database Name

	SELECT @l = 32, -- Target Final MB Size of the file to shink
		   @s = 128; -- MB Increment to shrink file by

	SELECT TOP 1 @f = [name]
	FROM         [master].[dbo].[sysaltfiles]
	WHERE        [dbid] = DB_ID(@d)
				 AND [groupid] = 1; -- Name of the 1st data file
	SELECT TOP 1 @c =
		[size] / 1024.0 * 8.0
	FROM         [master].[dbo].[sysaltfiles]
	WHERE        [dbid] = DB_ID(@d)
				 AND [groupid] = 1; -- Size of the 1st data file

	PRINT 'use '+@d;
	PRINT 'GO';
	WHILE(@c >= @l) -- While the size of the file is bigger than the target size
		BEGIN
			PRINT 'select ''Shrinking "'+@d+'.'+@f+'" File from Size "'+CAST(@c AS VARCHAR)+' Mb" by "'+CAST(@s AS VARCHAR)+' Mb" Increment at "'' + cast(getdate() as varchar) + ''"''';
			PRINT 'GO';
			PRINT 'DBCC SHRINKFILE (N'''+@f+''' , '+CAST(@c AS VARCHAR)+')';
			PRINT 'GO';
			SELECT @c =
				@c - @s; -- Size of the file minus the shrink increment
		END;
END;
GO