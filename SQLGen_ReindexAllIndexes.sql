/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to rebuild all indexes in a database
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
SELECT '
print '''+OBJECT_NAME([id])+'.'+[name]+'''; print convert(varchar(25), GETDATE(), 121)
ALTER INDEX ['+[name]+'] on [dbo].['+OBJECT_NAME([id])+'] REBUILD -- with (FILLFACTOR = 0, MAXDOP = 0, ONLINE = OFF)
GO
-- CHECKPOINT
-- GO
-- WAITFOR DELAY ''00:01:00''
-- GO
'
FROM   [sys].[sysindexes]
WHERE  OBJECT_NAME([id]) NOT LIKE 'sys%'
	   AND OBJECT_NAME([id]) NOT LIKE '_WA%'
	   AND [status] <> 8388672
	   AND [indid] > 0
	   AND [name] NOT LIKE '_WA%'
ORDER BY [rowcnt] ASC;