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
	@ObjectId int
)
RETURNS nvarchar(max)
AS
BEGIN
	
	DECLARE 
		@ObjectDefinition nvarchar(max);

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

-- Description for parameter: @ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object in the current database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDefinition',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectId';
GO