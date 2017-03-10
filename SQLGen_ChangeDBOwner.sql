/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to perform a database OWNER command change for each database to "sa" or the ORIGINAL owner as per a source server
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

-- Change to "sa"
/*
SELECT 'use ['+[name]+']'+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)+'execute dbo.sp_changedbowner ''sa'''+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)
FROM   [master].[dbo].[sysdatabases]
WHERE  [dbid] > 4
ORDER BY [name];
GO
*/

-- Change to Original Owner
SELECT 'use ['+[sd].[name]+']'+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)+'execute dbo.sp_changedbowner '''+isnull([l].[name], 'sa')+''''+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)
FROM   [master].[sys].[databases] AS [sd]
	   LEFT JOIN [master].[sys].[syslogins] AS [l] ON [sd].[owner_sid] = [l].[sid]
WHERE  [sd].[database_id] > 4
ORDER BY [sd].[name];
GO