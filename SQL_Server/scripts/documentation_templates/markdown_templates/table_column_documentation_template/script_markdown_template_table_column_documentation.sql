/*
	This script generates a Markdown documentation template for the columns of the specified table. 
	It includes all columns from application-defined and system-shipped tables, views, table-valued functions, 
	inline table-valued functions, and internal tables. Function parameters are not included in this script. 
	“Application-defined” typically refers to user-defined objects, while “System-shipped” generally refers 
	to system objects.

	This script uses the description from extended properties. If no description is provided, the column 
	description in the template will be empty.
*/

USE [DatabaseName];
GO

-- Enter the schema and table name to generate a Markdown documentation template for the table columns.
DECLARE 
	@TableSchema nvarchar(128) = N'TableSchema',
	@TableName nvarchar(128) = N'TableName';



/* ==================== Script Beginning ==================== */
DECLARE 
	@FullyQualifiedName nvarchar(257) = @TableSchema + N'.' + @TableName,
	@QuotedFullyQualifiedName nvarchar(261) = QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName);
	
DECLARE @ObjectId int = OBJECT_ID(@QuotedFullyQualifiedName);

DECLARE
	@SchemaError nvarchar(512) = N'The schema ''' + @TableSchema + N''' does not exists in the database.',
	@ObjectError nvarchar(512) = N'The table ''' + @FullyQualifiedName + N''' does not exists in the database.',
	@TableError nvarchar(512) = N'The object ''' + @FullyQualifiedName + N''' is not a table.'

IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[schemas]
	WHERE
		[schema_id] = SCHEMA_ID(@TableSchema)
)
	THROW 51000, @SchemaError, 1;
ELSE IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[all_objects]
	WHERE
		[object_id] = @ObjectId
)
	THROW 51000, @ObjectError, 1;
ELSE IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[all_objects]
	WHERE
		[object_id] = @ObjectId
	AND
		[type] IN (N'IF', N'IT', N'S', N'TF', N'U', N'V')
)
	THROW 51000, @TableError, 1;
ELSE
DECLARE @TableType nvarchar(512) = (
		SELECT
			CASE
				-- The Table provided is a inline table valued function.
				WHEN [type] = N'IF' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined Inline Table Valued Function'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped Inline Table Valued Function'
							ELSE N''
						END
				-- The Table provided is a internal table.
				WHEN [type] = N'IT' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined Internal Table'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped Internal Table'
							ELSE N''
						END
				-- The Table provided is a system table.
				WHEN [type] = N'S' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined System Table'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped System Table'
							ELSE N''
						END
				-- The Table provided is a table valued function.
				WHEN [type] = N'TF' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined Table Valued Function'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped Table Valued Function'
							ELSE N''
						END
				-- The Table provided is a user table.
				WHEN [type] = N'U' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined Table'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped Table'
							ELSE N''
						END
				-- The Table provided is a view.
				WHEN [type] = N'V' 
					THEN 
						CASE
							WHEN [is_ms_shipped] = 0 
								THEN N'Application-defined View'
							WHEN [is_ms_shipped] = 1
								THEN N'System-shipped View'
							ELSE N''
						END
			END
		FROM
			[sys].[all_objects]
		WHERE
			[object_id] = @ObjectId
	);

WITH [cteTableColumns] AS (
	SELECT
		[ac].[object_id] AS [ObjectId],
		[ac].[column_id] AS [ColumnId],
		[ac].[name] AS [ColumnName],
		CASE
			-- System datatypes.
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([ac].[system_type_id])
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[scale] AS nvarchar(128)) + N')'
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[precision] AS nvarchar(128)) + N',' + CAST([ac].[scale] AS nvarchar(128)) + N')'
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (165, 167, 173, 175) AND [ac].[max_length] <> -1
				THEN TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[max_length] AS nvarchar(128)) + N')'
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (231, 239) AND [ac].[max_length] <> -1
				THEN TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[max_length] / 2 AS nvarchar(128)) + N')'
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (165, 167, 231) AND [ac].[max_length] = -1
				THEN TYPE_NAME([ac].[system_type_id]) + N'(max)'
			WHEN [ac].[system_type_id] = [ac].[user_type_id] AND [ac].[system_type_id] IN (241)
				THEN N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = @ObjectId AND [cxscu].[column_id] = [ac].[column_id]), N'.') + N')'

			-- Datatypes hierarchyid, geometry, geography.
			WHEN [ac].[system_type_id] = 240
				THEN (SELECT [t].[name] FROM [sys].[types] [t] WHERE [ac].[system_type_id] = [t].[system_type_id] AND [ac].[user_type_id] = [t].[user_type_id]) 
			
			-- User-defined datatypes.
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[precision] AS nvarchar(128)) + N',' + CAST([ac].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (165, 167, 173, 175) AND [ac].[max_length] <> -1
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[max_length] AS nvarchar(128)) + N')' + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (231, 239) AND [ac].[max_length] <> -1
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N'(' + CAST([ac].[max_length] / 2 AS nvarchar(128)) + N')' + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (165, 167, 231) AND [ac].[max_length] = -1
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + TYPE_NAME([ac].[system_type_id]) + N'(max)' + N')'
			WHEN [ac].[system_type_id] <> [ac].[user_type_id] AND [ac].[system_type_id] IN (241)
				THEN TYPE_NAME([ac].[user_type_id]) + N'(' + N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = @ObjectId AND [cxscu].[column_id] = [ac].[column_id]), N'.') + N')' + N')'
		END AS [DataType]
	FROM
		[sys].[all_columns] [ac]
	WHERE
		[ac].[object_id] = @ObjectId
),

[cteMarkdownTemplate] AS (
	-- Header containing the table name and description.
	SELECT
		-2 AS [SortingColumn],
		N'**Documentation for ' + @FullyQualifiedName + N' (' + COALESCE(@TableType, N'') + N')' + N':** ' + COALESCE((SELECT CAST([ep].[value] AS nvarchar(MAX)) FROM [sys].[extended_properties] [ep] WHERE [ep].[major_id] = @ObjectId AND [ep].[name] = N'MS_Description' AND [ep].[minor_id] = 0), N'') AS [MarkdownTemplate]

	UNION ALL

	-- Whitespace
	SELECT
		-2 AS [SortingColumn],
		N'' AS [MarkdownTemplate]

	UNION ALL

	-- Markdown table header.
	SELECT
		-1 AS [SortingColumn],
		N'| Column Name | Data Type | Column Description |' AS [MarkdownTemplate]

	UNION ALL

	SELECT
		0 AS [SortingColumn],
		N'| -- | -- | -- |' AS [MarkdownTemplate]

	UNION ALL

	-- Table columns.
	SELECT
		COALESCE([ISC].[ORDINAL_POSITION], [cteTC].[ColumnId]) AS [SortingColumn],
		N'| ' + [cteTC].[ColumnName] + N' | ' + [cteTC].[DataType] + N' | ' + COALESCE(CAST([ep].[value] AS nvarchar(max)), N'') + N' |' AS [MarkdownTemplate]
	FROM
		[cteTableColumns] [cteTC]  
	LEFT JOIN
		[INFORMATION_SCHEMA].[COLUMNS] [ISC] ON [cteTC].[ObjectId] = OBJECT_ID([TABLE_SCHEMA] + '.' + [TABLE_NAME]) AND [cteTC].[ColumnName] = [ISC].[COLUMN_NAME] 
	LEFT JOIN
		[sys].[extended_properties] [ep] ON [ep].[major_id] = [cteTC].[ObjectId] AND [ep].[minor_id] = [cteTC].[ColumnId] AND [ep].[name] = N'MS_Description' AND [ep].[class] = 1		
	WHERE
		[cteTC].[ObjectId] = @ObjectId
)

SELECT 
	[MarkdownTemplate]
FROM
	[cteMarkdownTemplate]
ORDER BY
	[SortingColumn] ASC;