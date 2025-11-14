USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all duplicate rows of a table by grouping
--				all columns and selecting rows with Count > 1.
--				All columns of the table are used to detect duplicates.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspGetDuplicates] 
(
	@TableSchema sysname,  -- Schema name of the target table.
	@TableName  sysname  -- Name of the target table.
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Variable declarations
		DECLARE
			@TableColumns nvarchar(MAX),  
			@QuerySelectDuplicates nvarchar(MAX),
			@TableColumnsWithAlias nvarchar(MAX),
			@OnCondition nvarchar(MAX);  
	
		-- Build column list for SELECT and GROUP BY
		SET @TableColumns = (
			SELECT
				STRING_AGG(N'[' + [COLUMN_NAME] + N']', N', ')
			FROM
				[INFORMATION_SCHEMA].[COLUMNS]
			WHERE
				[TABLE_SCHEMA] = @TableSchema
			AND
				[TABLE_NAME] = @TableName
		);
		
		-- Same list, but with [t]. prefix for selecting original rows
		SET @TableColumnsWithAlias = N'[t].' + REPLACE(@TableColumns, N', ', N', [t].');

		-- Build ON condition. ! and : will be replaced with the table alias and the alias of the cte defined later.
		SET @OnCondition = (
			SELECT
				STRING_AGG(N'![' + [COLUMN_NAME] + N']' + N':[' + [COLUMN_NAME] + ']', N' AND ')
			FROM
				[INFORMATION_SCHEMA].[COLUMNS]
			WHERE
				[TABLE_SCHEMA] = @TableSchema
			AND
				[TABLE_NAME] = @TableName
		);

		SET @OnCondition = REPLACE(REPLACE(@OnCondition, ':', ' = [c].'), '!', '[t].');

		-- Build the dynamic SQL query
        -- 1. CTE groups by all columns and counts duplicates.
        -- 2. Join original table with CTE on all columns.
        -- 3. Only rows with Count > 1 are returned.
		SET @QuerySelectDuplicates = 
			N'WITH [cte] AS (SELECT ' + @TableColumns + N', COUNT(*) AS [Count] FROM ' 
			+ QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' GROUP BY ' + @TableColumns + N') ' + 
			N'SELECT ' + @TableColumnsWithAlias + N' FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' [t] LEFT JOIN [cte] [c] ON ' + @OnCondition + N' WHERE [c].[Count] > 1';
	
		-- Execute dynamic SQL
		EXEC [sys].[sp_executesql] @QuerySelectDuplicates;

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
    @value = N'Returns all duplicate rows from a table by grouping all columns and selecting all rows that occur more than once.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspGetDuplicates';
GO

-- Description for parameter @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Schema name of the table from which duplicate rows are returned.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspGetDuplicates',
    @level2type = N'PARAMETER',@level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the table from which duplicate rows are returned.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspGetDuplicates',
    @level2type = N'PARAMETER',@level2name = N'@TableName';
GO