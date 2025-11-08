USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the total number of NULL values for each column of a specified table within a given schema.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspTableNullValueCountByColumn] 
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
		@String nvarchar(MAX),
		@Query nvarchar(MAX) = N'';

	-- Loop through all columns of the table.
	WHILE @Counter <= @CounterEnd
	BEGIN
		IF @Counter = 1
			BEGIN
				-- Get the column name for the current ordinal position.
				SET @QueryColumnName = N'SELECT @ColumnName = [COLUMN_NAME] FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = ''' + @TableSchema + N''' AND [TABLE_NAME] = ''' + @TableName + N''' AND [ORDINAL_POSITION] = ' + CAST(@Counter AS nvarchar(128)) + N';';
		
				EXEC [sys].[sp_executesql]
				@QueryColumnName,
				N'@ColumnName sysname OUTPUT',
				@ColumnName = @ColumnName OUTPUT;
				
				-- Build the dynamic SQL statement that counts NULL values for the current column.
				-- The query selects the column name as [ColumnName] and calculates the number of NULLs
				-- by subtracting COUNT(column_name) from COUNT(*). 
				SET @String = N'SELECT ''' + @ColumnName + N''' AS [ColumnName], COUNT(*) - COUNT(' + QUOTENAME(@ColumnName) + N') AS [NULL Count] FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N' ';
				
				-- Append the generated query string for the current column to the cumulative query.
				SET @Query = @Query + @String;
				
				-- Increment column counter.
				SET @Counter = @Counter + 1;
			END;
		ELSE
			BEGIN
				-- Get the column name for the current ordinal position.
				SET @QueryColumnName = N'SELECT @ColumnName = [COLUMN_NAME] FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = ''' + @TableSchema + N''' AND [TABLE_NAME] = ''' + @TableName + N''' AND [ORDINAL_POSITION] = ' + CAST(@Counter AS nvarchar(128)) + N';';
		
				EXEC [sys].[sp_executesql]
				@QueryColumnName,
				N'@ColumnName sysname OUTPUT',
				@ColumnName = @ColumnName OUTPUT;

				-- Build the dynamic SQL statement that counts NULL values for the current column.
				-- The query selects the column name as [ColumnName] and calculates the number of NULLs
				-- by subtracting COUNT(column_name) from COUNT(*). 
				SET @String = N'UNION ALL SELECT ''' + @ColumnName + N''' AS [ColumnName], COUNT(*) - COUNT(' + QUOTENAME(@ColumnName) + N') AS [NULL Count] FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N' ';
				
				-- Append the generated query string for the current column to the cumulative query.
				SET @Query = @Query + @String;
				
				-- Increment column counter.
				SET @Counter = @Counter + 1;
			END;
	END;

	-- Ordering the table columns in ascending order.
	SET @Query = @Query + N' ORDER BY [ColumnName] ASC';

	-- Executing the dynamic query.
	EXEC [sys].[sp_sqlexec] @Query;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the procedure.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Returns the total number of NULL values for each column of a specified table within a given schema.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCountByColumn';
GO

-- Description for parameter @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the schema name of the table for which the column NULL counts will be calculated.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCountByColumn',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the name of the table for which the column NULL counts will be calculated.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspTableNullValueCountByColumn',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO