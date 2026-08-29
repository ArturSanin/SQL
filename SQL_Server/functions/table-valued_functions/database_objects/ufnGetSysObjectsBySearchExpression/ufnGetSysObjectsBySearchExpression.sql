USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all system 
--				objects in the [sys] and 
--				[INFORMATION_SCHEMA] schemas whose 
--				names contain the specified search 
--				expression.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetSysObjectsBySearchExpression]
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
	AND
		[ao].[is_ms_shipped] = 1
	AND
		SCHEMA_NAME([ao].[schema_id]) IN (N'sys', N'INFORMATION_SCHEMA')
);
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetSysObjectsBySearchExpression
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all system objects in the [sys] and [INFORMATION_SCHEMA] schemas whose names contain the specified search expression.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetSysObjectsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object names.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetSysObjectsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO