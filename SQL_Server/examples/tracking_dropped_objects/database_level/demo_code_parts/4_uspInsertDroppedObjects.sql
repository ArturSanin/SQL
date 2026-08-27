USE [DatabaseName];
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