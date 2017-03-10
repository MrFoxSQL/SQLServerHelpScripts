/************************************************************************************************
DESCRIPTION:
--------------------------------------------------------------------------------
Generate a script used to perform a drop of all indexes on the current database
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

BEGIN
	SET NOCOUNT ON;
	DECLARE
		@TName SYSNAME;
	SET @TName = NULL;
	SELECT 'DROP INDEX ['+[si].[name]+'] ON ['+[so].[name]+']'
	FROM   [sys].[indexes] AS [si]
		   INNER JOIN [sys].[objects] AS [so] ON [si].object_id = [so].object_id
	WHERE  [so].[name] = isnull(@TName, [so].[name])
		   AND [so].[type_desc] IN('USER_TABLE')
		   AND [si].[name] IS NOT NULL;
END;
GO