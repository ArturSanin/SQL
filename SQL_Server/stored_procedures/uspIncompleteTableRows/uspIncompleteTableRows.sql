USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all incomplete rows (records with at least one NULL value) from the specified table within a given schema.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspIncompleteTableRows] 
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
    -- Concatenates them with "IS NULL OR" between each one.
	-- This string is used to filter all rows containing at least one NULL.
	SET @StringWhereCondition = (SELECT STRING_AGG([COLUMN_NAME], ' IS NULL OR ') FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE [TABLE_SCHEMA] = @TableSchema AND [TABLE_NAME] = @TableName);

	-- Build the final SELECT statement dynamically.
	SET @Query = 'SELECT * FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' WHERE ' + @StringWhereCondition + ' IS NULL';

	-- Execute the generated SQL query.
    -- The result returns all rows that have at least one NULL value.
	EXEC [sys].[sp_executesql] @Query;

END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Returns all incomplete rows (records with at least one NULL value) from the specified table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspIncompleteTableRows';
GO

-- Description for parameter @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the schema name containing the table to check for incomplete rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspIncompleteTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the name of the table to check for incomplete rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspIncompleteTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO