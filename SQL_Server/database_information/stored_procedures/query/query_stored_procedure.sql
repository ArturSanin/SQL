USE [DatabaseName];
GO

WITH [cteProcedureParameters] AS (
	SELECT
		[ap].[object_id] AS [ObjectID],
		COUNT(*) AS [ParameterCount],
		STRING_AGG(CAST([ap].[name] AS nvarchar(max)) + ' ' + '(' + CAST([ap].[parameter_id] AS nvarchar) + ', ' + CASE WHEN [t].[system_type_id] <> [t].[user_type_id] THEN [t].[name] + '(' + [t2].[name] + ')' ELSE [t].[name] END + ', ' + CASE WHEN [ap].[is_output] = 0 THEN 'Input' ELSE 'Input/Output' END + ', ' + CASE WHEN [ap].[has_default_value] = 0 THEN 'No default' ELSE CAST([ap].[default_value] AS nvarchar(128)) END + ', ' + CASE WHEN [ap].[is_nullable] = 1 THEN 'Null' ELSE 'Not null' END + ')', ', ') AS [Parameters]
	FROM 
		[sys].[all_parameters] [ap]
	LEFT JOIN	
		[sys].[types] [t] ON [ap].[user_type_id] = [t].[user_type_id]
	LEFT JOIN	
		[sys].[types] [t2] ON [t].[system_type_id] = [t2].[user_type_id]
	GROUP BY 
		[object_id]
),

[cteDependencies] AS (
	SELECT
		[sed].[referencing_id] AS [ReferencingID],
		COUNT(DISTINCT [sed].[referenced_schema_name]) AS [ReferencedSchemasCount],
		(SELECT STRING_AGG(CAST([DV].[referenced_schema_name] AS nvarchar(max)), N', ') WITHIN GROUP (ORDER BY [DV].[referenced_schema_name] ASC) FROM (SELECT DISTINCT [referenced_schema_name] FROM [sys].[sql_expression_dependencies] [sed2] WHERE [sed].[referencing_id] = [sed2].[referencing_id]) DV) AS [ReferencedSchemas],
		SUM(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'IT', N'S', N'U') THEN 1 ELSE 0 END) AS [ReferencedTablesCount],
		STRING_AGG(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'IT', N'S', N'U') THEN CAST([sed].[referenced_schema_name] + N'.' + [sed].[referenced_entity_name] AS nvarchar(max)) ELSE NULL END, N', ') WITHIN GROUP (ORDER BY [sed].[referenced_schema_name] ASC) AS [ReferencedTables],
		SUM(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'V') THEN 1 ELSE 0 END) AS [ReferencedViewsCount],
		STRING_AGG(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'V') THEN CAST([sed].[referenced_schema_name] + N'.' + [sed].[referenced_entity_name] AS nvarchar(max)) ELSE NULL END, N', ') WITHIN GROUP (ORDER BY [sed].[referenced_schema_name] ASC) AS [ReferencedViews],
		SUM(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'P', N'PC', N'X') THEN 1 ELSE 0 END) AS [ReferencedProceduresCount],
		STRING_AGG(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'P', N'PC', N'X') THEN CAST([sed].[referenced_schema_name] + N'.' + [sed].[referenced_entity_name] AS nvarchar(max)) ELSE NULL END, N', ') WITHIN GROUP (ORDER BY [sed].[referenced_schema_name] ASC) AS [ReferencedProcedures],
		SUM(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'AF', N'FN', N'FS', N'IF', N'TF') THEN 1 ELSE 0 END) AS [ReferencedFunctionsCount],
		STRING_AGG(CASE WHEN [sed].[referenced_minor_id] = 0 AND [ao].[type] IN (N'AF', N'FN', N'FS', N'IF', N'TF') THEN CAST([sed].[referenced_schema_name] + N'.' + [sed].[referenced_entity_name] AS nvarchar(max)) ELSE NULL END, N', ') WITHIN GROUP (ORDER BY [sed].[referenced_schema_name] ASC) AS [ReferencedFunctions],
		SUM(CASE WHEN [sed].[referenced_minor_id] = 0 THEN 1 ELSE 0 END) AS [ReferencedObjectsCount],
		(SELECT STRING_AGG(CAST([DV].[QualifiedName] AS nvarchar(max)), N', ') WITHIN GROUP (ORDER BY [DV].[QualifiedName] ASC) FROM (SELECT DISTINCT [referenced_schema_name] + '.' + [referenced_entity_name] AS [QualifiedName] FROM [sys].[sql_expression_dependencies] [sed2] WHERE [sed2].[referenced_minor_id] = 0 AND [sed].[referencing_id] = [sed2].[referencing_id]) DV) AS [ReferencedObjects]
		--STRING_AGG(CASE WHEN [sed].[referenced_minor_id] = 0 THEN CAST([sed].[referenced_schema_name] + N'.' + [sed].[referenced_entity_name] AS nvarchar(max)) ELSE NULL END, N', ') WITHIN GROUP (ORDER BY [sed].[referenced_schema_name] ASC) AS [ReferencedObjects]
	FROM
		[sys].[sql_expression_dependencies] [sed] 
	LEFT JOIN	
		[sys].[all_objects] [ao] ON [sed].[referenced_id] = [ao].[object_id] 
	GROUP BY
		[sed].[referencing_id]
),

[cteTriggers] AS (
	SELECT
		[parent_id] AS [ParentID],
		COUNT(*) AS [ReferencingTriggersCount],
		STRING_AGG([name], ', ') AS [ReferencingTriggers]
	FROM
		[sys].[triggers]
	WHERE
		[parent_id] IN (
			SELECT
				[object_id]
			FROM
				[sys].[all_objects]
			WHERE
				[type] IN ('P', 'PC', 'X')
		)
	GROUP BY
		[parent_id]
)

SELECT
	[ao].[object_id] AS [ProcedureID],
	[s].[name] AS [ProcedureSchema],
	[ao].[name] AS [ProcedureName],
	[s].[name] + N'.' + [ao].[name] AS [ProcedureQualifiedName],
	CAST(
		CASE
			WHEN [ao].[type_desc] LIKE 'SQL%' THEN SUBSTRING([ao].[type_desc], 1, 3) + LOWER(REPLACE(SUBSTRING([ao].[type_desc], 4, LEN([ao].[type_desc])), '_', ' ')) 
			ELSE SUBSTRING([ao].[type_desc], 1, 1) + LOWER(REPLACE(SUBSTRING([ao].[type_desc], 2, LEN([ao].[type_desc])), '_', ' ')) 
		END AS nvarchar(60)
	) AS [ProcedureTyp],
	CASE
		WHEN [ao].[is_ms_shipped] = 0 THEN 'User-defined procedure'
		WHEN [ao].[is_ms_shipped] = 1 THEN 'System-defined procedure'
	END AS [ProcedureOrigin],
	USER_NAME(COALESCE([ao].[principal_id], [s].[principal_id])) AS [ProcedureOwner],
	[ao].[create_date] AS [ProcedureCreationDate],
	[ao].[modify_date] AS [ProcedureLastModifiedDate],
	COALESCE(CAST([ep].[value] AS nvarchar(MAX)), 'No description available') AS [ProcedureDescription],
	CASE
		WHEN [ao].[type] = 'P' THEN 'T-SQL'
		WHEN [ao].[type] = 'PC' THEN 'CLR'
		WHEN [ao].[type] = 'X' THEN 'Extended'
	END AS [ProcedureImplementation],
	COALESCE([ctePP].[ParameterCount], 0) AS [ParameterCount],
	COALESCE([ctePP].[Parameters], 'no parameters') AS [Parameters],
	COALESCE([asm].[definition], 'No definition available') AS [ProcedureDefinition],
	COALESCE(LEN([asm].[definition]), 0) AS [DefinitionSize],
	HASHBYTES('SHA2_256', REPLACE(REPLACE(REPLACE([asm].[definition], CHAR(13), ''), CHAR(10), ''), CHAR(9), '')) AS [DefinitionHash],
	COALESCE(DATALENGTH([asm].[definition]), 0) AS [ProcedureSizeBytes],
	[asm].[uses_ansi_nulls] AS [UsesAnsiNulls],
	[asm].[uses_quoted_identifier] AS [UsesQuotedIdentifier],
	[asm].[is_schema_bound] AS [IsSchemaBound],
	[asm].[uses_database_collation] AS [UsesDatabaseCollation],
	[asm].[is_recompiled] AS [IsRecompiled],
	[asm].[execute_as_principal_id] AS [ExecuteAsPrincipalID],
	[asm].[uses_native_compilation] AS [UsesNativeCompilation],
	[ao].[is_published] AS [IsPublished],
	[ao].[is_schema_published] AS [IsSchemaPublished],
	OBJECTPROPERTY([ao].[object_id], 'IsEncrypted') AS [IsEncrypted],
	COALESCE([cteD].[ReferencedSchemasCount], 0) AS [ReferencedSchemasCount],
	[cteD].[ReferencedSchemas],
	CASE
		WHEN COALESCE([cteD].[ReferencedTablesCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingTables],
	COALESCE([cteD].[ReferencedTablesCount], 0) AS [ReferencedTablesCount],
	[cteD].[ReferencedTables],
	CASE
		WHEN COALESCE([cteD].[ReferencedViewsCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingViews],
	COALESCE([cteD].[ReferencedViewsCount], 0) AS [ReferencedViewsCount],
	[cteD].[ReferencedViews],
	CASE
		WHEN COALESCE([cteD].[ReferencedProceduresCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingProcedures],
	COALESCE([cteD].[ReferencedProceduresCount], 0) AS [ReferencedProceduresCount],
	[cteD].[ReferencedProcedures],
	CASE
		WHEN COALESCE([cteD].[ReferencedFunctionsCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingFunctions],
	COALESCE([cteD].[ReferencedFunctionsCount], 0) AS [ReferencedFunctionsCount],
	[cteD].[ReferencedFunctions],
	COALESCE([cteD].[ReferencedObjectsCount], 0) AS [ReferencedObjectsCount],
	[cteD].[ReferencedObjects],
	[deps].[execution_count] AS [ExecutionCount],
	[deps].[last_execution_time] AS [LastExecutionTime],
	[deps].[total_elapsed_time] AS [TotalElapsedTime],
	-- [deps].[avg_elapsedTime] AS [AvgElapsedTime],
	[deps].[min_elapsed_time] AS [MinElapsedTime],
	[deps].[max_elapsed_time] AS [MaxElapsedTime],
	[deps].[total_logical_reads] AS [TotalLogicalReads],
	[deps].[total_logical_writes] AS [TotalLogicalWrites]  -- Total writes?
FROM
	[sys].[all_objects] [ao]
LEFT JOIN
	[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [ao].[object_id] = [ep].[major_id] AND [ep].[name] = 'MS_Description'
LEFT JOIN
	[cteProcedureParameters] [ctePP] ON [ao].[object_id] = [ctePP].[ObjectID] 
LEFT JOIN
	[sys].[all_sql_modules] [asm] ON [ao].[object_id] = [asm].[object_id]
LEFT JOIN
	[cteDependencies] [cteD] ON [ao].[object_id] = [cteD].[ReferencingID] 
LEFT JOIN
	[sys].[dm_exec_procedure_stats] [deps] ON [ao].[object_id] = [deps].[object_id] 
WHERE
	[ao].[type] IN (N'P', N'PC', N'X')
ORDER BY
	[s].[name] ASC, 
	[ao].[name] ASC;