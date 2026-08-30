USE [DatabaseName];
GO

/*
	==================== Description ====================
	This script demonstrates step by step how to implement 
	an object definition history table that tracks changes 
	to object definitions stored in sys.sql_modules. 
	
	The history table is not a backup table and does not 
	automatically track object definitions or their changes. 
	Instead, the procedure compares the current object 
	definitions in sys.sql_modules with the latest definitions 
	stored in the history table. If an object is not yet present 
	in the history or its current definition differs from the 
	latest stored definition, the current definition is added 
	to the history.
	
	Executing the procedure after an object such as a view, 
	stored procedure, or function is created or its definition 
	is changed provides a more complete and accurate history 
	of object definitions.
*/


-- ============================================================
-- 1. Create the table that will contain the object definition
--    history.
-- ============================================================
DROP TABLE IF EXISTS [DbInfo].[ObjectDefinitionHistory];
GO

CREATE TABLE [DbInfo].[ObjectDefinitionHistory](
	[ObjectId] int NOT NULL,
	[ObjectDefinition] nvarchar(max) NULL,
	[InsertedOn] datetime2 NOT NULL
);
GO

-- =============================================
-- MS_Description for table and its columns: 
-- DbInfo.ObjectDefinitionHistory
-- =============================================

-- Description for table
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Stores object definitions over time, including initial and subsequent definitions.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'ObjectDefinitionHistory';
GO

-- Description for column: ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object whose definition is stored.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'ObjectDefinitionHistory',
	 @level2type = N'COLUMN', @level2name = N'ObjectId';
GO 

-- Description for column: ObjectDefinition
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object definition stored at the time it was captured.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'ObjectDefinitionHistory',
	 @level2type = N'COLUMN', @level2name = N'ObjectDefinition';
GO

-- Description for column: InsertedOn
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The date and time when the object definition was stored in the history table.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'ObjectDefinitionHistory',
	 @level2type = N'COLUMN', @level2name = N'InsertedOn';
GO



-- ==============================================
-- 2. Initial data load into the 
--    object definition history table.
-- ==============================================
TRUNCATE TABLE [DbInfo].[ObjectDefinitionHistory];
GO

INSERT INTO [DbInfo].[ObjectDefinitionHistory]
SELECT
	[o].[object_id] AS [ObjectId],
	[sqlm].[definition] AS [ObjectDefinition],
	SYSDATETIME() AS [InsertedOn]
FROM
	[sys].[sql_modules] [sqlm]
INNER JOIN
	[sys].[objects] [o] ON [sqlm].[object_id] = [o].[object_id]
WHERE
	[o].[is_ms_shipped] = 0;
GO



-- ============================================================
-- 3. Create the stored procedure that compares the current
--    object definitions from sys.sql_modules with the latest
--    definitions stored in DbInfo.ObjectDefinitionHistory.
--    Changed definitions and definitions of objects not yet
--    stored in the history table will be added to the history.
-- ============================================================
DROP PROCEDURE IF EXISTS [DbInfo].[uspInsertObjectDefinitions];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Compares the current object definitions
--				found in sys.sql_modules with the latest
--				definitions stored in the table
--				DbInfo.ObjectDefinitionHistory. If a
--				definition has changed or is not yet stored
--				in the history table, the current definition
--				is inserted.
-- =============================================
CREATE OR ALTER PROCEDURE [DbInfo].[uspInsertObjectDefinitions]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InsertCount int;

	-- Temporary table for storing the latest definition from the history.
	CREATE TABLE [#LastObjectDefinitionInHistory](
		[ObjectId] int,
		[ObjectDefinition] nvarchar(max)
	);

	-- Insert the latest definition for each object from the history.
	-- The CTE assigns row numbers to identify the latest definition.
	WITH [cteObjectDefinitionRowNumbering] AS (
		SELECT
			[ObjectId],
			[ObjectDefinition],
			ROW_NUMBER() OVER(PARTITION BY [ObjectId] ORDER BY [InsertedOn] DESC) AS [RowNumber]
		FROM
			[DbInfo].[ObjectDefinitionHistory]
	)

	INSERT INTO [#LastObjectDefinitionInHistory]
	SELECT
		[ObjectId],
		[ObjectDefinition]
	FROM
		[cteObjectDefinitionRowNumbering]
	WHERE
		[RowNumber] = 1;

	SELECT
		@InsertCount = COUNT(*)
	FROM 
		[sys].[sql_modules] [sqlm]
	LEFT JOIN
		[#LastObjectDefinitionInHistory] [#LDIH] ON [sqlm].[object_id] = [#LDIH].[ObjectId] AND [sqlm].[definition] = [#LDIH].[ObjectDefinition]
	WHERE
		[#LDIH].[ObjectDefinition] IS NULL;
	
	IF @InsertCount > 0 BEGIN
		-- Insert the current definition of each changed or newly created object into the history.
		INSERT INTO [DbInfo].[ObjectDefinitionHistory]
		SELECT
			[sqlm].[object_id] AS [ObjectId],
			[sqlm].[definition] AS [ObjectDefinition],
			SYSDATETIME() AS [InsertedOn]
		FROM 
			[sys].[sql_modules] [sqlm]
		LEFT JOIN
			[#LastObjectDefinitionInHistory] [#LDIH] ON [sqlm].[object_id] = [#LDIH].[ObjectId] AND [sqlm].[definition] = [#LDIH].[ObjectDefinition]
		WHERE
			[#LDIH].[ObjectDefinition] IS NULL;

		-- Drop the temporary table.
		DROP TABLE [#LastObjectDefinitionInHistory];

		PRINT N'Definitions inserted: ' + CAST(@InsertCount AS nvarchar(128));
	END
	ELSE BEGIN
		-- Drop the temporary table.
		DROP TABLE [#LastObjectDefinitionInHistory];

		PRINT N'No new or changed object definitions found.';
	END
END;
GO

-- =============================================
-- MS_Description for procedure: DbInfo.uspInsertObjectDefinitions
-- =============================================
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Compares current object definitions with the latest definitions stored in DbInfo.ObjectDefinitionHistory and inserts definitions that are new or have changed into the history table.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'PROCEDURE', @level1name = N'uspInsertObjectDefinitions';
GO



-- ==============================
-- 4. Execute the procedure regularly
--    to detect new or changed 
--	  object definitions.
-- ==============================
EXEC [DbInfo].[uspInsertObjectDefinitions];
GO

-- View the object definition history.
SELECT 
	[ObjectId],
	[ObjectDefinition],
	[InsertedOn]
FROM 
	[DbInfo].[ObjectDefinitionHistory]
ORDER BY
	[ObjectId] ASC,
	[InsertedOn] DESC;
GO