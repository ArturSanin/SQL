USE [DatabaseName];
GO

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
INTO
	[DbInfo].[StoredProcedures]
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



EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comprehensive metadata overview of all stored procedures (T-SQL, CLR, and extended) in the database, including definitions, parameters, dependencies, usage of dynamic SQL, temporary tables, table variables, external resources, permissions, execution statistics, and other attributes such as schema binding, encryption, and ownership.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The object ID of the stored procedure in the database.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureID';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The schema to which the stored procedure belongs.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureSchema';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The name of the stored procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureName';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The fully qualified name of the procedure in the format SchemaName.ProcedureName.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureQualifiedName';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The type of procedure (e.g., SQL Stored Procedure, CLR Stored Procedure, Extended Stored Procedure).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureTyp';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'Specifies whether the procedure is user-defined or system-defined.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureOrigin';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The database principal that owns the stored procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureOwner';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The date and time when the stored procedure was created in the database.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureCreationDate';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The date and time when the stored procedure definition was last modified.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureLastModifiedDate';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The description of the stored procedure, if provided in extended properties.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureDescription';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'Indicates the implementation technology of the procedure (e.g., T-SQL, CLR, Extended).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureImplementation';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The total number of parameters defined for the stored procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ParameterCount';
GO

EXEC [sys].[sp_addextendedproperty]
    @Name = N'MS_Description',
    @value = N'The parameters in the stored procedure in the format @ParameterName(Parameter ID, Datatype, Input/Output, Default/No default, Null/Not null).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'Parameters';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Contains the full SQL definition text of the stored procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureDefinition';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A SHA-256 hash generated from the normalized procedure definition. Formatting whitespace is removed before hashing to produce a stable value.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'DefinitionHash';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of characters used in the stored procedure definition.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureDefinitionCharLength';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Approximate size of the stored procedure definition in bytes.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureDefinitionSizeBytes';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Heuristic flag indicating whether the procedure appears to use dynamic SQL. Accuracy is not guaranteed.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesDynamicSQL';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Heuristic flag indicating whether the procedure references table variables. Accuracy is not guaranteed.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesTableVariables';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Heuristic flag indicating whether the procedure references temporary tables. Accuracy is not guaranteed.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesTemporaryTables';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure appears to access external resources such as linked servers or OPENQUERY. May include false positives.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesExternalResources';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Specifies whether SET ANSI_NULLS was ON when the procedure was created.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesAnsiNulls';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether SET QUOTED_IDENTIFIER was ON when the procedure was created.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesQuotedIdentifier';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Specifies whether the procedure was created with WITH SCHEMABINDING.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'IsSchemaBound';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure explicitly uses the database collation for string operations.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesDatabaseCollation';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure was created with WITH RECOMPILE.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'IsRecompiled';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure is natively compiled (Hekaton / In-Memory OLTP).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'UsesNativeCompilation';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure is published for replication.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'IsPublished';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Specifies whether the schema associated with the procedure is published for replication.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'IsSchemaPublished';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure definition is encrypted. 1 = Encrypted, 0 = Not Encrypted, NULL = Encryption not supported.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'IsEncrypted';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The total number of distinct database schemas referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedSchemasCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comma-separated list of all distinct database schemas referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedSchemas';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure references at least one table (1 = Yes, 0 = No).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureReferencingTables';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of distinct tables referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedTablesCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comma-separated list of all tables referenced by the procedure, typically in schema-qualified form.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedTables';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure references at least one view (1 = Yes, 0 = No).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureReferencingViews';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of distinct views referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedViewsCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comma-separated list of all views referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedViews';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure calls or references other stored procedures (1 = Yes, 0 = No).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureReferencingProcedures';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of stored procedures called or referenced by this procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedProceduresCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comma-separated list of all procedures referenced by this procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedProcedures';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure calls or references any SQL functions (1 = Yes, 0 = No).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureReferencingFunctions';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of distinct functions referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedFunctionsCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A comma-separated list of all functions referenced by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedFunctions';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total number of all referenced objects (tables, views, procedures, functions) used by the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedObjectsCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'A unified comma-separated list of all referenced objects across all object types.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencedObjects';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Indicates whether the procedure is referenced or executed by one or more triggers.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedureReferencedByTriggers';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The number of triggers that reference or execute the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencingTriggersCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Comma-separated list of the names of triggers that reference or execute the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ReferencingTriggers';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'List of explicit permissions assigned to the procedure (e.g., GRANT EXECUTE), aggregated across all principals.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ProcedurePermissions';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Identifies the principal under which the procedure executes (EXECUTE AS clause). Defines the security context during execution.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ExecuteAsPrincipal';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The total number of times the stored procedure has been executed since the last restart or plan cache flush.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'ExecutionCount';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Timestamp of the most recent execution of the procedure. Updated whenever the cached plan is used.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'LastExecutionTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total cumulative CPU time (in microseconds) consumed by all executions of the procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'TotalCPUTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The average CPU time per execution, computed as TotalCPUTime / ExecutionCount.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'AverageCPUTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'Total cumulative elapsed time (in microseconds) for all executions of the stored procedure.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'TotalElapsedTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The average elapsed time (in microseconds) per execution. Computed as TotalElapsedTime / ExecutionCount.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'AverageElapsedTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The shortest measured execution time of the stored procedure (in microseconds).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'MinElapsedTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The longest measured execution time of the stored procedure (in microseconds).',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'MaxElapsedTime';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The total number of logical reads (8-KB pages) performed by the procedure across all executions.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'TotalLogicalReads';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The average number of logical reads per execution, calculated as TotalLogicalReads / ExecutionCount.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'AverageLogicalReads';
GO

EXEC [sys].[sp_addextendedproperty] 
    @Name = N'MS_Description',
    @value = N'The cumulative number of logical write operations performed by the procedure across all executions.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'TABLE',  @level1name = N'StoredProcedures',
    @level2type = N'COLUMN', @level2name = N'TotalLogicalWrites';
GO