USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Counts the total number of rows in a specified table where all provided columns contain NULL values.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCountEmptyTableRowsByColumns] 
(
	@TableSchema sysname,
	@TableName  sysname,
	@TableColumns nvarchar(MAX) -- Comma-separated list of column names to check for NULL values (e.g., 'Col1,Col2,Col3').
)
AS
BEGIN

	BEGIN TRY
		 -- Declare variables for dynamic SQL construction.
		DECLARE
			@StringWhereCondition nvarchar(MAX), -- WHERE condition.
			@Query nvarchar(MAX); -- Final SQL query string to execute.
	
		-- Construct the WHERE condition dynamically:
        -- Replaces commas in the column list with " IS NULL AND ", producing an AND-based NULL check.
		SET @StringWhereCondition = REPLACE(@TableColumns, ',', ' IS NULL AND ');

		-- Build the final SELECT statement dynamically.
		SET @Query = 'SELECT COUNT(*) FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' WHERE ' + @StringWhereCondition + ' IS NULL';

		-- Execute the generated SQL query.
		-- The result returns all rows that have only NULL values in the specified columns.
		EXEC [sys].[sp_executesql] @Query;
	END TRY

	BEGIN CATCH
		PRINT 'Make sure the variable @TableColumns is in the format Column1,Column2,Column3... .';
		PRINT 'Error message:';
		PRINT ERROR_MESSAGE();
	END CATCH;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Counts the total number of rows in a specified table where all provided columns contain NULL values. This procedure is useful for detecting "empty" records based on selected columns within a table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRowsByColumns';
GO

-- Description for parameter: @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Name of the schema containing the target table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRowsByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter: @TableName.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Name of the table from which to count rows that meet the condition.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRowsByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO

-- Description for parameter: @TableColumns.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Comma-separated list of column names (e.g., ''Column1,Column2,Column3''). All listed columns must contain NULL values for a row to be included in the count.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRowsByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableColumns';
GO