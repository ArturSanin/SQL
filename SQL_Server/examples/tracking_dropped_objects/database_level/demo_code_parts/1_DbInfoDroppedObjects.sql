USE [DatabaseName];
GO

DROP TABLE IF EXISTS [DbInfo].[DroppedObjects];
GO

CREATE TABLE [DbInfo].[DroppedObjects](
	[ObjectId] int NOT NULL,
	[ObjectType] nvarchar(60) NOT NULL,
	[ObjectSchema] sysname NOT NULL,
	[ObjectName] sysname NOT NULL,
	[ObjectDescription] nvarchar(4000) NULL,
	[ObjectDefinition] nvarchar(max) NULL,
	[ObjectCreationDate] datetime NOT NULL,
	[ObjectLastModifyDate] datetime NOT NULL,
	[DroppedOn] date NOT NULL
);
GO

-- =============================================
-- MS_Description for table and its columns: DbInfo.DroppedObjects
-- =============================================

-- Description for table
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Stores information about objects that have been dropped from the database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects';
GO

-- Description for column: ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the dropped object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectId';
GO

-- Description for column: ObjectType
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The type of the dropped object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectType';
GO

-- Description for column: ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the dropped object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectSchema';
GO

-- Description for column: ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the dropped object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectName';
GO

-- Description for column: ObjectDescription
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The description of the dropped object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectDescription';
GO

-- Description for column: ObjectDefinition
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The definition of the dropped object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectDefinition';
GO

-- Description for column: ObjectCreationDate
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The creation date of the dropped object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectCreationDate';
GO

-- Description for column: ObjectLastModifyDate
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The date on which the object was last modified.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'ObjectLastModifyDate';
GO

-- Description for column: DroppedOn
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The date on which the object was detected as dropped.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'TABLE', @level1name = N'DroppedObjects',
	 @level2type = N'COLUMN', @level2name = N'DroppedOn';
GO