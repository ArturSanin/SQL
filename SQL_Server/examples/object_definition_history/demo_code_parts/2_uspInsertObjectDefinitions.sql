USE [DatabaseName];
GO

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