/* Use the database in which you want to test this script. */
USE [DatabaseName];
GO

/*
	This script demonstrates a way to track changes in a field within a table.
	In the following example, we will historize a status field in a table named DummyTable.
	Execute all steps one after another.
*/


/* 
	For this example, I will use a schema named Example.
	If you already have a schema in your database that you use for testing, adjust this script accordingly.
*/

CREATE SCHEMA [Example];
GO

/* 
	1. Creating a dummy table with some data and a status field, that we want to track. 
*/

CREATE TABLE [Example].[DummyTable] (
	[ID] int,
	[ColumnOne] varchar(50),
	[ColumnTwo] varchar(50),
	[ColumnThree] varchar(50),
	[Status] varchar(50)
);

/* 
	2. Inserting some dummy values into the table. 
*/

INSERT INTO [Example].[DummyTable]
VALUES
	(1, 'Value', 'Value', 'Value', 'Active'),
	(2, 'Value', 'Value', 'Value', 'Active'),
	(3, 'Value', 'Value', 'Value', 'Inactive'),
	(4, 'Value', 'Value', 'Value', 'Active'),
	(5, 'Value', 'Value', 'Value', 'Deleted'),
	(6, 'Value', 'Value', 'Value', 'Active'),
	(7, 'Value', 'Value', 'Value', 'Inactive'),
	(8, 'Value', 'Value', 'Value', 'Deleted'),
	(9, 'Value', 'Value', 'Value', 'Active'),
	(10, 'Value', 'Value', 'Value', 'Active');

/* 
	3. Creating a table that will store the changed status values from the dummy table. 
*/

CREATE TABLE [Example].[StatusHistory] (
	[ID] int,
	[LastStatus] varchar(50),
	[LastStatusDate] datetime,
	[Status] varchar(50),
	[StatusDate] datetime
);

/* 
	4. Initially insert all status values from the dummy table.
*/

INSERT INTO [Example].[StatusHistory]
SELECT
	[DT].[ID] AS [ID],
	NULL AS [LastStatus],
	CAST(NULL AS datetime) AS [LastStatusDate],
	[DT].[Status] AS [Status],
	GETDATE() AS [StatusDate]
FROM
	[Example].[DummyTable] [DT];

/* 
	5. Next, change some status values in the dummy table. Afterwards, 
	we will insert the changed values into the StatusHistory table.
*/

UPDATE [Example].[DummyTable]
SET
	[Status] = 'Inactive'
FROM	
	[Example].[DummyTable]
WHERE 
	[ID] IN (1, 2, 6);

/* 
	6. This code checks whether the dummy table contains any new IDs. 
	If those IDs are not yet in the StatusHistory table, they will be 
	initially added to it, and their changes will start being tracked.
*/
INSERT INTO [Example].[StatusHistory]
SELECT
	[DT].[ID] AS [ID],
	NULL AS [LastStatus],
	CAST(NULL AS datetime) AS [LastStatusDate],
	[DT].[Status] AS [Status],
	GETDATE() AS [StatusDate]
FROM
	[Example].[DummyTable] [DT]
WHERE
	[DT].[ID] NOT IN (SELECT DISTINCT [SH].[ID] FROM [Example].[StatusHistory] [SH]);

/*
Insert these values into the dummy table and run the previous code again to verify that the new 
IDs and status values have been included in the StatusHistory table.

INSERT INTO [Example].[DummyTable]
VALUES
	(11, 'Value', 'Value', 'Value', 'Active'),
	(12, 'Value', 'Value', 'Value', 'Active')
*/

/* 
	7. Now we want to include the changed status values in the StatusHistory table. 
	
	Note: The following part of the script should be stored as a stored procedure, so 
	it can be executed at time intervals that fit your tracking schedule.
*/

-- We create a CTE that assigns a row number to each record in the StatusHistory table. 
-- This will help us identify, for every ID, the rows that were inserted most recently.

WITH [cteStatusHistoryWithRowNumbering] AS (
	SELECT
		[SH].[ID],
		[SH].[LastStatus],
		[SH].[LastStatusDate],
		[SH].[Status],
		[SH].[StatusDate],
		ROW_NUMBER() OVER(PARTITION BY [SH].[ID] ORDER BY [SH].[StatusDate] DESC) AS [RowNumber]
	FROM
		[Example].[StatusHistory] [SH]
),

-- Now we select only the rows with a row number equal to 1, since these represent the 
-- most recently inserted entries for each ID.

[cteStatusHistoryMostRecentStatus] AS (
	SELECT
		[ID],
		[LastStatus],
		[LastStatusDate],
		[Status],
		[StatusDate]
	FROM
		[cteStatusHistoryWithRowNumbering]
	WHERE
		[RowNumber] = 1
)

-- Now we insert the changed status values into the StatusHistory table.

INSERT INTO [Example].[StatusHistory]
SELECT
	[cteSHMRS].[ID],
	[cteSHMRS].[Status] AS [LastStatus],
	[cteSHMRS].[StatusDate] AS [LastStatusDate],
	[DT].[Status] AS [Status],
	GETDATE() AS [StatusDate]
FROM
	[Example].[DummyTable] [DT]
INNER JOIN
	[cteStatusHistoryMostRecentStatus] [cteSHMRS] ON [DT].[ID] = [cteSHMRS].[ID]
WHERE
	[DT].[Status] <> [cteSHMRS].[Status];