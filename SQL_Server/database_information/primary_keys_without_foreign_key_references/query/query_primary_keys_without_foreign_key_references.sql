/*
	============================== Description ==============================
	This query returns all primary keys that are not referenced by any 
	foreign key in the database.
*/

USE [DatabaseName];
GO

-- =====================================================================
-- CTE: Column-level information for primary key.
-- =====================================================================
WITH [ctePrimaryKeyColumns] AS (
	SELECT
		[ic].[object_id] AS [ObjectID],
		[ic].[index_id] AS [IndexID],
		COUNT(*) AS [PrimaryKeyColumnCount],
		STRING_AGG(N'(' + CAST([ic].[index_column_id] AS nvarchar(128)) + N', ' + [c].[name] + N', ' + CAST([ISC].[ORDINAL_POSITION] AS nvarchar(128)) + N')', N', ') AS [PrimaryKeyColumns]
	FROM
		[sys].[index_columns] [ic]
	LEFT JOIN	
		[sys].[columns] [c] ON [ic].[object_id] = [c].[object_id] AND [ic].[column_id] = [c].[column_id]
	LEFT JOIN
		[INFORMATION_SCHEMA].[COLUMNS] [ISC] ON [c].[object_id] = OBJECT_ID(QUOTENAME([ISC].[TABLE_CATALOG]) + N'.' + QUOTENAME([ISC].[TABLE_SCHEMA]) + N'.' + QUOTENAME([ISC].[TABLE_NAME])) AND [c].[name] = [ISC].[COLUMN_NAME]
	WHERE 
		[ic].[is_included_column] = 0  -- Ensures only key columns (not included non-key index columns) are considered.
	GROUP BY
		[ic].[object_id], 
		[ic].[index_id]
)

SELECT
	[kc].[parent_object_id] AS [TableID],
	[s].[name] AS [TableSchema], 
	[ao].[name] AS [TableName],
	[kc].[object_id] AS [PrimaryKeyID],
	[kc].[name] AS [PrimaryKeyName],
	[ctePKC].[PrimaryKeyColumnCount],
	[ctePKC].[PrimaryKeyColumns]
FROM
	[sys].[key_constraints] [kc]
LEFT JOIN
	[sys].[schemas] [s] ON [kc].[schema_id] = [s].[schema_id]
LEFT JOIN
	[sys].[all_objects] [ao] ON [kc].[parent_object_id] = [ao].[object_id]
LEFT JOIN
	[ctePrimaryKeyColumns] [ctePKC] ON [kc].[parent_object_id] = [ctePKC].[ObjectID] AND [kc].[unique_index_id] = [ctePKC].[IndexID]
WHERE
	[kc].[type] = N'PK'  -- Only primary key constraints.
AND
	[kc].[object_id] NOT IN (
		SELECT 
			[kc].[object_id] 
		FROM 
			[sys].[foreign_keys] [fk] 
		INNER JOIN 
			[sys].[key_constraints] [kc] ON [fk].[referenced_object_id] = [kc].[parent_object_id] AND [fk].[key_index_id] = [kc].[unique_index_id]
	)  -- Excluding primary keys referenced by foreign keys in other tables.
ORDER BY
	[s].[name] ASC,
	[ao].[name] ASC;