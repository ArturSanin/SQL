USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all user-created databases
--				(database ID > 4) that contain the
--				specified object by schema and name.
--				For each matching database, the database
--				name, object ID, and object type are returned.
--				The schema and object name must match
--				exactly; otherwise, nothing is returned.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetDatabasesContainingObject] 
(
	@ObjectSchema sysname,
	@ObjectName sysname
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
			CHAR(9) + CHAR(9) + N'[ao].[object_id] AS [ObjectId],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[ao].[type_desc] COLLATE DATABASE_DEFAULT AS [ObjectType]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[all_objects] [ao]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'WHERE' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[s].[name] = N''' + REPLACE(@ObjectSchema, N'''', N'''''') + N'''' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'AND' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[ao].[name] = N''' + REPLACE(@ObjectName, N'''', N'''''') + N'''',
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
	N'WITH [cteDatabases] AS (' + CHAR(13) + CHAR(10) +
	@SqlCommand + CHAR(13) + CHAR(10) +
	N')' + CHAR(13) + CHAR(10) +
	CHAR(13) + CHAR(10) +
	N'SELECT' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[DatabaseName],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectId],' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[ObjectType]' + CHAR(13) + CHAR(10) +
	N'FROM' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[cteDatabases]' + CHAR(13) + CHAR(10) +
	N'ORDER BY' + CHAR(13) + CHAR(10) +
	CHAR(9) + N'[DatabaseName] ASC;'; 
		
	EXEC [sys].[sp_executesql] @SqlCommand;
END;
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspGetDatabasesContainingObject
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all user-created databases (database ID > 4) that contain the specified object by schema and name. For each matching database, the database name, object ID, and object type are returned. The schema and object name must match exactly; otherwise, nothing is returned.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetDatabasesContainingObject';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The schema name of the object to search for. The name must match exactly.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetDatabasesContainingObject',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object to search for. The name must match exactly.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetDatabasesContainingObject',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO