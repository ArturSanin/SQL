USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 28.02.2026
-- Description:	This stored procedure refreshes the table [DbInfo].[ForeignKeyRelations]
--				by updating it with the current relationships between foreign key
--				constraints and the primary or unique constraints they reference.
-- =============================================
CREATE PROCEDURE [DbInfo].[uspRefreshForeignKeyRelations] 
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE [DbInfo].[ForeignKeyRelations];

	WITH [cteForeignKeyColumns] AS (
		SELECT
			[fkc].[constraint_object_id] AS [ConstraintObjectID],
			COUNT(*) AS [ForeignKeyColumnCount],
			STRING_AGG(N'(' + CAST([fkc].[constraint_column_id] AS nvarchar(128)) + N', ' + [c].[name] + N', ' + CAST([ISC].[ORDINAL_POSITION] AS nvarchar(128)) + N')', N', ') AS [ForeignKeyColumns]
		FROM
			[sys].[foreign_key_columns] [fkc]
		LEFT JOIN
			[sys].[columns] [c] ON [fkc].[parent_object_id] = [c].[object_id] AND [fkc].[parent_column_id] = [c].[column_id] 
		LEFT JOIN
			[INFORMATION_SCHEMA].[COLUMNS] [ISC] ON [c].[object_id] = OBJECT_ID(QUOTENAME([ISC].[TABLE_CATALOG]) + N'.' + QUOTENAME([ISC].[TABLE_SCHEMA]) + N'.' + QUOTENAME([ISC].[TABLE_NAME])) AND [c].[name] = [ISC].[COLUMN_NAME]
		GROUP BY
			[fkc].[constraint_object_id]
	),

	[cteReferencedKeyColumns] AS (
		SELECT
			[ic].[object_id] AS [ObjectID],
			[ic].[index_id] AS [IndexID],
			COUNT(*) AS [ReferencedKeyColumnCount], 
			STRING_AGG(N'(' + CAST([ic].[index_column_id] AS nvarchar(128)) + N', ' + [c].[name] + N', ' + CAST([ISC].[ORDINAL_POSITION] AS nvarchar(128)) + N')', N', ') AS [ReferencedKeyColumns]
		FROM
			[sys].[index_columns] [ic]
		LEFT JOIN	
			[sys].[columns] [c] ON [ic].[object_id] = [c].[object_id] AND [ic].[column_id] = [c].[column_id]
		LEFT JOIN
			[INFORMATION_SCHEMA].[COLUMNS] [ISC] ON [c].[object_id] = OBJECT_ID(QUOTENAME([ISC].[TABLE_CATALOG]) + N'.' + QUOTENAME([ISC].[TABLE_SCHEMA]) + N'.' + QUOTENAME([ISC].[TABLE_NAME])) AND [c].[name] = [ISC].[COLUMN_NAME]
		WHERE
			[ic].[is_included_column] = 0
		GROUP BY
			[ic].[object_id], 
			[ic].[index_id]
	)

	INSERT INTO
		[DbInfo].[ForeignKeyRelations]
	SELECT
		[fk].[parent_object_id] AS [ReferencingTableID],
		[s].[name] AS [ReferencingTableSchema],
		[ao].[name] AS [ReferencingTableName],
		[fk].[object_id] AS [ForeignKeyID],
		[fk].[name] AS [ForeignKeyName],
		[cteFKC].[ForeignKeyColumnCount],
		[cteFKC].[ForeignKeyColumns] AS [ForeignKeyColumns],
		[fk].[referenced_object_id] AS [ReferencedTableID],
		[sc].[name] AS [ReferencedTableSchema],
		[o].[name] AS [ReferencedTableName],
		CAST(SUBSTRING([kc].[type_desc], 1, 1) + LOWER(REPLACE(SUBSTRING([kc].[type_desc], 2, LEN([kc].[type_desc]) - 1), '_', ' ')) AS nvarchar(128)) AS [ReferencedKeyType],
		[kc].[object_id] AS [ReferencedKeyID],
		[kc].[name] AS [ReferencedKeyName],
		[cteRKC].[ReferencedKeyColumnCount],
		[cteRKC].[ReferencedKeyColumns]
	FROM
		[sys].[foreign_keys] [fk]
	LEFT JOIN 
		[sys].[all_objects] [ao] ON [fk].[parent_object_id] = [ao].[object_id]
	LEFT JOIN 
		[sys].[objects] [o] ON [fk].[referenced_object_id] = [o].[object_id]
	LEFT JOIN
		[sys].[schemas] [s] ON [fk].[schema_id] = [s].[schema_id]
	LEFT JOIN
		[sys].[schemas] [sc] ON [o].[schema_id] = [sc].[schema_id]
	LEFT JOIN
		[sys].[key_constraints] [kc] ON [fk].[referenced_object_id] = [kc].[parent_object_id] AND [fk].[key_index_id] = [kc].[unique_index_id]
	LEFT JOIN
		[cteForeignKeyColumns] [cteFKC] ON [fk].[object_id] = [cteFKC].[ConstraintObjectID]
	LEFT JOIN
		[cteReferencedKeyColumns] [cteRKC] ON [kc].[parent_object_id] = [cteRKC].[ObjectID] AND [kc].[unique_index_id] = [cteRKC].[IndexID];
END
GO


-- =======================================
-- MS_Description for the stored procedure 
-- uspRefreshForeignKeyRelations
-- =======================================

-- Stored procedure description.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'This stored procedure refreshes the table [DbInfo].[ForeignKeyRelations] by updating it with the current relationships between foreign key constraints and the primary or unique constraints they reference.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'PROCEDURE', @level1name = N'uspRefreshForeignKeyRelations';
GO