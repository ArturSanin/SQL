USE [DatabaseName];
GO

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



-- Initial data load into DbInfo.ObjectDefinitionHistory.
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