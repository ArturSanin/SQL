/*
	Description: This script generates SQL statements for adding an MS_Description extended
    property to all user-defined tables with their columns in the specified database. 
	Before copying the generated result, enable:
    Tools → Options → Query Results → SQL Server → Results to Grid →
    "Retain CR/LF on copy or save".
	The result will contain one row for every table, because the generated SQL may exceed
	the character limit for a single cell. In the result, select all and copy it into
    a new query window, enter the descriptions and execute it.
*/

-- Set the database in which the script should be executed.
USE [DatabaseName];
GO

DECLARE @DatabaseName nvarchar(128) = DB_NAME();

WITH [cteColumnEP] AS (
	SELECT
		SCHEMA_NAME([t].[schema_id]) AS [SchemaName],
		[t].[name] AS [TableName],
		STRING_AGG(
			N'-- Description for column: ' + CAST([c].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
			N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@value = N''Enter description for column here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level0type = N''SCHEMA'', @level0name = N''' + SCHEMA_NAME([t].[schema_id]) + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level1type = N''TABLE'', @level1name = N''' + [t].[name] + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level2type = N''COLUMN'', @level2name = N''' + [c].[name] + N''';' + CHAR(13) + CHAR(10) +
			N'GO',
			CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
		) WITHIN GROUP (ORDER BY COLUMNPROPERTY([t].[object_id], [c].[name], 'ordinal') ASC) AS [ColumnEP]
	FROM
		[sys].[columns] [c]
	LEFT JOIN 
		[sys].[tables] [t] ON [c].[object_id] = [t].[object_id]
	WHERE
		[t].[is_ms_shipped] = 0  -- Only user-defined tables.
	GROUP BY
		[t].[schema_id],
		[t].[name] 
),

[cteScriptParts] AS (
	SELECT
		N' ' AS [SortingColumn],
		N'USE ' + QUOTENAME(@DatabaseName) + N';' + CHAR(13) + CHAR(10) + N'GO' AS [ScriptParts]

	UNION ALL

	SELECT
		[cteCEP].[SchemaName] + '.' + [cteCEP].[TableName] AS [SortingColumn],
		CHAR(13) + CHAR(10) + 
		CHAR(13) + CHAR(10) + 
		CHAR(13) + CHAR(10) +
		STRING_AGG(
			N'-- =============================================' + CHAR(13) + CHAR(10) +
			N'-- MS_Description for table and its columns: ' + [cteCEP].[SchemaName] + N'.' + CAST([cteCEP].[TableName] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'-- =============================================' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
			N'-- Description for table' + CHAR(13) + CHAR(10) +
			N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
			N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@value = N''Enter description for table here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level0type = N''SCHEMA'', @level0name = N''' + [cteCEP].[SchemaName] + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level1type = N''TABLE'', @level1name = N''' + [cteCEP].[TableName] + N''';' + CHAR(13) + CHAR(10) + 
			N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
			[cteCEP].[ColumnEP],
			CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		) AS [ScriptParts]
	FROM
		[cteColumnEP] [cteCEP]
	GROUP BY
		[cteCEP].[SchemaName],
		[cteCEP].[TableName]
)

SELECT
	[ScriptParts]
FROM
	[cteScriptParts]
ORDER BY
	[SortingColumn] ASC;