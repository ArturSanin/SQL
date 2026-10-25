/*
	============================== Description ==============================
	This query provides detailed column metadata.

	Note: The SystemTypeId returned by this query may differ from the system_type_id 
	defined in sys.types. The Microsoft-provided types hierarchyid, geometry, 
	geography, and sysname are treated as system data types in this query, even 
	though their user_type_id values differ from their system_type_id values.

	These four types are handled as special cases: for them, the query uses 
	user_type_id from sys.types as SystemTypeId instead of the standard 
	system_type_id.
*/

--USE [DatabaseName];
--GO

WITH [cteColumnDataTypeInformation] AS (
	SELECT
		[c].[object_id] AS [ObjectId],
		[c].[column_id] AS [ColumnId],
		[c].[system_type_id] AS [SystemTypeId], -- For hierarchyid, geometry, geography, and sysname, the original system_type_id is retained in the CTE for reference by the SystemTypeBaseType and UserTypeBaseType columns.
		CASE
			WHEN [c].[system_type_id] = 240
				THEN 
					CASE
						WHEN [c].[user_type_id] = 128
							THEN N'hierarchyid'
						WHEN [c].[user_type_id] = 129
							THEN N'geometry'
						WHEN [c].[user_type_id] = 130
							THEN N'geography'
						ELSE
							N'CLR-/Assembly-based Type'
					END
				WHEN [c].[system_type_id] = 231 AND [c].[user_type_id] = 256
					THEN N'sysname'
			ELSE
				TYPE_NAME([c].[system_type_id])
		END AS [SystemType],
		[c].[user_type_id] AS [UserTypeId],
		TYPE_NAME([c].[user_type_id]) AS [UserType],
		CASE
			-- System data types.
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([c].[system_type_id])
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[scale] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[precision] AS nvarchar(128)) + N',' + CAST([c].[scale] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 173, 175) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (231, 239) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] / 2 AS nvarchar(128)) + N')'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 231) AND [c].[max_length] = -1
				THEN TYPE_NAME([c].[system_type_id]) + N'(max)'
			WHEN [c].[system_type_id] = [c].[user_type_id] AND [c].[system_type_id] IN (241)
				THEN N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = [c].[object_id] AND [cxscu].[column_id] = [c].[column_id]), N'.') + N')'

			-- CLR-/Assembly-based data types.
			WHEN [c].[system_type_id] = 240
				THEN (SELECT [t].[name] FROM [sys].[types] [t] WHERE [c].[system_type_id] = [t].[system_type_id] AND [c].[user_type_id] = [t].[user_type_id]) 
			
			-- System Alias data types (sysname)
			WHEN [c].[system_type_id] = 231 AND [c].[user_type_id] = 256
				THEN N'sysname(nvarchar(128))'

			-- User-defined data types.
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (34, 35, 36, 40, 48, 52, 56, 58, 59, 60, 61, 62, 98, 99, 104, 122, 127, 189)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (41, 42, 43)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (106, 108)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[precision] AS nvarchar(128)) + N',' + CAST([c].[scale] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 173, 175) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (231, 239) AND [c].[max_length] <> -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(' + CAST([c].[max_length] / 2 AS nvarchar(128)) + N')' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (165, 167, 231) AND [c].[max_length] = -1
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + TYPE_NAME([c].[system_type_id]) + N'(max)' + N')'
			WHEN [c].[system_type_id] <> [c].[user_type_id] AND [c].[system_type_id] IN (241)
				THEN TYPE_NAME([c].[user_type_id]) + N'(' + N'XML(' + COALESCE((SELECT SCHEMA_NAME([xsc].[schema_id]) + N'.' + [xsc].[name] FROM [sys].[column_xml_schema_collection_usages] [cxscu] LEFT JOIN [sys].[xml_schema_collections] [xsc] ON [cxscu].[xml_collection_id] = [xsc].[xml_collection_id] WHERE [cxscu].[object_id] = [c].[object_id] AND [cxscu].[column_id] = [c].[column_id]), N'.') + N')' + N')'
			END AS [DataType]
	FROM
		[sys].[all_columns] [c]
),
/* CTE's for primary key information */
[ctePrimaryKeyColumns] AS (
	SELECT
		[i].[object_id] AS [ObjectId],
		[i].[name] AS [PrimaryKeyConstraintName],
		[ic].[column_id] AS [ColumnId],
		[ic].[key_ordinal] AS [KeyOrdinal]
	FROM
		[sys].[index_columns] [ic]
	LEFT JOIN
		[sys].[indexes] [i] ON [ic].[object_id] = [i].[object_id] AND [ic].[index_id] = [i].[index_id]
	WHERE
		[i].[is_primary_key] = 1
),

[ctePrimaryKeyColumnsCount] AS (
	SELECT
		[ObjectId],
		COUNT(*) AS [PrimaryKeyColumnCount]
	FROM
		[ctePrimaryKeyColumns]
	GROUP BY
		[ObjectId]
),

[cteOtherPrimaryKeyColumns] AS (
	SELECT
		[ctePKC].[ObjectId],
		[ctePKC].[ColumnId],
		(
		SELECT
			N'[' + 
				STRING_AGG(
					CAST(
						N'{' +
							N'"PrimaryKeyOrdinal":' + CAST([subPKC].[KeyOrdinal] AS nvarchar(128)) + N',' +
							N'"ColumnName":"' + STRING_ESCAPE([c].[name], N'json') + N'",' +
							N'"ColumnOrdinalPosition":' + CAST(COLUMNPROPERTY([subPKC].[ObjectId], [c].[name], N'ordinal') AS nvarchar(128)) +
						N'}' AS nvarchar(max)
					)
				,N','
				) WITHIN GROUP (ORDER BY [subPKC].[KeyOrdinal]) +
			N']'
		FROM
			[ctePrimaryKeyColumns] [subPKC]
		LEFT JOIN
			[sys].[columns] [c] ON [subPKC].[ObjectId] = [c].[object_id] AND [subPKC].[ColumnId] = [c].[column_id]
		WHERE
			[subPKC].[ObjectId] = [ctePKC].[ObjectId]
		AND
			[subPKC].[ColumnId] <> [ctePKC].[ColumnId]
	) AS [OtherPrimaryKeyColumns]
	FROM
		[ctePrimaryKeyColumns] [ctePKC]
),

[ctePrimaryKeyInformation] AS (
	SELECT
		[ctePKC].[ObjectId],
		[ctePKC].[PrimaryKeyConstraintName],
		[ctePKC].[ColumnId],
		[ctePKC].[KeyOrdinal],
		[ctePKCC].[PrimaryKeyColumnCount],
		[cteOPKC].[OtherPrimaryKeyColumns]
	FROM
		[ctePrimaryKeyColumns] [ctePKC]
	LEFT JOIN
		[ctePrimaryKeyColumnsCount] [ctePKCC] ON [ctePKC].[ObjectId] = [ctePKCC].[ObjectId]
	LEFT JOIN
		[cteOtherPrimaryKeyColumns] [cteOPKC] ON [ctePKC].[ObjectId] = [cteOPKC].[ObjectId] AND [ctePKC].[ColumnId] = [cteOPKC].[ColumnId]
),
/* CTE's for unique constraint information */
[cteUniqueConstraintColumns] AS (
	SELECT
		[i].[object_id] AS [ObjectId],
		[i].[name] AS [UniqueConstraintName],
		[ic].[column_id] AS [ColumnId],
		[ic].[key_ordinal] AS [KeyOrdinal]
	FROM
		[sys].[index_columns] [ic]
	LEFT JOIN
		[sys].[indexes] [i] ON [ic].[object_id] = [i].[object_id] AND [ic].[index_id] = [i].[index_id]
	WHERE
		[i].[is_unique_constraint] = 1
),

[cteUniqueConstraintColumnsCount] AS (
	SELECT
		[ObjectId],
		COUNT(*) AS [UniqueConstraintColumnCount]
	FROM
		[cteUniqueConstraintColumns]
	GROUP BY
		[ObjectId]
),

[cteOtherUniqueConstraintColumns] AS (
	SELECT
		[cteUCC].[ObjectId],
		[cteUCC].[ColumnId],
		(
		SELECT
			N'[' + 
				STRING_AGG(
					CAST(
						N'{' +
							N'"UniqueConstraintOrdinalPosition":' + CAST([subUCC].[KeyOrdinal] AS nvarchar(128)) + N',' +
							N'"ColumnName":"' + STRING_ESCAPE([c].[name], N'json') + N'",' +
							N'"ColumnOrdinalPosition":' + CAST(COLUMNPROPERTY([subUCC].[ObjectId], [c].[name], N'ordinal') AS nvarchar(128)) +
						N'}' AS nvarchar(max)
					)
				,N','
				) WITHIN GROUP (ORDER BY [subUCC].[KeyOrdinal]) +
			N']'
		FROM
			[cteUniqueConstraintColumns] [subUCC]
		LEFT JOIN
			[sys].[columns] [c] ON [subUCC].[ObjectId] = [c].[object_id] AND [subUCC].[ColumnId] = [c].[column_id]
		WHERE
			[subUCC].[ObjectId] = [cteUCC].[ObjectId]
		AND
			[subUCC].[ColumnId] <> [cteUCC].[ColumnId]
	) AS [OtherUniqueConstraintColumns]
	FROM
		[cteUniqueConstraintColumns] [cteUCC]
),

[cteUniqueConstraintInformation] AS (
	SELECT
		[cteUCC].[ObjectId],
		[cteUCC].[UniqueConstraintName],
		[cteUCC].[ColumnId],
		[cteUCC].[KeyOrdinal] AS [UQColumnOrdinal],
		[cteUCCC].[UniqueConstraintColumnCount],
		[cteOUCC].[OtherUniqueConstraintColumns]
	FROM
		[cteUniqueConstraintColumns] [cteUCC]
	LEFT JOIN
		[cteUniqueConstraintColumnsCount] [cteUCCC] ON [cteUCC].[ObjectId] = [cteUCCC].[ObjectId]
	LEFT JOIN
		[cteOtherUniqueConstraintColumns] [cteOUCC] ON [cteUCC].[ObjectId] = [cteOUCC].[ObjectId] AND [cteUCC].[ColumnId] = [cteOUCC].[ColumnId]
),
/* CTE for check constraint information */
[cteCheckConstraintInformation] AS (
	SELECT
		[ckc].[parent_object_id] AS [ParentObjectId],
		[ckc].[parent_column_id] AS [ParentColumnId],
		N'[' +
			STRING_AGG(
				CAST(
					N'{' +
						N'"CheckConstraintName":"' + STRING_ESCAPE([ckc].[name], N'json') + N'",' +
						N'"CheckConstraintId":' + CAST([ckc].[object_id] AS nvarchar(128)) + N',' +
						N'"CheckConstraintDefinition":"' + STRING_ESCAPE([ckc].[definition], N'json') + N'",' +
						N'"CheckConstraintUsesDatabaseCollation":' + CAST([ckc].[uses_database_collation] AS nvarchar(128)) + N',' +
						N'"CheckConstraintCreatedOn":"' + CAST([ckc].[create_date] AS nvarchar(128)) + N'",' +
						N'"CheckConstraintLastModifiedOn":"' + CAST([ckc].[modify_date] AS nvarchar(128)) + N'",' +
						N'"CheckConstraintIsDisabled":' + CAST([ckc].[is_disabled] AS nvarchar(128)) + N',' +
						N'"CheckConstraintIsNotTrusted":' + CAST([ckc].[is_not_trusted] AS nvarchar(128)) + N',' +
						N'"CheckConstraintIsSystemNamed":' + CAST([ckc].[is_system_named] AS nvarchar(128)) + N',' +
						N'"CheckConstraintIsNotForReplication":' + CAST([ckc].[is_not_for_replication] AS nvarchar(128)) +
					N'}' AS nvarchar(max)
				),
				N','
			) +
		N']' AS [CheckConstraints]
	FROM
		[sys].[check_constraints] [ckc]
	WHERE
		[ckc].[parent_column_id] > 0
	GROUP BY
		[ckc].[parent_object_id],
		[ckc].[parent_column_id]
)

SELECT
	[ac].[name] AS [ColumnName],
	[ac].[column_id] AS [ColumnId],
	[ac].[object_id] AS [ObjectId],
	[s].[name] AS [ObjectSchema],
	[ao].[name] AS [ObjectName],
	[ao].[type_desc] AS [ObjectType],
	COLUMNPROPERTY([ao].[object_id], [ac].[name], N'ordinal') AS [ColumnOrdinalPosition],
	ISNULL(CAST([ep].[value] AS nvarchar(max)), N'No description available') AS [ColumnDescription],
	/* Data type information */
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN CAST(0 AS bit)
		ELSE 
			NULL
	END AS [IsSystemDataType],
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserTypeId]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN [cteCDTI].[SystemTypeId]
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			-1
	END AS [SystemDataTypeId], -- For hierarchyid, geometry, geography, and sysname, user_type_id is used as SystemTypeId in the query output.
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			N'xCheckx'
	END AS [SystemDataTypeName],
	CASE
		WHEN [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography')
			THEN N'CLR-/Assembly-based Type'
		WHEN [cteCDTI].[SystemType] IN (N'sysname')
			THEN TYPE_NAME([cteCDTI].[SystemTypeId])
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] 
			THEN NULL
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId]
			THEN NULL
		ELSE
			N'xCheckx'
	END AS [SystemDataTypeBaseType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(1 AS bit)
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN CAST(0 AS bit)
		ELSE 
			NULL
	END AS [IsUserDataType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserTypeId]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			-9999
	END AS [UserTypeId],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[UserType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			N'xCheckx'
	END AS [UserType],
	CASE
		WHEN [cteCDTI].[SystemTypeId] <> [cteCDTI].[UserTypeId] AND [cteCDTI].[SystemType] NOT IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN [cteCDTI].[SystemType]
		WHEN [cteCDTI].[SystemTypeId] = [cteCDTI].[UserTypeId] OR [cteCDTI].[SystemType] IN (N'hierarchyid', N'geometry', N'geography', N'sysname')
			THEN NULL
		ELSE 
			N'xCheckx'
	END AS [UserTypeBaseType],
	[cteCDTI].[DataType],
	COALESCE([ac].[collation_name], N'Not a text column') AS [ColumnCollationName],
	/* Primary key information */
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] = 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsOnlyPrimaryKeyColumn],
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] > 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsPartOfPrimaryKey],
	CASE
		WHEN [ctePKI].[PrimaryKeyColumnCount] > 1
			THEN [ctePKI].[KeyOrdinal]
		ELSE
			NULL
	END AS [PrimaryKeyOrdinal],
	[ctePKI].[OtherPrimaryKeyColumns],
	OBJECT_ID([s].[name] + N'.' + [ctePKI].[PrimaryKeyConstraintName]) AS [PrimaryKeyConstraintId],
	[ctePKI].[PrimaryKeyConstraintName],
	/* Unique constraint information */
	CASE
		WHEN [cteUCI].[UniqueConstraintColumnCount] = 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsOnlyUniqueConstraintColumn],
	CASE
		WHEN [cteUCI].[UniqueConstraintColumnCount] > 1
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [IsPartOfUniqueConstraint],
	CASE
		WHEN [cteUCI].[UniqueConstraintColumnCount] > 1
			THEN [cteUCI].[UQColumnOrdinal]
		ELSE
			NULL
	END AS [UniqueConstraintColumnOrdinal],
	[cteUCI].[OtherUniqueConstraintColumns],
	OBJECT_ID([s].[name] + N'.' + [cteUCI].[UniqueConstraintName]) AS [UniqueConstraintId],
	[cteUCI].[UniqueConstraintName],
	/* Default value information */
	CASE
		WHEN [dc].[name] IS NOT NULL
			THEN CAST(1 AS bit)
		WHEN [dc].[name] IS NULL
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [HasDefaultValue],
	[dc].[name] AS [DefaultConstraintName],
	[dc].[object_id] AS [DefaultConstraintId],
	[dc].[definition] AS [DefaultValue],
	[dc].[create_date] AS [DefaultConstraintCreatedOn],
	[dc].[modify_date] AS [DefaultConstraintLastModifiedOn],
	[dc].[is_system_named] AS [DefaultConstraintIsSystemNamed],
	/* Check constraint information */
	CASE
		WHEN [cteCCI].[ParentColumnId] IS NOT NULL
			THEN CAST(1 AS bit)
		WHEN [cteCCI].[ParentColumnId] IS NULL
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [HasCheckConstraint],
	[cteCCI].[CheckConstraints],
	/* Identity column information */
	[ac].[is_identity] AS [IsIdentity],
	[ic].[seed_value] AS [IdentityColumnSeedValue],
	[ic].[increment_value] AS [IdentityColumnIncrementValue],
	[ic].[last_value] AS [IdentityColumnLastValue],
	[ic].[is_not_for_replication] AS [IdentityColumnIsNotForReplication],
	/* Computed column information */
	[ac].[is_computed] AS [IsComputed],
	[cc].[definition] AS [ComputedColumnDefinition],
	[cc].[uses_database_collation] AS [ComputedColumnUsesDatabaseCollation],
	[cc].[is_persisted] AS [ComputedColumnIsPersisted],
	/* Masked column information */
	[ac].[is_masked] AS [IsMasked],
	[mc].[masking_function] AS [MaskingFunction],
	/* Period information */
	CASE
		WHEN [pst].[start_column_id] IS NOT NULL 
			THEN CAST(1 AS bit)
		WHEN [pst].[start_column_id] IS NULL 
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsPeriodStartColumn],
	CASE
		WHEN [pst].[end_column_id] IS NOT NULL 
			THEN CAST(1 AS bit)
		WHEN [pst].[end_column_id] IS NULL 
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsPeriodEndColumn],
	CASE
		WHEN [pst].[start_column_id] IS NOT NULL 
			THEN [pst].[name]
		WHEN [ped].[end_column_id] IS NOT NULL 
			THEN [ped].[name]
		ELSE
			NULL
	END AS [PeriodName],
	CASE
		WHEN [pst].[start_column_id] IS NOT NULL 
			THEN [pst].[period_type_desc]
		WHEN [ped].[end_column_id] IS NOT NULL 
			THEN [ped].[period_type_desc]
		ELSE
			NULL
	END AS [PeriodType],
	/* CLR-Table valued function order columns */
	CASE
		WHEN [foc].[column_id] IS NOT NULL
			THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [IsCLRTableValuedFunctionOrderColumn],
	[foc].[order_column_id] AS [CLRTableValuedFunctionColumnOrderId],
	CASE
		WHEN [foc].[is_descending] = 1
			THEN N'DESC'
		WHEN [foc].[is_descending] = 0
			THEN N'ASC'
		ELSE
			NULL
	END AS [CLRTableValuedFunctionColumnSortDirection],
	/* Other information */
	[ac].[is_nullable] AS [IsNullable],
	[ac].[is_ansi_padded] AS [IsAnsiPadded],
	[ac].[is_rowguidcol] AS [IsRowguidcol],
	[ac].[is_filestream] AS [IsFilestream],
	[ac].[is_replicated] AS [IsReplicated],
	[ac].[is_non_sql_subscribed] AS [IsNonSQLSubscribed],
	[ac].[is_merge_published] AS [IsMergePublished],
	[ac].[is_dts_replicated] AS [IsDTSReplicated],
	[ac].[is_xml_document] AS [IsXMLDocument],
	[ac].[is_sparse] AS [IsSparse],
	[ac].[is_column_set] AS [IsColumnSet],
	[ac].[is_hidden] AS [IsHidden],
	[ac].[is_data_deletion_filter_column] AS [IsDataDeletionFilterColumn],
	[ac].[is_dropped_ledger_column] AS [IsDroppedLedgerColumn],
	CASE
		WHEN [ao].[type] = N'U'
			THEN CAST(1 AS bit)
		WHEN [ao].[type] <> N'U'
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsTableColumn],
	CASE
		WHEN [ao].[type] = N'V'
			THEN CAST(1 AS bit)
		WHEN [ao].[type] <> N'V'
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsViewColumn],
	CASE
		WHEN [sc].[column_id] IS NOT NULL 
			THEN CAST(1 AS bit)
		WHEN [sc].[column_id] IS NULL 
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsSystemColumn],
	CASE  -- Only for user defined tables
		WHEN [t].[max_column_id_used] IS NOT NULL 
			THEN CAST(1 AS bit)
		ELSE
			NULL -- Information not available
	END AS [IsColumnIdEqualToMaxColumnIdUsed],
	CASE 
		WHEN [esc].[column_id] IS NOT NULL 
			THEN CAST(1 AS bit)
		WHEN [esc].[column_id] IS NULL 
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsExternalStreamColumn],
	CASE 
		WHEN [etc].[column_id] IS NOT NULL 
			THEN CAST(1 AS bit)
		WHEN [etc].[column_id] IS NULL 
			THEN CAST(0 AS bit)
		ELSE
			NULL
	END AS [IsExternalTableColumn]
FROM
	[sys].[all_columns] [ac]
LEFT JOIN
	[cteColumnDataTypeInformation] [cteCDTI] ON [ac].[object_id] = [cteCDTI].[ObjectId] AND [ac].[column_id] = [cteCDTI].[ColumnId]
LEFT JOIN
	[sys].[all_objects] [ao] ON [ac].[object_id] = [ao].[object_id] 
LEFT JOIN
	[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [ac].[object_id] = [ep].[major_id] AND [ac].[column_id] = [ep].[minor_id] AND [ep].[class] = 1 AND [ep].[name] = N'MS_Description'
LEFT JOIN
	[ctePrimaryKeyInformation] [ctePKI] ON [ac].[object_id] = [ctePKI].[ObjectId] AND [ac].[column_id] = [ctePKI].[ColumnId]
LEFT JOIN
	[cteUniqueConstraintInformation] [cteUCI] ON [ac].[object_id] = [cteUCI].[ObjectId] AND [ac].[column_id] = [cteUCI].[ColumnId]
LEFT JOIN
	[sys].[default_constraints] [dc] ON [ac].[object_id] = [dc].[parent_object_id] AND [ac].[column_id] = [dc].[parent_column_id]
LEFT JOIN
	[cteCheckConstraintInformation] [cteCCI] ON [ac].[object_id] = [cteCCI].[ParentObjectId] AND [ac].[column_id] = [cteCCI].[ParentColumnId]
LEFT JOIN
	[sys].[identity_columns] [ic] ON [ac].[object_id] = [ic].[object_id] AND [ac].[column_id] = [ic].[column_id]
LEFT JOIN
	[sys].[computed_columns] [cc] ON [ac].[object_id] = [cc].[object_id] AND [ac].[column_id] = [cc].[column_id]
LEFT JOIN
	[sys].[masked_columns] [mc] ON [ac].[object_id] = [mc].[object_id] AND [ac].[column_id] = [mc].[column_id]
LEFT JOIN
	[sys].[periods] [pst] ON [ac].[object_id] = [pst].[object_id] AND [ac].[column_id] = [pst].[start_column_id]
LEFT JOIN
	[sys].[periods] [ped] ON [ac].[object_id] = [ped].[object_id] AND [ac].[column_id] = [ped].[end_column_id]
LEFT JOIN
	[sys].[function_order_columns] [foc] ON [ac].[object_id] = [foc].[object_id] AND [ac].[column_id] = [foc].[column_id]
LEFT JOIN
	[sys].[system_columns] [sc] ON [ac].[object_id] = [sc].[object_id] AND [ac].[column_id] = [sc].[column_id]
LEFT JOIN
	[sys].[tables] [t] ON [ac].[object_id] = [t].[object_id] AND [ac].[column_id] = [t].[max_column_id_used]
LEFT JOIN
	[sys].[external_stream_columns] [esc] ON [ac].[object_id] = [esc].[object_id] AND [ac].[column_id] = [esc].[column_id]
LEFT JOIN
	[sys].[external_table_columns] [etc] ON [ac].[object_id] = [etc].[object_id] AND [ac].[column_id] = [etc].[column_id]
WHERE
--	[ao].[type] IN (N'ET', N'U', N'V')
--AND
	[ao].[is_ms_shipped] = 0
ORDER BY
	[s].[name] ASC, 
	[ao].[name] ASC, 
	[ac].[column_id];