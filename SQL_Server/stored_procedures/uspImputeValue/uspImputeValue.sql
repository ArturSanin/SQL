USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Replaces all NULL values in a specific column of a given table 
--              with a user-defined value. 
--              The imputed value must match the column’s data type 
--              to avoid errors or unexpected conversions.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspImputeValue] 
(
	@TableSchema sysname, -- Name of the schema containing the target table.
	@TableName  sysname, -- Name of the table where NULLs will be replaced.
	@ColumnName sysname, -- Name of the column to update.
	@Value nvarchar(MAX) -- The value to replace NULLs with. Must be type-compatible.
)
AS
BEGIN
	BEGIN TRY
		 -- Declare variables for dynamic SQL construction.
		DECLARE
			@UpdateStatement nvarchar(MAX);  -- Holds the final UPDATE statement.
	
		-- Build the dynamic UPDATE statement.
        -- This replaces all NULL values in the given column with the provided value.
		SET @UpdateStatement = 
			N'UPDATE ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName) + 
			N' SET ' + QUOTENAME(@ColumnName) + N' = ' + @Value + 
			N' WHERE ' + QUOTENAME(@ColumnName) + N' IS NULL';
		
		-- Execute the dynamic UPDATE statement.
		EXEC [sys].[sp_executesql] @UpdateStatement;
	END TRY

	BEGIN CATCH
		-- Error handling.
        -- Provides guidance if datatype mismatch or syntax errors occur.
		PRINT N'Something went wrong while imputing NULL values.';
        PRINT N'Make sure:';
        PRINT N'  • You specified only one column in @ColumnName.';
        PRINT N'  • The @Value parameter matches the column’s data type.';
        PRINT N'Error message:';
        PRINT ERROR_MESSAGE();
	END CATCH;
END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Replaces all NULL values in a specified column with a given value. The imputed value must be compatible with the column’s data type to avoid conversion errors or unexpected results.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspImputeValue';
GO

-- Description for parameter: @TableSchema.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the schema that contains the table where NULLs will be replaced.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspImputeValue',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter: @TableName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the target table containing the column to be updated.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspImputeValue',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO

-- Description for parameter: @ColumnName.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the column in which all NULL values will be replaced.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspImputeValue',
    @level2type = N'PARAMETER', @level2name = N'@ColumnName';
GO

-- Description for parameter: @Value.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'The value to impute for all NULL entries in the specified column. Must match the column’s data type.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspImputeValue',
    @level2type = N'PARAMETER', @level2name = N'@Value';
GO