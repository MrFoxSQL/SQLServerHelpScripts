/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to restore an entire database based on a backup file
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

	--------------------------------------------------------------------------------
	-- Procedure Parameters
	--------------------------------------------------------------------------------
	DECLARE
		@SourceBackupPath         VARCHAR(MAX) = 'C:\SQLBackup\',
		@SourceDBBackupFile       VARCHAR(MAX) = 'PartialDatabase_PARTIAL_Full.bak',
		@SourceFGBackupFile       VARCHAR(MAX) = 'PartialDatabase_PARTIAL_*.bak',
		@TargetFileRestorePath    VARCHAR(255) = 'C:\SQLData\',
		@TargetRestoreDBName      VARCHAR(255) = 'PartialDatabase_Recovery',
		@TargetRestoreWithPartial VARCHAR(255) = 'STATS = 1, REPLACE, NORECOVERY, PARTIAL',
		@TargetRestoreWithRWFG    VARCHAR(255) = 'STATS = 1, NORECOVERY',
		@TargetRestoreWithRWROFG  VARCHAR(255) = 'STATS = 1, RECOVERY',
		@TargetRestoreWithROFG    VARCHAR(255) = 'RECOVERY',
		@Debug                    BIT          = 0;
	--------------------------------------------------------------------------------
	-- Variables
	--------------------------------------------------------------------------------
	DECLARE
		@SQLString NVARCHAR(4000) = '';

	--------------------------------------------------------------------------------
	-- Parameter Validation
	--------------------------------------------------------------------------------
	IF(RIGHT(@TargetFileRestorePath, 1) <> '\')
		SELECT @TargetFileRestorePath = @TargetFileRestorePath+'\';
	IF(RIGHT(@SourceBackupPath, 1) <> '\')
		SELECT @SourceBackupPath = @SourceBackupPath+'\';

	--------------------------------------------------------------------------------
	-- Work Tables
	--------------------------------------------------------------------------------
	CREATE TABLE [#restore_filelistonly]
	(
		[logicalname]          VARCHAR(255),
		[physicalname]         VARCHAR(255),
		[type]                 CHAR(1),
		[filegroupname]        VARCHAR(50),
		[size]                 BIGINT,
		[maxsize]              BIGINT,
		[fileid]               INT,
		[createlsn]            NUMERIC(30, 2),
		[droplsn]              NUMERIC(30, 2),
		[uniqueid]             UNIQUEIDENTIFIER,
		[readonlylsn]          NUMERIC(30, 2),
		[readwritelsn]         NUMERIC(30, 2),
		[backupsizeinbytes]    BIGINT,
		[sourceblocksize]      INT,
		[filegroupid]          INT,
		[loggroupguid]         UNIQUEIDENTIFIER,
		[differentialbaselsn]  NUMERIC(30, 2),
		[differentialbaseguid] UNIQUEIDENTIFIER,
		[isreadonly]           INT,
		[ispresent]            INT,
		[tdethumbprint]        VARCHAR(10)
	);


	--------------------------------------------------------------------------------
	-- Collect RESTORE FILELISTONLY output
	--------------------------------------------------------------------------------
	SET @SQLString = '';
	SET @SQLString = 'RESTORE FILELISTONLY FROM DISK = '''+@SourceBackupPath+@SourceDBBackupFile+'''';
	IF(@Debug = 1)
		PRINT @SQLString;
	INSERT INTO [#restore_filelistonly]
	EXEC (@SQLString);
	IF(@Debug = 1)
		SELECT *
		FROM   [#restore_filelistonly];


	--------------------------------------------------------------------------------
	-- Build RESTORE Statement - CHECK STATUS OF RESTORE
	--------------------------------------------------------------------------------
	PRINT '';
	PRINT '-- RESTORE STATUS CHECK';
	SET @SQLString = '';
	SET @SQLString = 'SELECT file_id, name, type_desc, state_desc, physical_name, read_only_lsn, read_write_lsn, redo_start_lsn, redo_target_lsn '+CHAR(13)+'FROM ['+@TargetRestoreDBName+'].sys.database_files';
	PRINT @SQLString;


	--------------------------------------------------------------------------------
	-- Build RESTORE Statement - PRIMARY & LOG
	--------------------------------------------------------------------------------
	PRINT '';
	PRINT '-- RESTORE PRIMARY & LOG';
	SET @SQLString = '';
	SET @SQLString = 'RESTORE DATABASE ['+@TargetRestoreDBName+']'+CHAR(13)+' FROM DISK = '''+@SourceBackupPath+@SourceDBBackupFile+''''+CHAR(13)+' WITH '+@TargetRestoreWithPartial+', ';
	SELECT @SQLString = @SQLString+CHAR(13)+' MOVE '''+[logicalname]+''' TO '''+@TargetFileRestorePath+[logicalname]+'.'+RIGHT([physicalname], CHARINDEX('\', [physicalname]))+''','
	FROM   [#restore_filelistonly]
	WHERE  [ispresent] = 1;
	SET @SQLString = SUBSTRING(@SQLString, 1, LEN(@SQLString)-1);
	SET @SQLString = @SQLString+CHAR(13)+'GO';
	PRINT @SQLString;


	--------------------------------------------------------------------------------
	-- Build RESTORE Statement - RW FILES
	--------------------------------------------------------------------------------
	PRINT '';
	PRINT '-- RESTORE RW FILEGROUPS';
	SET @SQLString = '';
	SELECT @SQLString = @SQLString+'RESTORE DATABASE ['+@TargetRestoreDBName+'] '+CHAR(13)+'FILEGROUP = '''+[filegroupname]+''''+CHAR(13)+' FROM DISK = '''+@SourceBackupPath+@SourceDBBackupFile+''''+CHAR(13)+' WITH '+@TargetRestoreWithRWFG+CHAR(13)+'GO'+CHAR(13)
	FROM   [#restore_filelistonly]
	WHERE  [ispresent] = 1
		   AND [isreadonly] = 0
		   AND [type] = 'D'
		   AND [filegroupname] <> 'PRIMARY';
	PRINT @SQLString;


	--------------------------------------------------------------------------------
	-- Build RESTORE Statement - RO FILES THAT WERE PREVIOUSLY RW
	--------------------------------------------------------------------------------
	PRINT '';
	PRINT '-- RESTORE RO FILEGROUPS THAT WERE PREVIOUSLY RW';
	SET @SQLString = '';
	SELECT @SQLString = @SQLString+'RESTORE DATABASE ['+@TargetRestoreDBName+'] '+CHAR(13)+'FILEGROUP = '''+[filegroupname]+''''+CHAR(13)+' FROM DISK = '''+@SourceBackupPath+REPLACE(@SourceFGBackupFile, '*', [filegroupname])+''''+CHAR(13)+' WITH '+@TargetRestoreWithRWROFG+CHAR(13)+'GO'+CHAR(13)
	FROM   [#restore_filelistonly]
	WHERE  [isreadonly] = 1
		   AND [type] = 'D'
		   AND [filegroupname] <> 'PRIMARY';
	PRINT @SQLString;


	--------------------------------------------------------------------------------
	-- Build RESTORE Statement - RO FILES
	--------------------------------------------------------------------------------
	PRINT '';
	PRINT '-- RECOVER RO FILEGROUPS';
	SET @SQLString = '';
	SELECT @SQLString = @SQLString+'RESTORE DATABASE ['+@TargetRestoreDBName+'] '+CHAR(13)+'FILEGROUP = '''+[filegroupname]+''''+CHAR(13)+' WITH '+@TargetRestoreWithROFG+CHAR(13)+'GO'+CHAR(13)
	FROM   [#restore_filelistonly]
	WHERE  [isreadonly] = 1
		   AND [type] = 'D'
		   AND [filegroupname] <> 'PRIMARY';
	PRINT @SQLString;
END;
GO
DROP TABLE [#restore_filelistonly];
GO