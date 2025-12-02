USE [DatabaseName];
GO

CREATE VIEW [DbInfo].[vStoredProcedures]
AS
WITH [cteProcedureParameters] AS (
	SELECT
		[ap].[object_id] AS [ObjectID],
		COUNT(*) AS [ParameterCount],
		STRING_AGG(CAST([ap].[name] AS nvarchar(max)) + N' ' + N'(' + CAST([ap].[parameter_id] AS nvarchar) + N', ' + CASE WHEN [t].[system_type_id] <> [t].[user_type_id] THEN [t].[name] + N'(' + [t2].[name] + N')' ELSE [t].[name] END + N', ' + CASE WHEN [ap].[is_output] = 0 THEN N'Input' ELSE N'Input/Output' END + N', ' + CASE WHEN [ap].[has_default_value] = 0 THEN N'No default' ELSE CAST([ap].[default_value] AS nvarchar(128)) END + N', ' + CASE WHEN [ap].[is_nullable] = 1 THEN N'Null' ELSE N'Not null' END + N')', N', ') AS [Parameters]
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
		(SELECT COUNT(*) FROM (SELECT DISTINCT [referenced_schema_name] + N'.' + [referenced_entity_name] AS [QualifiedName] FROM [sys].[sql_expression_dependencies] [sed2] WHERE [sed2].[referenced_minor_id] = 0 AND [sed].[referencing_id] = [sed2].[referencing_id]) DV) AS [ReferencedObjectsCount],
		(SELECT STRING_AGG(CAST([DV].[QualifiedName] AS nvarchar(max)), N', ') WITHIN GROUP (ORDER BY [DV].[QualifiedName] ASC) FROM (SELECT DISTINCT [referenced_schema_name] + N'.' + [referenced_entity_name] AS [QualifiedName] FROM [sys].[sql_expression_dependencies] [sed2] WHERE [sed2].[referenced_minor_id] = 0 AND [sed].[referencing_id] = [sed2].[referencing_id]) DV) AS [ReferencedObjects]
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
		STRING_AGG(CAST([name] AS nvarchar(max)), N', ') AS [ReferencingTriggers]
	FROM
		[sys].[triggers]
	WHERE
		[parent_id] IN (
			SELECT
				[object_id]
			FROM
				[sys].[all_objects]
			WHERE
				[type] IN (N'P', N'PC', N'X')
		)
	GROUP BY
		[parent_id]
),

[cteProcedurePermissions] AS (
	SELECT
		[dp].[major_id] AS [MajorID],
		STRING_AGG(CAST(USER_NAME([dp].[grantor_principal_id]) AS nvarchar(max)) + N' ' + [dp].[state_desc] + N' ' + [dp].[permission_name] + N' to ' + USER_NAME([dp].[grantee_principal_id]), N', ') AS [ProcedurePermissions]
	FROM
		[sys].[database_permissions] [dp]
	LEFT JOIN
		[sys].[all_objects] [ao] ON [dp].[major_id] = [ao].[object_id]
	WHERE
		[dp].[minor_id] = 0
	AND
		[ao].[type] IN (N'P', N'PC', N'X')
	GROUP BY
		[dp].[major_id]
)

SELECT
	[ao].[object_id] AS [ProcedureID],
	[s].[name] AS [ProcedureSchema],
	[ao].[name] AS [ProcedureName],
	[s].[name] + N'.' + [ao].[name] AS [ProcedureQualifiedName],
	CAST(
		CASE
			WHEN [ao].[type_desc] LIKE N'SQL%' THEN SUBSTRING([ao].[type_desc], 1, 3) + LOWER(REPLACE(SUBSTRING([ao].[type_desc], 4, LEN([ao].[type_desc])), N'_', N' ')) 
			ELSE SUBSTRING([ao].[type_desc], 1, 1) + LOWER(REPLACE(SUBSTRING([ao].[type_desc], 2, LEN([ao].[type_desc])), N'_', N' ')) 
		END AS nvarchar(60)
	) AS [ProcedureTyp],
	CASE
		WHEN [ao].[is_ms_shipped] = 0 THEN N'User-defined procedure'
		WHEN [ao].[is_ms_shipped] = 1 THEN N'System-defined procedure'
	END AS [ProcedureOrigin],
	USER_NAME(COALESCE([ao].[principal_id], [s].[principal_id])) AS [ProcedureOwner],
	[ao].[create_date] AS [ProcedureCreationDate],
	[ao].[modify_date] AS [ProcedureLastModifiedDate],
	COALESCE(CAST([ep].[value] AS nvarchar(MAX)), N'No description available') AS [ProcedureDescription],
	CASE
		WHEN [ao].[type] = N'P' THEN N'T-SQL'
		WHEN [ao].[type] = N'PC' THEN N'CLR'
		WHEN [ao].[type] = N'X' THEN N'Extended'
	END AS [ProcedureImplementation],
	COALESCE([ctePP].[ParameterCount], 0) AS [ParameterCount],
	COALESCE([ctePP].[Parameters], N'No parameters') AS [Parameters],
	COALESCE([asm].[definition], N'No definition available') AS [ProcedureDefinition],
	HASHBYTES(N'SHA2_256', REPLACE(REPLACE(REPLACE([asm].[definition], CHAR(13), N''), CHAR(10), N''), CHAR(9), N'')) AS [DefinitionHash],
	COALESCE(LEN([asm].[definition]), 0) AS [ProcedureDefinitionCharLength],
	COALESCE(DATALENGTH([asm].[definition]), 0) AS [ProcedureDefinitionSizeBytes],
	CASE
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%sp_sqlexec%' THEN CAST(1 AS bit)
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%sp_executesql%' THEN CAST(1 AS bit)
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%exec(%' THEN CAST(1 AS bit)
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%execute(%' THEN CAST(1 AS bit)
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%execute(''%' THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [UsesDynamicSQL],
	CASE
		WHEN LOWER(REPLACE(REPLACE(REPLACE([asm].[definition], N' ', N''), char(13), N''), char(10), N'')) LIKE N'%declare%@%table%(%insertinto@%' THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [UsesTableVariables],
	CASE
		WHEN LOWER([asm].[definition]) LIKE N'%create table #%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%insert into #%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%select % into #%' THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [UsesTemporaryTables],
	CASE
		WHEN LOWER([asm].[definition]) LIKE N'%openquery%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%opendatasource%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%openrowset%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%http%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%bulk%' THEN CAST(1 AS bit)
		WHEN LOWER([asm].[definition]) LIKE N'%url%' THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [UsesExternalResources],
	[asm].[uses_ansi_nulls] AS [UsesAnsiNulls],
	[asm].[uses_quoted_identifier] AS [UsesQuotedIdentifier],
	[asm].[is_schema_bound] AS [IsSchemaBound],
	[asm].[uses_database_collation] AS [UsesDatabaseCollation],
	[asm].[is_recompiled] AS [IsRecompiled],
	[asm].[uses_native_compilation] AS [UsesNativeCompilation],
	[ao].[is_published] AS [IsPublished],
	[ao].[is_schema_published] AS [IsSchemaPublished],
	OBJECTPROPERTY([ao].[object_id], N'IsEncrypted') AS [IsEncrypted],
	COALESCE([cteD].[ReferencedSchemasCount], 0) AS [ReferencedSchemasCount],
	COALESCE([cteD].[ReferencedSchemas], N'No referenced schemas') AS [ReferencedSchemas],
	CASE
		WHEN COALESCE([cteD].[ReferencedTablesCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingTables],
	COALESCE([cteD].[ReferencedTablesCount], 0) AS [ReferencedTablesCount],
	COALESCE([cteD].[ReferencedTables], N'No referenced tables') AS [ReferencedTables],
	CASE
		WHEN COALESCE([cteD].[ReferencedViewsCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingViews],
	COALESCE([cteD].[ReferencedViewsCount], 0) AS [ReferencedViewsCount],
	COALESCE([cteD].[ReferencedViews], N'No views referenced') AS [ReferencedViews],
	CASE
		WHEN COALESCE([cteD].[ReferencedProceduresCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingProcedures],
	COALESCE([cteD].[ReferencedProceduresCount], 0) AS [ReferencedProceduresCount],
	COALESCE([cteD].[ReferencedProcedures], N'No procedures referenced') AS [ReferencedProcedures],
	CASE
		WHEN COALESCE([cteD].[ReferencedFunctionsCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencingFunctions],
	COALESCE([cteD].[ReferencedFunctionsCount], 0) AS [ReferencedFunctionsCount],
	COALESCE([cteD].[ReferencedFunctions], N'No functions referenced') AS [ReferencedFunctions],
	COALESCE([cteD].[ReferencedObjectsCount], 0) AS [ReferencedObjectsCount],
	COALESCE([cteD].[ReferencedObjects], N'No objects referenced') AS [ReferencedObjects],
	CASE
		WHEN COALESCE([cteT].[ReferencingTriggersCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [ProcedureReferencedByTriggers],
	COALESCE([cteT].[ReferencingTriggersCount], 0) AS [ReferencingTriggersCount],
	COALESCE([cteT].[ReferencingTriggers], N'No referencing triggers') AS [ReferencingTriggers],
	[cteProcP].[ProcedurePermissions],
	CASE
		WHEN [asm].[execute_as_principal_id] IS NULL THEN N'CALLER'
		WHEN [asm].[execute_as_principal_id] = 0 THEN N'SELF'
		WHEN [asm].[execute_as_principal_id] = 1 THEN N'OWNER'
		WHEN [asm].[execute_as_principal_id] > 1 THEN N'LOGIN/USER: ' + USER_NAME([asm].[execute_as_principal_id])
	END AS [ExecuteAsPrincipal],
	[deps].[execution_count] AS [ExecutionCount],
	[deps].[last_execution_time] AS [LastExecutionTime],
	[deps].[total_worker_time] AS [TotalCPUTime],
	CAST(1.0 * [deps].[total_worker_time] / NULLIF([deps].[execution_count], 0) AS decimal(18, 6)) AS [AverageCPUTime],
	[deps].[total_elapsed_time] AS [TotalElapsedTime],
	CAST(1.0 * [deps].[total_elapsed_time] / NULLIF([deps].[execution_count], 0) AS decimal(18, 6)) AS [AverageElapsedTime],
	[deps].[min_elapsed_time] AS [MinElapsedTime],
	[deps].[max_elapsed_time] AS [MaxElapsedTime],
	[deps].[total_logical_reads] AS [TotalLogicalReads],
	CAST(1.0 * [deps].[total_logical_reads] / NULLIF([deps].[execution_count], 0) AS decimal(18, 6)) AS [AverageLogicalReads],
	[deps].[total_logical_writes] AS [TotalLogicalWrites]
FROM
	[sys].[all_objects] [ao]
LEFT JOIN
	[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [ao].[object_id] = [ep].[major_id] AND [ep].[name] = N'MS_Description'
LEFT JOIN
	[cteProcedureParameters] [ctePP] ON [ao].[object_id] = [ctePP].[ObjectID] 
LEFT JOIN
	[sys].[all_sql_modules] [asm] ON [ao].[object_id] = [asm].[object_id]
LEFT JOIN
	[cteDependencies] [cteD] ON [ao].[object_id] = [cteD].[ReferencingID] 
LEFT JOIN
	[cteTriggers] [cteT] ON [ao].[object_id] = [cteT].[ParentID]
LEFT JOIN
	[cteProcedurePermissions] [cteProcP] ON [ao].[object_id] = [cteProcP].[MajorID]
LEFT JOIN
	[sys].[dm_exec_procedure_stats] [deps] ON [ao].[object_id] = [deps].[object_id] 
WHERE
	[ao].[type] IN (N'P', N'PC', N'X');
GO