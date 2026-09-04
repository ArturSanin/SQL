USE [ServerInfo];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	This stored procedure refreshes the
--				row counts in non-system tables and views
--				across all user-created databases (database ID > 4)
--				on the current server and writes them into the table
--				dbo.ObjectRowCounts.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspRefreshObjectRowCounts]
AS
BEGIN
	SET NOCOUNT ON;

    TRUNCATE TABLE [dbo].[ObjectRowCounts];

	CREATE TABLE [#Objects](
		[DatabaseName] sysname,
		[ObjectId] int,
		[ObjectType] nvarchar(60),
		[ObjectSchema] sysname,
		[ObjectName] sysname
	);

	DECLARE @SqlCommandInsertIntoTmpTable nvarchar(max) = N'';

	SELECT
		@SqlCommandInsertIntoTmpTable = 
		N'INSERT INTO [#Objects]' + CHAR(13) + CHAR(10) +
		STRING_AGG(
			CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
			CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[o].[object_id] AS [ObjectId],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[o].[type_desc] COLLATE DATABASE_DEFAULT AS [ObjectType],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[s].[name] COLLATE DATABASE_DEFAULT AS [ObjectSchema],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[o].[name] COLLATE DATABASE_DEFAULT AS [ObjectName]' + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[objects] [o]' + CHAR(13) + CHAR(10) +
			N'LEFT JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s] ON [o].[schema_id] = [s].[schema_id]' + CHAR(13) + CHAR(10) +
			N'WHERE'  + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[o].[is_ms_shipped] = 0' + CHAR(13) + CHAR(10) +
			N'AND' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[o].[type] IN (N''U'', N''V'')',
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			N'UNION ALL' + CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10)
		) + N';'
	FROM
		[sys].[databases] [d]
	WHERE
		[d].[database_id] > 4;

	EXEC [sys].[sp_executesql] @SqlCommandInsertIntoTmpTable;

	DECLARE @ObjectsCount int;

	SELECT
		@ObjectsCount = COUNT(*)
	FROM
		[#Objects];

	DECLARE @SqlCommand nvarchar(max) = N'';

	IF @ObjectsCount <= 1000 BEGIN
		SELECT
			@SqlCommand =
			N'INSERT INTO [dbo].[ObjectRowCounts]' + CHAR(13) + CHAR(10) + 
			N'VALUES' + CHAR(13) + CHAR(10) +
			STRING_AGG(
				CAST(N'(' AS nvarchar(max)) + 
				N'N''' + REPLACE([DatabaseName], N'''', N'''''') + N''', ' +
				N'' + CAST([ObjectId] AS nvarchar(128)) + N', ' +
				N'N''' + [ObjectType] + N''', ' +
				N'N''' + REPLACE([ObjectSchema], N'''', N'''''') + N''', ' +
				N'N''' + REPLACE([ObjectName], N'''', N'''''') + N''', ' +
				N'(SELECT COUNT_BIG(*) FROM ' + QUOTENAME([DatabaseName]) + N'.' + QUOTENAME([ObjectSchema]) + N'.' + QUOTENAME([ObjectName]) + ')' + N', ' +
				N'SYSDATETIME()' +
				N')',
				N',' + CHAR(13) + CHAR(10)
			)
		FROM
			[#Objects];
	
		EXEC [sys].[sp_executesql] @SqlCommand;
	END
	ELSE BEGIN
		WITH [cteObjectsWithRowNumbering] AS (
			SELECT
				[DatabaseName],
				[ObjectId],
				[ObjectType],
				[ObjectSchema],
				[ObjectName],
				ROW_NUMBER() OVER(ORDER BY [DatabaseName] ASC, [ObjectSchema] ASC, [ObjectName] ASC) AS [RowNumber]
			FROM
				[#Objects]
		)
	
		SELECT
			@SqlCommand =
			N'INSERT INTO [dbo].[ObjectRowCounts]' + CHAR(13) + CHAR(10) + 
			N'VALUES' + CHAR(13) + CHAR(10) +
			STRING_AGG(
				CAST(N'(' AS nvarchar(max)) + 
				N'N''' + REPLACE([DatabaseName], N'''', N'''''') + N''', ' +
				N'' + CAST([ObjectId] AS nvarchar(128)) + N', ' +
				N'N''' + [ObjectType] + N''', ' +
				N'N''' + REPLACE([ObjectSchema], N'''', N'''''') + N''', ' +
				N'N''' + REPLACE([ObjectName], N'''', N'''''') + N''', ' +
				N'(SELECT COUNT_BIG(*) FROM ' + QUOTENAME([DatabaseName]) + N'.' + QUOTENAME([ObjectSchema]) + N'.' + QUOTENAME([ObjectName]) + ')' + N', ' +
				N'SYSDATETIME()' +
				N')' + 
				CASE
					WHEN [RowNumber] = @ObjectsCount 
						THEN N';'
					WHEN [RowNumber] % 1000 = 0
						THEN N';' + CHAR(13) + CHAR(10) +
						CHAR(13) + CHAR(10) +
						N'INSERT INTO [dbo].[ObjectRowCounts]' + CHAR(13) + CHAR(10) +
						N'VALUES'
					ELSE
						N','
				END,
				CHAR(13) + CHAR(10)	
			)
		FROM
			[cteObjectsWithRowNumbering]

		EXEC [sys].[sp_executesql] @SqlCommand;
	END;

	DROP TABLE [#Objects];

	-- The row count of this table is always 0 because it is truncated before the row counts are calculated.
	DELETE FROM 
		[dbo].[ObjectRowCounts]
	WHERE
		[DatabaseName] = N'ServerInfo'
	AND
		[ObjectSchema] = N'dbo'
	AND
		[ObjectName] = N'ObjectRowCounts';
END
GO



-- =============================================
-- MS_Description for stored procedure:
-- dbo.uspRefreshObjectRowCounts
-- =============================================
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Refreshes the row counts of all non-system tables and views across all user-created databases (database ID > 4) on the current server and stores the results in dbo.ObjectRowCounts.',
	@level0type = N'SCHEMA', @level0name = N'dbo',
	@level1type = N'PROCEDURE', @level1name = N'uspRefreshObjectRowCounts';
GO