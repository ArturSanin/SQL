USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all columns in the database whose names
--				contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetColumnsBySearchExpression] 
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[ac].[object_id] AS [ObjectId],
		[ao].[type_desc] AS [ObjectType],
		SCHEMA_NAME([ao].[schema_id]) AS [SchemaName],
		[ao].[name] AS [ObjectName],
		[ac].[name] AS [ColumnName],
		COLUMNPROPERTY([ac].[object_id], [ac].[name], N'ordinal') AS [OrdinalPosition]
	FROM
		[sys].[all_columns] [ac]
	INNER JOIN
		[sys].[all_objects] [ao] ON [ac].[object_id] = [ao].[object_id]
	WHERE
		[ac].[name] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
)
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetColumnsBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all columns in the database whose names contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetColumnsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within column names.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetColumnsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO