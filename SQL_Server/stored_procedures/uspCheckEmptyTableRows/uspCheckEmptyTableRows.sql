USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Checks whether the specified table contains any empty rows 
--              (rows where all column values are NULL). 
--              Returns a BIT value:
--                  1 = Empty rows exist
--                  0 = No empty rows exist
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCheckEmptyTableRows] 
(
	@TableSchema sysname,  -- Name of the schema containing the table.
	@TableName  sysname  -- Name of the table to check.
)
AS
BEGIN
    SET NOCOUNT ON;

	 -- Step 1: Declare variables for dynamic SQL construction.
	DECLARE
		@StringWhereCondition nvarchar(MAX), -- WHERE clause built dynamically.
		@Query nvarchar(MAX), -- Holds the full SQL statement.
        @EmptyRowCount int;  -- Stores the count of empty rows.
	
	-- Step 2: Build the WHERE clause dynamically.
    -- Retrieves all column names of the target table
    -- and concatenates them with 'IS NULL AND' between each one.
    -- This ensures that only rows where *all* columns are NULL are counted.
	SET @StringWhereCondition = (
        SELECT 
            STRING_AGG([COLUMN_NAME], N' IS NULL AND ') 
        FROM 
            [INFORMATION_SCHEMA].[COLUMNS] 
        WHERE 
            [TABLE_SCHEMA] = @TableSchema 
        AND 
            [TABLE_NAME] = @TableName
        );

	-- Step 3: Build the dynamic SQL query.
    -- The query counts how many rows have all NULL column values.
	SET @Query = 
        N'SELECT @EmptyRowCount = COUNT(*) FROM ' + 
        QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
        N' WHERE ' + @StringWhereCondition + N' IS NULL';

	-- Step 4: Execute the dynamic query.
    -- The result is stored in the @EmptyRowCount variable.
	EXEC [sys].[sp_executesql] 
        @Query,
        N'@EmptyRowCount int OUTPUT', 
		@EmptyRowCount = @EmptyRowCount OUTPUT;

    -- Step 5: Return a BIT value indicating the presence of empty rows.
    -- 1 = Empty rows exist
    -- 0 = No empty rows
    IF @EmptyRowCount > 0
        BEGIN
            SELECT CAST(1 AS bit) AS [HasEmptyRow];
        END;
    ELSE
        BEGIN
            SELECT CAST(0 AS bit) AS [HasEmptyRow];
        END;
END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Checks whether the specified table contains any fully empty rows (rows where all columns are NULL). Returns a BIT value: 1 if empty rows exist, 0 if not.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckEmptyTableRows';
GO

-- Description for parameter: @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the schema that contains the table to check for empty rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter: @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the table to check for empty rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckEmptyTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO