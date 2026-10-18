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
	END AS [MayUseStrings],
	CASE
		WHEN PATINDEX(N'%collate%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCollate],
	-- Create statements
	CASE
		WHEN PATINDEX(N'%createfunction%returns%begin%return%end%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCreateScalarFunction],
	CASE
		WHEN PATINDEX(N'%createfunction%returnstable%return%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCreateInlineTableValuedFunction],
	CASE
		WHEN PATINDEX(N'%createfunction%returns%@%table%begin%end%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCreateMultiStatementTableValuedFunction],
		CASE
		WHEN PATINDEX(N'%createproc%as%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStoredProcedure],
	CASE
		WHEN PATINDEX(N'%createtable(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCreateTable],
	CASE
		WHEN PATINDEX(N'%createview%as%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCreateView],
	/* Heuristics for system functions */
	-- Aggregate Functions
	CASE
		WHEN PATINDEX(N'%any_value(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAnyValue],

	CASE
		WHEN PATINDEX(N'%approx_count_distinct(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseApproxCountDistinct],

	CASE
		WHEN PATINDEX(N'%approx_median(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseApproxMedian],

	CASE
		WHEN PATINDEX(N'%approx_percentile_cont(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseApproxPercentileCont],

	CASE
		WHEN PATINDEX(N'%approx_percentile_disc(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseApproxPercentileDisc],

	CASE
		WHEN PATINDEX(N'%approx_quantile(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseApproxQuantile],

	CASE
		WHEN PATINDEX(N'%avg(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAvg],

	CASE
		WHEN PATINDEX(N'%checksum_agg(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChecksumAgg],

	CASE
		WHEN PATINDEX(N'%count(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCount],

	CASE
		WHEN PATINDEX(N'%count_big(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCountBig],

	CASE
		WHEN PATINDEX(N'%grouping(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGrouping],

	CASE
		WHEN PATINDEX(N'%grouping_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGroupingId],

	CASE
		WHEN PATINDEX(N'%product(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseProduct],

	CASE
		WHEN PATINDEX(N'%max(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMax],

	CASE
		WHEN PATINDEX(N'%median(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMedian],

	CASE
		WHEN PATINDEX(N'%min(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMin],

	CASE
		WHEN PATINDEX(N'%percentile_cont(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePercentileCont],

	CASE
		WHEN PATINDEX(N'%percentile_disc(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
		END AS [MayUsePercentileDisc],

	CASE
		WHEN PATINDEX(N'%quantile(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseQuantile],

	CASE
		WHEN PATINDEX(N'%stdev(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStdev],

	CASE
		WHEN PATINDEX(N'%stdevp(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStdevp],

	CASE
		WHEN PATINDEX(N'%string_agg(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStringAgg],
	CASE
		WHEN PATINDEX(N'%sum(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSum],

	CASE
		WHEN PATINDEX(N'%var(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseVar],
	CASE
		WHEN PATINDEX(N'%varp(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseVarp],
	-- Configuration Functions
	CASE
		WHEN PATINDEX(N'%@@datefirst%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatefirst],
	CASE
		WHEN PATINDEX(N'%@@dbts%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDbts],
	CASE
		WHEN PATINDEX(N'%@@langid%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLangid],
	CASE
		WHEN PATINDEX(N'%@@language%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLanguage],
	CASE
		WHEN PATINDEX(N'%@@lock_timeout%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLockTimeout],
	CASE
		WHEN PATINDEX(N'%@@max_connections%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMaxConnections],
	CASE
		WHEN PATINDEX(N'%@@max_precision%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMaxPrecision],
	CASE
		WHEN PATINDEX(N'%@@nestlevel%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseNestlevel],
	CASE
		WHEN PATINDEX(N'%@@options%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOptions],
	CASE
		WHEN PATINDEX(N'%@@remserver%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRemserver],
	CASE
		WHEN PATINDEX(N'%@@servername%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseServername],
	CASE
		WHEN PATINDEX(N'%@@servicename%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseServicename],
	CASE
		WHEN PATINDEX(N'%@@spid%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSpid],
	CASE
		WHEN PATINDEX(N'%@@textsize%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTextsize],
	CASE
		WHEN PATINDEX(N'%@@version%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseVersion],
	-- Cursor Functions
	CASE
		WHEN PATINDEX(N'%@@cursor_rows%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCursorRows],
	CASE
		WHEN PATINDEX(N'%@@fetch_status%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFetchStatus],
	CASE
		WHEN PATINDEX(N'%cursor_status(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCursorStatus],
	-- Date and Time Functions
	CASE
		WHEN PATINDEX(N'%current_date%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCurrentDate],
	CASE
		WHEN PATINDEX(N'%current_timestamp%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCurrentTimestamp],
	CASE
		WHEN PATINDEX(N'%dateadd(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDateadd],
	CASE
		WHEN PATINDEX(N'%date_bucket(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDateBucket],
	CASE
		WHEN PATINDEX(N'%datediff(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatediff],
	CASE
		WHEN PATINDEX(N'%datediff_big(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatediffBig],
	CASE
		WHEN PATINDEX(N'%datefromparts(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatefromparts],
	CASE
		WHEN PATINDEX(N'%datename(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatename],
	CASE
		WHEN PATINDEX(N'%datepart(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatepart],
	CASE
		WHEN PATINDEX(N'%datetrunc(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatetrunc],
	CASE
		WHEN PATINDEX(N'%datetime2fromparts(%,%,%,%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatetime2fromparts],
	CASE
		WHEN PATINDEX(N'%datetimefromparts(%,%,%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatetimefromparts],
	CASE
		WHEN PATINDEX(N'%datetimeoffsetfromparts(%,%,%,%,%,%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatetimeoffsetfromparts],
	CASE
		WHEN PATINDEX(N'%day(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDay],
	CASE
		WHEN PATINDEX(N'%eomonth(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseEomonth],
	CASE
		WHEN PATINDEX(N'%getdate(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGetdate],
	CASE
		WHEN PATINDEX(N'%getutcdate(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGetutcdate],
	CASE
		WHEN PATINDEX(N'%isdate(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsdate],
	CASE
		WHEN PATINDEX(N'%month(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMonth],
	CASE
		WHEN PATINDEX(N'%smalldatetimefromparts(%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSmalldatetimefromparts],
	CASE
		WHEN PATINDEX(N'%switchoffset(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSwitchoffset],
	CASE
		WHEN PATINDEX(N'%sysdatetime(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSysdatetime],

	CASE
		WHEN PATINDEX(N'%sysdatetimeoffset(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSysdatetimeoffset],

	CASE
		WHEN PATINDEX(N'%sysutcdatetime(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSysutcdatetime],

	CASE
		WHEN PATINDEX(N'%timefromparts(%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTimefromparts],

	CASE
		WHEN PATINDEX(N'%todatetimeoffset(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTodatetimeoffset],

	CASE
		WHEN PATINDEX(N'%year(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseYear],
	-- Hierachy Id Functions
	CASE
		WHEN PATINDEX(N'%.getancestor(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdGetAncestor],
	CASE
		WHEN PATINDEX(N'%.getdescendant(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdGetDescendant],
	CASE
		WHEN PATINDEX(N'%.getlevel(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdGetLevel],
	CASE
		WHEN PATINDEX(N'%.getreparentedvalue(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdGetReparentedValue],
	CASE
		WHEN PATINDEX(N'%.getroot(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0 OR PATINDEX(N'%hierarchyid::getroot(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdGetRoot],
	CASE
		WHEN PATINDEX(N'%.isdescendantof(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdIsDescendantOf],

	CASE
		WHEN PATINDEX(N'%.parse(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdParse],

	CASE
		WHEN PATINDEX(N'%.tostring(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHierarchyIdToString],
	-- Mathematical Functions
	CASE
		WHEN PATINDEX(N'%abs(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAbs],
	CASE
		WHEN PATINDEX(N'%acos(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAcos],
	CASE
		WHEN PATINDEX(N'%asin(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAsin],
	CASE
		WHEN PATINDEX(N'%atan(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAtan],
	CASE
		WHEN PATINDEX(N'%atn2(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAtn2],
	CASE
		WHEN PATINDEX(N'%ceiling(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCeiling],
	CASE
		WHEN PATINDEX(N'%cos(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCos],
	CASE
		WHEN PATINDEX(N'%cot(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCot],
	CASE
		WHEN PATINDEX(N'%degrees(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDegrees],
	CASE
		WHEN PATINDEX(N'%exp(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseExp],
	CASE
		WHEN PATINDEX(N'%floor(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFloor],
	CASE
		WHEN PATINDEX(N'%log(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLog],
	CASE
		WHEN PATINDEX(N'%log10(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLog10],
	CASE
		WHEN PATINDEX(N'%pi(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePi],
	CASE
		WHEN PATINDEX(N'%power(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePower],
	CASE
		WHEN PATINDEX(N'%radians(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRadians],
	CASE
		WHEN PATINDEX(N'%rand(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRand],
	CASE
		WHEN PATINDEX(N'%round(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRound],
	CASE
		WHEN PATINDEX(N'%sign(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSign],
	CASE
		WHEN PATINDEX(N'%sin(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSin],
	CASE
		WHEN PATINDEX(N'%sqrt(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSqrt],
	CASE
		WHEN PATINDEX(N'%square(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSquare],
	CASE
		WHEN PATINDEX(N'%tan(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTan],
	-- Metadata Functions
	CASE
		WHEN PATINDEX(N'%applock_mode(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAppLockMode],
	CASE
		WHEN PATINDEX(N'%applock_test(%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAppLockTest],
	CASE
		WHEN PATINDEX(N'%app_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAppName],
	CASE
		WHEN PATINDEX(N'%assemblyproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAssemblyProperty],
	CASE
		WHEN PATINDEX(N'%col_length(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColLength],
	CASE
		WHEN PATINDEX(N'%col_name(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColName],
	CASE
		WHEN PATINDEX(N'%columnproperty(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColumnProperty],
	CASE
		WHEN PATINDEX(N'%database_principal_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatabasePrincipalId],
	CASE
		WHEN PATINDEX(N'%databaseproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatabaseProperty],
	CASE
		WHEN PATINDEX(N'%databasepropertyex(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatabasePropertyEx],
	CASE
		WHEN PATINDEX(N'%db_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDbId],
	CASE
		WHEN PATINDEX(N'%db_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDbName],
	CASE
		WHEN PATINDEX(N'%file_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFileId],
	CASE
		WHEN PATINDEX(N'%file_idex(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFileIdEx],
	CASE
		WHEN PATINDEX(N'%file_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFileName],
	CASE
		WHEN PATINDEX(N'%filegroup_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFilegroupId],
	CASE
		WHEN PATINDEX(N'%filegroup_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFilegroupName],
	CASE
		WHEN PATINDEX(N'%filegroupproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFilegroupProperty],
	CASE
		WHEN PATINDEX(N'%fileproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFileProperty],
	CASE
		WHEN PATINDEX(N'%::fn_listextendedproperty(%,%,%,%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnListextendedproperty],
	CASE
		WHEN PATINDEX(N'%fulltextcatalogproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFulltextCatalogProperty],
	CASE
		WHEN PATINDEX(N'%fulltextserviceproperty(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFulltextServiceProperty],
	CASE
		WHEN PATINDEX(N'%index_col(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIndexCol],
	CASE
		WHEN PATINDEX(N'%indexkey_property(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIndexKeyProperty],
	CASE
		WHEN PATINDEX(N'%indexproperty(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIndexProperty],
	CASE
		WHEN PATINDEX(N'%object_definition(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectDefinition],
	CASE
		WHEN PATINDEX(N'%object_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectId],
	CASE
		WHEN PATINDEX(N'%object_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectName],
	CASE
		WHEN PATINDEX(N'%object_schema_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectSchemaName],
	CASE
		WHEN PATINDEX(N'%objectproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectProperty],
	CASE
		WHEN PATINDEX(N'%objectpropertyex(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseObjectPropertyEx],
	CASE
		WHEN PATINDEX(N'%original_db_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOriginalDbName],
	CASE
		WHEN PATINDEX(N'%@@procid%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseProcId],
	CASE
		WHEN PATINDEX(N'%schema_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSchemaId],
	CASE
		WHEN PATINDEX(N'%schema_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSchemaName],
	CASE
		WHEN PATINDEX(N'%serverproperty(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseServerProperty],
	CASE
		WHEN PATINDEX(N'%sql_variant_property(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSqlVariantProperty],
	CASE
		WHEN PATINDEX(N'%type_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTypeId],
	CASE
		WHEN PATINDEX(N'%type_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTypeName],
	CASE
		WHEN PATINDEX(N'%typeproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTypeProperty],
	CASE
		WHEN PATINDEX(N'%change_tracking_current_version(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChangeTrackingCurrentVersion],
	CASE
		WHEN PATINDEX(N'%change_tracking_is_column_in_mask(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChangeTrackingIsColumnInMask],
	CASE
		WHEN PATINDEX(N'%change_tracking_cleanup_version(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChangeTrackingCleanupVersion],
	-- Rowset Functions
	CASE
		WHEN PATINDEX(N'%containstable(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseContainstable],
	CASE
		WHEN PATINDEX(N'%freetexttable(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFreetexttable],
	CASE
		WHEN PATINDEX(N'%openquery(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOpenQuery],
	CASE
		WHEN PATINDEX(N'%openrowset(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOpenRowset],
	CASE
		WHEN PATINDEX(N'%openxml(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOpenXml],
	CASE
		WHEN PATINDEX(N'%opendatasource(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOpenDataSource],
	-- Security Functions
	CASE
		WHEN PATINDEX(N'%certencoded(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCertEncoded],
	CASE
		WHEN PATINDEX(N'%certprivatekey(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCertPrivateKey],
	CASE
		WHEN PATINDEX(N'%current_user%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCurrentUser],
	CASE
		WHEN PATINDEX(N'%has_perms_by_name(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHasPermsByName],
	CASE
		WHEN PATINDEX(N'%is_member(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsMember],
	CASE
		WHEN PATINDEX(N'%is_rolemember(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsRoleMember],
	CASE
		WHEN PATINDEX(N'%is_srvrolemember(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsSrvRoleMember],
	CASE
		WHEN PATINDEX(N'%loginproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLoginProperty],
	CASE
		WHEN PATINDEX(N'%original_login%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseOriginalLogin],
	CASE
		WHEN PATINDEX(N'%permissions(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePermissions],
	CASE
		WHEN PATINDEX(N'%pwdcompare(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePwdCompare],
	CASE
		WHEN PATINDEX(N'%pwdencrypt(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePwdEncrypt],
	CASE
		WHEN PATINDEX(N'%session_user%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSessionUser],
	CASE
		WHEN PATINDEX(N'%suser_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSuserId],
	CASE
		WHEN PATINDEX(N'%suser_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSuserName],
	CASE
		WHEN PATINDEX(N'%suser_sid(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSuserSid],
	CASE
		WHEN PATINDEX(N'%suser_sname(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSuserSname],
	CASE
		WHEN PATINDEX(N'%sys.fn_builtin_permissions(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnBuiltinPermissions],
	CASE
		WHEN PATINDEX(N'%sys.fn_get_audit_file(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnGetAuditFile],
	CASE
		WHEN PATINDEX(N'%sys.fn_my_permissions(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnMyPermissions],
	CASE
		WHEN PATINDEX(N'%system_user%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSystemUser],
	CASE
		WHEN PATINDEX(N'%user%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUser],
	CASE
		WHEN PATINDEX(N'%user_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUserId],
	CASE
		WHEN PATINDEX(N'%user_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUserName],
	-- String Functions
	CASE
		WHEN PATINDEX(N'%ascii(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseAscii],
	CASE
		WHEN PATINDEX(N'%char(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChar],
	CASE
		WHEN PATINDEX(N'%charindex(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCharIndex],
	CASE
		WHEN PATINDEX(N'%concat(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseConcat],
	CASE
		WHEN PATINDEX(N'%concat_ws(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseConcatWs],
	CASE
		WHEN PATINDEX(N'%difference(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDifference],
	CASE
		WHEN PATINDEX(N'%format(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFormat],
	CASE
		WHEN PATINDEX(N'%left(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLeft],
	CASE
		WHEN PATINDEX(N'%len(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLen],
	CASE
		WHEN PATINDEX(N'%lower(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLower],
	CASE
		WHEN PATINDEX(N'%ltrim(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseLtrim],
	CASE
		WHEN PATINDEX(N'%nchar(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseNchar],
	CASE
		WHEN PATINDEX(N'%ngettext(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseNgettext],
	CASE
		WHEN PATINDEX(N'%quotename(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseQuotename],
	CASE
		WHEN PATINDEX(N'%replace(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseReplace],
	CASE
		WHEN PATINDEX(N'%replicate(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseReplicate],
	CASE
		WHEN PATINDEX(N'%reverse(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseReverse],
	CASE
		WHEN PATINDEX(N'%right(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRight],
	CASE
		WHEN PATINDEX(N'%rtrim(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRtrim],
	CASE
		WHEN PATINDEX(N'%string_escape(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStringEscape],
	CASE
		WHEN PATINDEX(N'%string_split(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStringSplit],
	CASE
		WHEN PATINDEX(N'%stuff(%,%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStuff],
		CASE
		WHEN PATINDEX(N'%substring(%,%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStuff],
	CASE
		WHEN PATINDEX(N'%trim(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTrim],
	CASE
		WHEN PATINDEX(N'%unicode(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUnicode],
	CASE
		WHEN PATINDEX(N'%upper(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUpper],
	-- System Statistical Functions
	CASE
		WHEN PATINDEX(N'%@@connections%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseConnections],
	CASE
		WHEN PATINDEX(N'%@@cpu_busy%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCpuBusy],
	CASE
		WHEN PATINDEX(N'%fn_virtualfilestats(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnVirtualFileStats],

	CASE
		WHEN PATINDEX(N'%@@idle%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdle],
	CASE
		WHEN PATINDEX(N'%@@io_busy%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIoBusy],
	CASE
		WHEN PATINDEX(N'%@@pack_received%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePackReceived],
	CASE
		WHEN PATINDEX(N'%@@pack_sent%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePackSent],
	CASE
		WHEN PATINDEX(N'%@@packet_errors%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePacketErrors],
	CASE
		WHEN PATINDEX(N'%@@timeticks%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTimeticks],
	CASE
		WHEN PATINDEX(N'%@@total_errors%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTotalErrors],
	CASE
		WHEN PATINDEX(N'%@@total_read%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTotalRead],
	CASE
		WHEN PATINDEX(N'%@@total_write%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTotalWrite],
	-- Text and Image Functions
	CASE
		WHEN PATINDEX(N'%patindex(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUsePatindex],
	CASE
		WHEN PATINDEX(N'%textptr(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTextptr],
	CASE
		WHEN PATINDEX(N'%textvalid(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTextvalid],
	-- Other Functions
	CASE
		WHEN PATINDEX(N'%@@microsoftversion%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseMicrosoftversion],
	CASE
		WHEN PATINDEX(N'%binary_checksum(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseBinaryChecksum],
	CASE
		WHEN PATINDEX(N'%checksum(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseChecksum],
	CASE
		WHEN PATINDEX(N'%connectionproperty(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseConnectionproperty],
	CASE
		WHEN PATINDEX(N'%cast(%as%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCast],
	CASE
		WHEN PATINDEX(N'%coalesce(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCoalesce],
	CASE
		WHEN PATINDEX(N'%collationproperty(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseCollationProperty],
	CASE
		WHEN PATINDEX(N'%columns_updated(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseColumnsUpdated],
	CASE
		WHEN PATINDEX(N'%convert(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseConvert],
	CASE
		WHEN PATINDEX(N'%datalength(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseDatalength],
	CASE
		WHEN PATINDEX(N'%@@error%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseError],
	CASE
		WHEN PATINDEX(N'%fn_helpcollations(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnHelpCollations],
	CASE
		WHEN PATINDEX(N'%fn_indexinfo(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnIndexInfo],
	CASE
		WHEN PATINDEX(N'%fn_serverhadrives(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFnServerHadDrives],
	CASE
		WHEN PATINDEX(N'%formatmessage(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseFormatMessage],
	CASE
		WHEN PATINDEX(N'%getansinull(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseGetAnsiNull],
	CASE
		WHEN PATINDEX(N'%host_id(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHostId],
	CASE
		WHEN PATINDEX(N'%host_name(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseHostName],
	CASE
		WHEN PATINDEX(N'%ident_current(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdentCurrent],
	CASE
		WHEN PATINDEX(N'%ident_incr(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdentIncr],
	CASE
		WHEN PATINDEX(N'%ident_seed(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdentSeed],
	CASE
		WHEN PATINDEX(N'%@@identity%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdentity],
	CASE
		WHEN PATINDEX(N'%identity(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIdentityFunction],
	CASE
		WHEN PATINDEX(N'%isnull(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsNull],
	CASE
		WHEN PATINDEX(N'%isnumeric(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseIsNumeric],
	CASE
		WHEN PATINDEX(N'%newid(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseNewId],
	CASE
		WHEN PATINDEX(N'%nullif(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseNullIf],
	CASE
		WHEN PATINDEX(N'%parsename(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseParsename],
	CASE
		WHEN PATINDEX(N'%@@rowcount%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRowcount],
	CASE
		WHEN PATINDEX(N'%rowcount_big(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseRowcountBig],
	CASE
		WHEN PATINDEX(N'%scope_identity(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseScopeIdentity],
	CASE
		WHEN PATINDEX(N'%sessionproperty(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseSessionProperty],
	CASE
		WHEN PATINDEX(N'%stats_date(%,%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseStatsDate],
	CASE
		WHEN PATINDEX(N'%@@trancount%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseTrancount],
	CASE
		WHEN PATINDEX(N'%update(%)%', [cteODM].[ObjectDefinitionLowerCaseStandardized]) > 0
			THEN CAST(1 AS bit)
		ELSE
			CAST(0 AS bit)
	END AS [MayUseUpdate]
FROM
	[cteObjectDefinitionMetadata] [cteODM];