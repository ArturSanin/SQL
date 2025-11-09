USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Deletes all empty rows (rows where all columns are NULL) 
--              from the specified table within a given schema.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspDeleteEmptyTableRows] 
(
	@TableSchema sysname,
	@TableName  sysname	
)
AS
BEGIN
	
	-- Declare variables for dynamic SQL construction.
	DECLARE
		@StringWhereCondition nvarchar(MAX), -- Builds the WHERE condition dynamically.
		@DeleteStatement nvarchar(MAX); -- Holds the final DELETE statement to execute.
	
	-- Build the WHERE condition dynamically.
    -- Retrieves all column names for the specified table and concatenates
    -- them with "IS NULL AND" to identify rows where all columns are NULL.
	SET @StringWhereCondition = (SELECT STRING_AGG([COLUMN_NAME], N' IS NULL AND ') FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = @TableSchema AND [TABLE_NAME] = @TableName);

	-- Construct the DELETE statement.
    -- This deletes all rows where every column is NULL.
	SET @DeleteStatement = N'DELETE FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + N' WHERE ' + @StringWhereCondition + N' IS NULL';

	-- Execute the generated SQL query.
    -- The result returns all rows that have at least one NULL value.
	EXEC [sys].[sp_executesql] @DeleteStatement;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Deletes all rows in a specified table where all columns contain NULL values. Useful for cleaning up completely empty records in datasets imported from external sources.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspDeleteEmptyTableRows';
GO

-- Description for parameter: @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the schema that contains the target table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspDeleteEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter: @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the table from which completely empty rows (rows with all NULL values) will be deleted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspDeleteEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO