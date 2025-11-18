USE [DatabaseName];
GO

/*
	============================== Description ==============================
	This query summarizes various pieces of information in the database at the 
	schema level. 
*/

With [cteAggAllObjects] AS (
	SELECT
		[cao].[schema_id] AS [SchemaID],
		MAX([cao].[modify_date]) AS [SchemaObjectLastModificationDate],
		COUNT(*) AS [SchemaObjectCount],
		-- Objects of type 'AF'.
		SUM(CASE WHEN [cao].[type] = 'AF' THEN 1 ELSE 0 END) AS [AggregateFunctionCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'AF' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [AggregateFunctions],
		-- Objects of type 'C'.
		SUM(CASE WHEN [cao].[type] = 'C' THEN 1 ELSE 0 END) AS [CheckConstraintCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'C' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [CheckConstraints],
		-- Objects of type 'D'.
		SUM(CASE WHEN [cao].[type] = 'D' THEN 1 ELSE 0 END) AS [DefaultConstraintCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'D' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [DefaultConstraints],
		-- Objects of type 'F'.	
		SUM(CASE WHEN [cao].[type] = 'F' THEN 1 ELSE 0 END) AS [ForeignKeyConstraintCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'F' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [ForeignKeyConstraints],
		-- Objects of type 'FN'.
		SUM(CASE WHEN [cao].[type] = 'FN' THEN 1 ELSE 0 END) AS [SqlScalarFunctionCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'FN' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SqlScalarFunctions],
		-- Objects of type 'FS'.
		SUM(CASE WHEN [cao].[type] = 'FS' THEN 1 ELSE 0 END) AS [ClrScalarFunctionCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'FS' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [ClrScalarFunctions],
		-- Objects of type 'IF'.
		SUM(CASE WHEN [cao].[type] = 'IF' THEN 1 ELSE 0 END) AS [SqlInlineTableValuedFunctionCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'IF' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SqlInlineTableValuedFunctions],
		-- Objects of type 'IT'.
		SUM(CASE WHEN [cao].[type] = 'IT' THEN 1 ELSE 0 END) AS [InternalTableCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'IT' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [InternalTables],
		-- Objects of type 'P'.
		SUM(CASE WHEN [cao].[type] = 'P' THEN 1 ELSE 0 END) AS [SqlStoredProcedureCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'P' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SqlStoredProcedures],
		-- Objects of type 'PC'.
		SUM(CASE WHEN [cao].[type] = 'PC' THEN 1 ELSE 0 END) AS [ClrStoredProcedureCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'PC' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [ClrStoredProcedures],
		-- Objects of type 'PK'.
		SUM(CASE WHEN [cao].[type] = 'PK' THEN 1 ELSE 0 END) AS [PrimaryKeyConstraintCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'PK' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [PrimaryKeyConstraints],
		-- Objects of type 'S'.
		SUM(CASE WHEN [cao].[type] = 'S' THEN 1 ELSE 0 END) AS [SystemTableCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'S' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SystemTables],
		-- Objects of type 'SQ'.
		SUM(CASE WHEN [cao].[type] = 'SQ' THEN 1 ELSE 0 END) AS [ServiceQueueCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'SQ' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [ServiceQueues],
		-- Objects of type 'TF'.
		SUM(CASE WHEN [cao].[type] = 'TF' THEN 1 ELSE 0 END) AS [SqlTableValuedFunctionCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'TF' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SqlTableValuedFunctions],
		-- Objects of type 'TR'.
		SUM(CASE WHEN [cao].[type] = 'TR' THEN 1 ELSE 0 END) AS [SqlTriggerCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'TR' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [SqlTriggers],
		-- Objects of type 'U'.
		SUM(CASE WHEN [cao].[type] = 'U' THEN 1 ELSE 0 END) AS [UserTableCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'U' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [UserTables],
		-- Objects of type 'UQ'.
		SUM(CASE WHEN [cao].[type] = 'UQ' THEN 1 ELSE 0 END) AS [UniqueConstraintCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'UQ' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [UniqueConstraints],
		-- Objects of type 'V'.
		SUM(CASE WHEN [cao].[type] = 'V' THEN 1 ELSE 0 END) AS [ViewCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'V' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [Views],
		-- Objects of type 'X'.
		SUM(CASE WHEN [cao].[type] = 'X' THEN 1 ELSE 0 END) AS [ExtendedStoredProcedureCount],
		STRING_AGG(CASE WHEN [cao].[type] = 'X' THEN CAST([cao].[name] AS varchar(MAX)) ELSE NULL END, ', ') WITHIN GROUP (ORDER BY [cao].[name] ASC) AS [ExtendedStoredProcedures]
	FROM
		[sys].[all_objects] [cao]
	GROUP BY
		[cao].[schema_id]
)

SELECT
	[s].[schema_id] AS [SchemaID],
	[s].[name] AS [SchemaName],
	COALESCE([ep].[value], 'No description available')  AS [SchemaDescription],
	CASE
		WHEN [s].[schema_id] <= 4 THEN 'System Schema'
		WHEN [s].[schema_id] >= 10000 THEN 'Internal Schema'
		WHEN [s].[schema_id] BETWEEN 5 AND 9999 THEN 'User Schema'
		ELSE NULL
	END AS [SchemaTyp],
	CASE
		WHEN [s].[schema_id] = [s].[principal_id] THEN 'exact'
		ELSE 'approximate'
	END AS [SchemaCreationDateType],
	CASE
		WHEN [s].[schema_id] = [s].[principal_id] THEN (SELECT [d].[create_date] FROM [sys].[databases] [d] WHERE [d].[database_id] = DB_ID())
		WHEN [s].[schema_id] <> [s].[principal_id] THEN (SELECT MIN([ao].[create_date]) FROM [sys].[all_objects] [ao] WHERE [ao].[schema_id] = [s].[schema_id])
		ELSE NULL
	END AS [SchemaCreationDate],
	[dp].[name] AS [SchemaOwner],
	[s].[principal_id] AS [SchemaOwnerID],
	[cteAAO].[SchemaObjectLastModificationDate],
	(SELECT COALESCE(STRING_AGG(CAST([ao].[name] AS varchar(MAX)), ', ') WITHIN GROUP (ORDER BY [ao].[name] ASC), '') FROM [sys].[all_objects] [ao] WHERE [ao].[schema_id] = [s].[schema_id] AND [ao].[modify_date] = (SELECT MAX([aob].[modify_date]) FROM [sys].[all_objects] [aob] WHERE [aob].[schema_id] = [s].[schema_id])) AS [LastModifiedObjects],
	COALESCE([cteAAO].[SchemaObjectCount], 0) AS [SchemaObjectCount],
	CASE
		WHEN COALESCE([cteAAO].[AggregateFunctionCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasAggregateFunctions],
	COALESCE([cteAAO].[AggregateFunctionCount], 0) AS [AggregateFunctionCount],
	COALESCE([cteAAO].[AggregateFunctions], '') AS [AggregateFunctions],
	CASE
		WHEN COALESCE([cteAAO].[CheckConstraintCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasCheckConstraints],
	COALESCE([cteAAO].[CheckConstraintCount], 0) AS [CheckConstraintsCount],
	COALESCE([cteAAO].[CheckConstraints], '') AS [CheckConstraints],
	CASE
		WHEN COALESCE([cteAAO].[DefaultConstraintCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasDefaultConstraints],
	COALESCE([cteAAO].[DefaultConstraintCount], 0) AS [DefaultConstraintCount],
	COALESCE([cteAAO].[DefaultConstraints], '') AS [DefaultConstraints],
	CASE
		WHEN COALESCE([cteAAO].[ForeignKeyConstraintCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasForeignKeyConstraint],
	COALESCE([cteAAO].[ForeignKeyConstraintCount], 0) AS [ForeignKeyConstraintCount],
	COALESCE([cteAAO].[ForeignKeyConstraints], '') AS [ForeignKeyConstraints],
	CASE
		WHEN COALESCE([cteAAO].[SqlScalarFunctionCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSqlScalarFunctions],
	COALESCE([cteAAO].[SqlScalarFunctionCount], 0) AS [SqlScalarFunctionCount],
	COALESCE([cteAAO].[SqlScalarFunctions], '') AS [SqlScalarFunctions],
	CASE
		WHEN COALESCE([cteAAO].[ClrScalarFunctionCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasClrScalarFunctions],
	COALESCE([cteAAO].[ClrScalarFunctionCount], 0) AS [ClrScalarFunctionCount],
	COALESCE([cteAAO].[ClrScalarFunctions], '') AS [ClrScalarFunctions],
	CASE
		WHEN COALESCE([cteAAO].[SqlInlineTableValuedFunctionCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSqlInlineTableValuedFunctions],
	COALESCE([cteAAO].[SqlInlineTableValuedFunctionCount], 0) AS [SqlInlineTableValuedFunctionCount],
	COALESCE([cteAAO].[SqlInlineTableValuedFunctions], '') AS [SqlInlineTableValuedFunctions],
	CASE
		WHEN COALESCE([cteAAO].[InternalTableCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasInternalTables],
	COALESCE([cteAAO].[InternalTableCount], 0) AS [InternalTableCount],
	COALESCE([cteAAO].[InternalTables], '') AS [InternalTables],
	CASE
		WHEN COALESCE([cteAAO].[SqlStoredProcedureCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSqlStoredProcedures],
	COALESCE([cteAAO].[SqlStoredProcedureCount], 0) AS [SqlStoredProcedureCount],
	COALESCE([cteAAO].[SqlStoredProcedures], '') AS [SqlStoredProcedures],
	CASE
		WHEN COALESCE([cteAAO].[ClrStoredProcedureCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasClrStoredProcedures],
	COALESCE([cteAAO].[ClrStoredProcedureCount], 0) AS [ClrStoredProcedureCount],
	COALESCE([cteAAO].[ClrStoredProcedures], '') AS [ClrStoredProcedures],
	CASE
		WHEN COALESCE([cteAAO].[PrimaryKeyConstraintCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasPrimaryKeyConstraint],
	COALESCE([cteAAO].[PrimaryKeyConstraintCount], 0) AS [PrimaryKeyConstraintCount],
	COALESCE([cteAAO].[PrimaryKeyConstraints], '') AS [PrimaryKeyConstraints],
	CASE
		WHEN COALESCE([cteAAO].[SystemTableCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSystemTables],
	COALESCE([cteAAO].[SystemTableCount], 0) AS [SystemTableCount],
	COALESCE([cteAAO].[SystemTables], '') AS [SystemTables],
	CASE
		WHEN COALESCE([cteAAO].[ServiceQueueCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasServiceQueues],
	COALESCE([cteAAO].[ServiceQueueCount], 0) AS [ServiceQueueCount],
	COALESCE([cteAAO].[ServiceQueues], '') AS [ServiceQueues],
	CASE
		WHEN COALESCE([cteAAO].[SqlTableValuedFunctionCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSqlTableValuedFunction],
	COALESCE([cteAAO].[SqlTableValuedFunctionCount], 0) AS [SqlTableValuedFunctionCount],
	COALESCE([cteAAO].[SqlTableValuedFunctions], '') AS [SqlTableValuedFunctions],
	CASE
		WHEN COALESCE([cteAAO].[SqlTriggerCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasSqlTriggers],
	COALESCE([cteAAO].[SqlTriggerCount], 0) AS [SqlTriggerCount],
	COALESCE([cteAAO].[SqlTriggers], '') AS [SqlTriggers],
	CASE
		WHEN COALESCE([cteAAO].[UserTableCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasUserTables],
	COALESCE([cteAAO].[UserTableCount], 0) AS [UserTableCount],
	COALESCE([cteAAO].[UserTables], '') AS [UserTables],
	CASE
		WHEN COALESCE([cteAAO].[UniqueConstraintCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasUniqueConstraints],
	COALESCE([cteAAO].[UniqueConstraintCount], 0) AS [UniqueConstraintCount],
	COALESCE([cteAAO].[UniqueConstraints], '') AS [UniqueConstraints],
	CASE
		WHEN COALESCE([cteAAO].[ViewCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasViews],
	COALESCE([cteAAO].[ViewCount], 0) AS [ViewCount],
	COALESCE([cteAAO].[Views], '') AS [Views],
	CASE
		WHEN COALESCE([cteAAO].[ExtendedStoredProcedureCount], 0) > 0 THEN CAST(1 AS bit)
		ELSE CAST(0 AS bit)
	END AS [HasExtendedStoredProcedures],
	COALESCE([cteAAO].[ExtendedStoredProcedureCount], 0) AS [ExtendedStoredProcedureCount],
	COALESCE([cteAAO].[ExtendedStoredProcedures], '') AS [ExtendedStoredProcedures]
FROM
	[sys].[schemas] [s]
LEFT JOIN
	[sys].[database_principals] [dp] ON [s].[principal_id] = [dp].[principal_id]
LEFT JOIN
	[sys].[extended_properties] [ep] ON [s].[schema_id] = [ep].[major_id] AND [ep].[class_desc] = 'SCHEMA'
LEFT JOIN
	[cteAggAllObjects] [cteAAO] ON [s].[schema_id] = [cteAAO].[SchemaID]
ORDER BY
	[s].[schema_id];