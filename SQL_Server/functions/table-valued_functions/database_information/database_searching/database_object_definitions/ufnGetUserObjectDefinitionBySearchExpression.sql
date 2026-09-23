USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-23
-- Description:	Returns all user-defined objects in the database whose 
--				definitions contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetUserObjectDefinitionBySearchExpression] 
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[sm].[object_id] AS [ObjectId],
		[o].[type_desc] AS [ObjectType],
		SCHEMA_NAME([o].[schema_id]) AS [ObjectSchema],
		[o].[name] AS [ObjectName],
		[sm].[definition] AS [ObjectDefinition]
	FROM
		[sys].[sql_modules] [sm]
	LEFT JOIN
		[sys].[objects] [o] ON [sm].[object_id] = [o].[object_id]
	WHERE
		[o].[is_ms_shipped] = 0
	AND
		[sm].[definition] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
);
GO



-- =============================================
-- MS_Description for function and its parameters: 
-- DbInfo.ufnGetUserObjectDefinitionBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all user-defined objects in the database whose definitions contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUserObjectDefinitionBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object definitions.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetUserObjectDefinitionBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO