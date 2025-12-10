USE [DatabaseName];
GO

CREATE TABLE [Stats].[ColumnNullValueOverview](
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[ColumnName] sysname,
	[RowCount] int NULL,
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
	@ColumnName sysname,
	@RowCount int,
	@NullCount int,
	@NullRatio decimal(18,6),
	@NullPercentage decimal(5,2),
	@NotNullCount int,
	@NotNullRatio decimal(18,6),
	@NotNullPercentage decimal(5,2);

DECLARE @TblColumns TABLE (
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[ColumnName] sysname,
	[TableNumber] int
);

INSERT INTO @TblColumns
SELECT
	CASE
		WHEN [o].[type] = N'U' THEN N'User Table'
		WHEN [o].[type] = N'V' THEN N'View'
	END AS [TableType],
	[s].[name] AS [TableSchema],
	[o].[name] AS [TableName],
	[c].[name] AS [ColumnName],
	DENSE_RANK() OVER (ORDER BY [s].[name] ASC, [o].[name] ASC) AS [TableNumber] -- Aus Query entfernen
FROM
	[sys].[columns] [c]
INNER JOIN
	[sys].[objects] [o] ON [c].[object_id] = [o].[object_id] 
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
		MAX([TableNumber])
	FROM
		@TblColumns
);

WHILE @TableCounter <= @TableEndCounter
BEGIN
	SELECT TOP (1)
		@TableType = [TableType],
		@TableSchema = [TableSchema],
		@TableName = [TableName] 
	FROM
		@TblColumns 
	WHERE 
		[TableNumber] = @TableCounter;

	DECLARE
		@QuotedQualifiedName nvarchar(251) = QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName),
		@QueryTableRowCount nvarchar(MAX) = N'';

	SET @QueryTableRowCount = N'
		SELECT @RowCount = COUNT(*) 
		FROM ' + @QuotedQualifiedName + N';';

	EXEC [sys].[sp_executesql]
		@QueryTableRowCount, 
		N'@RowCount int OUTPUT', 
		@RowCount = @RowCount OUTPUT;
  	
	IF @RowCount = 0
		BEGIN
			SET @NullCount = 0;
			SET @NotNullCount = 0;
			SET @NullRatio = 0.0;
			SET @NullPercentage = 0.0;
			SET @NotNullRatio = 0.0;
			SET @NotNullPercentage = 0.0;
		END;
	ELSE IF @RowCount IS NULL
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
				@DeclareStatement nvarchar(max) = N'',
				@SelectCounts nvarchar(max) = N'',
				@Values nvarchar(max) = N'',
				@InsertValuesInto nvarchar(max) = N'',
				@Query nvarchar(max) = N'';

			SELECT
				@DeclareStatement = N'DECLARE ' +  
					STRING_AGG(
						CAST(N'@' AS nvarchar(max)) + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NullCount int, ' + 
						N'@' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NotNullCount int',
						N', '
					),
				@SelectCounts = N'SELECT ' + 
					STRING_AGG(
						CAST(N'@' AS nvarchar(max)) + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NullCount' + N' = SUM(CASE WHEN [' + [ColumnName] + '] IS NULL THEN 1 ELSE 0 END), ' + 
						N'@' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NotNullCount' + N' = SUM(CASE WHEN [' + [ColumnName] + '] IS NOT NULL THEN 1 ELSE 0 END)', 
						N', '
					) + 
					N' FROM ' + @QuotedQualifiedName,
				@Values = STRING_AGG(
					CAST(N'(''' AS nvarchar(max)) + 
					@TableType + N''', ''' + 
					@TableSchema + N''', ''' + 
					@TableName + N''', ''' + 
					[ColumnName] + N''', ' +
					CAST(@RowCount AS nvarchar(128)) + N', ' +
					N'@' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NullCount' + N', ' +
					N'1.0 * @' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NullCount / ' + CAST(@RowCount AS nvarchar(128)) + N', ' +
					N'100 * 1.0 * @' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NullCount / ' + CAST(@RowCount AS nvarchar(128)) + N', ' +
					N'@' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NotNullCount' + N', ' +
					N'1.0 * @' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NotNullCount / ' + CAST(@RowCount AS nvarchar(128)) + N', ' +
					N'100 * 1.0 * @' + REPLACE(REPLACE([ColumnName], ' ', ''), '.', '') + N'NotNullCount / ' + CAST(@RowCount AS nvarchar(128)) +
					N')', 
					N', '
				)
			FROM
				@TblColumns
			WHERE
				[TableNumber] = @TableCounter;
		
			SET @InsertValuesInto = N'INSERT INTO [Stats].[ColumnNullValueOverview] VALUES ' + @Values + N';';
	
			SET @Query = @DeclareStatement + N'; ' + @SelectCounts + N'; ' + @InsertValuesInto;
	
			EXEC [sys].[sp_executesql] @Query;
		END;
	
	SET @TableCounter = @TableCounter + 1;
END;