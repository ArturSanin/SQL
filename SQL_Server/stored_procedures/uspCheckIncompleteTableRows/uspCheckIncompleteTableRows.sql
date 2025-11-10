USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Checks whether the specified table contains any incomplete rows 
--              (rows with at least one NULL value in any column).
--              Returns a BIT value:
--                  1 = Incomplete rows exist
--                  0 = No incomplete rows
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCheckIncompleteTableRows] 
(
	@TableSchema sysname,  -- Name of the schema containing the table to check.
	@TableName  sysname  -- Name of the table to check.
)
AS
BEGIN
    SET NOCOUNT ON;
	 
    -- Step 1: Declare variables for dynamic SQL construction.
	DECLARE
		@StringWhereCondition nvarchar(MAX),  -- Builds the WHERE clause dynamically.
		@Query nvarchar(MAX),  -- Holds the final SQL statement.
        @IncompleteRowCount int;  -- Stores the number of incomplete rows found.
	
	-- Step 2: Dynamically build the WHERE condition.
    -- Retrieves all column names for the given table and
    -- concatenates them with 'IS NULL OR' between each one.
    -- This allows detection of any rows with at least one NULL value.
	SET @StringWhereCondition = (
        SELECT 
            STRING_AGG([COLUMN_NAME], N' IS NULL OR ') 
        FROM 
            [INFORMATION_SCHEMA].[COLUMNS] 
        WHERE 
            [TABLE_SCHEMA] = @TableSchema 
        AND 
            [TABLE_NAME] = @TableName
        );

    -- Step 3: Construct the dynamic SQL query.
    -- Counts how many rows contain at least one NULL value.
	SET @Query = 
        N'SELECT @IncompleteRowCount = COUNT(*) FROM ' + 
        QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
        N' WHERE ' + @StringWhereCondition + N' IS NULL';

	-- Step 4: Execute the query and capture the count of incomplete rows.
	EXEC [sys].[sp_executesql] 
        @Query,
        N'@IncompleteRowCount int OUTPUT', 
		@IncompleteRowCount = @IncompleteRowCount OUTPUT;

    -- Step 5: Return a BIT value to indicate whether incomplete rows exist.
    -- 1 = Incomplete rows exist
    -- 0 = No incomplete rows
    IF @IncompleteRowCount > 0
        BEGIN
            SELECT CAST(1 AS bit) AS [HasIncompleteRow];
        END;
    ELSE
        BEGIN
            SELECT CAST(0 AS bit) AS [HasIncompleteRow];
        END;
END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Checks whether the specified table contains any incomplete rows (rows with at least one NULL value in any column). Returns 1 if incomplete rows exist, otherwise 0.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckIncompleteTableRows';
GO

-- Description for parameter @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the schema that contains the table to check for incomplete rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckIncompleteTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the table to check for incomplete rows.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCheckIncompleteTableRows',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO