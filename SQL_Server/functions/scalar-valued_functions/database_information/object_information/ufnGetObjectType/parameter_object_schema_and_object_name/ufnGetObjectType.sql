USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the type of the specified object.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectType]
(
	@ObjectSchema sysname,
	@ObjectName sysname
)
RETURNS nvarchar(60)
AS
BEGIN
	
	DECLARE 
		@ObjectType nvarchar(60),
		@ObjectId int = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName));

	SELECT 
		@ObjectType = [ao].[type_desc]
	FROM
		[sys].[all_objects] [ao]
	WHERE
		[ao].[object_id] = @ObjectId; 
	
	RETURN @ObjectType;

END
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectType
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the type of the specified object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectType';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectType',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectType',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO