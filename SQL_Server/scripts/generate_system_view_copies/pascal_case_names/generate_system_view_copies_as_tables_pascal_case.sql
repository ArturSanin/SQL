/*
	============================== Description ==============================
	This script generates SELECT INTO statements for all system views in the
	[sys] and [INFORMATION_SCHEMA] schemas of the specified database. The generated
	statements are intended to create tables containing materialized copies of
	the data returned by the system views.

	The generated table names and column names are converted to PascalCase based
	on the names of the original system views and their columns.
	The script applies a deterministic PascalCase naming convention.
	Existing abbreviations and acronyms are not preserved and may be converted
	according to the same rules as regular words. Underscores '_' are treated
	as word delimiters in object and column names from both system schemas.

	You need to specify the names of the user-defined schemas in which the copies
	of the system views will be created.

	Two separate schemas must be specified: the schema for the [sys] views is
	defined by the @SchemaForSys variable, and the schema for the [INFORMATION_SCHEMA]
	views is defined by the @SchemaForInformationSchema variable. The script will
	create these schemas if they do not already exist.

	It is recommended to use dedicated schemas for managing the copies of the
	system views rather than existing schemas.

	The default schema names are:
	SysUd                  -> [sys] views
	InformationSchemaUd    -> [INFORMATION_SCHEMA] views

	Before copying the generated result, enable:
	Tools → Options → Query Results → SQL Server → Results to Grid →
	"Retain CR/LF on copy or save".

	The result will contain one row for every system view because the generated
	SQL may exceed the character limit for a single cell. Select all rows in the
	result and copy them into a new query window, then execute the generated
	statements.
*/

/* Specify the database in which the script should be executed. */
USE [DatabaseName];
GO

DECLARE @DatabaseName nvarchar(128) = DB_NAME();


/* Specify the names of the schemas in which the views will be managed. */
DECLARE 
	@SchemaForSys nvarchar(128) = N'SysUd',  -- Schema for the [sys] views.
	@SchemaForInformationSchema nvarchar(128) = N'InformationSchemaUd';  -- Schema for the [INFORMATION_SCHEMA] views.


IF @SchemaForSys IS NULL OR @SchemaForSys = N'' BEGIN
	DECLARE @ErrorMessageSysNullOrEmpty nvarchar(256) = N'Schema provided in @SchemaForSys can''t be NULL or an empty string.';
	THROW 50000, @ErrorMessageSysNullOrEmpty, 1;
END
ELSE IF @SchemaForInformationSchema IS NULL OR @SchemaForInformationSchema = N'' BEGIN
	DECLARE @ErrorMessageInformationSchemaNullOrEmpty nvarchar(256) = N'Schema provided in @SchemaForInformationSchema can''t be NULL or an empty string.';
	THROW 50000, @ErrorMessageInformationSchemaNullOrEmpty, 1;
END 
ELSE IF @SchemaForSys = @SchemaForInformationSchema BEGIN
	DECLARE @ErrorMessageEqualSchemas nvarchar(256) = N'The schemas provided in @SchemaForSys and @SchemaForInformationSchema can''t be the same.';
	THROW 50000, @ErrorMessageEqualSchemas, 1;
END
ELSE BEGIN
	/* Creating tmp table for name mapping. */
	SELECT 
		[ac].[object_id] AS [ObjectId],
		[av].[name] AS [ViewName],
		(
			SELECT 
				STRING_AGG(
					UPPER(SUBSTRING([value], 1, 1)) + SUBSTRING([value], 2, LEN([value]) - 1),
					N''
				)
			FROM 
				string_split(LOWER([av].[name]), N'_')
		) AS [ViewNamePascalCase],
		[ac].[column_id] AS [ColumnId],
		[ac].[name] AS [ColumnName],
		(
			SELECT 
				STRING_AGG(
					UPPER(SUBSTRING([value], 1, 1)) + SUBSTRING([value], 2, LEN([value]) - 1),
					N''
				)
			FROM 
				string_split(LOWER([ac].[name]), N'_')
		) AS [ColumnNamePascalCase] 
	INTO
		[#MappingPascalCase]
	FROM 
		[sys].[all_columns] [ac]
	LEFT JOIN
		[sys].[all_views] [av] ON [ac].[object_id] = [av].[object_id]
	WHERE
		SCHEMA_NAME([av].[schema_id]) IN (N'sys', N'INFORMATION_SCHEMA');

	/* 
		If this script has been executed before, the following section drops all
		tables previously created by this script in the specified schemas whose names
		match the generated PascalCase names of the system views.

		Caution: The specified schema names must match the schema names used during
		the previous execution of this script. If a schema name has been changed,
		the tables created in the previously specified schema will not be dropped.
		This also applies if only one of the specified schema names does not match
		the corresponding schema name from the previous execution. In this case,
		the tables in the previously specified schema will remain in the database.

		Only tables with names matching the generated PascalCase system view names
		are dropped. Other user-defined tables in the specified schemas remain
		unaffected.
	*/
	DECLARE @DropTables nvarchar(MAX) = N'';
	
	SET @DropTables = (
		SELECT
			N'USE ' + DB_NAME() + N';' + 
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			STRING_AGG(
				CAST(N'DROP TABLE IF EXISTS ' AS nvarchar(MAX)) + QUOTENAME(SCHEMA_NAME([t].[schema_id])) + N'.' + QUOTENAME([t].[name]) + N';',
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10)
			)
		FROM
			[sys].[tables] [t]
		WHERE
			[t].[is_ms_shipped] = 0
		AND
			SCHEMA_NAME([t].[schema_id]) IN (@SchemaForSys, @SchemaForInformationSchema)
		AND
		-- Only drop tables whose names match the generated PascalCase names of the
		-- original system views. This ensures that if an existing schema is used
		-- instead of a dedicated schema, only tables corresponding to the original
		-- system views are dropped, while other user-defined tables in the schema
		-- remain unaffected.
			[t].[name] IN (
				SELECT DISTINCT
					[ViewNamePascalCase]
				FROM
					[#MappingPascalCase]
			)
	);

	EXEC [sys].[sp_executesql] @DropTables;
	
	
	/* Create the specified schemas if they do not already exist. */
	DECLARE
		@DropIfExistsSchemaForSys nvarchar(256) = N'DROP SCHEMA IF EXISTS ' + QUOTENAME(@SchemaForSys) + N';', 
		@CreateSchemaForSys nvarchar(256) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaForSys) + N';',
		@DropIfExistsSchemaForInformationSchema nvarchar(256) =  N'DROP SCHEMA IF EXISTS ' + QUOTENAME(@SchemaForInformationSchema) + N';',
		@CreateSchemaForInformationSchema nvarchar(256) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaForInformationSchema) + N';';

	IF SCHEMA_ID(@SchemaForSys) IS NULL BEGIN
		EXEC [sys].[sp_executesql] @CreateSchemaForSys;
	END;

	IF SCHEMA_ID(@SchemaForInformationSchema) IS NULL BEGIN
		EXEC [sys].[sp_executesql] @CreateSchemaForInformationSchema;
	END;
		
	WITH [cteSelectIntoStatements] AS (
		SELECT
			SCHEMA_NAME([av].[schema_id]) AS [SchemaName],
			[av].[name] AS [ViewName],
			N'-- =============================================' + CHAR(13) + CHAR(10) +
			N'-- View: ' + SCHEMA_NAME([av].[schema_id]) + N'.' + CAST([av].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'-- =============================================' + CHAR(13) + CHAR(10) + 
			N'DROP TABLE IF EXISTS ' + CASE WHEN SCHEMA_NAME([av].[schema_id]) = N'sys' THEN QUOTENAME(@SchemaForSys) WHEN SCHEMA_NAME([av].[schema_id]) = N'INFORMATION_SCHEMA' THEN QUOTENAME(@SchemaForInformationSchema) ELSE NULL END + N'.' + QUOTENAME([#MPC].[ViewNamePascalCase]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +   
			N'SELECT' + CHAR(13) + CHAR(10) + CHAR(9) +
			STRING_AGG(			
				CAST(QUOTENAME([ac].[name]) AS nvarchar(MAX)) + N' AS ' + QUOTENAME([#MPC].[ColumnNamePascalCase]),
				',' + CHAR(13) + CHAR(10) + CHAR(9)  
			) WITHIN GROUP (ORDER BY COLUMNPROPERTY([av].[object_id], [ac].[name], N'ordinal') ASC) + CHAR(13) + CHAR(10) +
			N'INTO' + CHAR(13) + CHAR(10) + CHAR(9) +
			CASE WHEN SCHEMA_NAME([av].[schema_id]) = N'sys' THEN QUOTENAME(@SchemaForSys) WHEN SCHEMA_NAME([av].[schema_id]) = N'INFORMATION_SCHEMA' THEN QUOTENAME(@SchemaForInformationSchema) ELSE NULL END + N'.' + QUOTENAME([#MPC].[ViewNamePascalCase]) + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) + CHAR(9) +
			QUOTENAME(SCHEMA_NAME([av].[schema_id])) + N'.' + QUOTENAME([av].[name]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + 
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10)
			AS [SelectIntoStatements]
		FROM
			[sys].[all_columns] [ac]
		INNER JOIN
			[sys].[all_views] [av] ON [ac].[object_id] = [av].[object_id]
		LEFT JOIN 
			[#MappingPascalCase] [#MPC] ON [ac].[object_id] = [#MPC].[ObjectId] AND [ac].[column_id] = [#MPC].[ColumnId]
		WHERE
			[av].[is_ms_shipped] = 1
		AND
			SCHEMA_NAME([av].[schema_id]) IN (N'INFORMATION_SCHEMA', N'sys')
		GROUP BY
			[av].[schema_id],
			[av].[name],
			[#MPC].[ViewNamePascalCase]
	),

	[cteScriptParts] AS (
		SELECT
			N' ' AS [SortingColumn],
			N'USE ' + QUOTENAME(@DatabaseName) + N';' + CHAR(13) + CHAR(10) + N'GO' + 
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10) AS [ScriptParts]

		UNION ALL

		SELECT
			[cteSIS].[SchemaName] + N'.' + [cteSIS].[ViewName] AS [SortingColumn],
			[cteSIS].[SelectIntoStatements] AS [ScriptParts]
		FROM
			[cteSelectIntoStatements] [cteSIS]
	)

	SELECT
		[ScriptParts]
	FROM
		[cteScriptParts]
	ORDER BY
		[SortingColumn] ASC;

	-- Dropping the created tmp table.
	DROP TABLE [#MappingPascalCase];
END
GO