**Table description:** A comprehensive metadata overview of all stored procedures (T-SQL, CLR, and extended) in the database, including definitions, parameters, dependencies, usage of dynamic SQL, temporary tables, table variables, external resources, permissions, execution statistics, and other attributes such as schema binding, encryption, and ownership.

| Column Name | Data Type | Description |
| :----- | :----- | :----- |
| ProcedureID | int | The object ID of the stored procedure in the database. |
| ProcedureSchema | sysname(nvarchar(128)) | The schema to which the stored procedure belongs. |
| ProcedureName | sysname(nvarchar(128)) | The name of the stored procedure. | 
| ProcedureQualifiedName | nvarchar(257) | The fully qualified name of the procedure in the format SchemaName.ProcedureName. |
| ProcedureTyp | nvarchar(60) | The type of procedure (e.g., SQL Stored Procedure, CLR Stored Procedure, Extended Stored Procedure). |
| ProcedureOrigin | nvarchar(24) | Specifies whether the procedure is user-defined or system-defined. |
| ProcedureOwner | nvarchar(128) | The database principal that owns the stored procedure. |
| ProcedureCreationDate | datetime | The date and time when the stored procedure was created in the database. |
| ProcedureLastModifiedDate | datetime | The date and time when the stored procedure definition was last modified. |
| ProcedureDescription | nvarchar(max) | The description of the stored procedure, if provided in the extended properties. |
| ProcedureImplementation | varchar(8) | Indicates the implementation technology of the procedure (e.g., T-SQL, CLR, Extended). |
| ParameterCount | int | The total number of parameters defined for the stored procedure. |
| Parameters | nvarchar(max) | The parameters in the stored procedure in the format @ParameterName(Parameter ID, Datatype, Input/Output, Default/No default, Null/Not null). |
| ProcedureDefinition | nvarchar(max) | Contains the full SQL definition text of the stored procedure. |
| DefinitionHash | varbinary(8000) | A SHA-256 hash generated from the normalized procedure definition. Before hashing, line breaks (CR/LF), tabs, and other formatting whitespace are removed to ensure the hash remains stable even if the formatting changes. |
| ProcedureDefinitionCharLength | bigint | Total number of characters used in the definition of the stored procedure. |
| ProcedureDefinitionSizeBytes | bigint | Approximate size of the stored procedure’s definition measured in bytes, based on its text content. |
| UsesDynamicSQL | bit | Heuristic flag indicating whether the procedure appears to use dynamic SQL. This detection may not be fully accurate. |
| UsesTableVariables | bit | Heuristic flag indicating whether the procedure appears to reference table variables (e.g., declarations using @variable TABLE). This detection may not be fully accurate. |
| UsesTemporaryTables | bit | Heuristic flag indicating whether the procedure appears to reference temporary tables. This detection may not be fully accurate. |
| UsesExternalResources | bit | Heuristic flag indicating whether the procedure appears to access external resources (e.g., Linked Servers, OPENQUERY, OPENDATASOURCE). Detection is approximate and may include false positives. |
| UsesAnsiNulls | bit | Specifies whether the procedure was created with SET ANSI_NULLS ON. This determines how SQL Server handles comparisons involving NULL inside the procedure. |
| UsesQuotedIdentifier | bit | Indicates whether SET QUOTED_IDENTIFIER ON was active when the procedure was created. With this setting enabled, identifiers enclosed in double quotes are interpreted as object names rather than string literals. |
| IsSchemaBound | bit | Specifies whether the procedure was created using WITH SCHEMABINDING. When enabled, referenced objects (tables, views) cannot be altered in ways that would affect the procedure unless the procedure is dropped or altered first. |
| UsesDatabaseCollation | bit | Indicates whether the procedure explicitly references the database’s default collation rather than inheriting the server-level collation or using object-specific collations. This is relevant for string comparison behavior inside the procedure. |
| IsRecompiled | bit | Indicates whether the procedure was created with WITH RECOMPILE, forcing SQL Server to generate a new execution plan every time the procedure is executed. |
| UsesNativeCompilation | bit | Indicates whether the procedure is natively compiled (Hekaton). Native compilation is used for in-memory OLTP objects and provides significant performance improvements for certain workloads. |
| IsPublished | bit | Indicates whether the procedure has been included in replication. When set, the procedure participates in publication for replication subscribers. |
| IsSchemaPublished | bit | Specifies whether the schema associated with the procedure is published for replication. This controls whether the schema itself (not only the data or procedure content) is replicated to subscribers. |
| IsEncrypted | bit | 1 = Encrypted, 0 = Not Encrypted, NULL = Encryption not supported. |
| ReferencedSchemasCount | int | The total number of distinct database schemas that are referenced by the stored procedure. |
| ReferencedSchemas | nvarchar(max) | A comma-separated list of all distinct database schemas referenced by the stored procedure. Includes schemas of tables, views, functions, procedures, or other objects the procedure depends on. |
| ProcedureReferencingTables | bit | Indicates whether the procedure references at least one table (1 = yes, 0 = no). |
| ReferencedTablesCount | int | Total number of distinct tables referenced by the procedure. |
| ReferencedTables | nvarchar(max) | A comma-separated list of all tables referenced by the procedure, typically in schema-qualified form. |
| ProcedureReferencingViews | bit | Indicates whether the procedure references at least one view (1 = yes, 0 = no). |
| ReferencedViewsCount | int | Total number of distinct views referenced by the procedure. |
| ReferencedViews | nvarchar(max) | A comma-separated list of all views referenced by the procedure. |
| ProcedureReferencingProcedures | bit | Indicates whether the procedure calls or references other stored procedures (1 = yes, 0 = no). |
| ReferencedProceduresCount | int | Total number of stored procedures called or referenced by this procedure. |
| ReferencedProcedures | nvarchar(max) | A comma-separated list of all procedures referenced by this procedure. |
| ProcedureReferencingFunctions | bit | Indicates whether the procedure calls or references any SQL functions (1 = yes, 0 = no). |
| ReferencedFunctionsCount | int | Total number of distinct functions referenced by the procedure. |
| ReferencedFunctions | nvarchar(max) | A comma-separated list of all functions referenced by the procedure. |
| ReferencedObjectsCount | int | Total number of all referenced objects (tables, views, procedures, functions) used by the procedure. |
| ReferencedObjects | nvarchar(max) | A unified comma-separated list of all referenced objects across all object types |
| ProcedureReferencedByTriggers | bit | Indicates whether the procedure is referenced or executed by one or more triggers. |
| ReferencingTriggersCount | int | Indicates whether the procedure is referenced or executed by one or more triggers. |
| ReferencingTriggers | nvarchar(max) | Comma-separated list of the names of triggers that reference or execute the procedure. |
| ProcedurePermissions | nvarchar(max) | List of explicit permissions assigned to the procedure (e.g., GRANT EXECUTE), aggregated across all principals. |
| ExecuteAsPrincipal | nvarchar(140) | Identifies the principal (user, login, or role) under which the procedure executes. This corresponds to the EXECUTE AS clause and defines the security context used during execution. |
| ExecutionCount | bigint | The total number of times the stored procedure has been executed since the last server restart or the last plan cache flush. Indicates how frequently the procedure is used. |
| LastExecutionTime | datetime | The timestamp of the most recent execution of the stored procedure. This value is updated each time the cached plan is used. |
| TotalCPUTime | bigint | The cumulative CPU time (in microseconds) consumed by all executions of the procedure. |
| AverageCPUTime | decimal(18, 6) | The average CPU time per execution, calculated as: (TotalCPUTime / ExecutionCount). |
| TotalElapsedTime | bigint | The total cumulative elapsed time (in microseconds) for all executions of the stored procedure. |
| AverageElapsedTime | decimal(18, 6) | The average elapsed time (in microseconds) per execution. Calculated as: (TotalElapsedTime / ExecutionCount) Reflects typical performance. |
| MinElapsedTime | bigint | The shortest measured execution time of the stored procedure (in microseconds). |
| MaxElapsedTime | bigint | The longest measured execution time of the stored procedure (in microseconds). |
| TotalLogicalReads | bigint | The total number of logical reads (8-KB pages) performed across all executions. |
| AverageLogicalReads | decimal(18, 6) | The average number of logical reads per execution. Calculated as: (TotalLogicalReads / ExecutionCount). |
| TotalWrites | bigint | The cumulative number of logical write operations performed by the procedure across all executions. |