USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Calculates the total number of NULL values across all columns of a specified table within a given schema. The procedure iterates through each column, counts the NULLs, and returns the summed result.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspTableNullValueCount] 
(
	@TableSchema sysname,
	@TableName  sysname	
)
AS
BEGIN

	DECLARE
		@Counter int = 1,
		@CounterEnd int,
		@QueryCounterEnd nvarchar(MAX);
	
	-- Determine number of columns in the target table.
	SET @QueryCounterEnd = N'SELECT @CounterEnd = MAX(ORDINAL_POSITION) FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = ''' + @TableSchema + N''' AND [TABLE_NAME] = ''' + @TableName + N''';';

	EXEC [sys].[sp_executesql]
		@QueryCounterEnd,
		N'@CounterEnd INT OUTPUT',
		@CounterEnd = @CounterEnd OUTPUT;

	DECLARE
		@ColumnName sysname,
		@QueryColumnName nvarchar(MAX),
		@TotalNullValueCount int = 0,
		@ColumnNullValueCount int,
		@QueryColumnNullCount nvarchar(MAX);

	-- Loop through all columns and sum up their NULL counts.
	WHILE @Counter <= @CounterEnd
	BEGIN
		-- Get the column name for the current ordinal position.
		SET @QueryColumnName = N'SELECT @ColumnName = [COLUMN_NAME] FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = ''' + @TableSchema + N''' AND [TABLE_NAME] = ''' + @TableName + N''' AND [ORDINAL_POSITION] = ' + CAST(@Counter AS nvarchar(128)) + N';';
		
		EXEC [sys].[sp_executesql]
		@QueryColumnName,
		N'@ColumnName sysname OUTPUT',
		@ColumnName = @ColumnName OUTPUT;
		
		-- Count NULL values for the current column.
		SET @QueryColumnNullCount = 'SELECT @ColumnNullValueCount = COUNT(*) - COUNT(' + QUOTENAME(@ColumnName) + ') FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName)
		
		EXEC sp_executesql 
			@QueryColumnNullCount, 
			N'@ColumnNullValueCount int OUTPUT', 
			@ColumnNullValueCount = @ColumnNullValueCount OUTPUT
		
		-- Add current column’s NULL count to total.
		SET @TotalNullValueCount = @TotalNullValueCount + @ColumnNullValueCount;
		
		-- Increment column counter.
		SET @Counter = @Counter + 1;
	END;

	-- Return total NULL value count as a single result set.
	SELECT @TotalNullValueCount AS [TotalNullValueCount]

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure itself.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Calculates the total number of NULL values across all columns of a specified table within a given schema.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCount';
GO

-- Description for parameter @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The schema name of the table for which NULL values should be counted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCount',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The name of the table for which the total number of NULL values is calculated.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCount',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO