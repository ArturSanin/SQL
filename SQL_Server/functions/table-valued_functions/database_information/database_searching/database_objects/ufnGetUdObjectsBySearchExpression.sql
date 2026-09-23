USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all user-defined objects
--				whose names contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetUdObjectsBySearchExpression]
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[o].[object_id] AS [ObjectId],
		[o].[type_desc] AS [ObjectType],
		SCHEMA_NAME([o].[schema_id]) AS [SchemaName],
		[o].[name] AS [ObjectName],
		[o].[create_date] AS [ObjectCreationDate],
		[o].[modify_date] AS [ObjectLastModified]
	FROM
		[sys].[objects] [o]
	WHERE
		[o].[name] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
	AND
		[o].[is_ms_shipped] = 0
);
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetUdObjectsBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all user-defined objects whose names contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUdObjectsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object names.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUdObjectsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO