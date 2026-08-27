USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the definition of the specified object,
--				if available in [sys].[all_sql_modules].
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectDefinition] 
(
	@ObjectSchema sysname,
	@ObjectName sysname
)
RETURNS nvarchar(max)
AS
BEGIN
	
	DECLARE 
		@ObjectDefinition nvarchar(max),
		@ObjectId int = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName));

	SELECT 
		@ObjectDefinition = [asqlm].[definition]
	FROM
		[sys].[all_sql_modules] [asqlm]
	WHERE
		[asqlm].[object_id] = @ObjectId; 
	
	RETURN @ObjectDefinition;

END
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectDefinition
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the definition of the specified object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDefinition';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDefinition',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDefinition',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO