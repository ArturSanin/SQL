USE [DatabaseName];
GO

/*
	Profiling table for integer-valued columns (tinyint, smallint, int, bigint) in the database.
*/

-- =====================================================================
-- Create profiling table.
-- =====================================================================
CREATE TABLE [Stats].[IntegerColumnProfiling](
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[ColumnName] sysname NULL,
	[DataType] sysname NULL,
	[RowCount] int NULL,
	[NullCount] int NULL,
	[NullRelativeFrequency] float NULL,
	[NullRelativeFrequencyPercent] float NULL,
	[NotNullCount] int NULL,
	[NotNullRelativeFrequency] float NULL,
	[NotNullRelativeFrequencyPercent] float NULL,
	[Minimum] int NULL,
	[MinimumCount] int NULL,
	[MinimumRelativeFrequency] float NULL,
	[MinimumRelativeFrequencyPercent] float NULL,
	[Maximum] int NULL,
	[MaximumCount] int NULL,
	[MaximumRelativeFrequency] float NULL,
	[MaximumRelativeFrequencyPercent] float NULL,
	[Range] int NULL,
	[HasNegativeValues] bit NULL,
	[NegativeValueCount] int NULL,
	[NegativeValuesRelativeFrequency] float NULL,
	[NegativeValuesRelativeFrequencyPercent] float NULL,
	[OnlyNegativeValues] bit NULL,
	[HasZero] bit NULL,
	[ZeroCount] int NULL,
	[ZeroRelativeFrequency] float NULL,
	[ZeroRelativeFrequencyPercent] float NULL,
	[HasPositiveValues] bit NULL,
	[PositiveValueCount] int NULL,
	[PositiveValuesRelativeFrequency] float NULL,
	[PositiveValuesRelativeFrequencyPercent] float NULL,
	[OnlyPositiveValues] bit NULL,
	[IsMixed] bit NULL,
	[HasEvenValues] bit NULL,
	[EvenValuesCount] int NULL,
	[EvenValuesRelativeFrequency] float NULL,
	[EvenValuesRelativeFrequencyPercent] float NULL,
	[OnlyEvenValues] bit NULL,
	[HasOddValues] bit NULL,
	[OddValuesCount] int NULL,
	[OddValuesRelativeFrequency] float NULL,
	[OddValuesRelativeFrequencyPercent] float NULL,
	[OnlyOddValues] bit NULL,
	[DistinctCount] int NULL,
	[UniquenessRatio] float NULL,
	[UniquenessRatioPercent] float NULL,
	[ColumnSum] int NULL,
	[Mean] float NULL,
	[ValuesSmallerColumnsMeanCount] int NULL,
	[ValuesSmallerColumnsMeanRelativeFrequency] float NULL,
	[ValuesSmallerColumnsMeanRelativeFrequencyPercent] float NULL,
	[ValuesGreaterColumnsMeanCount] int NULL,
	[ValuesGreaterColumnsMeanRelativeFrequency] float NULL,
	[ValuesGreaterColumnsMeanRelativeFrequencyPercent] float NULL,
	[Variance] float NULL,
	[StandardDeviation] float NULL,
	[Percentile25] float NULL,
	[Percentile50] float NULL,
	[Percentile75] float NULL,
	[InterquartileRange] float NULL,
	[LowerFence] float NULL,
	[UpperFence] float NULL,
	[OutlierCountLower] int NULL,
	[OutlierCountUpper] int NULL,
	[OutlierCountTotal] int NULL,
	[ErrorNumber] int NULL,
	[ErrorMessage] nvarchar(4000) NULL
);

-- =====================================================================
-- Declare variables used during iteration.
-- =====================================================================
DECLARE 
	@TableType nvarchar(60),
	@TableSchema sysname,
	@TableName sysname,
	@ColumnName sysname,
	@DataType sysname,
	@RowCount int,
	@NullCount int,
	@NullRelativeFrequency float,
	@NullRelativeFrequencyPercent float,
	@NotNullCount int,
	@NotNullRelativeFrequency float,
	@NotNullRelativeFrequencyPercent float,
	@Minimum int,
	@MinimumCount int,
	@MinimumRelativeFrequency float,
	@MinimumRelativeFrequencyPercent float,
	@Maximum int,
	@MaximumCount int,
	@MaximumRelativeFrequency float,
	@MaximumRelativeFrequencyPercent float,
	@Range int,
	@HasNegativeValues bit,
	@NegativeValueCount int,
	@NegativeValuesRelativeFrequency float,
	@NegativeValuesRelativeFrequencyPercent float,
	@OnlyNegativeValues bit,
	@HasZero bit,
	@ZeroCount int,
	@ZeroRelativeFrequency float,
	@ZeroRelativeFrequencyPercent float,
	@HasPositiveValues bit,
	@PositivValueCount int,
	@PositiveValuesRelativeFrequency float,
	@PositiveValuesRelativeFrequencyPercent float,
	@OnlyPositiveValues bit,
	@IsMixed bit,
	@HasEvenValues bit,
	@EvenValuesCount int,
	@EvenValuesRelativeFrequency float,
	@EvenValuesRelativeFrequencyPercent float,
	@OnlyEvenValues bit,
	@HasOddValues bit,
	@OddValuesCount int,
	@OddValuesRelativeFrequency float,
	@OddValuesRelativeFrequencyPercent float,
	@OnlyOddValues bit,
	@DistinctCount int,
	@UniquenessRatio float,
	@UniquenessRatioPercent float,
	@ColumnSum int,
	@Mean float,
	@ValuesSmallerColumnsMeanCount int,
	@ValuesSmallerColumnsMeanRelativeFrequency float,
	@ValuesSmallerColumnsMeanRelativeFrequencyPercent float,
	@ValuesGreaterColumnsMeanCount int,
	@ValuesGreaterColumnsMeanRelativeFrequency float,
	@ValuesGreaterColumnsMeanRelativeFrequencyPercent float,
	@Variance float,
	@StandardDeviation float,
	@Percentile25 float,
	@Percentile50 float,
	@Percentile75 float,
	@InterquartileRange float,
	@LowerFence float,
	@UpperFence float,
	@OutlierCountLower int,
	@OutlierCountUpper int,
	@OutlierCountTotal int,
	@ErrorNumber int,
	@ErrorMessage nvarchar(4000);

-- =====================================================================
-- Table with all columns to process.
-- =====================================================================
DECLARE @TblColumns TABLE (
	[TableType] nvarchar(60),
	[TableSchema] sysname,
	[TableName] sysname,
	[ColumnName] sysname,
	[DataType] sysname,
	[TableNumber] int,
	[ColumnNumber] int
);

INSERT INTO @TblColumns
SELECT
	[ao].[type_desc] AS [TableType],
	[s].[name] AS [TableSchema],
	[ao].[name] AS [TableName],
	[ac].[name] AS [ColumnName],
	[t].[name] AS [DataType],
	DENSE_RANK() OVER (ORDER BY [ao].[type_desc], [s].[name], [ao].[name]) AS [TableNumber],
	ROW_NUMBER() OVER (PARTITION BY [s].[name], [ao].[name] ORDER BY [ac].[column_id] ASC) AS [ColumnNumber]
FROM
	[sys].[all_columns] [ac] 
LEFT JOIN
	[sys].[all_objects] [ao] ON [ac].[object_id] = [ao].[object_id] 
LEFT JOIN
	[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]
LEFT JOIN 
	[sys].[types] [t] ON [ac].[system_type_id] = [t].[system_type_id] 
WHERE
	[ao].[type] IN ('IT', 'S', 'U', 'V')
AND
	[t].[system_type_id] IN (48, 52, 56, 127);

-- =====================================================================
-- Loop through each table and column.
-- =====================================================================
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
	BEGIN TRY
		SET @ErrorNumber = NULL;
		SET @ErrorMessage = NULL;

		-- =====================================================================
		-- Value for the column TableType.
		-- =====================================================================
		SET @TableType = (
			SELECT TOP (1)
				[TableType] 
			FROM 
				@TblColumns 
			WHERE 
				[TableNumber] = @TableCounter
		);

		-- =====================================================================
		-- Value for the column TableSchema.
		-- =====================================================================
		SET @TableSchema = (
			SELECT TOP (1)
				[TableSchema] 
			FROM 
				@TblColumns 
			WHERE 
				[TableNumber] = @TableCounter
		);

		-- =====================================================================
		-- Value for the column TableName.
		-- =====================================================================
		SET @TableName = (
			SELECT TOP (1)
				[TableName] 
			FROM 
				@TblColumns 
			WHERE 
				[TableNumber] = @TableCounter
		);

		-- =====================================================================
		-- Checks whether the table exists. If it does not exist, an error is 
		-- raised and control is passed to the CATCH block.
		-- =====================================================================
		DECLARE 
			@QueryTest nvarchar(MAX),
			@TestParameter int;

		SET @QueryTest = N'SELECT @TestParameter = COUNT(*) FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';
		
		EXEC [sys].[sp_executesql] 
			@QueryTest,
			N'@TestParameter int OUTPUT', 
			@TestParameter = @TestParameter OUTPUT;
		
		-- =====================================================================
		-- Declaration of the column counter variable.
		-- =====================================================================

		DECLARE 
			@ColumnCounter int = 1,
			@EndColumnCounter int;

		SET @EndColumnCounter = (
			SELECT
				MAX([ColumnNumber])
			FROM
				@TblColumns
			WHERE
				[TableSchema] = @TableSchema
			AND
				[TableName] = @TableName
		);

		WHILE @ColumnCounter <= @EndColumnCounter
		BEGIN
			-- =====================================================================
			-- Value for the column ColumnName.
			-- =====================================================================
			SET @ColumnName = (
				SELECT 
					[ColumnName] 
				FROM 
					@TblColumns 
				WHERE 
					[TableNumber] = @TableCounter
				AND
					[ColumnNumber] = @ColumnCounter
			);

			-- =====================================================================
			-- Value for the column DataType.
			-- =====================================================================
			SET @DataType = (
				SELECT  TOP (1)
					[DataType] 
				FROM 
					@TblColumns 
				WHERE 
					[TableNumber] = @TableCounter
				AND
					[ColumnNumber] = @ColumnCounter
			);

			-- =====================================================================
			-- Value for the column NullCount.
			-- =====================================================================
			DECLARE @QueryNullCount nvarchar(MAX);

			SET @QueryNullCount = N'SELECT @NullCount = COUNT(*) FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N' WHERE ' + QUOTENAME(@ColumnName) + N' IS NULL;'

			EXEC [sys].[sp_executesql]
				@QueryNullCount, 
				N'@NullCount int OUTPUT', 
				@NullCount = @NullCount OUTPUT;

			-- =====================================================================
			-- Value for the column NotNullCount.
			-- =====================================================================
			DECLARE @QueryNotNullCount nvarchar(MAX);

			SET @QueryNotNullCount = N'SELECT @NotNullCount = COUNT(*) FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N' WHERE ' + QUOTENAME(@ColumnName) + N' IS NOT NULL;'

			EXEC [sys].[sp_executesql]
				@QueryNotNullCount, 
				N'@NotNullCount int OUTPUT', 
				@NotNullCount = @NotNullCount OUTPUT;

			-- =====================================================================
			-- Value for the column RowCount.
			-- =====================================================================
			SET @RowCount = @NullCount + @NotNullCount;

			IF @RowCount > 0
				BEGIN
					-- =====================================================================
					-- Value for the column NullRelativeFrequency.
					-- =====================================================================
					SET @NullRelativeFrequency = 1.0 * @NullCount / @RowCount;

					-- =====================================================================
					-- Value for the column NullRelativeFrequencyPercent.
					-- =====================================================================
					SET @NullRelativeFrequencyPercent = 100 * @NullRelativeFrequency;

					-- =====================================================================
					-- Value for the column NotNullRelativeFrequency.
					-- =====================================================================
					SET @NotNullRelativeFrequency = 1.0 * @NotNullCount / @RowCount;

					-- =====================================================================
					-- Value for the column NotNullRelativeFrequencyPercent.
					-- =====================================================================
					SET @NotNullRelativeFrequencyPercent = 100 * @NotNullRelativeFrequency;
				END;
			ELSE IF @RowCount = 0
				BEGIN
					SET @NullRelativeFrequency = 0.0;
					SET @NullRelativeFrequencyPercent = 0.0;
					SET @NotNullRelativeFrequency = 0.0;
					SET @NotNullRelativeFrequencyPercent = 0.0;
				END;
			ELSE
				BEGIN
					SET @NullRelativeFrequency = NULL;
					SET @NullRelativeFrequencyPercent = NULL;
					SET @NotNullRelativeFrequency = NULL;
					SET @NotNullRelativeFrequencyPercent = NULL;
				END;

			-- =====================================================================
			-- Computing various statistics.
			-- =====================================================================
			DECLARE 
				@QueryStatistics nvarchar(MAX),
				@QueryCountStatistics nvarchar(MAX),
				@QueryPercentiles nvarchar(MAX),
				@Parameters nvarchar(MAX);

			SET @QueryStatistics = N'
			SELECT
				-- =====================================================================
				-- Value for the column Minimum.
				-- =====================================================================
				@Minimum = MIN(' + QUOTENAME(@ColumnName) + N'),

				-- =====================================================================
				-- Value for the column Maximum.
				-- =====================================================================
				@Maximum = MAX(' + QUOTENAME(@ColumnName) + N'),

				-- =====================================================================
				-- Value for the column DistinctCount.
				-- =====================================================================
				@DistinctCount = COUNT(DISTINCT ' + QUOTENAME(@ColumnName) + N'),

				-- =====================================================================
				-- Value for the column ColumnSum.
				-- =====================================================================
				@ColumnSum = SUM( ' + QUOTENAME(@ColumnName) + N' ),

				-- =====================================================================
				-- Value for the column Mean.
				-- =====================================================================
				@Mean = AVG(1.0 * ' + QUOTENAME(@ColumnName) + N'),
				
				-- =====================================================================
				-- Value for the column Variance.
				-- =====================================================================
				@Variance = VAR(1.0 * ' + QUOTENAME(@ColumnName) + N'),

				-- =====================================================================
				-- Value for the column StandardDeviation.
				-- =====================================================================
				@StandardDeviation = STDEV(1.0 * ' + QUOTENAME(@ColumnName) + N')
			FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';

			SET @Parameters = N'
				@Minimum int OUTPUT,
				@Maximum int OUTPUT,
				@DistinctCount int OUTPUT,
				@ColumnSum int OUTPUT,
				@Mean float OUTPUT,
				@Variance float OUTPUT,
				@StandardDeviation float OUTPUT
			';

			EXEC [sys].[sp_executesql]
				@QueryStatistics,
				@Parameters,
				@Minimum = @Minimum OUTPUT,
				@Maximum = @Maximum OUTPUT,
				@DistinctCount = @DistinctCount OUTPUT,
				@ColumnSum = @ColumnSum OUTPUT,
				@Mean = @Mean OUTPUT,
				@Variance = @Variance OUTPUT,
				@StandardDeviation = @StandardDeviation OUTPUT;

			-- =====================================================================
			-- Value for the column Range.
			-- =====================================================================
			SET @Range = @Maximum - @Minimum;

			-- =====================================================================
			-- Computing various percentiles.
			-- =====================================================================
			SET @QueryPercentiles = N'
			SELECT
				-- =====================================================================
				-- Value for the column Percentile25.
				-- =====================================================================
				@Percentile25 = PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY 1.0 * ' + QUOTENAME(@ColumnName) + N') OVER(),
				
				-- =====================================================================
				-- Value for the column Percentile50.
				-- =====================================================================
				@Percentile50 = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY 1.0 * ' + QUOTENAME(@ColumnName) + N') OVER(),
				
				-- =====================================================================
				-- Value for the column Percentile75.
				-- =====================================================================
				@Percentile75 = PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY 1.0 * ' + QUOTENAME(@ColumnName) + N') OVER()
			FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';

			SET @Parameters = N'
				@Percentile25 float OUTPUT,
				@Percentile50 float OUTPUT,
				@Percentile75 float OUTPUT
			';

			EXEC [sys].[sp_executesql]
				@QueryPercentiles,
				@Parameters,
				@Percentile25 = @Percentile25 OUTPUT,
				@Percentile50 = @Percentile50 OUTPUT,
				@Percentile75 = @Percentile75 OUTPUT;

			-- =====================================================================
			-- Value for the column InterquartileRange.
			-- =====================================================================
			SET @InterquartileRange = @Percentile75 - @Percentile25;

			-- =====================================================================
			-- Value for the column LowerFence.
			-- =====================================================================
			SET @LowerFence = @Percentile25 - 1.5 * @InterquartileRange;

			-- =====================================================================
			-- Value for the column UpperFence.
			-- =====================================================================
			SET @UpperFence = @Percentile75 + 1.5 * @InterquartileRange;



			-- =====================================================================
			-- Computing various count statistics.
			-- =====================================================================
			SET @QueryCountStatistics = N'
			SELECT
				-- =====================================================================
				-- Value for the column MinimumCount.
				-- =====================================================================
				@MinimumCount = SUM(CASE WHEN ' + CAST(@Minimum AS nvarchar(128)) + N' IS NULL THEN NULL WHEN ' + QUOTENAME(@ColumnName) + N' = ' + CAST(@Minimum AS nvarchar(128)) + N' THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column MaximumCount.
				-- =====================================================================
				@MaximumCount = SUM(CASE WHEN ' + CAST(@Maximum AS nvarchar(128)) + N' IS NULL THEN NULL WHEN ' + QUOTENAME(@ColumnName) + N' = ' + CAST(@Maximum AS nvarchar(128)) + N' THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column NegativeValueCount.
				-- =====================================================================
				@NegativeValueCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' < 0 THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column ZeroCount.
				-- =====================================================================
				@ZeroCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' = 0 THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column PositivValueCount.
				-- =====================================================================
				@PositivValueCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' > 0 THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column EvenValuesCount.
				-- =====================================================================
				@EvenValuesCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' % 2 = 0 THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column OddValuesCount.
				-- =====================================================================
				@OddValuesCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' % 2 = 1 THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column ValuesSmallerColumnsMeanCount.
				-- =====================================================================
				@ValuesSmallerColumnsMeanCount = SUM(CASE WHEN ' + CAST(@Mean AS nvarchar(128)) + N' IS NULL THEN NULL WHEN ' + QUOTENAME(@ColumnName) + N' < ' + CAST(@Mean AS nvarchar(128)) + N' THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column ValuesGreaterColumnsMeanCount.
				-- =====================================================================
				@ValuesGreaterColumnsMeanCount = SUM(CASE WHEN ' + CAST(@Mean AS nvarchar(128)) + N' IS NULL THEN NULL WHEN ' + QUOTENAME(@ColumnName) + N' > ' + CAST(@Mean AS nvarchar(128)) + N' THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column OutlierCountLower.
				-- =====================================================================
				@OutlierCountLower = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' < ' + CAST(@LowerFence AS nvarchar(128)) + N' THEN 1 ELSE 0 END),

				-- =====================================================================
				-- Value for the column OutlierCountUpper.
				-- =====================================================================
				@OutlierCountUpper = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + N' < ' + CAST(@LowerFence AS nvarchar(128)) + N' THEN 1 ELSE 0 END)
				
			FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N';';

			SET @Parameters = N'
				@MinimumCount int OUTPUT,
				@MaximumCount int OUTPUT,
				@NegativeValueCount int OUTPUT,
				@ZeroCount int OUTPUT,
				@PositivValueCount int OUTPUT,
				@EvenValuesCount int OUTPUT,
				@OddValuesCount int OUTPUT,
				@ValuesSmallerColumnsMeanCount int OUTPUT,
				@ValuesGreaterColumnsMeanCount int OUTPUT,
				@OutlierCountLower int OUTPUT,
				@OutlierCountUpper int OUTPUT
			';

			EXEC [sys].[sp_executesql]
				@QueryCountStatistics,
				@Parameters,
				@MinimumCount = @MinimumCount OUTPUT,
				@MaximumCount = @MaximumCount OUTPUT,
				@NegativeValueCount = @NegativeValueCount OUTPUT,
				@ZeroCount = @ZeroCount OUTPUT,
				@PositivValueCount = @PositivValueCount OUTPUT,
				@EvenValuesCount = @EvenValuesCount OUTPUT,
				@OddValuesCount = @OddValuesCount OUTPUT,
				@ValuesSmallerColumnsMeanCount = @ValuesSmallerColumnsMeanCount OUTPUT,
				@ValuesGreaterColumnsMeanCount = @ValuesGreaterColumnsMeanCount OUTPUT,
				@OutlierCountLower = @OutlierCountLower OUTPUT,
				@OutlierCountUpper = @OutlierCountUpper  OUTPUT;
			
			-- =====================================================================
			-- Value for the column OutlierCountTotal.
			-- =====================================================================
			SET @OutlierCountTotal = @OutlierCountLower + @OutlierCountUpper;
 


			-- =====================================================================
			-- Computing Ratios.
			-- =====================================================================
			IF @NotNullCount > 0
				BEGIN
					-- =====================================================================
					-- Value for the column MinimumRelativeFrequency.
					-- =====================================================================
					SET @MinimumRelativeFrequency = 1.0 * @MinimumCount / @NotNullCount; 

					-- =====================================================================
					-- Value for the column MinimumRelativeFrequencyPercent.
					-- =====================================================================
					SET @MinimumRelativeFrequencyPercent = 100 * @MinimumRelativeFrequency;

					-- =====================================================================
					-- Value for the column MaximumRelativeFrequency.
					-- =====================================================================
					SET @MaximumRelativeFrequency = 1.0 * @MaximumCount / @NotNullCount; 

					-- =====================================================================
					-- Value for the column MaximumRelativeFrequencyPercent.
					-- =====================================================================
					SET @MaximumRelativeFrequencyPercent = 100 * @MaximumRelativeFrequency;

					-- =====================================================================
					-- Value for the column NegativeValuesRelativeFrequency.
					-- =====================================================================
					SET @NegativeValuesRelativeFrequency = 1.0 * @NegativeValueCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column NegativeValuesRelativeFrequencyPercent.
					-- =====================================================================
					SET @NegativeValuesRelativeFrequencyPercent = 100 * @NegativeValuesRelativeFrequency;

					-- =====================================================================
					-- Value for the column ZeroRelativeFrequency.
					-- =====================================================================
					SET @ZeroRelativeFrequency = 1.0 * @ZeroCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column ZeroRelativeFrequencyPercent.
					-- =====================================================================
					SET @ZeroRelativeFrequencyPercent = 100 * @ZeroRelativeFrequency;

					-- =====================================================================
					-- Value for the column PositiveValuesRelativeFrequency.
					-- =====================================================================
					SET @PositiveValuesRelativeFrequency = 1.0 * @PositivValueCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column PositiveValuesRelativeFrequencyPercent.
					-- =====================================================================
					SET @PositiveValuesRelativeFrequencyPercent = 100 * @PositiveValuesRelativeFrequency;

					-- =====================================================================
					-- Value for the column EvenValuesRelativeFrequency.
					-- =====================================================================
					SET @EvenValuesRelativeFrequency = 1.0 * @EvenValuesCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column EvenValuesRelativeFrequencyPercent.
					-- =====================================================================
					SET @EvenValuesRelativeFrequencyPercent = 100 * @EvenValuesRelativeFrequency;

					-- =====================================================================
					-- Value for the column OddValuesRelativeFrequency.
					-- =====================================================================
					SET @OddValuesRelativeFrequency = 1.0 * @OddValuesCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column OddValuesRelativeFrequencyPercent.
					-- =====================================================================
					SET @OddValuesRelativeFrequencyPercent = 100 * @OddValuesRelativeFrequency;

					-- =====================================================================
					-- Value for the column ValuesSmallerColumnsMeanRelativeFrequency.
					-- =====================================================================
					SET @ValuesSmallerColumnsMeanRelativeFrequency = 1.0 * @ValuesSmallerColumnsMeanCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column ValuesSmallerColumnsMeanRelativeFrequencyPercent.
					-- =====================================================================
					SET @ValuesSmallerColumnsMeanRelativeFrequencyPercent = 100 * @ValuesSmallerColumnsMeanRelativeFrequency;

					-- =====================================================================
					-- Value for the column ValuesGreaterColumnsMeanRelativeFrequency.
					-- =====================================================================
					SET @ValuesGreaterColumnsMeanRelativeFrequency = 1.0 * @ValuesGreaterColumnsMeanCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column ValuesGreaterColumnsMeanRelativeFrequencyPercent.
					-- =====================================================================
					SET @ValuesGreaterColumnsMeanRelativeFrequencyPercent = 100 * @ValuesGreaterColumnsMeanRelativeFrequency;

					-- =====================================================================
					-- Value for the column UniquenessRatio.
					-- =====================================================================
					SET @UniquenessRatio = 1.0 * @DistinctCount / @NotNullCount;

					-- =====================================================================
					-- Value for the column UniquenessRatioPercent.
					-- =====================================================================
					SET @UniquenessRatioPercent = 100 * @UniquenessRatio;
				END;
			ELSE IF @NotNullCount = 0
				BEGIN
					SET @MinimumRelativeFrequency = 0.0;
					SET @MinimumRelativeFrequencyPercent = 0.0;
					SET @MaximumRelativeFrequency = 0.0;
					SET @MaximumRelativeFrequencyPercent = 0.0;
					SET @NegativeValuesRelativeFrequency = 0.0;
					SET @NegativeValuesRelativeFrequencyPercent = 0.0;
					SET @ZeroRelativeFrequency = 0.0;
					SET @ZeroRelativeFrequencyPercent = 0.0;
					SET @PositiveValuesRelativeFrequency = 0.0;
					SET @PositiveValuesRelativeFrequencyPercent = 0.0;
					SET @EvenValuesRelativeFrequency = 0.0;
					SET @EvenValuesRelativeFrequencyPercent = 0.0;
					SET @OddValuesRelativeFrequency = 0.0;
					SET @OddValuesRelativeFrequencyPercent = 0.0;
					SET @ValuesSmallerColumnsMeanRelativeFrequency = 0.0;
					SET @ValuesSmallerColumnsMeanRelativeFrequencyPercent = 0.0;
					SET @ValuesGreaterColumnsMeanRelativeFrequency = 0.0;
					SET @ValuesGreaterColumnsMeanRelativeFrequencyPercent = 0.0;
					SET @UniquenessRatio = 0.0;
					SET @UniquenessRatioPercent = 0.0;
				END;
			ELSE
				BEGIN
					SET @MinimumRelativeFrequency = NULL;
					SET @MinimumRelativeFrequencyPercent = NULL;
					SET @MaximumRelativeFrequency = NULL;
					SET @MaximumRelativeFrequencyPercent = NULL;
					SET @NegativeValuesRelativeFrequency = NULL;
					SET @NegativeValuesRelativeFrequencyPercent = NULL;
					SET @ZeroRelativeFrequency = NULL;
					SET @ZeroRelativeFrequencyPercent = NULL;
					SET @PositiveValuesRelativeFrequency = NULL;
					SET @PositiveValuesRelativeFrequencyPercent = NULL;
					SET @EvenValuesRelativeFrequency = NULL;
					SET @EvenValuesRelativeFrequencyPercent = NULL;
					SET @OddValuesRelativeFrequency = NULL;
					SET @OddValuesRelativeFrequencyPercent = NULL;
					SET @ValuesSmallerColumnsMeanRelativeFrequency = NULL;
					SET @ValuesSmallerColumnsMeanRelativeFrequencyPercent = NULL;
					SET @ValuesGreaterColumnsMeanRelativeFrequency = NULL;
					SET @ValuesGreaterColumnsMeanRelativeFrequencyPercent = NULL;
					SET @UniquenessRatio = NULL;
					SET @UniquenessRatioPercent = NULL;
				END;

			-- =====================================================================
			-- Computing various flags.
			-- =====================================================================

			-- =====================================================================
			-- Value for the column HasNegativeValues.
			-- =====================================================================
			IF @NegativeValueCount > 0
				BEGIN
					SET @HasNegativeValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @HasNegativeValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column OnlyNegativeValues.
			-- =====================================================================
			IF @NegativeValueCount = @NotNullCount
				BEGIN
					SET @OnlyNegativeValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @OnlyNegativeValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column HasZero.
			-- =====================================================================
			IF @ZeroCount > 0
				BEGIN
					SET @HasZero = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @HasZero = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column HasPositiveValues.
			-- =====================================================================
			IF @PositivValueCount > 0
				BEGIN
					SET @HasPositiveValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @HasPositiveValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column OnlyPositiveValues.
			-- =====================================================================
			IF @PositivValueCount = @NotNullCount
				BEGIN
					SET @OnlyPositiveValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @OnlyPositiveValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column IsMixed.
			-- =====================================================================
			IF @NegativeValueCount > 0 AND @PositivValueCount > 0
				BEGIN
					SET @IsMixed = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @IsMixed = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column HasEvenValues.
			-- =====================================================================
			IF @EvenValuesCount > 0
				BEGIN
					SET @HasEvenValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @HasEvenValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column OnlyEvenValues.
			-- =====================================================================
			IF @EvenValuesCount = @NotNullCount
				BEGIN
					SET @OnlyEvenValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @OnlyEvenValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column OddValuesCount.
			-- =====================================================================
			IF @OddValuesCount > 0
				BEGIN
					SET @HasOddValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @HasOddValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Value for the column OnlyOddValues.
			-- =====================================================================
			IF @OddValuesCount = @NotNullCount
				BEGIN
					SET @OnlyOddValues = CAST(1 AS bit);
				END;
			ELSE
				BEGIN
					SET @OnlyOddValues = CAST(0 AS bit);
				END;

			-- =====================================================================
			-- Inserting all values as a row into the table.
			-- =====================================================================
			INSERT INTO [Stats].[IntegerColumnProfiling] VALUES (
				@TableType, 
				@TableSchema, 
				@TableName,
				@ColumnName,
				@DataType,
				@RowCount,
				@NullCount,
				@NullRelativeFrequency,
				@NullRelativeFrequencyPercent,
				@NotNullCount,
				@NotNullRelativeFrequency,
				@NotNullRelativeFrequencyPercent,
				@Minimum,
				@MinimumCount,
				@MinimumRelativeFrequency,
				@MinimumRelativeFrequencyPercent,
				@Maximum,
				@MaximumCount,
				@MaximumRelativeFrequency,
				@MaximumRelativeFrequencyPercent,
				@Range,
				@HasNegativeValues,
				@NegativeValueCount,
				@NegativeValuesRelativeFrequency,
				@NegativeValuesRelativeFrequencyPercent,
				@OnlyNegativeValues,
				@HasZero,
				@ZeroCount,
				@ZeroRelativeFrequency,
				@ZeroRelativeFrequencyPercent,
				@HasPositiveValues,
				@PositivValueCount,
				@PositiveValuesRelativeFrequency,
				@PositiveValuesRelativeFrequencyPercent,
				@OnlyPositiveValues,
				@IsMixed,
				@HasEvenValues,
				@EvenValuesCount,
				@EvenValuesRelativeFrequency,
				@EvenValuesRelativeFrequencyPercent,
				@OnlyEvenValues,
				@HasOddValues,
				@OddValuesCount,
				@OddValuesRelativeFrequency,
				@OddValuesRelativeFrequencyPercent,
				@OnlyOddValues,
				@DistinctCount,
				@UniquenessRatio,
				@UniquenessRatioPercent,
				@ColumnSum,
				@Mean,
				@ValuesSmallerColumnsMeanCount,
				@ValuesSmallerColumnsMeanRelativeFrequency,
				@ValuesSmallerColumnsMeanRelativeFrequencyPercent,
				@ValuesGreaterColumnsMeanCount,
				@ValuesGreaterColumnsMeanRelativeFrequency,
				@ValuesGreaterColumnsMeanRelativeFrequencyPercent,
				@Variance,
				@StandardDeviation,
				@Percentile25,
				@Percentile50,
				@Percentile75,
				@InterquartileRange,
				@LowerFence,
				@UpperFence,
				@OutlierCountLower,
				@OutlierCountUpper,
				@OutlierCountTotal,
				@ErrorNumber,
				@ErrorMessage
			);

			SET @ColumnCounter = @ColumnCounter + 1;
		END;
		
		SET @TableCounter = @TableCounter + 1;
	END TRY
	-- =====================================================================
	-- If an error occurs, all values are set to NULL and the error number 
	-- and message are printed. If the error is specifically 208, the table 
	-- is excluded from processing.
	-- =====================================================================
	BEGIN CATCH
		IF ERROR_NUMBER() = 208
			BEGIN 
				SET @TableCounter = @TableCounter + 1;
			END;
		ELSE
			BEGIN
				SET @ColumnName = NULL;
				SET @DataType = NULL;
				SET @RowCount = NULL;
				SET @NullCount = NULL;
				SET @NullRelativeFrequency = NULL;
				SET @NullRelativeFrequencyPercent = NULL;
				SET	@NotNullCount = NULL;
				SET @NotNullRelativeFrequency = NULL;
				SET @NotNullRelativeFrequencyPercent = NULL;
				SET	@Minimum = NULL;
				SET	@MinimumCount = NULL;
				SET @MinimumRelativeFrequency = NULL;
				SET @MinimumRelativeFrequencyPercent = NULL;
				SET	@Maximum = NULL;
				SET	@MaximumCount = NULL;
				SET @MaximumRelativeFrequency = NULL;
				SET @MaximumRelativeFrequencyPercent = NULL;
				SET	@Range = NULL;
				SET @HasNegativeValues = NULL;
				SET @NegativeValueCount = NULL;
				SET @NegativeValuesRelativeFrequency = NULL;
				SET @NegativeValuesRelativeFrequencyPercent = NULL;
				SET @OnlyNegativeValues = NULL;
				SET @HasZero = NULL;
				SET @ZeroCount = NULL;
				SET @ZeroRelativeFrequency = NULL;
				SET @ZeroRelativeFrequencyPercent = NULL;
				SET @HasPositiveValues = NULL;
				SET @PositivValueCount = NULL;
				SET @PositiveValuesRelativeFrequency = NULL;
				SET @PositiveValuesRelativeFrequencyPercent = NULL;
				SET @OnlyPositiveValues = NULL;
				SET @IsMixed = NULL;
				SET @HasEvenValues = NULL;
				SET @EvenValuesCount = NULL;
				SET @EvenValuesRelativeFrequency = NULL;
				SET @EvenValuesRelativeFrequencyPercent = NULL;
				SET @OnlyEvenValues = NULL;
				SET @HasOddValues = NULL;
				SET @OddValuesCount = NULL;
				SET @OddValuesRelativeFrequency = NULL;
				SET @OddValuesRelativeFrequencyPercent = NULL;
				SET @OnlyOddValues = NULL;
				SET @DistinctCount = NULL;
				SET @UniquenessRatio = NULL;
				SET @UniquenessRatioPercent = NULL;
				SET	@ColumnSum = NULL;
				SET	@Mean = NULL;
				SET @ValuesSmallerColumnsMeanCount = NULL;
				SET @ValuesSmallerColumnsMeanRelativeFrequency = NULL;
				SET @ValuesSmallerColumnsMeanRelativeFrequencyPercent = NULL;
				SET @ValuesGreaterColumnsMeanCount = NULL;
				SET @ValuesGreaterColumnsMeanRelativeFrequency = NULL;
				SET @ValuesGreaterColumnsMeanRelativeFrequencyPercent = NULL;
				SET	@Variance = NULL;
				SET	@StandardDeviation = NULL;
				SET	@Percentile25 = NULL;
				SET	@Percentile50 = NULL;
				SET	@Percentile75 = NULL;
				SET	@InterquartileRange = NULL;
				SET @LowerFence = NULL;
				SET	@UpperFence = NULL;
				SET	@OutlierCountLower = NULL;
				SET	@OutlierCountUpper = NULL;
				SET	@OutlierCountTotal = NULL;
				SET @ErrorNumber = ERROR_NUMBER();
				SET @ErrorMessage = ERROR_Message();

				INSERT INTO [Stats].[IntegerColumnProfiling] VALUES (
					@TableType, 
					@TableSchema, 
					@TableName,
					@ColumnName,
					@DataType,
					@RowCount,
					@NullCount,
					@NullRelativeFrequency,
					@NullRelativeFrequencyPercent,
					@NotNullCount,
					@NotNullRelativeFrequency,
					@NotNullRelativeFrequencyPercent,
					@Minimum,
					@MinimumCount,
					@MinimumRelativeFrequency,
					@MinimumRelativeFrequencyPercent,
					@Maximum,
					@MaximumCount,
					@MaximumRelativeFrequency,
					@MaximumRelativeFrequencyPercent,
					@Range,
					@HasNegativeValues,
					@NegativeValueCount,
					@NegativeValuesRelativeFrequency,
					@NegativeValuesRelativeFrequencyPercent,
					@OnlyNegativeValues,
					@HasZero,
					@ZeroCount,
					@ZeroRelativeFrequency,
					@ZeroRelativeFrequencyPercent,
					@HasPositiveValues,
					@PositivValueCount,
					@PositiveValuesRelativeFrequency,
					@PositiveValuesRelativeFrequencyPercent,
					@OnlyPositiveValues,
					@IsMixed,
					@HasEvenValues,
					@EvenValuesCount,
					@EvenValuesRelativeFrequency,
					@EvenValuesRelativeFrequencyPercent,
					@OnlyEvenValues,
					@HasOddValues,
					@OddValuesCount,
					@OddValuesRelativeFrequency,
					@OddValuesRelativeFrequencyPercent,
					@OnlyOddValues,
					@DistinctCount,
					@UniquenessRatio,
					@UniquenessRatioPercent,
					@ColumnSum,
					@Mean,
					@ValuesSmallerColumnsMeanCount,
					@ValuesSmallerColumnsMeanRelativeFrequency,
					@ValuesSmallerColumnsMeanRelativeFrequencyPercent,
					@ValuesGreaterColumnsMeanCount,
					@ValuesGreaterColumnsMeanRelativeFrequency,
					@ValuesGreaterColumnsMeanRelativeFrequencyPercent,
					@Variance,
					@StandardDeviation,
					@Percentile25,
					@Percentile50,
					@Percentile75,
					@InterquartileRange,
					@LowerFence,
					@UpperFence,
					@OutlierCountLower,
					@OutlierCountUpper,
					@OutlierCountTotal,
					@ErrorNumber,
					@ErrorMessage
				);

				SET @TableCounter = @TableCounter + 1;
			END
	END CATCH;
END;