USE [DatabaseName];
GO

/*
	==================== Description ====================
	This script demonstrates step by step how to implement
	a dropped objects tracking flow.

	Important limitation to consider: The stored state of a
	dropped object is based on the most recent available snapshot
	and not necessarily on the state of the object immediately
	before it was dropped.
	
	The accuracy of the stored information depends on how frequently
	database object snapshots are taken. For example, if a snapshot
	is taken only once per day and an object's description or
	definition is changed and the object is dropped afterwards,
	the dropped object record will contain the information from
	the last available snapshot rather than the state immediately
	before the object was dropped.

	To capture the state of dropped objects as accurately as possible,
	database object snapshots should be taken at regular intervals
	throughout the day.
*/


-- ============================================================
-- 1. Create a table that stores dropped objects along with 
--    additional information about them.
-- ============================================================
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



-- ============================================================
-- 2. Create a snapshot of all user-defined objects in the database
-- with the information that should be stored for dropped objects.
-- ============================================================
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

-- Create a stored procedure to take snapshots of database objects.
DROP PROCEDURE IF EXISTS [DbInfo].[uspSnapshotDatabaseObjects];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Creates a snapshot of all user-defined 
--				database objects and stores their metadata 
--				in the [DbInfo].[SnapshotDatabaseObjects] table.
-- =============================================
CREATE OR ALTER PROCEDURE [DbInfo].[uspSnapshotDatabaseObjects]
AS
BEGIN
	SET NOCOUNT ON;

	TRUNCATE TABLE [DbInfo].[SnapshotDatabaseObjects];

	INSERT INTO [DbInfo].[SnapshotDatabaseObjects]
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
	FROM
		[sys].[objects] [o]
	LEFT JOIN
		[sys].[sql_modules] [sqlm] ON [o].[object_id] = [sqlm].[object_id]
	LEFT JOIN
		[sys].[extended_properties] [ep] ON [o].[object_id] = [ep].[major_id] AND [ep].[class] = 1 AND [ep].[name] = N'MS_Description' AND [ep].[minor_id] = 0
	WHERE
		[o].[is_ms_shipped] = 0;
END;
GO

-- =============================================
-- MS_Description for procedure: DbInfo.uspSnapshotDatabaseObjects
-- =============================================
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Creates a snapshot of all user-defined database objects and stores their metadata in the [DbInfo].[SnapshotDatabaseObjects] table.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'PROCEDURE', @level1name = N'uspSnapshotDatabaseObjects';
GO



-- ==============================
-- 3.Create a stored procedure to compare the snapshot
-- with the current database objects.
-- If objects were dropped, insert them into the
-- [DbInfo].[DroppedObjects] table and refresh the snapshot.
-- ==============================
DROP PROCEDURE IF EXISTS [DbInfo].[uspInsertDroppedObjects];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Compares the current database objects 
--				with the latest snapshot, stores dropped 
--				objects in the [DbInfo].[DroppedObjects] 
--				table, and creates a new snapshot if 
--				objects were dropped.
-- =============================================
CREATE OR ALTER PROCEDURE [DbInfo].[uspInsertDroppedObjects]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DroppedObjectsCount int;
	
	SELECT
		@DroppedObjectsCount = COUNT(*)
	FROM
		[DbInfo].[SnapshotDatabaseObjects] [SDO]
	LEFT JOIN
		[sys].[objects] [o] ON [SDO].[ObjectId] = [o].[object_id]
	WHERE
		[o].[name] IS NULL;
	
	IF @DroppedObjectsCount > 0 BEGIN
		-- Insert the dropped objects into the [DbInfo].[DroppedObjects] table.
		INSERT INTO [DbInfo].[DroppedObjects]
		SELECT
			[ObjectId],
			[ObjectType],
			[ObjectSchema],
			[ObjectName],
			[ObjectDescription],
			[ObjectDefinition],
			[ObjectCreationDate],
			[ObjectLastModifyDate],
			CAST(GETDATE() AS date) AS [DroppedOn]
		FROM
			[DbInfo].[SnapshotDatabaseObjects] [SDO]
		LEFT JOIN
			[sys].[objects] [o] ON [SDO].[ObjectId] = [o].[object_id]
		WHERE
			[o].[name] IS NULL;	

		-- New database snapshot.
		EXEC [DbInfo].[uspSnapshotDatabaseObjects];

		PRINT N'Objects dropped since the last snapshot: ' + CAST(@DroppedObjectsCount AS nvarchar(128))
	END
	ELSE BEGIN
		PRINT N'No objects were dropped since the last snapshot.'
	END
END;
GO

-- =============================================
-- MS_Description for procedure: DbInfo.uspInsertDroppedObjects
-- =============================================
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Compares the current database objects with the latest snapshot, stores dropped objects in the [DbInfo].[DroppedObjects] table, and creates a new snapshot if objects were dropped.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'PROCEDURE', @level1name = N'uspInsertDroppedObjects';
GO



-- ==============================
-- 4. Execute the procedure regularly to detect dropped objects.
-- The more frequently it is executed, the more up-to-date
-- the stored information about dropped objects will be. 
-- ==============================
EXEC [DbInfo].[uspInsertDroppedObjects];
GO

-- View the detected dropped objects.
SELECT 
	[ObjectId],
    [ObjectType],
	[ObjectSchema],
	[ObjectName],
	[ObjectDescription],
	[ObjectDefinition],
	[ObjectCreationDate],
	[ObjectLastModifyDate],
	[DroppedOn]
FROM 
	[DbInfo].[DroppedObjects];
GO