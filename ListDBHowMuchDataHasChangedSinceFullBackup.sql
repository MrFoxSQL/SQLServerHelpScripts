/************************************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
This will list the amount of 8KB pages (data) in the database which has changed since the last time a DB backup was taken
This will indicate how big your next log or differential backup may be

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
************************************************************************************************************************/

-- Prepare staging table for all DBCC outputs
DECLARE
	@Sample TABLE
(
	[col1] VARCHAR(MAX) NOT NULL,
	[col2] VARCHAR(MAX) NOT NULL,
	[col3] VARCHAR(MAX) NOT NULL,
	[col4] VARCHAR(MAX) NOT NULL,
	[col5] VARCHAR(MAX)
);
 
-- Some intermediate variables for controlling loop
DECLARE
	@FileNum      BIGINT       = 1,
	@PageNum      BIGINT       = 6,
	@SQL          VARCHAR(100),
	@Error        INT,
	@DatabaseName SYSNAME      = NULL;
SELECT @DatabaseName = DB_NAME();
 
-- Loop all files to the very end
WHILE 1 = 1
	BEGIN
		BEGIN TRY
			-- Build the SQL string to execute
			SET @SQL = 'DBCC PAGE('+QUOTENAME(@DatabaseName)+', '+CAST(@FileNum AS VARCHAR(50))+', '+CAST(@PageNum AS VARCHAR(50))+', 3) WITH TABLERESULTS';
 
			-- Insert the DBCC output in the staging table
			INSERT INTO @Sample
			([col1],
			 [col2],
			 [col3],
			 [col4]
			)
			EXEC (@SQL);
 
			-- DCM pages exists at an interval
			SET @PageNum+=511232;
		END TRY
		BEGIN CATCH
			-- If error and first DCM page does not exist, all files are read
			IF @PageNum = 6 BREAK;
			ELSE
			-- If no more DCM, increase filenum and start over
			SELECT @FileNum+=1,
				   @PageNum = 6;
		END CATCH;
	END;
 
-- Delete all records not related to diff information
DELETE FROM @Sample
WHERE       [col1] NOT LIKE 'DIFF%';
 
-- Split the range
UPDATE @Sample
SET
	[col5] = PARSENAME(REPLACE([col3], ' - ', '.'), 1),
	[col3] = PARSENAME(REPLACE([col3], ' - ', '.'), 2);
 
-- Remove last paranthesis
UPDATE @Sample
SET
	[col3] = RTRIM(REPLACE([col3], ')', '')),
	[col5] = RTRIM(REPLACE([col5], ')', ''));
 
-- Remove initial information about filenum
UPDATE @Sample
SET
	[col3] = SUBSTRING([col3], CHARINDEX(':', [col3])+1, 8000),
	[col5] = SUBSTRING([col5], CHARINDEX(':', [col5])+1, 8000);
 
-- Prepare data outtake
WITH ctesource([changed],
			   [pagecount])
	 AS (SELECT [changed],
				SUM(
			 COALESCE([topage], [frompage]) - [frompage] + 1) AS [pagecount]
		 FROM
		 (
			 SELECT CAST([col3] AS INT) AS [frompage],
					CAST(NULLIF([col5], '') AS INT) AS [topage],
					LTRIM([col4]) AS [changed]
			 FROM   @Sample
		 ) AS [d]
		 GROUP BY [changed] WITH ROLLUP)
	 -- Present the final result
	 SELECT COALESCE([changed], 'TOTAL PAGES') AS [changed],
			[pagecount],
		 [pagecount] / SUM(CASE
							   WHEN [changed] IS NULL
							   THEN 0
							   ELSE [pagecount]
						   END) OVER() AS [percentage]
	 FROM   [ctesource];