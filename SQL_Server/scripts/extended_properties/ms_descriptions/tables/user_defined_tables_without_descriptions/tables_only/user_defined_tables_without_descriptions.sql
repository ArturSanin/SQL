/*
	Description: This script generates SQL statements for adding an MS_Description extended
    property to all user-defined tables in the specified database that do not have a
    description yet.
    If all user-defined tables already have an MS_Description extended property, NULL is returned.
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
		N'-- MS_Description for ' + N'table ' + SCHEMA_NAME([t].[schema_id]) + N'.' + CAST([t].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
		N'-- =============================================' + CHAR(13) + CHAR(10) +
		N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
		N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@value = N''Enter description for table here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@level0type = N''SCHEMA'', @level0name = N''' + SCHEMA_NAME([t].[schema_id]) + N''',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@level1type = N''TABLE'', @level1name = N''' + [t].[name] + N''';' + CHAR(13) + CHAR(10) + 
		N'GO',
		CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
	) WITHIN GROUP (ORDER BY SCHEMA_NAME([t].[schema_id]) ASC, [t].[name] ASC) AS [Script]
FROM
	[sys].[tables] [t]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [t].[object_id] = [ep].[major_id] AND [ep].[name] = N'MS_Description' AND [ep].[minor_id] = 0
WHERE
	[t].[is_ms_shipped] = 0  -- Excluding system tables.
AND
	[ep].[value] IS NULL;  -- Excluding tables that already have a description.