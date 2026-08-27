USE [DatabaseName];
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