USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Returns all descriptions of the specified object
--				that are available in [sys].[extended_properties].
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectDescriptions] 
(
	@ObjectId int
)
RETURNS TABLE
AS
RETURN
(		
	SELECT
		CASE
			WHEN [ep].[class] = 1 AND [ep].[minor_id] = 0
				THEN N'OBJECT'
			WHEN [ep].[class] = 1 AND [ep].[minor_id] > 0
				THEN N'COLUMN'
			WHEN [ep].[class] = 2 AND [ep].[minor_id] > 0
				THEN N'PARAMETER'
			ELSE
				[ep].[class_desc]
		END AS [DescriptionType],
		CASE
			WHEN [ep].[class] = 1 AND [ep].[minor_id] = 0
				THEN OBJECT_NAME([ep].[major_id])
			WHEN [ep].[class] = 1 AND [ep].[minor_id] > 0
				THEN [c].[name]
			WHEN [ep].[class] = 2 AND [ep].[minor_id] > 0
				THEN [p].[name]
			ELSE
				NULL
		END AS [Name],
		CAST([ep].[value] AS nvarchar(max)) AS [Description]
	FROM
		[sys].[extended_properties] [ep]
	LEFT JOIN
		[sys].[columns] [c] ON [ep].[major_id] = [c].[object_id] AND [ep].[minor_id] = [c].[column_id]
	LEFT JOIN
		[sys].[parameters] [p] ON [ep].[major_id] = [p].[object_id] AND [ep].[minor_id] = [p].[parameter_id] AND [p].[parameter_id] > 0
	WHERE
		[ep].[major_id] = @ObjectId
	AND
		[ep].[name] = N'MS_Description'
);
GO



-- =============================================
-- MS_Description for function and its parameters: DbInfo.ufnGetObjectDescriptions
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all descriptions of the specified object that are available in [sys].[extended_properties].',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescriptions';
GO

-- Description for parameter: @ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object in the current database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectDescriptions',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectId';
GO