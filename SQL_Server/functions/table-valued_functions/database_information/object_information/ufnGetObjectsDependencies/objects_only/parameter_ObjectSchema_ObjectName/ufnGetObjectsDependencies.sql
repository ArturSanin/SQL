USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description: Returns all objects that reference 
--				or are referenced by the specified 
--				object, including server and database 
--				information.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectsDependencies] 
(
	@ObjectSchema sysname,
	@ObjectName sysname
)
RETURNS TABLE
AS
RETURN
(		
	SELECT
		N'Referenced By' AS [DependencyType],
		@@SERVERNAME AS [ServerName],
		DB_NAME() AS [DatabaseName],
		[sqled].[referencing_id] AS [ObjectId],
		OBJECT_SCHEMA_NAME([sqled].[referencing_id]) AS [ObjectSchemaName],
		OBJECT_NAME([sqled].[referencing_id]) AS [ObjectName]
	FROM
		[sys].[sql_expression_dependencies] [sqled]
	WHERE
		[sqled].[referenced_id] = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName))
	AND
		[sqled].[referencing_class] = 1
	AND
		[sqled].[referencing_minor_id] = 0
	
	UNION ALL
	
	SELECT
		N'References' AS [DependencyType],
		[sqled].[referenced_server_name] AS [ServerName],
		[sqled].[referenced_database_name] AS [DatabaseName],
		[sqled].[referenced_id] AS [ObjectId],
		[sqled].[referenced_schema_name] AS [ObjectSchemaName],
		[sqled].[referenced_entity_name] AS [ObjectName]
	FROM
		[sys].[sql_expression_dependencies] [sqled]
	WHERE
		[sqled].[referencing_id] = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName))
	AND
		[sqled].[referenced_class] = 1
	AND
		[sqled].[referenced_minor_id] = 0
);
GO



-- =============================================
-- MS_Description for function and its parameters:
-- DbInfo.ufnGetObjectsDependencies
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'Returns all objects that reference or are referenced by the specified object.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetObjectsDependencies';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'The schema name of the object for which to return dependencies.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetObjectsDependencies',
     @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
     @name = N'MS_Description',
     @value = N'The name of the object for which to return dependencies.',
     @level0type = N'SCHEMA', @level0name = N'DbInfo',
     @level1type = N'FUNCTION', @level1name = N'ufnGetObjectsDependencies',
     @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO