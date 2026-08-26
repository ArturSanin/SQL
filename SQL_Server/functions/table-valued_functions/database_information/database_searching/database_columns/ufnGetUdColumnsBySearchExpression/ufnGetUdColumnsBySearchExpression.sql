USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all columns in user-defined objects
--				whose names contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetUdColumnsBySearchExpression]
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[c].[object_id] AS [ObjectId],
		[o].[type_desc] AS [ObjectType],
		SCHEMA_NAME([o].[schema_id]) AS [SchemaName],
		[o].[name] AS [ObjectName],
		[c].[name] AS [ColumnName],
		COLUMNPROPERTY([c].[object_id], [c].[name], N'ordinal') AS [OrdinalPosition]
	FROM
		[sys].[columns] [c]
	INNER JOIN
		[sys].[objects] [o] ON [c].[object_id] = [o].[object_id]
	WHERE
		[c].[name] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
	AND
		[o].[is_ms_shipped] = 0
)
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetUdColumnsBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all columns in user-defined objects whose names contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUdColumnsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within column names.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUdColumnsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO