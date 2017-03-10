/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
list all of the table indexes along with the fragmentation levels

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

-- DMV
-- List all indexes in a database and their fragmentation level

SELECT DB_NAME() AS [dbname],
	   [ss].[name] AS [schemaname],
	   [so].[name] AS [objectname],
	   [si].[name] AS [indexname],
	   [ps].*
FROM   [sys].[dm_db_index_physical_stats](DB_ID(DB_NAME()), NULL, NULL, NULL, 'limited') AS [ps]
	   INNER JOIN [sys].[objects] AS [so] ON [ps].object_id = [so].object_id
	   INNER JOIN [sys].[indexes] AS [si] ON [si].object_id = [ps].object_id
											 AND [si].[index_id] = [ps].[index_id]
	   INNER JOIN [sys].[schemas] AS [ss] ON [ss].schema_id = [so].schema_id
WHERE  1 = 1
--and		object_name(ps.object_id) not like 'Spot%'
ORDER BY 1,
		 2;