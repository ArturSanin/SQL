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
	@ObjectId int
)
RETURNS nvarchar(max)
AS
BEGIN
	
	DECLARE 
		@ObjectDescription nvarchar(max);

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

-- Description for parameter: @ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object in the current database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescription',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectId';
GO