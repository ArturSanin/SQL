/*
	============================== Description ==============================
	This query creates a table, that contains the relationships between foreign 
    key constraints and the primary key or unique key constraints they reference. 
    Each row represents one foreign key definition, including the table where it is 
	defined and the table and key it points to.
*/

USE [DatabaseName];
GO

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
INTO 
    [DbInfo].[ForeignKeyRelations]
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
GO



-- =================================================
-- MS_Description for the table ForeignKeyRelations.
-- =================================================

-- Table description.
EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', 
    @value = N'Table that stores the relationships between foreign key constraints and the primary key or unique key constraints they reference. Each row represents one foreign key definition, including the table where it is defined and the table and key it points to.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'ForeignKeyRelations';
GO

-- Column descriptions.
EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The object ID of the table that contains the foreign key.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencingTableID';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The schema of the referencing table.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencingTableSchema';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The name of the referencing table.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencingTableName';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The object ID of the foreign key constraint.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ForeignKeyID';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The name of the foreign key constraint.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ForeignKeyName';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'Number of columns included in the foreign key.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ForeignKeyColumnCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'List of columns forming the foreign key, formatted as (Foreign Key Column ID, Column Name, Ordinal Position in the Table).',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ForeignKeyColumns';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The object ID of the table containing the referenced primary or unique key.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedTableID';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The schema of the referenced table.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedTableSchema';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The name of the referenced table.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedTableName';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'Type of the referenced constraint (Primary Key or Unique).',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedKeyType';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The object ID of the referenced primary key or unique constraint.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedKeyID';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The name of the referenced primary key or unique constraint.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedKeyName';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'The number of columns included in the referenced key constraint.',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedKeyColumnCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @name = N'MS_Description', @value = N'Columns forming the referenced primary key or unique constraint, formatted as (Key Column ID, Column Name, Ordinal Position in the Table).',
    @level0type=N'SCHEMA', @level0name=N'DbInfo', 
    @level1type=N'TABLE', @level1name=N'ForeignKeyRelations', 
    @level2type=N'COLUMN', @level2name=N'ReferencedKeyColumns';
GO