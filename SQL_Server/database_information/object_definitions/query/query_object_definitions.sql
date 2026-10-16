USE [DatabaseName];
GO

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

[cte] AS (
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
	[cte].[ObjectId],
	[cte].[ObjectSchema],
	[cte].[ObjectName],
	[cte].[ObjectType],
	[cte].[ObjectDefinition],
	[cte].[ObjectDefinitionCharacterCount],
	[cte].[ObjectDefinitionDataLength],
	[cte].[ObjectDefinitionLineCount],
	[cte].[ObjectDefinitionHash],
	[cte].[ObjectDefinitionStandardized],
	[cte].[ObjectDefinitionStandardizedCharacterCount],
	[cte].[ObjectDefinitionStandardizedDataLength],
	[cte].[ObjectDefinitionStandardizedHash],
	[cte].[RemovedCharactersInDefinitionStandardized],
	/* Heuristics for SQL object definition analysis */
	CASE
		WHEN CHARINDEX(N'--', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 OR (CHARINDEX(N'/*', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'/*', [cte].[ObjectDefinitionLowerCaseStandardized]) < CHARINDEX(N'*/', [cte].[ObjectDefinitionLowerCaseStandardized]))
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseComments],
	CASE
		WHEN CHARINDEX(N'declare@', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseParameterDeclaration],
	CASE
		WHEN CHARINDEX(N'exec', REPLACE([cte].[ObjectDefinitionLowerCaseStandardized], N'executeas', N'')) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseProcedureExecution],
	CASE
		WHEN CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelect],
	CASE
		WHEN CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'*', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) + 6, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelectAll],
	CASE
		WHEN (CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0) AND CHARINDEX(N'from', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) + 6, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSelectFrom],
	CASE
		WHEN CHARINDEX(N'where', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseWhere],
	CASE
		WHEN CHARINDEX(N'crossapply', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCrossApply],
	CASE
		WHEN CHARINDEX(N'outerapply', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOuterApply],
	CASE
		WHEN (CHARINDEX(N'leftjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'leftjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 8, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0) OR (CHARINDEX(N'leftouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'leftouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 13, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0)
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLeftJoin],
	CASE
		WHEN (CHARINDEX(N'rightjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'rightjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 9, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0) OR (CHARINDEX(N'rightouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'rightouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 14, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0)
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRightJoin],
	CASE
		WHEN (CHARINDEX(N'fulljoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'fulljoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 8, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0) OR (CHARINDEX(N'fullouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'on', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'fullouterjoin', [cte].[ObjectDefinitionLowerCaseStandardized]) + 13, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0)
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFullJoin],
	CASE
		WHEN CHARINDEX(N'join', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([cte].[ObjectDefinitionLowerCaseStandardized], N'leftjoin', N''), N'leftouterjoin',N''), N'rightjoin',N''), N'rightouterjoin', N''), N'fulljoin', N''), N'fullouterjoin', N'')) > 0 AND CHARINDEX(N'on', SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([cte].[ObjectDefinitionLowerCaseStandardized], N'leftjoin', N''), N'leftouterjoin',N''), N'rightjoin',N''), N'rightouterjoin', N''), N'fulljoin', N''), N'fullouterjoin', N''), CHARINDEX(N'join', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([cte].[ObjectDefinitionLowerCaseStandardized], N'leftjoin', N''), N'leftouterjoin',N''), N'rightjoin',N''), N'rightouterjoin', N''), N'fulljoin', N''), N'fullouterjoin', N'')) + 4, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInnerJoin],
	CASE
		WHEN CHARINDEX(N'groupby', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGroupBy],
		CASE
		WHEN CHARINDEX(N'having', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHaving],
	CASE
		WHEN CHARINDEX(N'unionall', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUnionAll],
	CASE
		WHEN CHARINDEX(N'union', REPLACE([cte].[ObjectDefinitionLowerCaseStandardized], N'unionall', N'')) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUnion],
	CASE
		WHEN CHARINDEX(N'update', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'set', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'update', [cte].[ObjectDefinitionLowerCaseStandardized]) + 6, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUpdateTable],
	CASE
		WHEN CHARINDEX(N'drop', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDropObject],
	CASE
		WHEN CHARINDEX(N'delete', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDeleteFromTable],
	CASE
		WHEN CHARINDEX(N'insertinto', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'values(', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'insertinto', [cte].[ObjectDefinitionLowerCaseStandardized]) + 10, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInsertIntoValues],
	CASE
		WHEN CHARINDEX(N'insertinto', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'select', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'insertinto', [cte].[ObjectDefinitionLowerCaseStandardized]) + 10, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseInsertIntoSelect],
	CASE
		WHEN CHARINDEX(N'with', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'as(', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'with', [cte].[ObjectDefinitionLowerCaseStandardized]) + 4, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCTE],
	CASE
		WHEN CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'as', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) + 6, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) < CHARINDEX(N'from', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'select', [cte].[ObjectDefinitionLowerCaseStandardized]) + 6, [cte].[ObjectDefinitionLowerCaseStandardizedLength]))
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColumnAlias],
	CASE
		WHEN CHARINDEX(N'orderby', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOrderBy],
	CASE
		WHEN CHARINDEX(N'case', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'when', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'case', [cte].[ObjectDefinitionLowerCaseStandardized]) + 4, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0 AND CHARINDEX(N'then', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'when', [cte].[ObjectDefinitionLowerCaseStandardized]) + 4, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0 AND CHARINDEX(N'end', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'then', [cte].[ObjectDefinitionLowerCaseStandardized]) + 4, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCase],
	CASE
		WHEN CHARINDEX(N'begintry', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'endtry', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'begintry', [cte].[ObjectDefinitionLowerCaseStandardized]) + 8, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0 AND CHARINDEX(N'begincatch', [cte].[ObjectDefinitionLowerCaseStandardized]) > 0 AND CHARINDEX(N'endcatch', SUBSTRING([cte].[ObjectDefinitionLowerCaseStandardized], CHARINDEX(N'begincatch', [cte].[ObjectDefinitionLowerCaseStandardized]) + 10, [cte].[ObjectDefinitionLowerCaseStandardizedLength])) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseBeginCatch]
FROM
	[cte] [cte];