/*
    ==================== Description ====================
    This script creates a table that stores the row counts
    of non-system tables and views across all user-created
    databases (database ID > 4) on the server.

    The table is created in the database named ServerInfo.
    If you want to use a different database, search for
    "ServerInfo" and replace it with the name of your database.

    Caution: This script creates the table and performs an
    initial calculation of the row counts. If you want to
    calculate the row counts on a regular basis, consider
    creating a stored procedure that can be executed
    whenever needed.
*/

USE [ServerInfo];
GO


-- ============================================================
-- 1. Creating the table that will store the row counts of
--    non-system tables and views on the server.
-- ============================================================
DROP TABLE IF EXISTS [dbo].[ObjectRowCounts];
GO

CREATE TABLE [dbo].[ObjectRowCounts](
	[DatabaseName] sysname,
	[ObjectId] int,
	[ObjectType] nvarchar(60),
	[ObjectSchema] sysname,
	[ObjectName] sysname,
	[RowCount] bigint,
	[ComputedOn] datetime2(0)
);
GO

-- =============================================
-- MS_Description for table and its columns:
-- dbo.ObjectRowCounts
-- =============================================

-- Description for table
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'Stores the row counts of all non-system tables and views across all user-created databases (database ID > 4) on the server.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts';
GO

-- Description for column: DatabaseName
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The name of the database containing the object.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'DatabaseName';
GO

-- Description for column: ObjectId
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The object ID of the table or view within its database.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectId';
GO

-- Description for column: ObjectType
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The type of the object, such as a user table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectType';
GO

-- Description for column: ObjectSchema
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The schema name of the table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectSchema';
GO

-- Description for column: ObjectName
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The name of the table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectName';
GO

-- Description for column: RowCount
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The number of rows returned by the table or view when the row count was calculated.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'RowCount';
GO

-- Description for column: ComputedOn
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The date and time when the row count was calculated.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ComputedOn';
GO



-- ============================================================
-- 2. Computing the row counts on the server and inserting them
--    into the table.
-- ============================================================
CREATE TABLE [#Objects](
	[DatabaseName] sysname,
	[ObjectId] int,
	[ObjectType] nvarchar(60),
	[ObjectSchema] sysname,
	[ObjectName] sysname
);
GO

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
GO

-- The row count of this table is always 0 because it is truncated before the row counts are calculated.
DELETE FROM 
	[dbo].[ObjectRowCounts]
WHERE
	[DatabaseName] = N'ServerInfo'
AND
	[ObjectSchema] = N'dbo'
AND
	[ObjectName] = N'ObjectRowCounts';