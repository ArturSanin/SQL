USE [DatabaseName];
GO

/*
	============================== Description ==============================
	This script generates an INSERT INTO statement for a predefined table. 
	All table values are grouped into batches of 1000 rows, which are then inserted 
	into the table. The target table must already exist and the column order must be 
	defined correctly before executing the script. This script is intended for 
	user-defined tables only.

	To use the output, select all results, copy them, paste them into a new query window, 
	and execute the script.
*/

-- Enter the schema and table name here.
DECLARE 
	@TableSchema nvarchar(128) = N'TableSchema',
	@TableName nvarchar(128) = N'TableName';



/* ==================== Script Beginning ====================*/

DECLARE 
	@FullyQualifiedName nvarchar(512) = @TableSchema + N'.' + @TableName,
	@QuotedFullyQualifiedName nvarchar(512) = QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName);

DECLARE @ObjectId int = OBJECT_ID(@QuotedFullyQualifiedName);

DECLARE
	@SchemaError nvarchar(512) = N'The schema ''' + @TableSchema + N''' does not exists in the database.',
	@ObjectError nvarchar(512) = N'The object ''' + @FullyQualifiedName + N''' does not exists in the database.',
	@TableError nvarchar(512) = N'The object ''' + @FullyQualifiedName + N''' is not a user-defined table.'

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
		[type] IN (N'U')
)
	THROW 51000, @TableError, 1;
ELSE

DECLARE @Cte nvarchar(MAX) = 
N'DECLARE @TableRowCount int = (SELECT COUNT(*) FROM ' + @QuotedFullyQualifiedName + N');

WITH [cteNumberedThousandRowGroups] AS (
	SELECT
		*,
		ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS [RowNumber],
		CASE
			WHEN CEILING((ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) / 1000.0)) * 1000 - ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) = 0
				THEN CAST(1 AS bit)
			ELSE	
				CAST(0 AS bit)
		END [IsThousandRowBoundary]
	FROM ' + 
		@QuotedFullyQualifiedName + N'
)' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);

DECLARE @Select nvarchar(MAX) = 
N'SELECT 
	N''INSERT INTO ' + @QuotedFullyQualifiedName + N' VALUES '' + CHAR(13) + CHAR(10) AS [Script]

UNION ALL' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
N'SELECT' + CHAR(13) + CHAR(10) + CHAR(9);

DECLARE @From nvarchar(512) = CHAR(13) + CHAR(10) + N'FROM' + CHAR(13) + CHAR(10) + CHAR(9) + N'[cteNumberedThousandRowGroups];';

DECLARE @TableColumns nvarchar(MAX) = (
	SELECT
		N'N''('' + ' + CHAR(13) + CHAR(10) + CHAR(9) +
		STRING_AGG(
			CASE
				WHEN [ac].[system_type_id] IN (48, 52, 56, 59, 60, 62, 104, 106, 108, 122, 127)
					THEN N'COALESCE(CAST(' + QUOTENAME([ac].[name]) + N' AS nvarchar(MAX)), N''NULL'')'
				WHEN [ac].[system_type_id] IN (35, 99, 231, 239) 
					THEN N'COALESCE(N''N'''''' + CAST(REPLACE(' + QUOTENAME([ac].[name]) + N', N'''''''', N'''''''''''') AS nvarchar(MAX)) + N'''''''', N''NULL'')'
				ELSE 
					N'COALESCE(N''N'''''' + CAST(' + QUOTENAME([ac].[name]) + N' AS nvarchar(MAX)) + N'''''''', N''NULL'')'
			END,
			N' + N'', '' +' + CHAR(13) + CHAR(10) + CHAR(9)
		) WITHIN GROUP (ORDER BY [ISC].[ORDINAL_POSITION] ASC)
		+ N' + 
	CASE
		WHEN [IsThousandRowBoundary] = 1
			THEN N'')'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + N''INSERT INTO ' + @QuotedFullyQualifiedName + ' VALUES''
		ELSE + 
			CASE 
				WHEN [RowNumber] = @TableRowCount 
					THEN N'')''
				ELSE N''), ''
			END
	END'
	FROM
		[sys].[all_columns] [ac]
	LEFT JOIN
		[INFORMATION_SCHEMA].[COLUMNS] [ISC] ON [ac].[object_id] = OBJECT_ID(QUOTENAME([ISC].[TABLE_SCHEMA]) + N'.' + QUOTENAME([ISC].[TABLE_NAME])) AND [ac].[name] = [ISC].[COLUMN_NAME]
	WHERE
		[ac].[object_id] = @ObjectId
);

DECLARE @DynamicSQL nvarchar(MAX) = @Cte + @Select + @TableColumns + @From;

EXEC [sys].[sp_executesql] @DynamicSQL;
GO