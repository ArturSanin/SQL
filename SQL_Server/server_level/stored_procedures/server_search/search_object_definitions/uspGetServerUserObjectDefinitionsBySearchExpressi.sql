USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-23
-- Description:	Returns all user-created objects across all 
--				user-created databases (database ID > 4) 
--				whose definitions contain the specified 
--				search expression. The search is 
--				case insensitive.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetServerUserObjectDefinitionsBySearchExpression]
(
	@SearchExpression nvarchar(512)
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SqlCommand nvarchar(max) = N'';

	SELECT
		@SqlCommand =
		STRING_AGG(
			CHAR(9) + CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[sm].[object_id] AS [ObjectId],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[o].[type_desc] COLLATE DATABASE_DEFAULT AS [ObjectType],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[s].[name] COLLATE DATABASE_DEFAULT AS [ObjectSchema],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[o].[name] COLLATE DATABASE_DEFAULT AS [ObjectName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[sm].[definition] COLLATE DATABASE_DEFAULT AS [ObjectDefinition]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[sql_modules] [sm]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[objects] [o] ON [sm].[object_id] = [o].[object_id]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s] ON [o].[schema_id] = [s].[schema_id]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'WHERE' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[o].[is_ms_shipped] = 0',
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(9) + N'UNION ALL' + CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10)
		)
	FROM
		[sys].[databases] [d]
	WHERE
		[d].[database_id] > 4;

	SET @SqlCommand = 
	N'WITH [cteServerObjectDefinitions] AS (' + CHAR(13) + CHAR(10) +
	@SqlCommand + CHAR(13) + CHAR(10) +
	N')' + CHAR(13) + CHAR(10) +
	CHAR(13) + CHAR(10) +
	N'SELECT' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[DatabaseName],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectId],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectType],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectSchema],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectName],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectDefinition]' + CHAR(13) + CHAR(10) +
	N'FROM' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[cteServerObjectDefinitions]' + CHAR(13) + CHAR(10) +
	N'WHERE' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectDefinition] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N''%'' + @SearchExpression + N''%'';'; 
		
	EXEC [sys].[sp_executesql] 
		 @SqlCommand,
		 N'@SearchExpression nvarchar(512)',
		 @SearchExpression = @SearchExpression;
END;
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspGetServerUserObjectDefinitionsBySearchExpression
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all user-created objects across all user-created databases (database ID > 4) whose definitions contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetServerUserObjectDefinitionsBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object definitions.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetServerUserObjectDefinitionsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO