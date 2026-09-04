USE [ServerInfo];
GO

DROP TABLE IF EXISTS [dbo].[ObjectRowCounts];
GO

CREATE TABLE [dbo].[ObjectRowCounts](
	[DatabaseName] sysname,
	[ObjectId] int,
	[ObjectType] nvarchar(60),
	[ObjectSchema] sysname,
	[ObjectName] sysname,
	[RowCount] bigint,
	[ComputedOn] datetime2(0)
);
GO



-- =============================================
-- MS_Description for table and its columns:
-- dbo.ObjectRowCounts
-- =============================================

-- Description for table
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'Stores the row counts of all non-system tables and views across all user-created databases (database ID > 4) on the server.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts';
GO

-- Description for column: DatabaseName
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The name of the database containing the object.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'DatabaseName';
GO

-- Description for column: ObjectId
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The object ID of the table or view within its database.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectId';
GO

-- Description for column: ObjectType
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The type of the object, such as a user table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectType';
GO

-- Description for column: ObjectSchema
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The schema name of the table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectSchema';
GO

-- Description for column: ObjectName
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The name of the table or view.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ObjectName';
GO

-- Description for column: RowCount
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The number of rows returned by the table or view when the row count was calculated.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'RowCount';
GO

-- Description for column: ComputedOn
EXEC [sys].[sp_addextendedproperty]
		@name = N'MS_Description',
		@value = N'The date and time when the row count was calculated.',
		@level0type = N'SCHEMA', @level0name = N'dbo',
		@level1type = N'TABLE', @level1name = N'ObjectRowCounts',
		@level2type = N'COLUMN', @level2name = N'ComputedOn';
GO