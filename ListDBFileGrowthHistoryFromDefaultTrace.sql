/****************************************************************************************************************************************************************
================================================================================
DESCRIPTION:
--------------------------------------------------------------------------------
List the last time a log file was expanded for a databaswe
this will will identify the times when log growth occurs to pinpoint when IO load occurs
these are actual log file expansions on the disk (ie gorws from 10GB to 11GB)
if the file expansion happes in file these are not detected (ie log is 78GB but 5GB used. if it expands to 6GB used but still a 78GB file these are not detected)

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
****************************************************************************************************************************************************************/

BEGIN
	SET NOCOUNT ON;
	DECLARE
		@TracePath NVARCHAR(4000);
	SELECT @TracePath = CAST(value AS NVARCHAR(4000))
	FROM   [sys].[fn_trace_getinfo](1)
	WHERE  [property] = 2;
	SELECT @TracePath;
	SELECT [e].[name] AS [event_name],
		   [t].[loginname],
		   [t].[spid],
		   [t].[databasename],
		   [t].[filename],
		   [t].[starttime],
		   [t].[endtime]
	FROM   [sys].[fn_trace_gettable](@TracePath, DEFAULT) AS [t]
		   INNER JOIN [sys].[trace_events] AS [e] ON [t].[eventclass] = [e].[trace_event_id]
	WHERE  [t].[eventclass] IN(92, 93)
	ORDER BY [endtime];
END;
GO