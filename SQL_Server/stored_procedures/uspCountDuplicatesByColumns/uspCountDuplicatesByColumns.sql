USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Calculates the total number of duplicate rows in a specified table
--              based on a subset of columns.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCountDuplicatesByColumns] 
(
	@TableSchema sysname,  -- Schema name of the target table.
	@TableName  sysname,  -- Name of the target table.
	@TableColumns nvarchar(MAX)  -- Comma-separated list of column names to check for duplicates.
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Variable declarations
		DECLARE
			@QueryDuplicateCountByColumns nvarchar(MAX),  -- Holds the dynamic SQL query.
			@DuplicateCountByColumns int;  -- Receives the total number of duplicate rows.

		SET @TableColumns = (SELECT N'[' + REPLACE(REPLACE(@TableColumns, ' ', ''), N',', N'],[') + N']');
		
		SET @QueryDuplicateCountByColumns = 
			N'WITH [cte] AS (SELECT ' + @TableColumns + N', COUNT(*) AS [Count] FROM ' 
			+ QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' GROUP BY ' + @TableColumns + N') ' + 
			N'SELECT @DuplicateCountByColumns = SUM([Count]) FROM [cte] WHERE [Count] > 1'
	
		-- Execute the dynamic SQL and capture the duplicate count.
		EXEC [sys].[sp_executesql]
			@QueryDuplicateCountByColumns,
			N'@DuplicateCountByColumns int OUTPUT',
			@DuplicateCountByColumns = @DuplicateCountByColumns OUTPUT;

		
		SELECT COALESCE(@DuplicateCountByColumns, 0) AS [DuplicateCount];
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
    @value = N'Calculates the total number of duplicate rows in a table based on specified columns.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountDuplicatesByColumns';
GO

-- Description for parameter @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Schema name of the table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountDuplicatesByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Specifies the table name within the given schema whose duplicate records are to be counted by the specified columns.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountDuplicatesByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO

-- Description for parameter @TableColumns.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Comma-separated list of column names to check for duplicates.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspCountDuplicatesByColumns',
    @level2type = N'PARAMETER', @level2name = N'@TableColumns';
GO