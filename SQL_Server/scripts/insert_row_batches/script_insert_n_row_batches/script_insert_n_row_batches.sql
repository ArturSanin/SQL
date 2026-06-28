USE [DatabaseName];
GO

/*
	============================== Description ==============================
	This script generates INSERT INTO statements for a predefined source table.
	The source table rows are grouped into batches of n rows, as specified by 
	the user in the @BatchSize variable, and are generated as INSERT INTO statements 
	for a target table. The target table must already exist, and its column order 
	must match the source table. This script is intended for user-defined tables only.

	To use the output, select all results, copy them, paste them into a new query window, 
	and execute the script.
*/

-- Enter the schema and table name of your source and target table here.
DECLARE 
	@SourceTableSchema nvarchar(128) = N'SourceTableSchema',
	@SourceTableName nvarchar(128) = N'SourceTableName',
	@TargetTableSchema nvarchar(128) = N'TargetTableSchema',
	@TargetTableName nvarchar(128) = N'TargetTableName';

-- Enter the batch size here.
DECLARE	
	@BatchSize int = 10;



/* ==================== Script Beginning ====================*/

DECLARE 
	@SourceTableFullyQualifiedName nvarchar(512) = @SourceTableSchema + N'.' + @SourceTableName,
	@SourceTableQuotedFullyQualifiedName nvarchar(512) = QUOTENAME(@SourceTableSchema) + '.' + QUOTENAME(@SourceTableName),
	@TargetTableFullyQualifiedName nvarchar(512) = @TargetTableSchema + N'.' + @TargetTableName,
	@TargetTableQuotedFullyQualifiedName nvarchar(512) = QUOTENAME(@TargetTableSchema) + '.' + QUOTENAME(@TargetTableName);

DECLARE @SourceTableObjectId int = OBJECT_ID(@SourceTableQuotedFullyQualifiedName);

DECLARE
	@SchemaError nvarchar(512) = N'The schema ''' + @SourceTableSchema + N''' does not exist in the database.',
	@ObjectError nvarchar(512) = N'The object ''' + @SourceTableFullyQualifiedName + N''' does not exist in the database.',
	@TableError nvarchar(512) = N'The object ''' + @SourceTableFullyQualifiedName + N''' is not a user-defined table.',
	@DataTypeError nvarchar(512) = N'The provided table contains a data type that is not supported by this script. Unsupported data types: image, sql_variant, varbinary, binary, timestamp, hierarchyid, geometry, geography, xml.';

IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[schemas]
	WHERE
		[schema_id] = SCHEMA_ID(@SourceTableSchema)
)
	THROW 51000, @SchemaError, 1;
ELSE IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[all_objects]
	WHERE
		[object_id] = @SourceTableObjectId
)
	THROW 51000, @ObjectError, 1;
ELSE IF NOT EXISTS (
	SELECT
		1
	FROM
		[sys].[all_objects]
	WHERE
		[object_id] = @SourceTableObjectId
	AND
		[type] IN (N'U')
)
	THROW 51000, @TableError, 1;
ELSE IF EXISTS (
	SELECT
		1
	FROM
		[sys].[all_columns]
	WHERE
		[object_id] = @SourceTableObjectId
	AND (
			[user_type_id] = 34  -- image
		OR
			[user_type_id] = 98  -- sql_variant
		OR
			[user_type_id] = 165  -- varbinary
		OR
			[user_type_id] = 173  -- binary
		OR
			[user_type_id] = 189  -- timestamp
		OR
			[user_type_id] = 128  -- hierarchyid
		OR
			[user_type_id] = 129  -- geometry
		OR
			[user_type_id] = 130  -- geography
		OR
			[user_type_id] = 241  -- xml
	)
)
	THROW 51000, @DataTypeError, 1;
ELSE BEGIN
	DECLARE @SourceTableColumns nvarchar(MAX) = (
		SELECT
			STRING_AGG(
				CAST(QUOTENAME([name]) AS nvarchar(MAX)),
				', ' + CHAR(13) + CHAR(10)
			) WITHIN GROUP (ORDER BY [column_id] ASC)
		FROM
			[sys].[all_columns] 
		WHERE
			[object_id] = @SourceTableObjectId
	)
	DECLARE @Cte nvarchar(MAX) = 
	N'DECLARE @TableRowCount bigint = (
		SELECT 
			COUNT(*) 
		FROM ' + CHAR(13) + CHAR(10) + CHAR(9) +
			@SourceTableQuotedFullyQualifiedName + 
	N');

	WITH [cteNumberedThousandRowGroups] AS (
		SELECT ' + CHAR(13) + CHAR(10) + CHAR(9) +
			@SourceTableColumns + ',
			ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS [RowNumber]
		FROM ' + 
			@SourceTableQuotedFullyQualifiedName + N'
	)' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);

	DECLARE @Select nvarchar(MAX) = 
	N'SELECT 
		N''INSERT INTO ' + @TargetTableQuotedFullyQualifiedName + N' VALUES '' + CHAR(13) + CHAR(10) AS [Script]

	UNION ALL' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
	N'SELECT' + CHAR(13) + CHAR(10) + CHAR(9);

	DECLARE @From nvarchar(512) = CHAR(13) + CHAR(10) + N'FROM' + CHAR(13) + CHAR(10) + CHAR(9) + N'[cteNumberedThousandRowGroups];';

	DECLARE @TableColumns nvarchar(MAX) = (
		SELECT
			N'N''('' + ' + CHAR(13) + CHAR(10) + CHAR(9) +
			STRING_AGG(
				CASE
					-- tinyint, smallint, int, real, money, float, decimal, numeric, smallmoney, bigint.
					WHEN [ac].[system_type_id] IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
						THEN N'COALESCE(CAST(' + QUOTENAME([ac].[name]) + N' AS nvarchar(MAX)), N''NULL'')'
					-- bit.
					WHEN [ac].[system_type_id] = 104
						THEN N'COALESCE(CAST(' + QUOTENAME([ac].[name]) + N' AS nvarchar(MAX)), N''NULL'')'
					-- text, uniqueidentifier, char, varchar.
					WHEN [ac].[system_type_id] IN (35, 36, 167, 175) 
						THEN N'COALESCE(N'''''''' + CAST(REPLACE(' + QUOTENAME([ac].[name]) + N', N'''''''', N'''''''''''') AS nvarchar(MAX)) + N'''''''', N''NULL'')'
					-- ntext, nchar, nvarchar.
					WHEN [ac].[system_type_id] IN (99, 231, 239) 
						THEN N'COALESCE(N''N'''''' + CAST(REPLACE(' + QUOTENAME([ac].[name]) + N', N'''''''', N'''''''''''') AS nvarchar(MAX)) + N'''''''', N''NULL'')'
					-- date, datetime2, datetimeoffset, smalldatetime, datetime.
					WHEN [ac].[system_type_id] IN (40, 42, 43, 58, 61)
						THEN N'COALESCE(N'''''''' + CONVERT(nvarchar(MAX), ' + QUOTENAME([ac].[name]) + N', 126) + N'''''''', N''NULL'')'
					-- time.
					WHEN [ac].[system_type_id] = 41
						THEN N'COALESCE(N'''''''' + CONVERT(nvarchar(MAX), ' + QUOTENAME([ac].[name]) + N', 108) + N'''''''', N''NULL'')'
				END,
				N' + N'', '' +' + CHAR(13) + CHAR(10) + CHAR(9)
			) WITHIN GROUP (ORDER BY [ac].[column_id] ASC)
			+ N' + 
		CASE
			WHEN [RowNumber] % ' + CAST(@BatchSize AS nvarchar(128)) + ' = 0
				THEN N'')'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + N''INSERT INTO ' + @TargetTableQuotedFullyQualifiedName + ' VALUES''
			ELSE + 
				CASE 
					WHEN [RowNumber] = @TableRowCount 
						THEN N'')''
					ELSE N''), ''
				END
		END'
		FROM
			[sys].[all_columns] [ac]
		WHERE
			[ac].[object_id] = @SourceTableObjectId
	);

	DECLARE @DynamicSQL nvarchar(MAX) = @Cte + @Select + @TableColumns + @From;

	EXEC [sys].[sp_executesql] @DynamicSQL;
END
GO