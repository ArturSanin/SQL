USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns a flag (bit) indicating whether the specified table 
--              contains any duplicate rows based on all columns.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCheckDuplicates] 
(
	@TableSchema sysname,  -- Schema name of the target table.
	@TableName  sysname  -- Name of the target table.
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Variable declarations.
		DECLARE
			@TableColumns nvarchar(MAX),  -- Stores all column names of the target table.
			@QueryDuplicateCount nvarchar(MAX),  -- Holds the dynamic SQL query.
			@DuplicateCount int;  -- Receives the total number of duplicate rows.
	
		-- Build a comma-separated list of all columns in the given table.
		SET @TableColumns = (
			SELECT
				STRING_AGG([COLUMN_NAME], N', ')
			FROM
				[INFORMATION_SCHEMA].[COLUMNS]
			WHERE
				[TABLE_SCHEMA] = @TableSchema
			AND
				[TABLE_NAME] = @TableName
		);
		
		-- Construct the dynamic SQL query to count duplicates:
        -- 1. Use a CTE to group by all columns.
        -- 2. Count occurrences of identical rows.
        -- 3. Sum up all counts greater than 1 to get total duplicates.
		SET @QueryDuplicateCount = 
			N'WITH [cte] AS (SELECT ' + @TableColumns + N', COUNT(*) AS [Count] FROM ' 
			+ QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' GROUP BY ' + @TableColumns + N') ' + 
			N'SELECT @DuplicateCount = SUM([Count]) FROM [cte] WHERE [Count] > 1'
	
		-- Execute the dynamic SQL and capture the duplicate count.
		EXEC [sys].[sp_executesql]
			@QueryDuplicateCount,
			N'@DuplicateCount int OUTPUT',
			@DuplicateCount = @DuplicateCount OUTPUT;

		-- Return result as a BIT flag:
        --    1 = table contains duplicates
        --    0 = table has no duplicates
		IF COALESCE(@DuplicateCount, 0) > 0
			BEGIN
				SELECT CAST(1 AS bit) AS [HasDuplicates]
			END
		ELSE
			BEGIN
				SELECT CAST(0 AS bit) AS [HasDuplicates]
			END
	END TRY
	BEGIN CATCH
		PRINT N'The operation failed. Check if your table contains unsupported data types.';
		PRINT N'Unsupported types: text, ntext, image, xml, sql_variant, hierarchyid, geometry, geography, timestamp, varchar(max), nvarchar(max), varbinary(max)';
		PRINT N'Error Message:';
		PRINT ERROR_MESSAGE();
	END CATCH;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure itself.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Returns a flag (bit) indicating whether the specified table contains duplicate rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckDuplicates';
GO

-- Description for parameter @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Schema name of the target table to check for duplicate rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckDuplicates',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the target table to check for duplicate rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckDuplicates',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO