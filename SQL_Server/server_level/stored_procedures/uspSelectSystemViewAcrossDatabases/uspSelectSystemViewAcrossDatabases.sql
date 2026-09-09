USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Selects all columns across all 
--				user-created databases (database ID > 4) 
--				from a specified system view in 
--				the schema INFORMATION_SCHEMA or 
--				sys.
-- =============================================
CREATE PROCEDURE [dbo].[uspSelectSystemViewAcrossDatabases]
(
	@SchemaName sysname,
	@ViewName sysname
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ObjectType char(2);

	SELECT
		@ObjectType = [ao].[type]
	FROM
		[sys].[all_objects] [ao]
	INNER JOIN
		[sys].[schemas] [s] ON [ao].[schema_id] = [s].[schema_id] 
	WHERE
		[s].[name] = @SchemaName
	AND
		[ao].[name] = @ViewName;

	IF @SchemaName NOT IN (N'INFORMATION_SCHEMA', N'sys') BEGIN
		;THROW 50000, N'The specified schema must be INFORMATION_SCHEMA or sys.', 1;
	END
	ELSE IF @ObjectType IS NULL OR @ObjectType <> N'V' BEGIN
		;THROW 50000, N'The specified object is not a system view.', 1;
	END
	ELSE BEGIN
		DECLARE 
			@SqlCommand nvarchar(max) = N'',
			@Columns nvarchar(max) = N'';

		SELECT
			@Columns =
			STRING_AGG(
				CHAR(9) + CAST(QUOTENAME([ac].[name]) AS nvarchar(max)) + 
				CASE
					WHEN [ac].[collation_name] IS NOT NULL
						THEN N' COLLATE DATABASE_DEFAULT AS ' + QUOTENAME([ac].[name]) 
					ELSE
						N''
				END,
				N',' + CHAR(13) + CHAR(10)
			)
		FROM
			[sys].[all_columns] [ac]
		WHERE
			[ac].[object_id] = OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ViewName));

		SELECT
			@SqlCommand =
			STRING_AGG(
				CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
				CHAR(9) + N'N''' + [d].[name] + N''' COLLATE DATABASE_DEFAULT AS [database_name],' + CHAR(13) + CHAR(10) +
				@Columns + CHAR(13) + CHAR(10) +
				N'FROM' + CHAR(13) + CHAR(10) +
				CHAR(9) + QUOTENAME([d].[name]) + N'.' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ViewName) 
				,
				CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10) +
				N'UNION ALL' + CHAR(13) + CHAR(10) +
				CHAR(13) + CHAR(10)
			) + N';'
		FROM
			[sys].[databases] [d]
		WHERE
			[d].[database_id] > 4;

		EXEC [sys].[sp_executesql] @SqlCommand;
	END
END
GO



-- =============================================
-- MS_Description for stored procedure and its parameters:
-- dbo.uspSelectSystemViewAcrossDatabases
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Selects all columns across all user-created databases (database ID > 4) from a specified system view in the schema INFORMATION_SCHEMA or sys.',
	@level0type = N'SCHEMA', @level0name = N'dbo',
	@level1type = N'PROCEDURE', @level1name = N'uspSelectSystemViewAcrossDatabases';
GO

-- Description for parameter: @SchemaName
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'The schema name of the system view. Must be INFORMATION_SCHEMA or sys.',
	@level0type = N'SCHEMA', @level0name = N'dbo',
	@level1type = N'PROCEDURE', @level1name = N'uspSelectSystemViewAcrossDatabases',
	@level2type = N'PARAMETER', @level2name = N'@SchemaName';
GO

-- Description for parameter: @ViewName
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'The name of the system view to select from.',
	@level0type = N'SCHEMA', @level0name = N'dbo',
	@level1type = N'PROCEDURE', @level1name = N'uspSelectSystemViewAcrossDatabases',
	@level2type = N'PARAMETER', @level2name = N'@ViewName';
GO