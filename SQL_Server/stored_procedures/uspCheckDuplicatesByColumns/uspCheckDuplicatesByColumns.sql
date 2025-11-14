USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description: Checks whether a table contains duplicate rows based on a specified set
--				of columns.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspCheckDuplicatesByColumns] 
(
	@TableSchema sysname,  -- Schema name of the target table.
	@TableName  sysname,  -- Name of the target table.
	@TableColumns nvarchar(MAX)  -- Comma-separated list of column names to check for duplicates. 'Column1, Column2,...'
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Variable declarations
		DECLARE
			@QueryDuplicateCountByColumns nvarchar(MAX),  -- Holds the dynamic SQL query.
			@DuplicateCountByColumns int;  -- Receives the total number of duplicate rows.
		
		-- Clean column list, remove spaces, bracket each column.
		SET @TableColumns = (SELECT N'[' + REPLACE(REPLACE(@TableColumns, ' ', ''), N',', N'],[') + N']');
		
		-- Build dynamic SQL using a CTE to group by chosen columns.
		SET @QueryDuplicateCountByColumns = 
			N'WITH [cte] AS (SELECT ' + @TableColumns + N', COUNT(*) AS [Count] FROM ' 
			+ QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' GROUP BY ' + @TableColumns + N') ' + 
			N'SELECT @DuplicateCountByColumns = SUM([Count]) FROM [cte] WHERE [Count] > 1'
	
		-- Execute and retrieve duplicate count.
		EXEC [sys].[sp_executesql]
			@QueryDuplicateCountByColumns,
			N'@DuplicateCountByColumns int OUTPUT',
			@DuplicateCountByColumns = @DuplicateCountByColumns OUTPUT;
		
		-- Return boolean result.
		IF COALESCE(@DuplicateCountByColumns, 0) > 0
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
    @value = N'Checks whether a table contains duplicate rows based on a specified list of columns.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspCheckDuplicatesByColumns';
GO

-- Description for parameter @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Schema name of the table to check for duplicates.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspCheckDuplicatesByColumns',
    @level2type = N'PARAMETER',@level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the table to check for duplicates.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspCheckDuplicatesByColumns',
    @level2type = N'PARAMETER',@level2name = N'@TableName';
GO

-- Description for parameter @TableColumns.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Comma-separated list of column names used to detect duplicates.',
    @level0type = N'SCHEMA',   @level0name = N'SchemaName',
    @level1type = N'PROCEDURE',@level1name = N'uspCheckDuplicatesByColumns',
    @level2type = N'PARAMETER',@level2name = N'@TableColumns';
GO