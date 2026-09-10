USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the count of all user-created 
--				objects across all user-created databases 
--				(database ID > 4) in total, by object type, 
--				by database, or by database and object type.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspCountUserObjectsBySearchExpression] 
(
	@CountType nvarchar(17),
	@SearchExpression nvarchar(512)
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @CountType IS NULL OR @CountType NOT IN (N'Total', N'ByType', N'ByDatabase', N'ByDatabaseAndType') BEGIN
		;THROW 50000, N'@CountType has to be one of the following values: Total, ByType, ByDatabase, ByDatabaseAndType.', 1;
	END
	ELSE BEGIN
		DECLARE @SqlCommand nvarchar(max) = N'';

		SELECT
			@SqlCommand =
			STRING_AGG(
				CHAR(9) + CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'[ao].[object_id] AS [ObjectId],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'[ao].[type_desc] COLLATE DATABASE_DEFAULT AS [ObjectType],' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'[ao].[name] COLLATE DATABASE_DEFAULT AS [ObjectName]' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'FROM' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[all_objects] [ao]' + CHAR(13) + CHAR(10) +
	--			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
	--			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'WHERE' + CHAR(13) + CHAR(10) +
				CHAR(9) + CHAR(9) + N'[ao].[is_ms_shipped] = 0',
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
		N'WITH [cteServerObjects] AS (' + CHAR(13) + CHAR(10) +
		@SqlCommand + CHAR(13) + CHAR(10) +
		N')' + CHAR(13) + CHAR(10) +
		CHAR(13) + CHAR(10) +
		N'SELECT' + CHAR(13) + CHAR(10) +
		CASE 
			WHEN @CountType = N'Total' 
				THEN N'' 
			WHEN @CountType = N'ByType' 
				THEN CHAR(9) + N'[ObjectType],' + CHAR(13) + CHAR(10)
			WHEN @CountType = N'ByDatabase' 
				THEN CHAR(9) + N'[DatabaseName],' + CHAR(13) + CHAR(10)
			WHEN @CountType = N'ByDatabaseAndType' 
				THEN CHAR(9) + N'[DatabaseName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[ObjectType],' + CHAR(13) + CHAR(10)
		END  +
		CHAR(9) + N'COUNT(*) AS [ObjectCount]' + CHAR(13) + CHAR(10) +
		N'FROM' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[cteServerObjects]' + CHAR(13) + CHAR(10) +
		N'WHERE' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[ObjectName] COLLATE SQL_Latin1_General_CP1_CI_AS LIKE N''%'' + @SearchExpression + N''%''' +
		CASE
			WHEN @CountType = N'Total' 
				THEN N';'
			WHEN @CountType = N'ByType' 
				THEN CHAR(13) + CHAR(10) + 
				N'GROUP BY' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[ObjectType];'
			WHEN @CountType = N'ByDatabase' 
				THEN CHAR(13) + CHAR(10) + 
				N'GROUP BY' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[DatabaseName];'
			WHEN @CountType = N'ByDatabaseAndType' 
				THEN CHAR(13) + CHAR(10) + 
				N'GROUP BY' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[DatabaseName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[ObjectType];'
		END; 
		
		EXEC [sys].[sp_executesql] 
			 @SqlCommand,
			 N'@SearchExpression nvarchar(512)',
			 @SearchExpression = @SearchExpression;
	END;
END;
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspCountUserObjectsBySearchExpression
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the count of all user-created objects across all user-created databases (database ID > 4) in total, by object type, by database, or by database and object type, based on the specified search expression.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspCountUserObjectsBySearchExpression';
GO

-- Description for parameter: @CountType
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Specifies how the object count is grouped. Must be one of the following values: Total, ByType, ByDatabase, ByDatabaseAndType.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspCountUserObjectsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@CountType';
GO

-- Description for parameter: @SearchExpression
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The expression to search for within object names.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspCountUserObjectsBySearchExpression',
	 @level2type = N'PARAMETER', @level2name = N'@SearchExpression';
GO