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
--				created within the specified number 
--				of days from today.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetRecentlyCreatedObjects] 
(
	@CreatedWithinDays int
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
		[o].[create_date] AS [ObjectCreatedOn]
	FROM
		[sys].[objects] [o]
	WHERE
		[o].[is_ms_shipped] = 0
	AND
		@CreatedWithinDays >= 0
	AND
		[o].[create_date] >= DATEADD(DAY, -@CreatedWithinDays, CAST(SYSDATETIME() AS date))
);
GO



-- =============================================
-- MS_Description for function and its parameters:
-- DbInfo.ufnGetRecentlyCreatedObjects
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'Returns all non-system objects created within the specified number of days from today.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetRecentlyCreatedObjects';
GO

-- Description for parameter: @CreatedWithinDays
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'The number of days to look back from today. A value of 0 includes only objects created today.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetRecentlyCreatedObjects',
     @level2type = N'PARAMETER', @level2name = N'@CreatedWithinDays';
GO