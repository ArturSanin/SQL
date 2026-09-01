USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description: Returns all non-system objects 
--				modified within the specified number 
--				of days from today.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetRecentlyModifiedObjects] 
(
	@ModifiedWithinDays int
)
RETURNS TABLE
AS
RETURN
(		
	SELECT
		[o].[object_id] AS [ObjectId],
		[o].[type_desc] AS [ObjectType],
		SCHEMA_NAME([o].[schema_id]) AS [ObjectSchemaName],
		[o].[name] AS [ObjectName],
		[o].[modify_date] AS [ObjectModifiedOn]
	FROM
		[sys].[objects] [o]
	WHERE
		[o].[is_ms_shipped] = 0
	AND
		@ModifiedWithinDays >= 0
	AND
		[o].[modify_date] >= DATEADD(DAY, -@ModifiedWithinDays, CAST(SYSDATETIME() AS date))
	AND
		[o].[create_date] <> [o].[modify_date]
);
GO



-- =============================================
-- MS_Description for function and its parameters:
-- DbInfo.ufnGetRecentlyModifiedObjects
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'Returns all non-system objects modified within the specified number of days from today.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetRecentlyModifiedObjects';
GO

-- Description for parameter: @ModifiedWithinDays
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'The number of days to look back from today. A value of 0 includes only objects modified today.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetRecentlyModifiedObjects',
     @level2type = N'PARAMETER', @level2name = N'@ModifiedWithinDays';
GO