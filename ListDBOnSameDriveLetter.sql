/*******************************************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
Databases where the log is on the same drive as the data 
This is a good indicator on which database have data and log sharing a drive
shared data & log can impact IO performance and ideally should be split to different drives (and preferabily different spindles)

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
*******************************************************************************************************************************/

SELECT DISTINCT
	   [dbid] = [s1].[dbid],
	   [dbname] = DB_NAME([s1].[dbid]),
	   [logical_name] = [s1].[name],
	   File_Name = [s1].[filename]
FROM   [master].[dbo].[sysaltfiles] AS [s1]
	   INNER JOIN [master].[dbo].[sysaltfiles] AS [s2] ON [s1].[dbid] = [s2].[dbid]
														  AND LEFT(RTRIM([s1].[filename]), 1) = LEFT(RTRIM([s2].[filename]), 1)
WHERE  [s1].[groupid] = 0
	   AND [s2].[groupid] = 1;