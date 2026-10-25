/*
	============================== Description ==============================
	This query provides detailed column metadata for user-defined tables and 
	views.

	Note: The SystemTypeId returned by this query may differ from the system_type_id 
	defined in sys.types. The Microsoft-provided types hierarchyid, geometry, 
	geography, and sysname are treated as system data types in this query, even 
	though their user_type_id values differ from their system_type_id values.

	These four types are handled as special cases: for them, the query uses 
	user_type_id from sys.types as SystemTypeId instead of the standard 
	system_type_id.
*/

USE [DatabaseName];
GO

WITH [cteColumnDataTypeInformation] AS (
	SELECT
		[c].[object_id] AS [ObjectId],
		[c].[column_id] AS [ColumnId],
		[c].[system_type_id] AS [SystemTypeId], -- For hierarchyid, geometry, geography, and sysname, the original system_type_id is retained in the CTE for reference by the SystemTypeBaseType and UserTypeBaseType columns.
		CASE
			WHEN [c].[system_type_id] = 240
				THEN 
					CASE
						WHEN [c].[user_type_id] = 128
							THEN N'hierarchyid'
						WHEN [c].[user_type_id] = 129
							THEN N'geometry'
						WHEN [c].[user_type_id] = 130
							THEN N'geography'
						ELSE
							N'CLR-/Assembly-based Type'
					END
				WHEN [c].[system_type_id] = 231 AND [c].[user_type_id] = 256
					THEN N'sysname'
			ELSE
				TYPE_NAME([c].[system_type_id])
		END AS [SystemType],
		[c].[user_type_id] AS [UserTypeId],
		TYPE_NAME([c].[user_type_id]) AS [UserType],
		CASE
			-- System data types.
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([c].[system_type_id])
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[scale] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[precision] AS nvarchar(128)) + N',' + CAST([c].[scale] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 173, 175) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (231, 239) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] / 2 AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 231) AND [c].[max_length] = -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(max)'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (241)
				THEN N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = [c].[object_id] AND [cxscu].[column_id] = [c].[column_id]), N'.') + N')'

			-- CLR-/Assembly-based data types.
			WHEN [c].[system_type_id] = 240
				THEN (SELECT [t].[name] FROM [sys].[types] [t] WHERE [c].[system_type_id] = [t].[system_type_id] AND [c].[user_type_id] = [t].[user_type_id]) 
			
			-- System Alias data types (sysname)
			WHEN [c].[system_type_id] = 231 AND [c].[user_type_id] = 256
				THEN N'sysname(nvarchar(128))'

			-- User-defined data types.
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[precision] AS nvarchar(128)) + N',' + CAST([c].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 173, 175) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (231, 239) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] / 2 AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 231) AND [c].[max_length] = -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(max)' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (241)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = [c].[object_id] AND [cxscu].[column_id] = [c].[column_id]), N'.') + N')' + N')'
			END AS [DataType]
	FROM
		[sys].[all_columns] [c]
),
/* CTE's for primary key information */
[ctePrimaryKeyColumns] AS (
	SELECT
		[i].[object_id] AS [ObjectId],
		[i].[name] AS [PrimaryKeyConstraintName],
		[ic].[column_id] AS [ColumnId],
		--[ic].[index_id],
		--[ic].[index_column_id],
		[ic].[key_ordinal] AS [KeyOrdinal]
	FROM
		[sys].[index_columns] [ic]
	LEFT JOIN
		[sys].[indexes] [i] ON [ic].[object_id] = [i].[object_id] AND [ic].[index_id] = [i].[index_id]
	WHERE
		[i].[is_primary_key] = 1
),

[ctePrimaryKeyColumnsCount] AS (
	SELECT
		[ObjectId],
		COUNT(*) AS [PrimaryKeyColumnCount]
	FROM
		[ctePrimaryKeyColumns]
	GROUP BY
		[ObjectId]
),

-- Überprüfen.
[cteOtherPrimaryKeyColumns] AS (
	SELECT
		[ctePKC].[ObjectId],
		[ctePKC].[ColumnId],
		(
		SELECT
			N'[' + 
				STRING_AGG(
					N'{' +
						N'"PrimaryKeyOrdinal":' + CAST([subPKC].[KeyOrdinal] AS nvarchar(128)) + N',' +
						N'"ColumnName":"' + STRING_ESCAPE([c].[name], N'json') + N'",' +
						N'"ColumnOrdinalPosition":' + CAST(COLUMNPROPERTY([subPKC].[ObjectId], [c].[name], N'ordinal') AS nvarchar(128)) +
					N'}'
				,N','
				) WITHIN GROUP (ORDER BY [subPKC].[KeyOrdinal]) +
			N']'
		FROM
			[ctePrimaryKeyColumns] [subPKC]
		LEFT JOIN
			[sys].[columns] [c] ON [subPKC].[ObjectId] = [c].[object_id] AND [subPKC].[ColumnId] = [c].[column_id]
		WHERE
			[subPKC].[ObjectId] = [ctePKC].[ObjectId]
		AND
			[subPKC].[ColumnId] <> [ctePKC].[ColumnId]
	) AS [OtherPrimaryKeyColumns]
	FROM
		[ctePrimaryKeyColumns] [ctePKC]
),

[ctePrimaryKeyInformation] AS (
	SELECT
		[ctePKC].[ObjectId],
		[ctePKC].[PrimaryKeyConstraintName],
		[ctePKC].[ColumnId],
		[ctePKC].[KeyOrdinal],
		[ctePKCC].[PrimaryKeyColumnCount],
		[cteOPKC].[OtherPrimaryKeyColumns]
	FROM
		[ctePrimaryKeyColumns] [ctePKC]
	LEFT JOIN
		[ctePrimaryKeyColumnsCount] [ctePKCC] ON [ctePKC].[ObjectId] = [ctePKCC].[ObjectId]
	LEFT JOIN
		[cteOtherPrimaryKeyColumns] [cteOPKC] ON [ctePKC].[ObjectId] = [cteOPKC].[ObjectId] AND [ctePKC].[ColumnId] = [cteOPKC].[ColumnId]
)

SELECT
	[ac].[name] AS [ColumnName],
	[ac].[column_id] AS [ColumnId],
	[ac].[object_id] AS [ObjectId],
	[s].[name] AS [ObjectSchema],
	[ao].[name] AS [ObjectName],
	[ao].[type_desc] AS [ObjectType],
	COLUMNPROPERTY([ao].[object_id], [ac].[name], N'ordinal') AS [ColumnOrdinalPosition],
	ISNULL(CAST([ep].[value] AS nvarchar(max)), N'No description available') AS [ColumnDescription],
	/* Data type information */
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN CAST(0 AS bit)
		ELSE 
			NULL
	END AS [IsSystemDataType],
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserTypeId]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN [cteCDTI].[SystemTypeId]
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			-1
	END AS [SystemDataTypeId], -- For hierarchyid, geometry, geography, and sysname, user_type_id is used as SystemTypeId in the query output.
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			N'xCheckx'
	END AS [SystemDataTypeName],
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography')
			THEN N'CLR-/Assembly-based Type'
		WHEN [cteCDTI].[SystemType] IN (N'sysname')
			THEN TYPE_NAME([cteCDTI].[SystemTypeId])
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN NULL
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			N'xCheckx'
	END AS [SystemDataTypeBaseType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(0 AS bit)
		ELSE 
			NULL
	END AS [IsUserDataType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserTypeId]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			-9999
	END AS [UserTypeId],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			N'xCheckx'
	END AS [UserType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			N'xCheckx'
	END AS [UserTypeBaseType],
	[cteCDTI].[DataType],
	/* Primary key information */
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] = 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsPrimaryKey],
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] > 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsPartOfPrimaryKey],
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] > 1
			THEN [ctePKI].[KeyOrdinal]
		ELSE
			NULL
	END AS [PrimaryKeyOrdinal],
	[ctePKI].[OtherPrimaryKeyColumns],
	OBJECT_ID([s].[name] + N'.' + [ctePKI].[PrimaryKeyConstraintName]) AS [PrimaryKeyConstraintId],
	[ctePKI].[PrimaryKeyConstraintName]
FROM
	[sys].[all_columns] [ac]
LEFT JOIN
	[cteColumnDataTypeInformation] [cteCDTI] ON [ac].[object_id] = [cteCDTI].[ObjectId] AND [ac].[column_id] = [cteCDTI].[ColumnId]
LEFT JOIN
	[sys].[all_objects] [ao] ON [ac].[object_id] = [ao].[object_id] 
LEFT JOIN
	[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [ac].[object_id] = [ep].[major_id] AND [ac].[column_id] = [ep].[minor_id] AND [ep].[class] = 1 AND [ep].[name] = N'MS_Description'
LEFT JOIN
	[ctePrimaryKeyInformation] [ctePKI] ON [ac].[object_id] = [ctePKI].[ObjectId] AND [ac].[column_id] = [ctePKI].[ColumnId]
WHERE
	[ao].[type] IN (N'U', N'V')
AND
	[ao].[is_ms_shipped] = 0
ORDER BY
	[s].[name] ASC, 
	[ao].[name] ASC, 
	[ac].[column_id];