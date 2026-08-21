/*
	Description: This script generates SQL statements for adding an MS_Description extended
    property to all user-defined stored procedures with their parameters in the specified 
	database. 
	Before copying the generated result, enable:
    Tools → Options → Query Results → SQL Server → Results to Grid →
    "Retain CR/LF on copy or save".
	The result will contain one row for every stored procedure, because the generated SQL may exceed
	the character limit for a single cell. In the result, select all and copy it into
    a new query window, enter the descriptions and execute it.
*/

-- Set the database in which the script should be executed.
USE [DatabaseName];
GO

DECLARE @DatabaseName nvarchar(128) = DB_NAME();

WITH [cteParameterEP] AS (
	SELECT
		SCHEMA_NAME([p].[schema_id]) AS [SchemaName],
		[p].[name] AS [ProcedureName],
		STRING_AGG(
			N'-- Description for parameter: ' + CAST([par].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
			N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@value = N''Enter description for parameter here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level0type = N''SCHEMA'', @level0name = N''' + SCHEMA_NAME([p].[schema_id]) + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level1type = N''PROCEDURE'', @level1name = N''' + [p].[name] + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level2type = N''PARAMETER'', @level2name = N''' + [par].[name] + N''';' + CHAR(13) + CHAR(10) +
			N'GO',
			CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
		) WITHIN GROUP (ORDER BY [par].[parameter_id] ASC) AS [ParameterEP]
	FROM
		[sys].[procedures] [p]
	LEFT JOIN 
		 [sys].[parameters] [par] ON [par].[object_id] = [p].[object_id]
	WHERE
		[p].[is_ms_shipped] = 0  -- Only user-defined stored procedures.
	GROUP BY
		[p].[schema_id],
		[p].[name] 
),

[cteScriptParts] AS (
	SELECT
		N' ' AS [SortingColumn],
		N'USE ' + QUOTENAME(@DatabaseName) + N';' + CHAR(13) + CHAR(10) + N'GO' AS [ScriptParts]

	UNION ALL

	SELECT
		[ctePEP].[SchemaName] + '.' + [ctePEP].[ProcedureName] AS [SortingColumn],
		CHAR(13) + CHAR(10) + 
		CHAR(13) + CHAR(10) + 
		CHAR(13) + CHAR(10) +
		STRING_AGG(
			N'-- =============================================' + CHAR(13) + CHAR(10) +
			N'-- MS_Description for stored procedure and its parameters: ' + [ctePEP].[SchemaName] + N'.' + CAST([ctePEP].[ProcedureName] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
			N'-- =============================================' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
			N'-- Description for stored procedure' + CHAR(13) + CHAR(10) +
			N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
			N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@value = N''Enter description for stored procedure here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level0type = N''SCHEMA'', @level0name = N''' + [ctePEP].[SchemaName] + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
			N'@level1type = N''PROCEDURE'', @level1name = N''' + [ctePEP].[ProcedureName] + N''';' + CHAR(13) + CHAR(10) + 
			N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
			COALESCE([ctePEP].[ParameterEP], ''),
			CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		) AS [ScriptParts]
	FROM
		[cteParameterEP] [ctePEP]
	GROUP BY
		[ctePEP].[SchemaName],
		[ctePEP].[ProcedureName]
)

SELECT
	[ScriptParts]
FROM
	[cteScriptParts]
ORDER BY
	[SortingColumn] ASC;