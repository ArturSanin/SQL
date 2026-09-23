USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-23
-- Description:	Returns all system objects in the database whose 
--				definitions contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetSystemObjectDefinitionBySearchExpression] 
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[asm].[object_id] AS [ObjectId],
		[ao].[type_desc] AS [ObjectType],
		SCHEMA_NAME([ao].[schema_id]) AS [ObjectSchema],
		[ao].[name] AS [ObjectName],
		[asm].[definition] AS [ObjectDefinition]
	FROM
		[sys].[all_sql_modules] [asm]
	LEFT JOIN
		[sys].[all_objects] [ao] ON [asm].[object_id] = [ao].[object_id]
	WHERE
		[ao].[is_ms_shipped] = 1
	AND
		[asm].[definition] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
);
GO



-- =============================================
-- MS_Description for function and its parameters: 
-- DbInfo.ufnGetSystemObjectDefinitionBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all system objects in the database whose definitions contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetSystemObjectDefinitionBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object definitions.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetSystemObjectDefinitionBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO