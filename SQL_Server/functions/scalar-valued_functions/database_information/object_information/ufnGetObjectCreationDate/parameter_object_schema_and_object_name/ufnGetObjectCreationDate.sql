USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns the creation date of the
-- specified object.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectCreationDate] 
(
	@ObjectSchema sysname,
	@ObjectName sysname
)
RETURNS datetime
AS
BEGIN
	
	DECLARE 
		@ObjectCreationDate datetime,
		@ObjectId int = OBJECT_ID(QUOTENAME(@ObjectSchema) + N'.' + QUOTENAME(@ObjectName));

	SELECT 
		@ObjectCreationDate = [ao].[create_date]
	FROM
		[sys].[all_objects] [ao]
	WHERE
		[ao].[object_id] = @ObjectId; 
	
	RETURN @ObjectCreationDate;

END
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectCreationDate
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the creation date of the specified object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectCreationDate';
GO

-- Description for parameter: @ObjectSchema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectCreationDate',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectSchema';
GO

-- Description for parameter: @ObjectName
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the object.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectCreationDate',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectName';
GO