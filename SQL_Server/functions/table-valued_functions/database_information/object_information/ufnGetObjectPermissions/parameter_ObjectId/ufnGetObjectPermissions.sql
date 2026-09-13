USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-13
-- Description:	Returns all permissions granted on the specified
--				object from [sys].[database_permissions].
--				Column-level permissions are excluded.
-- =============================================
CREATE OR ALTER FUNCTION [DbInfo].[ufnGetObjectPermissions]
(
	@ObjectId int
)
RETURNS TABLE
AS
RETURN
(		
	SELECT
		OBJECT_SCHEMA_NAME([dp].[major_id]) AS [ObjectSchema],
		OBJECT_NAME([dp].[major_id]) AS [ObjectName],
		[grantor].[name] AS [Grantor],
		[dp].[state_desc] AS [PermissionState],
		[dp].[permission_name] AS [PermissionName],
		[grantee].[name] AS [Grantee]
	FROM
		[sys].[database_permissions] [dp]
	LEFT JOIN
		[sys].[database_principals] [grantor] ON [dp].[grantor_principal_id] = [grantor].[principal_id]
	LEFT JOIN
		[sys].[database_principals] [grantee] ON [dp].[grantee_principal_id] = [grantee].[principal_id]
	WHERE
		[dp].[major_id] = @ObjectId
	AND
		[dp].[class] = 1
	AND
		[dp].[minor_id] = 0
);
GO



-- =============================================
-- MS_Description for function and its parameters: 
-- DbInfo.ufnGetObjectPermissions
-- =============================================

-- Description for function
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all permissions granted on the specified object from [sys].[database_permissions]. Only object-level permissions are returned; column-level permissions are excluded.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectPermissions';
GO

-- Description for parameter: @ObjectId
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The object ID of the object in the current database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'FUNCTION', @level1name = N'ufnGetObjectPermissions',
	 @level2type = N'PARAMETER', @level2name = N'@ObjectId';
GO