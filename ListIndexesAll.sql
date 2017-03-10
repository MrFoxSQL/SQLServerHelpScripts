/*================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
list all indexes and particulars, including columns and settings

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
================================================================================*/

SELECT DB_NAME() AS [dbname],
	   [so].[name] AS 'tablename',
	   [si].[indid],
	   [si].[rowcnt],
	   [si].[name] AS [indname],
	   [sik].[keyno] AS [colorder],
	   [sc].[name] AS [colname],
	   CASE
		   WHEN [si].[status]&2048 <> 0
		   THEN 'y'
		   ELSE 'n'
	   END AS 'IsPrimaryKey',
	   CASE
		   WHEN([si].[status]&2 <> 0)
			   OR ([si].[status]&4096 <> 0)
		   THEN 'y'
		   ELSE 'n'
	   END AS 'IsUnique',
	   CASE
		   WHEN OBJECTPROPERTY([so].[id], 'IsMSShipped') = 1
		   THEN 'y'
		   ELSE 'n'
	   END AS 'IsMSShipped'
FROM   [sysindexes] AS [si]
	   JOIN [sysobjects] AS [so] ON [si].[id] = [so].[id]
	   JOIN [sysindexkeys] AS [sik] ON [si].[id] = [sik].[id]
									   AND [si].[indid] = [sik].[indid]
	   JOIN [syscolumns] AS [sc] ON [sik].[id] = [sc].[id]
									AND [sik].[colid] = [sc].[colid]
WHERE  [si].[status]&64 = 0-- and so.name = '" & tbl & "' 
	   AND OBJECTPROPERTY([so].[id], 'IsMSShipped') = 0
ORDER BY [so].[name],
		 [si].[indid],
		 [sik].[keyno]; 

