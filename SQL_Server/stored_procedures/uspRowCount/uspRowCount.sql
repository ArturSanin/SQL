USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the total number of rows from a specified table.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspRowCount] 
(
	@TableSchema varchar(500),
	@TableName  varchar(500)	
)
AS
BEGIN

	DECLARE @QueryRowCount nvarchar(MAX);

    SET @QueryRowCount = '
		SELECT
			COUNT(*)
		FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ';';

	EXEC [sys].[sp_sqlexec] @QueryRowCount;
    
END
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Returns the total number of rows from a specified table.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspRowCount';
GO

-- Description for parameter @TableSchema.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the schema name of the target table whose rows should be counted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspRowCount',
    @level2type = N'PARAMETER', @level2name = N'@TableSchema';
GO

-- Description for parameter @TableName.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Specifies the name of the target table whose rows should be counted.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspRowCount',
    @level2type = N'PARAMETER', @level2name = N'@TableName';
GO