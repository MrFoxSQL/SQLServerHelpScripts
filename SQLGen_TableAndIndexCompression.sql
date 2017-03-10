/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to rebuild tables and indexes to a specific set compression
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
SELECT 'ALTER TABLE '+'['+[s].[name]+']'+'.'+'['+[o].[name]+']'+' REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM   [sys].[objects] AS [o] WITH (nolock)
	   INNER JOIN [sys].[indexes] AS [i] WITH (nolock) ON [o].[object_id] = [i].[object_id]
	   INNER JOIN [sys].[schemas] AS [s] WITH (nolock) ON [o].[schema_id] = [s].[schema_id]
	   INNER JOIN [sys].[dm_db_partition_stats] AS [ps] WITH (nolock) ON [i].[object_id] = [ps].[object_id]
																		 AND [ps].[index_id] = [i].[index_id]
WHERE  [o].[type] = 'U'
ORDER BY [ps].[reserved_page_count];
GO

SET NOCOUNT ON;
SELECT 'ALTER INDEX '+'['+[i].[name]+']'+' ON '+'['+[s].[name]+']'+'.'+'['+[o].[name]+']'+' REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM   [sys].[objects] AS [o] WITH (nolock)
	   INNER JOIN [sys].[indexes] AS [i] WITH (nolock) ON [o].[object_id] = [i].[object_id]
	   INNER JOIN [sys].[schemas] AS [s] WITH (nolock) ON [o].[schema_id] = [s].[schema_id]
	   INNER JOIN [sys].[dm_db_partition_stats] AS [ps] WITH (nolock) ON [i].[object_id] = [ps].[object_id]
																		 AND [ps].[index_id] = [i].[index_id]
WHERE  [o].[type] = 'U'
	   AND [i].[index_id] > 0
ORDER BY [ps].[reserved_page_count];
GO