/* Use the database in which you want to test this script. */
USE [DatabaseName];
GO

/*
	This script demonstrates how to import a CSV file originating from either a Linux or Windows 
    operating system using the BULK INSERT command.
*/


/* 
	For this example, I will use a schema named Example.
	If you already have a schema in your database that you use for testing, adjust this script accordingly.
*/

CREATE SCHEMA [Example];
GO


/* 
    1. First, we’re going to create a table that matches the number of columns and data types in the CSV file.
    If you just want to import the CSV file first and model the table later (for example, in a Medallion architecture),
    you can simply define every column as [Column1] VARCHAR(8000). Once the data is in your database, you can rename 
    the columns, adjust the data types, and clean the data as needed.
*/

CREATE TABLE [Example].[TableName](
    /* Enter your columns here. */
    
    /* For quick import use this definition: */
    
    /*
        [Column1] varchar(8000),
        [Column2] varchar(8000),
        [Column3] varchar(8000),
        [Column4] varchar(8000),
        [Column5] varchar(8000)
        .
        .
        .
        .
    */
);
GO

/*
    2. Next, we’re going to import the data from the CSV file.
    Before you run one of the commands, you need to know which operating system the CSV file comes from.
    One way to check is by opening the file in Visual Studio Code.
    In the bottom-right corner, you’ll see either LF (for Linux) or CRLF (for Windows).
*/

-- Use this for a Windows CSV file.
BULK INSERT [Example].[TableName]
FROM 'FilePath'
WITH (
    FIELDTERMINATOR = ',',      -- Separator
    ROWTERMINATOR = '0x0d0a',   -- Windows-CSV
    FIRSTROW = 2,               -- Skips header
    TABLOCK,                    -- Faster loading
    CODEPAGE = '65001'          -- For UTF-8 CSV
);
GO

-- Use this for a Linux CSV file.
BULK INSERT [Example].[TableName]
FROM 'FilePath'
WITH (
    FIELDTERMINATOR = ',',      -- Separator
    ROWTERMINATOR = '0x0a',     -- Linux-CSV
    FIRSTROW = 2,               -- Skips header
    TABLOCK,                    -- Faster loading
    CODEPAGE = '65001'          -- For UTF-8 CSV
);
GO