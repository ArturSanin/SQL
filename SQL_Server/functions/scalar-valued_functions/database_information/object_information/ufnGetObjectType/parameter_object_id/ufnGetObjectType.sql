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
	@ObjectId int
)
RETURNS nvarchar(60)
AS
BEGIN
	
	DECLARE 
		@ObjectType nvarchar(60);

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

-- Description for parameter: @ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object in the current database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectType',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectId';
GO