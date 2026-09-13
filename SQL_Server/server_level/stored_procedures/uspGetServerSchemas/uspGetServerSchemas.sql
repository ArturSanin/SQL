USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-13
-- Description:	Returns all schemas of user-created 
--				databases (database ID > 4) on the 
--				server. Depending on @SchemaType, 
--				either all schemas or only user-created 
--				schemas are returned.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetServerSchemas]
(
	@SchemaType nvarchar(4) = N'User'
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @SchemaType NOT IN (N'All', N'User') BEGIN
		;THROW 50000, N'@SchemaType has to be All or User.', 1;
	END
	ELSE BEGIN
		DECLARE @SqlCommand nvarchar(max) = N'';

		SELECT
			@SqlCommand =
			STRING_AGG(
				CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
				CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[s].[schema_id] AS [SchemaId],' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[s].[name] COLLATE DATABASE_DEFAULT AS [SchemaName],' + CHAR(13) + CHAR(10) +
				CHAR(9) + N'[dp].[name] COLLATE DATABASE_DEFAULT AS [PrincipalName]' + CHAR(13) + CHAR(10) +
				N'FROM' + CHAR(13) + CHAR(10) +
				CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s]' + CHAR(13) + CHAR(10) + 
				N'LEFT JOIN' + CHAR(13) + CHAR(10) +
				CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[database_principals] [dp] ON [s].[principal_id] = [dp].[principal_id]' +
				CASE
					WHEN @SchemaType = N'All'
						THEN N''
					WHEN @SchemaType = N'User'
						THEN CHAR(13) + CHAR(10) +
						N'WHERE' + CHAR(13) + CHAR(10) +
						CHAR(9) + N'[s].[schema_id] BETWEEN 5 AND 16383'
				END,
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10) +
				N'UNION ALL' + CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10)
			) + CHAR(13) + CHAR(10) +
			N'ORDER BY' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[DatabaseName] ASC,' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[SchemaId] ASC;'
		FROM
			[sys].[databases] [d]
		WHERE
			[d].[database_id] > 4;
	
		EXEC [sys].[sp_executesql] @SqlCommand;
	END;
END;
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspGetServerSchemas
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns all schemas of user-created databases (database ID > 4) on the server. Depending on @SchemaType, either all schemas or only user-created schemas are returned.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetServerSchemas';
GO

-- Description for parameter: @SchemaType
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Specifies which schemas are returned. Must be either All or User. The default value is User.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetServerSchemas',
	 @level2type = N'PARAMETER', @level2name = N'@SchemaType';
GO