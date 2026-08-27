USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the description of the specified object,
--				if available in [sys].[extended_properties].
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectDescription] 
(
	@ObjectSchema sysname,
	@ObjectName sysname
)
RETURNS nvarchar(max)
AS
BEGIN
	
	DECLARE 
		@ObjectDescription nvarchar(max),
		@ObjectId int = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName));

	SELECT 
		@ObjectDescription = CAST([ex].[value] AS nvarchar(max))
	FROM
		[sys].[extended_properties] [ex]
	WHERE
		[ex].[major_id] = @ObjectId
	AND
		[ex].[name] = N'MS_Description'
	AND
		[ex].[class] = 1
	AND
		[ex].[minor_id] = 0;
	
	RETURN @ObjectDescription;

END
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectDescription
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the description of the specified object, if available.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescription';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescription',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescription',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO