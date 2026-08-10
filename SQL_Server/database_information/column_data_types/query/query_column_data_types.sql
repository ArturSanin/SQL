/*
	==================== Description ====================
	This query returns data type information for columns 
	in user-defined tables and views. It provides an 
	overview of the data types used and can be used to 
	identify opportunities for data type optimization and 
	standardization.
*/

USE [DatabaseName];
GO

SELECT
	[c].[object_id] AS [ObjectId],
	CASE
		WHEN [o].[type] = N'U'
			THEN N'Table'
		WHEN [o].[type] = N'V'
			THEN N'View'
	END AS [ObjectType], 
	[o].[schema_id] AS [SchemaId],
	SCHEMA_NAME([o].[schema_id]) AS [SchemaName],
	[o].[name] AS [ObjectName],
	[c].[column_id] AS [ColumnId],
	[c].[name] AS [ColumnName],
	[c].[system_type_id] AS [SystemTypeId],
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
	[sys].[columns] [c]
LEFT JOIN
	[sys].[objects] [o] ON [c].[object_id] = [o].[object_id]
WHERE
	[o].[is_ms_shipped] = 0
AND
	[o].[type] IN (N'U', N'V')
ORDER BY
	[SchemaName] ASC,
	[ObjectName] ASC,
	[ColumnId] ASC;