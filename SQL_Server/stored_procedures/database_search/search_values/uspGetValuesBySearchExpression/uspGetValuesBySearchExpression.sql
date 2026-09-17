USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-17
-- Description:	Returns all values from user-defined 
--				tables and views whose values 
--				contain the specified search expression. 
--				The search is case insensitive.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetValuesBySearchExpression] 
(
	@SearchExpression nvarchar(512),
	@MaxRows int
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @MaxRows < - 1 BEGIN
		;THROW 50000, N'@MaxRows has to be greater than or equal to 0, or -1 for all rows.', 1;
	END
	ELSE BEGIN
		DECLARE 
			@SqlSelectValues nvarchar(max) = N'',
			@SqlCommand nvarchar(max) = N'';

		SELECT
			@SqlSelectValues =
			STRING_AGG(
				CHAR(9) + CAST(N'SELECT DISTINCT ' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + CAST([c].[object_id] AS nvarchar(128)) + N' AS [ObjectId],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'N''' + [o].[type_desc] COLLATE DATABASE_DEFAULT + N''' COLLATE DATABASE_DEFAULT AS [ObjectType],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'N''' + REPLACE(SCHEMA_NAME([o].[schema_id]), N'''', N'''''') COLLATE DATABASE_DEFAULT + N''' COLLATE DATABASE_DEFAULT AS [ObjectSchema],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'N''' + REPLACE([o].[name], N'''', N'''''') COLLATE DATABASE_DEFAULT + N''' COLLATE DATABASE_DEFAULT AS [ObjectName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'N''' + REPLACE([c].[name], N'''', N'''''') COLLATE DATABASE_DEFAULT + N''' COLLATE DATABASE_DEFAULT AS [ColumnName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + CAST(COLUMNPROPERTY([c].[object_id], [c].[name], N'ordinal') AS nvarchar(128)) + N' AS [OrdinalPosition],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + QUOTENAME([c].[name]) + N' COLLATE DATABASE_DEFAULT AS [Value]' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'FROM' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + QUOTENAME(SCHEMA_NAME([o].[schema_id])) + N'.' + QUOTENAME([o].[name]) + CHAR(13) + CHAR(10) +
				CHAR(9) + N'WHERE' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + QUOTENAME([c].[name]) + N' COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N''%'' + @SearchExpression + N''%''',
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10) +
				CHAR(9) + N'UNION ALL' + CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10)
			)
		FROM
			[sys].[columns] [c]
		LEFT JOIN
			[sys].[objects] [o] ON [c].[object_id] = [o].[object_id]
		WHERE
			[o].[is_ms_shipped] = 0
		AND
			[o].[type] IN (N'U', N'V')
		AND
			[c].[system_type_id] IN (167, 175, 231, 239);

		SET @SqlCommand =
		N'WITH [cteValues] AS (' + CHAR(13) + CHAR(10) + 
		@SqlSelectValues + CHAR(13) + CHAR(10) +
		N')' + CHAR(13) + CHAR(10) +
		CHAR(13) + CHAR(10) +
		N'SELECT ' + 
		CASE
			WHEN @MaxRows IS NULL 
				THEN N'TOP (1000)' + CHAR(13) + CHAR(10)
			WHEN @MaxRows = -1
				THEN N'' + CHAR(13) + CHAR(10)
			WHEN @MaxRows >= 0
				THEN N'TOP (' + CAST(@MaxRows AS nvarchar(128)) + N')' + CHAR(13) + CHAR(10)
		END +
		CHAR(9) + N'[ObjectId],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[ObjectType],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[ObjectSchema],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[ObjectName],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[ColumnName],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[OrdinalPosition],' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[Value]' + CHAR(13) + CHAR(10) +
		N'FROM' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[cteValues]' + CHAR(13) + CHAR(10) +
		N'ORDER BY' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[ObjectSchema] ASC,' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[ObjectName] ASC,' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[OrdinalPosition] ASC,' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[Value] ASC' + N';';

		EXEC [sys].[sp_executesql] 
			 @SqlCommand,
			 N'@SearchExpression nvarchar(512)',
			 @SearchExpression = @SearchExpression;
	END;
END;
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspGetValuesBySearchExpression
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all values from user-defined tables and views whose values contain the specified search expression. The search is case insensitive.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetValuesBySearchExpression';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within column values.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetValuesBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO

-- Description for parameter: @MaxRows
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Specifies the maximum number of rows to return. If NULL, a maximum of 1,000 rows is returned. If set to -1, all matching rows are returned.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetValuesBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@MaxRows';
GO