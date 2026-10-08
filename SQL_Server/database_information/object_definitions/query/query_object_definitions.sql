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
		) AS [ObjectDefinitionStandardized]
	FROM
		[sys].[sql_modules] [sqlm]
	LEFT JOIN
		[sys].[objects] [o] ON [sqlm].[object_id] = [o].[object_id] 
	WHERE
		[o].[is_ms_shipped] = 0
)
	
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
	LEN([cteOD].[ObjectDefinition]) - LEN([cteOD].[ObjectDefinitionStandardized]) AS [RemovedCharactersInDefinitionStandardized] 
FROM
	[cteObjectDefinitions] [cteOD];