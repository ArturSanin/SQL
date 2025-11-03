SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Name of the database in which you want to create the procedure. */
USE [DatabaseName];
GO

/* 
    =============================================
    Author: <Author,,Name>
    
    Create date: <Create Date,,>
    
    Description: This procedure imports a CSV file 
    with either CRLF (Windows) or LF (Linux) line breaks 
    and saves the data into a table where all columns 
    are defined as varchar(8000).
    =============================================
*/

CREATE PROCEDURE [SchemaName].[uspImportCsvToTextTable] 
	@FilePath varchar(MAX),  -- The full file path to the CSV file to be imported.
	@TableSchemaName varchar(500),  -- The name of the schema where the data will be imported.
	@TableName varchar(500),  -- The name of the table into which the data will be imported.
	@NumberOfColumns int  -- The number of columns in the target table (must match the number of columns in the CSV file).
AS
BEGIN
	SET NOCOUNT ON;

	/* Drop the table if it already exists. */
    DECLARE @SqlDropTable varchar(MAX) = 'DROP TABLE IF EXISTS ' + QUOTENAME(@TableSchemaName) + '.' + QUOTENAME(@TableName) + ';';
	EXEC [sys].[sp_sqlexec] @SqlDropTable;


	/* 
        Create the table structure (skeleton) for the data.
        All columns receive default column names and use the 
        varchar(8000) data type.
    */
	DECLARE @Counter int = 1;
    DECLARE @Columns varchar(MAX) = '';
	
    BEGIN
		WHILE @Counter <= @NumberOfColumns
			IF @Counter = 1
				BEGIN
					SET @Columns = QUOTENAME('Column' + CAST(@Counter AS varchar(MAX))) + ' varchar(8000)'
					SET @Counter = @Counter + 1
				END
			ELSE
			BEGIN
				SET @Columns = @Columns + ', ' + QUOTENAME('Column' + CAST(@Counter AS varchar(MAX))) + ' varchar(8000)'
				SET @Counter = @Counter + 1
			END
	END;

	DECLARE @SqlCreateTable varchar(MAX) = 'CREATE TABLE ' + QUOTENAME(@TableSchemaName) + '.' + QUOTENAME(@TableName) + ' (' + @Columns + ' )';
	EXEC [sys].[sp_sqlexec] @SqlCreateTable;

	/* 
        Perform the bulk insert to import the CSV file into the newly created table.
        First, the script attempts a bulk insert using the CRLF (Windows) line break.
        If this fails with an error, it automatically retries using the LF (Linux) line break.
        If both attempts fail, the corresponding error message will be displayed.

        If the CRLF bulk insert succeeds but inserts zero rows (which sometimes happens with Linux CSV files),
        the script will perform a second bulk insert using the LF line break.
        If this also fails, the error message will be displayed again. 
    */
    
	BEGIN TRY
        DECLARE @SqlBulkInsertCRLF varchar(MAX) = '
        BULK INSERT ' + @TableSchemaName + '.' + @TableName + '
        FROM ''' + @FilePath + '''
        WITH (
            FIELDTERMINATOR = ' + ''',''' + ',      
            ROWTERMINATOR = ' + '''0x0d0a''' + ',   
            FIRSTROW = 2,               
            TABLOCK,                    
            CODEPAGE = ' + '''65001''' + ' );';

        EXEC [sys].[sp_sqlexec] @SqlBulkInsertCRLF;
        
        PRINT 'Bulk insert using CRLF line break was successfull.';
    END TRY
        
    BEGIN CATCH
        BEGIN TRY
            DECLARE @SqlBulkInsertLF varchar(MAX) = '
            BULK INSERT ' + @TableSchemaName + '.' + @TableName + '
            FROM ''' + @FilePath + '''
            WITH (
                FIELDTERMINATOR = ' + ''',''' + ',
                ROWTERMINATOR = ' + '''0x0a''' + ',
                FIRSTROW = 2,
                TABLOCK,
                CODEPAGE = ' + '''65001''' + ');'

            EXEC [sys].[sp_sqlexec] @SqlBulkInsertLF;

            PRINT 'Bulk insert using LF line break was successfull.'
        END TRY 

        BEGIN CATCH
            PRINT 'Bulk insert using both CRLF and LF line breaks was unsuccessful. Error message:';
            PRINT ERROR_MESSAGE();
        END CATCH
    END CATCH

    DECLARE @RowsImported int;
    DECLARE @QueryRowsImported nvarchar(MAX);

    SET @QueryRowsImported = '
		SELECT
			@RowsImported = COUNT(*)
		FROM ' + QUOTENAME(@TableSchemaName) + '.' + QUOTENAME(@TableName) + ';';

    EXEC [sys].[sp_executesql]
	    @QueryRowsImported,
	    N'@RowsImported INT OUTPUT',
	    @RowsImported = @RowsImported OUTPUT;

    IF @RowsImported = 0
        BEGIN
            BEGIN TRY
                PRINT 'Bulk insert using the CRLF line break succeeded, but imported 0 rows.';
                
                DECLARE @SqlAgainBulkInsertLF varchar(MAX) = '
                BULK INSERT ' + @TableSchemaName + '.' + @TableName + '
                FROM ''' + @FilePath + '''
                WITH (
                    FIELDTERMINATOR = ' + ''',''' + ',
                    ROWTERMINATOR = ' + '''0x0a''' + ',
                    FIRSTROW = 2,
                    TABLOCK,
                    CODEPAGE = ' + '''65001''' + ');';

                EXEC [sys].[sp_sqlexec] @SqlAgainBulkInsertLF;

                PRINT 'Tried bulk insert using LF line break.';
                PRINT 'Bulk insert using LF line break was successfull.';
            END TRY 
            
            BEGIN CATCH
                PRINT 'Bulk insert using both CRLF and LF line breaks was unsuccessful. Error message:';
                PRINT ERROR_MESSAGE();
            END CATCH
        END
END
GO