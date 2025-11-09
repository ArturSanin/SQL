USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the total number of empty records (rows containing only NULL values) from the specified table.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCountEmptyTableRows] 
(
	@TableSchema sysname,
	@TableName  sysname	
)
AS
BEGIN

	 -- Declare variables for dynamic SQL construction.
	DECLARE
		@StringWhereCondition nvarchar(MAX), -- Builds the WHERE condition dynamically.
		@Query nvarchar(MAX); -- Holds the final query to execute.
	
	-- Construct the WHERE condition dynamically:
    -- Retrieves all column names for the given table.
    -- Concatenates them with "IS NULL AND" between each one.
	-- This string is used to filter all rows containing only NULL values.
	SET @StringWhereCondition = (SELECT STRING_AGG([COLUMN_NAME], ' IS NULL AND ') FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = @TableSchema AND [TABLE_NAME] = @TableName);

	-- Build the final SELECT statement dynamically.
	SET @Query = 'SELECT COUNT(*) FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' WHERE ' + @StringWhereCondition + ' IS NULL';

	-- Execute the generated SQL query.
    -- The result returns the number of empty rows in the table.
	EXEC [sys].[sp_executesql] @Query;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Returns the total number of empty rows (records containing only NULL values) from the specified table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRows';
GO

-- Description for parameter: @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the schema name of the target table whose empty rows should be counted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter: @TableName
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the name of the target table whose empty rows should be counted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO