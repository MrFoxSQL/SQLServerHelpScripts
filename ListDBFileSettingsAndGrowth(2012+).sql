/************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List all databases and all files in the databsae, along with sizing used and free
and the growth values
SQL Server 2012+

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

BEGIN
	SET NOCOUNT ON;

	-- CALCULATE DATABASE GROWTH OPTIONS CALCULATIONS
	DECLARE
		@DBName    SYSNAME,
		@SQLString NVARCHAR(4000);
	CREATE TABLE [#tempforfilestats]
	(
		[database name]        VARCHAR(35) NOT NULL,
		[file name]            VARCHAR(128) NOT NULL,
		[usage type]           VARCHAR(6) NOT NULL,
		[size (mb)]            REAL NOT NULL,
		[space used (mb)]      REAL NULL,
		[maxsize (mb)]         REAL NOT NULL,
		[next allocation (mb)] REAL NOT NULL,
		[growth type]          VARCHAR(12) NOT NULL,
		[file id]              SMALLINT NOT NULL,
		[group id]             SMALLINT NOT NULL,
		[physical file]        NVARCHAR(260) NOT NULL,
		[date checked]         DATETIME NOT NULL
	);
	CREATE TABLE [#tempfordatafile]
	(
		[file id]       SMALLINT NOT NULL,
		[group id]      SMALLINT NOT NULL,
		[total extents] INT NOT NULL,
		[used extents]  INT NOT NULL,
		[file name]     NVARCHAR(128) NOT NULL,
		[physical file] NVARCHAR(260) NOT NULL
	);
	CREATE TABLE [#tempforlogfile]
	(
		[recovery unit id] INT NOT NULL,
		[file id]          INT NOT NULL,
		[size (bytes)]     REAL NOT NULL,
		[start offset]     VARCHAR(50) NOT NULL,
		[fseqno]           INT NOT NULL,
		[status]           INT NOT NULL,
		[parity]           SMALLINT NOT NULL,
		[createtime]       VARCHAR(50) NOT NULL
	);
	DECLARE cursdb CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR SELECT [name]
		FROM   [master].[dbo].[sysdatabases](nolock)
		WHERE  [status]&512 <> 512 -- NOT OFFLINE
			   AND [status]&1073741824 <> 1073741824 -- NOT SUSPECT
			   AND [status]&32 <> 32 -- NOT LOADING
			   AND [status]&128 <> 128; -- NOT RECOVERING

	OPEN cursdb;
	FETCH FROM cursdb INTO
		@DBName;
	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			SELECT @SQLString = ''+'select '+''''+@DBName+''''+' as ''Database'', '+'convert(nvarchar(128), f.name), '+'case '+'	when (64 & f.status) = 64 then ''Log'' '+'	else ''Data'' '+'end as ''Usage Type'', '+'f.size * 8.00 / 1024.00 as ''Size (MB)'', '+'NULL as ''Space Used (MB)'', '+'case '+'	when f.maxsize < 0 then -1 '+'	when f.maxsize = 0 then f.size * 8.00 / 1024.00'+'	when f.maxsize > 2147483647 then 2147483647 '+'	else f.maxsize * 8.00 / 1024.00 '+'end as ''max Size (MB)'', '+'case '+'	when (1048576 & f.status) = 1048576 then growth'+'	when f.growth = 0 then 0 '+'	else f.growth * 8.00 / 1024.00 '+'end as ''next Allocation (MB)'', '+'case '+'	when (1048576 & f.status) = 1048576 then ''%'' '+'	else ''Mb'' '+'end as ''Usage Type'', '+'f.fileid, '+'f.groupid, '+'filename, '+'getdate() '+' from ['+@DBName+'].dbo.sysfiles f (nolock)';

			--print @SQLString
			INSERT INTO [#tempforfilestats]
			EXECUTE (@SQLString);

			-- SHOW FILE STATS
			SELECT @SQLString = 'USE ['+@DBName+'] DBCC SHOWFILESTATS';

			--print @SQLString
			INSERT INTO [#tempfordatafile]
			EXECUTE (@SQLString);
			UPDATE [#tempforfilestats]
			SET
				[space used (mb)] =
				CONVERT( REAL, [s].[used extents]) * 64 / 1024.00
			FROM [#tempforfilestats] [f](nolock)
				 INNER JOIN [#tempfordatafile] [s](nolock) ON [f].[file id] = [s].[file id]
															  AND [f].[group id] = [s].[group id]
			WHERE  [f].[database name] = @DBName;
			TRUNCATE TABLE [#tempfordatafile];

			-- LOG INFO
			SELECT @SQLString = 'USE ['+@DBName+'] DBCC LOGINFO';

			--print @SQLString
			INSERT INTO [#tempforlogfile]
			EXECUTE (@SQLString);
			UPDATE [#tempforfilestats]
			SET
				[space used (mb)] =
			(
				SELECT
					(
						MIN([l].[start offset]) + SUM(CASE
														  WHEN [l].[status] <> 0
														  THEN [l].[size (bytes)]
														  ELSE 0
													  END)
					) / 1048576.00
				FROM  [#tempforlogfile] AS [l](nolock)
				WHERE [l].[file id] = [f].[file id]
			)
			FROM [#tempforfilestats] [f](nolock)
			WHERE  [f].[database name] = @DBName
				   AND [f].[usage type] = 'Log';
			TRUNCATE TABLE [#tempforlogfile];
			FETCH NEXT FROM cursdb INTO
				@DBName;
		END;
	CLOSE cursdb;
	DEALLOCATE cursdb;
END;
GO
PRINT '';
SELECT [database name],
	   [file name],
	   [usage type],
	   [size (mb)],
	   [space used (mb)],
	   CAST(
			   (
				   [space used (mb)] / [size (mb)] * 100.00
			   ) AS NUMERIC(5, 2)) AS [space used (%)],
	   CASE CONVERT( VARCHAR(25), [maxsize (mb)])
		   WHEN '-1'
		   THEN 'No max Size'
		   ELSE CONVERT(VARCHAR(25), [maxsize (mb)])
	   END AS 'maxSize',
	   CASE CONVERT( VARCHAR, [next allocation (mb)])
		   WHEN '0'
		   THEN 'No'
		   ELSE 'Yes - '+CONVERT(VARCHAR(25), [next allocation (mb)])+' '+[growth type]
	   END AS 'Auto Grow',
	   [next allocation (mb)],
	   [growth type],
	   [file id],
	   [group id],
	   [physical file],
	   [date checked]
FROM   [#tempforfilestats](nolock)
ORDER BY 1,
		 2;
GO
DROP TABLE [#tempforfilestats];
GO
DROP TABLE [#tempfordatafile];
GO
DROP TABLE [#tempforlogfile];
GO