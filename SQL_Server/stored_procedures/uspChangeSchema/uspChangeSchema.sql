USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Transfers the specified object to the target schema.
-- =============================================
CREATE PROCEDURE [SchemaName].[uspChangeSchema] 
(
	@OldSchema sysname,  -- The name of the schema in which the object currently resides.
	@NewSchema  sysname, -- The name of the target schema to which the object will be transferred.
    @ObjectName sysname  -- The name of the object whose schema will be changed. This must be only the object’s name, without its schema prefix.
)
AS
BEGIN
	SET NOCOUNT ON;

    -- Checking whether the schema specified in @OldSchema exists.
    IF NOT EXISTS (
        SELECT 
            1
        FROM
            [sys].[schemas]
        WHERE
            [name] = @OldSchema
    )
        THROW 51000, N'The schema specified in the @OldSchema parameter does not exist.', 1;

    -- Checking whether the schema specified in @NewSchema exists.
    ELSE IF NOT EXISTS (
        SELECT 
            1
        FROM
            [sys].[schemas]
        WHERE
            [name] = @NewSchema
    )
        THROW 51000, N'The schema specified in the @NewSchema parameter does not exist.', 1;
	
    -- Checking whether the specified object exists.
    ELSE IF OBJECT_ID(QUOTENAME(@OldSchema) + N'.' + QUOTENAME(@ObjectName)) IS NULL
    BEGIN
        DECLARE @ErrorMessage nvarchar(4000) = N'The object ' + @OldSchema + N'.' + @ObjectName + N' does not exist in the ' + DB_NAME() + N' database.'; 
        THROW 51000, @ErrorMessage, 1;
    END;

    -- Checking whether the specified object is schema-bound.
    ELSE IF OBJECTPROPERTY(OBJECT_ID(QUOTENAME(@OldSchema) + N'.' + QUOTENAME(@ObjectName)), N'IsSchemaBound') = 1        
        THROW 51000, N'The object provided is schema-bound and cannot be transferred.', 1;

    ELSE 
    BEGIN TRY
        DECLARE @TransferQuery nvarchar(max) = N'';
            
        SET @TransferQuery = N'ALTER SCHEMA ' + QUOTENAME(@NewSchema) 
            + N' TRANSFER ' + QUOTENAME(@OldSchema) + N'.' + QUOTENAME(@ObjectName) + N';';

        EXEC [sys].[sp_executesql] @TransferQuery;
    END TRY
    BEGIN CATCH
        PRINT N'The procedure execution failed. Please see the following error message for details:' + char(13) + char(10);
        THROW;
    END CATCH;
END;
GO

-- =============================================
-- MS_Description for the stored procedure.
-- =============================================

-- Description for the stored procedure itself.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Transfers the specified object to the target schema.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspChangeSchema';
GO

-- Parameter: @OldSchema
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the existing schema that currently contains the object.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspChangeSchema',
    @level2type = N'PARAMETER', @level2name = N'@OldSchema';
GO

-- Parameter: @NewSchema
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the target schema to which the object will be moved.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspChangeSchema',
    @level2type = N'PARAMETER', @level2name = N'@NewSchema';
GO

-- Parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Name of the object whose schema will be changed.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'PROCEDURE', @level1name = N'uspChangeSchema',
    @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO