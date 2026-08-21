/*
	Description: This script generates SQL statements for adding an MS_Description extended
    property to all user-defined views in the specified database. 
	Before copying the generated result, enable:
    Tools → Options → Query Results → SQL Server → Results to Grid →
    "Retain CR/LF on copy or save".
	Then copy the generated result into a new query window and execute it.
*/

-- Set the database in which the script should be executed.
USE [DatabaseName];
GO

DECLARE @DatabaseName nvarchar(128) = DB_NAME();
  
SELECT
	N'USE ' + QUOTENAME(@DatabaseName) + N';' + CHAR(13) + CHAR(10) + N'GO' +
	CHAR(13) + CHAR(10) + 
	CHAR(13) + CHAR(10) + 
	CHAR(13) + CHAR(10) +
	CHAR(13) + CHAR(10) +
	STRING_AGG(
		N'-- =============================================' + CHAR(13) + CHAR(10) +
		N'-- MS_Description for ' + N'view ' + SCHEMA_NAME([v].[schema_id]) + N'.' + CAST([v].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
		N'-- =============================================' + CHAR(13) + CHAR(10) +
		N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
		N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@value = N''Enter description for view here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@level0type = N''SCHEMA'', @level0name = N''' + SCHEMA_NAME([v].[schema_id]) + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@level1type = N''VIEW'', @level1name = N''' + [v].[name] + N''';' + CHAR(13) + CHAR(10) + 
		N'GO',
		CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
	) WITHIN GROUP (ORDER BY SCHEMA_NAME([v].[schema_id]) ASC, [v].[name] ASC) AS [Script]
FROM
	[sys].[views] [v]
WHERE
	[v].[is_ms_shipped] = 0;  -- Excluding system views.