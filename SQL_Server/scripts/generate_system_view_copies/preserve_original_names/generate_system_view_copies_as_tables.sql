/*
	============================== Description ==============================
	This script generates SELECT INTO statements for all system views in the
	[sys] and [INFORMATION_SCHEMA] schemas of the specified database. The generated
	statements materialize the data returned by the system views as tables in
	user-defined schemas.

	The generated table names and column names are identical to those of the
	original system views and are not modified.

	You need to specify the names of the user-defined schemas in which the copies
	of the system views will be created.

	If the database in which this script is executed is case-sensitive (CS),
	all system views will be created in the schema specified by the
	@SchemaForCSCase variable.

	If the database is case-insensitive (CI), two separate schemas must be
	specified: the schema for the [sys] views is defined by the @SchemaForSys
	variable, and the schema for the [INFORMATION_SCHEMA] views is defined by
	the @SchemaForInformationSchema variable. The script will create these
	schemas if they do not already exist.

	It is recommended to use dedicated schemas for managing the copies of the
	system views rather than existing schemas.

	The default schema names are:

	For a case-insensitive (CI) database:
		SysUd                  -> [sys] views
		InformationSchemaUd    -> [INFORMATION_SCHEMA] views

	For a case-sensitive (CS) database:
		SysUd                  -> [sys] and [INFORMATION_SCHEMA] views

	Remark:
	In a case-insensitive database, views from the [sys] and
	[INFORMATION_SCHEMA] schemas cannot be created in the same user-defined
	schema if their names differ only in case. For example, [sys].[columns]
	and [INFORMATION_SCHEMA].[COLUMNS] would be interpreted as the same object
	name in a case-insensitive database. Attempting to create both views in
	the same schema would therefore result in an error.

	For this reason, this script handles case-sensitive and case-insensitive
	databases differently and uses separate schemas for the two groups of
	system views in a case-insensitive database.

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

DECLARE 
	@DatabaseName nvarchar(128) = DB_NAME(),
	@DatabaseCollation nvarchar(128);


/* 	Determine the collation of the specified database. */
SELECT
	@DatabaseCollation = [collation_name]
FROM
	[sys].[databases]
WHERE
	[name] = @DatabaseName;


/* Specify the names of the schemas in which the table copies will be managed. */
DECLARE 
	@SchemaForSys nvarchar(128) = N'SysUd',  -- Schema for the tables copied from [sys] views in a CI database.
	@SchemaForInformationSchema nvarchar(128) = N'InformationSchemaUd';  -- Schema for the tables copied from [INFORMATION_SCHEMA] views in a CI database.

DECLARE	@SchemaForCSCase nvarchar(128) = N'SysUd';  -- Schema for the tables copied from [sys] and [INFORMATION_SCHEMA] views in a CS database.


/* 
	If this script has been executed before, the following section drops all
	tables previously created by this script in the specified schemas.

	Caution: The specified schema names must match the schema names used during
	the previous execution of this script. If a schema name has been changed,
	the tables created in the previously specified schema will not be dropped.
	This also applies if only one of the specified schema names does not match
	the corresponding schema name from the previous execution. In this case,
	the tables in the previously specified schema will remain in the database.
*/
DECLARE @DropTables nvarchar(MAX) = '';

IF @DatabaseCollation LIKE N'%[_]CI[_]%' BEGIN
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
		-- Only drop tables whose names match the names of the original system views.
		-- This ensures that if an existing schema is used instead of a dedicated
		-- schema, only tables corresponding to the original system views are dropped,
		-- while other user-defined tables in the schema remain unaffected.
			[t].[name] IN (
				SELECT
					[name]
				FROM
					[sys].[all_views]
				WHERE
					[is_ms_shipped] = 1
				AND
					SCHEMA_NAME([schema_id]) IN (N'sys', N'INFORMATION_SCHEMA')
			)
	);

	EXEC [sys].[sp_executesql] @DropTables;
END
ELSE IF @DatabaseCollation LIKE N'%[_]CS[_]%' BEGIN
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
			SCHEMA_NAME([t].[schema_id]) = @SchemaForCSCase
		AND
		-- Only drop tables whose names match the names of the original system views.
		-- This ensures that if an existing schema is used instead of a dedicated
		-- schema, only tables corresponding to the original system views are dropped,
		-- while other user-defined tables in the schema remain unaffected.
			[t].[name] IN (
				SELECT
					[name]
				FROM
					[sys].[all_views]
				WHERE
					[is_ms_shipped] = 1
				AND
					SCHEMA_NAME([schema_id]) IN (N'sys', N'INFORMATION_SCHEMA')
			)
	);

	EXEC [sys].[sp_executesql] @DropTables;
END;


/* Create the specified schemas if they do not already exist. */
DECLARE
	@DropIfExistsSchemaForSys nvarchar(256) = N'DROP SCHEMA IF EXISTS ' + QUOTENAME(@SchemaForSys) + N';', 
	@CreateSchemaForSys nvarchar(256) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaForSys) + N';',
	@DropIfExistsSchemaForInformationSchema nvarchar(256) =  N'DROP SCHEMA IF EXISTS ' + QUOTENAME(@SchemaForInformationSchema) + N';',
	@CreateSchemaForInformationSchema nvarchar(256) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaForInformationSchema) + N';',
	@DropIfExistsSchemaForCSCase nvarchar(256) =  N'DROP SCHEMA IF EXISTS ' + QUOTENAME(@SchemaForCSCase) + N';',
	@CreateSchemaForCSCase nvarchar(256) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaForCSCase) + N';';

IF SCHEMA_ID(@SchemaForSys) IS NULL BEGIN
	EXEC [sys].[sp_executesql] @CreateSchemaForSys;
END;

IF SCHEMA_ID(@SchemaForInformationSchema) IS NULL BEGIN
	EXEC [sys].[sp_executesql] @CreateSchemaForInformationSchema;
END;

IF @SchemaForCSCase <> @SchemaForSys AND @SchemaForCSCase <> @SchemaForInformationSchema AND SCHEMA_ID(@SchemaForCSCase) IS NULL BEGIN
	EXEC [sys].[sp_executesql] @CreateSchemaForCSCase;
END;


/* Generate the script. */
IF @DatabaseCollation LIKE N'%[_]CI[_]%' BEGIN
	WITH [cteSelectIntoStatements] AS (
		SELECT
			SCHEMA_NAME([v].[schema_id]) AS [SchemaName],
			[v].[name] AS [ViewName],
			N'-- =============================================' + CHAR(13) + CHAR(10) +
			N'-- View: ' + SCHEMA_NAME([v].[schema_id]) + N'.' + CAST([v].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'-- =============================================' + CHAR(13) + CHAR(10) + 
			N'DROP TABLE IF EXISTS ' + CASE WHEN SCHEMA_NAME([v].[schema_id]) = N'sys' THEN QUOTENAME(@SchemaForSys) WHEN SCHEMA_NAME([v].[schema_id]) = N'INFORMATION_SCHEMA' THEN QUOTENAME(@SchemaForInformationSchema) ELSE NULL END + N'.' + QUOTENAME([v].[name]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +    
			N'SELECT' + CHAR(13) + CHAR(10) + CHAR(9) +
			STRING_AGG(			
				CAST(QUOTENAME([c].[name]) AS nvarchar(MAX)),
				',' + CHAR(13) + CHAR(10) + CHAR(9)  
			) WITHIN GROUP (ORDER BY COLUMNPROPERTY([v].[object_id], [c].[name], N'ordinal') ASC) + CHAR(13) + CHAR(10) +
			N'INTO ' + CHAR(13) + CHAR(10) + CHAR(9) +
			CASE WHEN SCHEMA_NAME([v].[schema_id]) = N'sys' THEN QUOTENAME(@SchemaForSys) WHEN SCHEMA_NAME([v].[schema_id]) = N'INFORMATION_SCHEMA' THEN QUOTENAME(@SchemaForInformationSchema) ELSE NULL END + N'.' + QUOTENAME([v].[name]) + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) + CHAR(9) +
			QUOTENAME(SCHEMA_NAME([v].[schema_id])) + N'.' + QUOTENAME([v].[name]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + 
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10)
			AS [SelectIntoStatements]
		FROM
			[sys].[all_columns] [c]
		INNER JOIN
			[sys].[all_views] [v] ON [c].[object_id] = [v].[object_id]
		WHERE
			[v].[is_ms_shipped] = 1
		AND
			SCHEMA_NAME([v].[schema_id]) IN (N'INFORMATION_SCHEMA', N'sys')
		GROUP BY
			[v].[schema_id],
			[v].[name] 
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

	-- Drop the schema specified by @SchemaForCSCase if it differs from both
	-- @SchemaForSys and @SchemaForInformationSchema.
	IF @SchemaForCSCase <> @SchemaForSys AND @SchemaForCSCase <> @SchemaForInformationSchema BEGIN
		EXEC [sys].[sp_executesql] @DropIfExistsSchemaForCSCase;
	END;
END
ELSE IF @DatabaseCollation LIKE N'%[_]CS[_]%' BEGIN	
	WITH [cteSelectIntoStatements] AS (
		SELECT
			SCHEMA_NAME([v].[schema_id]) AS [SchemaName],
			[v].[name] AS [ViewName],
			N'-- =============================================' + CHAR(13) + CHAR(10) +
			N'-- View: ' + SCHEMA_NAME([v].[schema_id]) + N'.' + CAST([v].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'-- =============================================' + CHAR(13) + CHAR(10) +  
			N'DROP TABLE IF EXISTS ' + QUOTENAME(@SchemaForCSCase) + N'.' + QUOTENAME([v].[name]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +    
			N'SELECT' + CHAR(13) + CHAR(10) + CHAR(9) +
			STRING_AGG(			
				CAST(QUOTENAME([c].[name]) AS nvarchar(MAX)),
				',' + CHAR(13) + CHAR(10) + CHAR(9)  
			) WITHIN GROUP (ORDER BY COLUMNPROPERTY([v].[object_id], [c].[name], N'ordinal') ASC) + CHAR(13) + CHAR(10) +
			N'INTO ' + CHAR(13) + CHAR(10) + CHAR(9) +
			QUOTENAME(@SchemaForCSCase) + N'.' + QUOTENAME([v].[name]) + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) + CHAR(9) +
			QUOTENAME(SCHEMA_NAME([v].[schema_id])) + N'.' + QUOTENAME([v].[name]) + N';' + CHAR(13) + CHAR(10) +
			N'GO' + 
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10)
			AS [SelectIntoStatements]
		FROM
			[sys].[all_columns] [c]
		INNER JOIN
			[sys].[all_views] [v] ON [c].[object_id] = [v].[object_id]
		WHERE
			[v].[is_ms_shipped] = 1
		AND
			SCHEMA_NAME([v].[schema_id]) IN (N'INFORMATION_SCHEMA', N'sys')
		GROUP BY
			[v].[schema_id],
			[v].[name] 
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
			[cteSIS].[SchemaName] + '.' + [cteSIS].[ViewName] AS [SortingColumn],
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

	-- Drop the schemas that are not specified by @SchemaForCSCase.
	IF @SchemaForSys <> @SchemaForCSCase BEGIN
		EXEC [sys].[sp_executesql] @DropIfExistsSchemaForSys;
	END;

	IF @SchemaForInformationSchema <> @SchemaForCSCase BEGIN
		EXEC [sys].[sp_executesql] @DropIfExistsSchemaForInformationSchema;
	END;
END 
ELSE BEGIN
	DECLARE @ErrorMessage nvarchar(512) = N'Could not determine whether the database collation "' + @DatabaseCollation + N'" is case-sensitive or case-insensitive.' ;
	THROW 50000, @ErrorMessage, 1;
END;
GO