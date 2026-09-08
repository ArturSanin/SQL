USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all objects in the database whose names
--				contain the specified search expression.
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectsBySearchExpression] 
(	
	@SearchExpression nvarchar(512)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[ao].[object_id] AS [ObjectId],
		[ao].[type_desc] AS [ObjectType],
		SCHEMA_NAME([ao].[schema_id]) AS [SchemaName],
		[ao].[name] AS [ObjectName],
		[ao].[create_date] AS [ObjectCreationDate],
		[ao].[modify_date] AS [ObjectLastModified]
	FROM
		[sys].[all_objects] [ao]
	WHERE
		[ao].[name] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N'%' + @SearchExpression + N'%'
);
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectsBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all objects in the database whose names contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object names.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO