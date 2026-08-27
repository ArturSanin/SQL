USE [DatabaseName];
GO

DROP TABLE IF EXISTS [DbInfo].[SnapshotDatabaseObjects];
GO

SELECT
	[o].[object_id] AS [ObjectId],
	[o].[type_desc] AS [ObjectType],
	SCHEMA_NAME([o].[schema_id]) AS [ObjectSchema],
	[o].[name] AS [ObjectName],
	CAST([ep].[value] AS nvarchar(4000)) AS [ObjectDescription],
	[sqlm].[definition] AS [ObjectDefinition],
	[o].[create_date] AS [ObjectCreationDate],
	[o].[modify_date] AS [ObjectLastModifyDate],
	GETDATE() AS [SnapshotDateTime]
INTO
	[DbInfo].[SnapshotDatabaseObjects]
FROM
	[sys].[objects] [o]
LEFT JOIN
	[sys].[sql_modules] [sqlm] ON [o].[object_id] = [sqlm].[object_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [o].[object_id] = [ep].[major_id] AND [ep].[class] = 1 AND [ep].[name] = N'MS_Description' AND [ep].[minor_id] = 0
WHERE
	[o].[is_ms_shipped] = 0;
GO

-- =============================================
-- MS_Description for table and its columns: DbInfo.SnapshotDatabaseObjects
-- =============================================

-- Description for table
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Stores a snapshot of user-defined database objects and their metadata.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects';
GO

-- Description for column: ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectId';
GO

-- Description for column: ObjectType
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The type of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectType';
GO

-- Description for column: ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectSchema';
GO

-- Description for column: ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectName';
GO

-- Description for column: ObjectDescription
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The description of the object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectDescription';
GO

-- Description for column: ObjectDefinition
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The definition of the object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectDefinition';
GO

-- Description for column: ObjectCreationDate
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The creation date of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectCreationDate';
GO

-- Description for column: ObjectLastModifyDate
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The date on which the object was last modified.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectLastModifyDate';
GO

-- Description for column: SnapshotDateTime
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The date and time when the snapshot was created.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'SnapshotDatabaseObjects',
	 @level2type = N'COLUMN', @level2name = N'SnapshotDateTime';
GO