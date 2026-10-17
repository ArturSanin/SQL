USE [DatabaseName];
GO

CREATE VIEW [DbInfo].[vObjectDefinitions]
AS
WITH [cteObjectDefinitions] AS (
	SELECT
		[sqlm].[object_id] AS [ObjectId],
		SCHEMA_NAME([o].[schema_id]) [ObjectSchema],
		[o].[name] AS [ObjectName],
		[o].[type_desc] AS [ObjectType],
		[sqlm].[definition] AS [ObjectDefinition],
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						[sqlm].[definition],
						N' ',
						N''
					),
					CHAR(13),
					N''
				),
				CHAR(10),
				N''
			),
			CHAR(9),
			N''
		) AS [ObjectDefinitionStandardized],
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						LOWER([sqlm].[definition]),
						N' ',
						N''
					),
					CHAR(13),
					N''
				),
				CHAR(10),
				N''
			),
			CHAR(9),
			N''
		) AS [ObjectDefinitionLowerCaseStandardized]
	FROM
		[sys].[sql_modules] [sqlm]
	LEFT JOIN
		[sys].[objects] [o] ON [sqlm].[object_id] = [o].[object_id] 
	WHERE
		[o].[is_ms_shipped] = 0
),

[cteObjectDefinitionMetadata] AS (
	SELECT
		[cteOD].[ObjectId],
		[cteOD].[ObjectSchema],
		[cteOD].[ObjectName],
		[cteOD].[ObjectType],
		[cteOD].[ObjectDefinition],
		LEN([cteOD].[ObjectDefinition]) AS [ObjectDefinitionCharacterCount],
		DATALENGTH([cteOD].[ObjectDefinition]) AS [ObjectDefinitionDataLength],
		LEN([cteOD].[ObjectDefinition]) - LEN(REPLACE([cteOD].[ObjectDefinition], CHAR(10), N'')) + 1 AS [ObjectDefinitionLineCount],
		HASHBYTES(N'SHA2_256', [cteOD].[ObjectDefinition]) AS [ObjectDefinitionHash],
		[cteOD].[ObjectDefinitionStandardized],
		LEN([cteOD].[ObjectDefinitionStandardized]) AS [ObjectDefinitionStandardizedCharacterCount],
		DATALENGTH([cteOD].[ObjectDefinitionStandardized]) AS [ObjectDefinitionStandardizedDataLength],
		HASHBYTES(N'SHA2_256', [cteOD].[ObjectDefinitionStandardized]) AS [ObjectDefinitionStandardizedHash],
		LEN([cteOD].[ObjectDefinition]) - LEN([cteOD].[ObjectDefinitionStandardized]) AS [RemovedCharactersInDefinitionStandardized],
		[cteOD].[ObjectDefinitionLowerCaseStandardized],
		LEN([cteOD].[ObjectDefinitionLowerCaseStandardized]) AS [ObjectDefinitionLowerCaseStandardizedLength]
	FROM
		[cteObjectDefinitions] [cteOD]
)
	
SELECT
	[cteODM].[ObjectId],
	[cteODM].[ObjectSchema],
	[cteODM].[ObjectName],
	[cteODM].[ObjectType],
	[cteODM].[ObjectDefinition],
	[cteODM].[ObjectDefinitionCharacterCount],
	[cteODM].[ObjectDefinitionDataLength],
	[cteODM].[ObjectDefinitionLineCount],
	[cteODM].[ObjectDefinitionHash],
	[cteODM].[ObjectDefinitionStandardized],
	[cteODM].[ObjectDefinitionStandardizedCharacterCount],
	[cteODM].[ObjectDefinitionStandardizedDataLength],
	[cteODM].[ObjectDefinitionStandardizedHash],
	[cteODM].[RemovedCharactersInDefinitionStandardized],
	/* Heuristics for SQL object definition analysis */
	CASE 
		WHEN PATINDEX(N'%--%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%/*%*/%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseComments],
	CASE
		WHEN PATINDEX(N'%declare@%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseParameterDeclaration],
	CASE
		WHEN PATINDEX(N'%exec%', REPLACE([cteODM].[ObjectDefinitionLowerCaseStandardized], N'executeas', N'')) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseProcedureExecution],
	CASE
		WHEN PATINDEX(N'%select%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelect],
	CASE
		WHEN PATINDEX(N'%select%*%from%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelectAll],
	CASE
		WHEN PATINDEX(N'%select%from%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelectFrom],
	CASE
		WHEN PATINDEX(N'%where%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseWhere],
	CASE
		WHEN PATINDEX(N'%crossapply%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCrossApply],
	CASE
		WHEN PATINDEX(N'%outerapply%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOuterApply],
	CASE
		WHEN PATINDEX(N'%from%leftjoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%from%leftouterjoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLeftJoin],
	CASE
		WHEN PATINDEX(N'%from%rightjoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%from%rightouterjoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRightJoin],
	CASE
		WHEN PATINDEX(N'%from%fulljoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%from%fullouterjoin%on%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFullJoin],
	CASE
		WHEN PATINDEX(N'%from%crossjoin%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCrossJoin],
	CASE
		WHEN PATINDEX(N'%from%join%on%', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([cteODM].[ObjectDefinitionLowerCaseStandardized], N'leftjoin', N''), N'leftouterjoin',N''), N'rightjoin',N''), N'rightouterjoin', N''), N'fulljoin', N''), N'fullouterjoin', N''), N'crossjoin', N'')) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInnerJoin],
	CASE
		WHEN PATINDEX(N'%groupby%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGroupBy],
		CASE
		WHEN PATINDEX(N'%having%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHaving],
	CASE
		WHEN PATINDEX(N'%unionall%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUnionAll],
	CASE
		WHEN PATINDEX(N'%union%', REPLACE([cteODM].[ObjectDefinitionLowerCaseStandardized], N'unionall', N'')) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUnion],
	CASE
		WHEN PATINDEX(N'%update%set%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUpdateTable],
	CASE
		WHEN PATINDEX(N'%drop%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDropObject],
	CASE
		WHEN PATINDEX(N'%delete%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDeleteFromTable],
	CASE
		WHEN PATINDEX(N'%truncatetable%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTruncateTable],
	CASE
		WHEN PATINDEX(N'%insertinto%values(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInsertIntoValues],
	CASE
		WHEN PATINDEX(N'%insertinto%select%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInsertIntoSelect],
	CASE
		WHEN PATINDEX(N'%with%as(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCTE],
	CASE
		WHEN PATINDEX(N'%select%as%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColumnAlias],
	CASE
		WHEN PATINDEX(N'%orderby%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOrderBy],
	CASE
		WHEN PATINDEX(N'%case%when%then%end%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCase],
	CASE
		WHEN PATINDEX(N'%begintry%endtry%begincatch%endcatch%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTryCatch],
	CASE
		WHEN PATINDEX(N'%while%begin%end%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseWhileLoop],
	CASE
		WHEN PATINDEX(N'%exec%sp_executesql%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%exec%sp_sqlexec%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%exec(''%'')%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%execute(''%'')%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0  -- Check exec('...') and execute('...') separately to minimize false positives.
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDynamicSql],
	CASE
		WHEN PATINDEX(N'%createtable#%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%select%into%#%from%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTemporaryTables],
	CASE
		WHEN PATINDEX(N'%begintran%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTransaction],
		CASE
		WHEN PATINDEX(N'%begintran%save%tran%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSaveTransaction],
	CASE
		WHEN PATINDEX(N'%begintran%commit%tran%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCommitTransaction],
	CASE
		WHEN PATINDEX(N'%begintran%rollback%tran%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRollbackTransaction],
	CASE
		WHEN PATINDEX(N'%''%''%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%n''%''%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStrings]
FROM
	[cteObjectDefinitionMetadata] [cteODM];