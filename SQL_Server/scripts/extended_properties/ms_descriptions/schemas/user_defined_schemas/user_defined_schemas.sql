/*
	Description: This script generates SQL statements for adding an MS_Description extended
    property to all user-defined schemas in the specified database. 
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
		N'-- MS_Description for ' + N'schema ' + CAST([s].[name] AS nvarchar(MAX)) + CHAR(13) + CHAR(10) + 
		N'-- =============================================' + CHAR(13) + CHAR(10) +
		N'EXEC [sys].[sp_addextendedproperty]' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' + 
		N'@name = N''MS_Description'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@value = N''Enter description for schema here'',' + CHAR(13) + CHAR(10) + CHAR(9) + N' ' +
		N'@level0type = N''SCHEMA'', @level0name = N''' + [s].[name] + N''';' + CHAR(13) + CHAR(10) + 
		N'GO',
		CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
	) WITHIN GROUP (ORDER BY [s].[name] ASC) AS [Script]
FROM
	[sys].[schemas] [s]
WHERE
	[s].[name] NOT IN (
			N'dbo', N'INFORMATION_SCHEMA', N'sys',
			N'guest', N'db_owner', N'db_accessadmin',
			N'db_securityadmin', N'db_ddladmin', N'db_backupoperator',
			N'db_datareader', N'db_datawriter', N'db_denydatareader', N'db_denydatawriter'
		);  -- Excluding system schemas and database roles.