USE [DatabaseName];
GO

/*
    Creates a table that stores NULL and NOT NULL statistics of all user-defined tables and views in the database.
*/

CREATE TABLE [Stats].[NullValueOverview](
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[CellCount] bigint,
	[NullCount] int,
	[NullRatio] float,
	[NullPercentage] float,
	[NotNullCount] int,
	[NotNullRatio] float,
	[NotNullPercentage] float
);

DECLARE 
	@TableType nvarchar(60),
	@TableSchema sysname,
	@TableName sysname,
	@CellCount bigint,
	@NullCount int,
	@NullRatio float,
	@NullPercentage float,
	@NotNullCount int,
	@NotNullRatio float,
	@NotNullPercentage float;

DECLARE @TblTables TABLE (
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[TableNumber] int
);

INSERT INTO @TblTables
SELECT
	CASE
		WHEN [IST].[TABLE_TYPE] = 'BASE TABLE' THEN 'User Table'
		WHEN [IST].[TABLE_TYPE] = 'VIEW' THEN 'View'
	END AS [TableType],
	[IST].[TABLE_SCHEMA] AS [Schema],
	[IST].[TABLE_NAME] AS [Name],
	ROW_NUMBER() OVER (ORDER BY [IST].[TABLE_SCHEMA] ASC, [IST].[TABLE_NAME] ASC) AS [TableNumber]
FROM
	[INFORMATION_SCHEMA].[TABLES] [IST];

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
	SET @TableType = (
		SELECT 
			[TableType] 
		FROM 
			@TblTables 
		WHERE 
			[TableNumber] = @TableCounter
	);

	SET @TableSchema = (
		SELECT 
			[TableSchema] 
		FROM 
			@TblTables 
		WHERE 
			[TableNumber] = @TableCounter
	);

	SET @TableName = (
		SELECT 
			[TableName] 
		FROM 
			@TblTables 
		WHERE 
			[TableNumber] = @TableCounter
	);

	DECLARE 
		@TableRowCount int,
		@QueryTableRowCount nvarchar(MAX) = '',
		@TableColumnCount int,
		@QueryTableColumnCount nvarchar(MAX) = '';

	SET @QueryTableRowCount = N'
		SELECT @TableRowCount = COUNT(*) 
		FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';

	EXEC [sys].[sp_executesql]
		@QueryTableRowCount, 
		N'@TableRowCount int OUTPUT', 
		@TableRowCount = @TableRowCount OUTPUT;

	SET @QueryTableColumnCount = N'
		SELECT @TableColumnCount = COUNT(*) 
		FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_SCHEMA] = ''' + @TableSchema + N''' AND [TABLE_NAME] = ''' + @TableName + N''';';

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
				@Counter int = 1,
				@CounterEnd int = @TableColumnCount,
				@ColumnName sysname,
				@TotalNullCount int = 0,
				@TotalNotNullCount int = 0,
				@ColumnNullCount int,
				@QueryColumnCounts nvarchar(MAX) = '',
				@ColumnNotNullCount int

			WHILE @Counter <= @CounterEnd
			BEGIN				
				SET @ColumnName = (
					SELECT 
						[COLUMN_NAME] 
					FROM 
						[INFORMATION_SCHEMA].[COLUMNS] 
					WHERE 
						[TABLE_SCHEMA] = @TableSchema 
					AND
						[TABLE_NAME] = @TableName 
					AND 
						[ORDINAL_POSITION] = @Counter
				);

				SET @QueryColumnCounts = N'
					SELECT 
						@ColumnNullCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + ' IS NULL THEN 1 ELSE 0 END),
						@ColumnNotNullCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + ' IS NOT NULL THEN 1 ELSE 0 END)
					FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';
		
				EXEC [sys].[sp_executesql]
				@QueryColumnCounts, 
				N'@ColumnNullCount int OUTPUT, @ColumnNotNullCount int OUTPUT', 
				@ColumnNullCount = @ColumnNullCount OUTPUT,
				@ColumnNotNullCount = @ColumnNotNullCount OUTPUT;

				SET @TotalNullCount = @TotalNullCount + @ColumnNullCount;
				SET @TotalNotNullCount = @TotalNotNullCount + @ColumnNotNullCount;
				
				SET @Counter = @Counter + 1;
			END;
			SET @NullCount = @TotalNullCount;
			SET @NotNullCount = @TotalNotNullCount;

			SET @NullRatio = 1.0 * @TotalNullCount / @CellCount;
			SET @NullPercentage = 100 * 1.0 * @TotalNullCount / @CellCount;
			SET @NotNullRatio = 1.0 * @TotalNotNullCount / @CellCount;
			SET @NotNullPercentage = 100 * 1.0 * @TotalNotNullCount / @CellCount;
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