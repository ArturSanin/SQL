USE [DatabaseName];
GO

/*
    Creates a table that stores NULL and NOT NULL statistics of all user-defined tables and views in the database.
*/

CREATE TABLE [Stats].[NullValueOverview](
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[CellCount] bigint NULL,
	[NullCount] int NULL,
	[NullRatio] decimal(18,6) NULL,
	[NullPercentage] decimal(5, 2) NULL,
	[NotNullCount] int NULL,
	[NotNullRatio] decimal(18,6) NULL,
	[NotNullPercentage] decimal(5, 2) NULL
);

DECLARE 
	@TableType nvarchar(60),
	@TableSchema sysname,
	@TableName sysname,
	@CellCount bigint,
	@NullCount int,
	@NullRatio decimal(18,6),
	@NullPercentage decimal(5,2),
	@NotNullCount int,
	@NotNullRatio decimal(18,6),
	@NotNullPercentage decimal(5,2);

DECLARE @TblTables TABLE (
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[TableNumber] int
);

INSERT INTO @TblTables
SELECT
	CASE
		WHEN [o].[type] = N'U' THEN N'User Table'
		WHEN [o].[type] = N'V' THEN N'View'
	END AS [TableType],
	[s].[name] AS [TableSchema],
	[o].[name] AS [TableName],
	ROW_NUMBER() OVER (ORDER BY [s].[name] ASC, [o].[name] ASC) AS [TableNumber]
FROM
	[sys].[objects] [o]
INNER JOIN
	[sys].[schemas] [s] ON [o].[schema_id] = [s].[schema_id] 
WHERE
	[o].[is_ms_shipped] = 0
AND
	[o].[type] IN ('U', 'V');

DECLARE
	@TableCounter int = 1,
	@TableEndCounter int;

SET @TableEndCounter = (
	SELECT
		COUNT(*)
	FROM
		@TblTables
);

WHILE @TableCounter <= @TableEndCounter
BEGIN
	SELECT
		@TableType = [TableType],
		@TableSchema = [TableSchema],
		@TableName = [TableName] 
	FROM
		@TblTables 
	WHERE 
		[TableNumber] = @TableCounter;

	DECLARE
		@QuotedQualifiedName nvarchar(251) = QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName),
		@ObjectID int,
		@TableRowCount int,
		@QueryTableRowCount nvarchar(MAX) = N'',
		@TableColumnCount int,
		@QueryTableColumnCount nvarchar(MAX) = N'';

	SET @ObjectID = OBJECT_ID(@QuotedQualifiedName);

	SET @QueryTableRowCount = N'
		SELECT @TableRowCount = COUNT(*) 
		FROM ' + @QuotedQualifiedName + N';';

	EXEC [sys].[sp_executesql]
		@QueryTableRowCount, 
		N'@TableRowCount int OUTPUT', 
		@TableRowCount = @TableRowCount OUTPUT;

	SET @QueryTableColumnCount = N'
		SELECT @TableColumnCount = COUNT(*) 
		FROM [sys].[columns] 
		WHERE [object_id] = ' + CAST(@ObjectID AS nvarchar(128)) + N';';

	EXEC [sys].[sp_executesql]
		@QueryTableColumnCount, 
		N'@TableColumnCount int OUTPUT', 
		@TableColumnCount = @TableColumnCount OUTPUT;

	SET @CellCount = @TableRowCount * @TableColumnCount;  
	
	IF @CellCount = 0
		BEGIN
			SET @NullCount = 0;
			SET @NotNullCount = 0;
			SET @NullRatio = 0.0;
			SET @NullPercentage = 0.0;
			SET @NotNullRatio = 0.0;
			SET @NotNullPercentage = 0.0;
		END;
	ELSE IF @CellCount IS NULL
		BEGIN
			SET @NullCount = NULL;
			SET @NotNullCount = NULL;
			SET @NullRatio = NULL;
			SET @NullPercentage = NULL;
			SET @NotNullRatio = NULL;
			SET @NotNullPercentage = NULL;
		END;
	ELSE
		BEGIN
			DECLARE 
				@NullSum nvarchar(max) = N'',
				@NotNullSum nvarchar(max) = N'',
				@Query nvarchar(max) = N'';

			SELECT
				@NullSum = STRING_AGG(CAST(N'SUM(CASE WHEN ' + QUOTENAME([c].[name]) + N' IS NULL THEN 1 ELSE 0 END)' AS nvarchar(max)), N' + '),
				@NotNullSum = STRING_AGG(CAST(N'SUM(CASE WHEN ' + QUOTENAME([c].[name]) + N' IS NOT NULL THEN 1 ELSE 0 END)' AS nvarchar(max)), N' + ')
			FROM
				[sys].[columns] [c]
			WHERE
				[object_id] = @ObjectID;

			SET @Query = N'SELECT @NullCount = ' + @NullSum + N', @NotNullCount = ' + @NotNullSum + 
			N' FROM ' + @QuotedQualifiedName + N';';

			EXEC [sys].[sp_executesql]
			@Query, 
			N'@NullCount int OUTPUT, @NotNullCount int OUTPUT', 
			@NullCount = @NullCount OUTPUT,
			@NotNullCount = @NotNullCount OUTPUT;

			SET @NullRatio = 1.0 * @NullCount / @CellCount;
			SET @NullPercentage = 100 * 1.0 * @NullCount / @CellCount;
			SET @NotNullRatio = 1.0 * @NotNullCount / @CellCount;
			SET @NotNullPercentage = 100 * 1.0 * @NotNullCount / @CellCount;
		END;

	INSERT INTO [Stats].[NullValueOverview] VALUES (
		@TableType, 
		@TableSchema, 
		@TableName, 
		@CellCount, 
		@NullCount, 
		@NullRatio, 
		@NullPercentage, 
		@NotNullCount, 
		@NotNullRatio, 
		@NotNullPercentage
	);
	
	SET @TableCounter = @TableCounter + 1;
END;


EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Contains NULL and NOT NULL statistics of all user-defined tables and views in the database.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Type of the table (User Table, View).',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'TableType';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Schema of the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'TableSchema';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Name of the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'TableName';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Number of cells in the table/view (Rows × Columns).',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'CellCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of NULL values in the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NullCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Ratio of NULL values (NullCount / CellCount).',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NullRatio';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Percentage of NULL values in the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NullPercentage';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of NOT NULL values in the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NotNullCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Ratio of NOT NULL values (NotNullCount / CellCount).',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NotNullRatio';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Percentage of NOT NULL values in the table/view.',
    @level0type = N'SCHEMA', @level0name = N'Stats',
    @level1type = N'TABLE',  @level1name = N'NullValueOverview',
    @level2type = N'COLUMN', @level2name = N'NotNullPercentage';
GO