USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-13
-- Description:	Returns the size of all 
--				tables in user-created databases 
--				(database ID > 4) on the server 
--				in kilobytes, megabytes, and gigabytes.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetServerTableSizes] 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@SqlTablePages nvarchar(max) = N'',
		@SqlSelect nvarchar(max) = N'',
		@SqlCommand nvarchar(max) = N'';

	SELECT
		@SqlTablePages =
		STRING_AGG(
			CHAR(9) + CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[t].[object_id] AS [TableId],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'SUM([au].[total_pages]) AS [TotalPages],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'SUM([au].[used_pages]) AS [UsedPages],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'SUM([au].[total_pages]) - SUM([au].[used_pages]) AS [UnusedPages],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'SUM([au].[used_pages]) - SUM(CASE WHEN [i].[index_id] IN (0, 1) THEN [au].[data_pages] ELSE 0 END) AS [IndexPages],' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'SUM(CASE WHEN [i].[index_id] IN (0, 1) THEN [au].[data_pages] ELSE 0 END) AS [DataPages]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[tables] [t]' + CHAR(13) + CHAR(10) + 
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[indexes] [i] ON [t].[object_id] = [i].[object_id]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[partitions] [p] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[allocation_units] [au] ON [au].[container_id] = CASE WHEN [au].[type] IN (1, 3) THEN [p].[hobt_id] ELSE [p].[partition_id] END' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'GROUP BY' + CHAR(13) + CHAR(10) +
			CHAR(9) + CHAR(9) + N'[t].[object_id]',
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10) +
			CHAR(9) + N'UNION ALL' + CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10)
		),
		@SqlSelect =
		STRING_AGG(
			CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
			CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[t].[object_id] AS [TableId],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[s].[name] COLLATE DATABASE_DEFAULT AS [TableSchema],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[t].[name] COLLATE DATABASE_DEFAULT AS [TableName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'ISNULL([cteTP].[TotalPages], 0) * 8 AS [ReservedSpaceKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[TotalPages], 0) * 8) / 1024.0 AS [ReservedSpaceMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[TotalPages], 0) * 8) / 1024.0 / 1024.0 AS [ReservedSpaceGB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'ISNULL([cteTP].[UsedPages], 0) * 8 AS [UsedSpaceKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[UsedPages], 0) * 8) / 1024.0 AS [UsedSpaceMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[UsedPages], 0) * 8) / 1024.0 / 1024.0 AS [UsedSpaceGB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'ISNULL([cteTP].[UnusedPages], 0) * 8 AS [UnusedSpaceKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[UnusedPages], 0) * 8) / 1024.0 AS [UnusedSpaceMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[UnusedPages], 0) * 8) / 1024.0 / 1024.0 AS [UnusedSpaceGB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'ISNULL([cteTP].[IndexPages], 0) * 8 AS [IndexSizeKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[IndexPages], 0) * 8) / 1024.0 AS [IndexSizeMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[IndexPages], 0) * 8) / 1024.0 / 1024.0 AS [IndexSizeGB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'ISNULL([cteTP].[DataPages], 0) * 8 AS [DataSizeKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[DataPages], 0) * 8) / 1024.0 AS [DataSizeMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'(ISNULL([cteTP].[DataPages], 0) * 8) / 1024.0 / 1024.0 AS [DataSizeGB]' + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[tables] [t]' + CHAR(13) + CHAR(10) + 
			N'INNER JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[schemas] [s] ON [t].[schema_id] = [s].[schema_id]' + CHAR(13) + CHAR(10) +
			N'LEFT JOIN' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'[cteTablePages] [cteTP] ON [cteTP].[DatabaseName] = ' + N'N''' + REPLACE([d].[name], N'''', N'''''') + ''' AND [t].[object_id] = [cteTP].[TableId]',
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			N'UNION ALL' + CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10)
		) + CHAR(13) + CHAR(10) +
		N'ORDER BY' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[DatabaseName] ASC,' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[TableSchema] ASC,' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[TableName] ASC;'
	FROM
		[sys].[databases] [d]
	WHERE
		[d].[database_id] > 4;

	SET @SqlCommand = 
	N'WITH [cteTablePages] AS (' + CHAR(13) + CHAR(10) +
	@SqlTablePages + CHAR(13) + CHAR(10) +
	N')' + CHAR(13) + CHAR(10) +
	CHAR(13) + CHAR(10) +
	@SqlSelect;

	EXEC [sys].[sp_executesql] @SqlCommand;
END;
GO



-- =============================================
-- MS_Description for stored procedure:
-- dbo.uspGetServerTableSizes
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the size of all tables in user-created databases (database ID > 4) on the server in kilobytes, megabytes, and gigabytes.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetServerTableSizes';
GO