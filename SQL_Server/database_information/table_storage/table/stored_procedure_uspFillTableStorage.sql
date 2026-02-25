USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 25.02.2026
-- Description:	This stored procedure updates [DbInfo].[TableStorage] with the latest 
--              per-table storage and structure metrics.
-- =============================================
CREATE PROCEDURE [DbInfo].[uspFillTableStorage] 
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE [DbInfo].[TableStorage];

	WITH [cteTableColumnsCount] AS (
        SELECT
            [sc].[object_id] AS [TableId],
            COUNT(*) AS [TableColumnCount]
        FROM
            [sys].[columns] [sc]
        INNER JOIN
            [sys].[tables] [st] ON [sc].[object_id] = [st].[object_id]
        GROUP BY
            [sc].[object_id]
    ),

    [cteTableRowCount] AS (
        SELECT
            [sddps].[object_id] AS [TableId],
            SUM([sddps].[row_count]) AS [TableRowCount]
        FROM
            [sys].[dm_db_partition_stats] [sddps]
        INNER JOIN
            [sys].[tables] [st] ON [sddps].[object_id] = [st].[object_id]
        WHERE
            [sddps].[index_id] IN (0, 1)
        GROUP BY
            [sddps].[object_id]
    ),

    [cteTablePages] AS (
        SELECT 
            [t].[object_id] AS [TableId],
            SUM([au].[total_pages]) AS [TotalPages],
            SUM([au].[used_pages]) AS [UsedPages],
            SUM([au].[total_pages]) - SUM([au].[used_pages]) AS [UnusedPages],
            SUM([au].[used_pages]) - SUM(CASE WHEN [i].[index_id] IN (0, 1) THEN [au].[data_pages] ELSE 0 END) AS [IndexPages],
            SUM(CASE WHEN [i].[index_id] IN (0, 1) THEN [au].[data_pages] ELSE 0 END) AS [DataPages]
        FROM 
            [sys].[tables] [t]
        INNER JOIN      
            [sys].[indexes] [i] ON [t].[object_id] = [i].[object_id]
        INNER JOIN 
            [sys].[partitions] [p] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
        INNER JOIN 
            [sys].[allocation_units] [au] ON [au].[container_id] = CASE WHEN [au].[type] IN (1, 3) THEN [p].[hobt_id] ELSE [p].[partition_id] END 
        GROUP BY 
            [t].[object_id]
    )

    INSERT INTO
        [DbInfo].[TableStorage]
    SELECT
        [t].[object_id] AS [TableId],
        SCHEMA_NAME([t].[schema_id]) AS [TableSchema],
        [t].[name] AS [TableName],
        QUOTENAME(SCHEMA_NAME([t].[schema_id])) + '.' + QUOTENAME([t].[name]) AS [TableFullyQualifiedName],
        [cteTCC].[TableColumnCount],
        [cteTRC].[TableRowCount],
        ISNULL([cteTS].[TotalPages], 0) * 8 AS [ReservedSpaceKB],
        (1.0 * ISNULL([cteTS].[TotalPages], 0) * 8) / 1024 AS [ReservedSpaceMB],
        (1.0 * ISNULL([cteTS].[TotalPages], 0) * 8) / 1024 / 1024 AS [ReservedSpaceGB],
        ISNULL([cteTS].[UsedPages], 0) * 8 AS [UsedSpaceKB],
        (1.0 * ISNULL([cteTS].[UsedPages], 0) * 8) / 1024 AS [UsedSpaceMB],
        (1.0 * ISNULL([cteTS].[UsedPages], 0) * 8) / 1024 / 1024 AS [UsedSpaceGB],
        ISNULL([cteTS].[UnusedPages], 0) * 8 AS [UnusedSpaceKB],
        (1.0 * ISNULL([cteTS].[UnusedPages], 0) * 8) / 1024 AS [UnusedSpaceMB],
        (1.0 * ISNULL([cteTS].[UnusedPages], 0) * 8) / 1024 / 1024 AS [UnusedSpaceGB],
        ISNULL([cteTS].[IndexPages], 0) * 8 AS [IndexSizeKB],
        (1.0 * ISNULL([cteTS].[IndexPages], 0) * 8) / 1024 AS [IndexSizeMB],
        (1.0 * ISNULL([cteTS].[IndexPages], 0) * 8) / 1024 / 1024 AS [IndexSizeGB],
        ISNULL([cteTS].[DataPages], 0) * 8 AS [DataSizeKB],
        (1.0 * ISNULL([cteTS].[DataPages], 0) * 8) / 1024 AS [DataSizeMB],
        (1.0 * ISNULL([cteTS].[DataPages], 0) * 8) / 1024 / 1024 AS [DataSizeGB]    
    FROM 
        [sys].[tables] [t]
    LEFT JOIN
        [cteTableColumnsCount] [cteTCC] ON [t].[object_id] = [cteTCC].[TableId]
    LEFT JOIN
        [cteTableRowCount] [cteTRC] ON [t].[object_id] = [cteTRC].[TableId]
    LEFT JOIN
        [cteTablePages] [cteTS] ON [t].[object_id] = [cteTS].[TableId];
END
GO


-- ===========================================================
-- MS_Description for the stored procedure uspFillTableStorage
-- ===========================================================

-- Stored procedure description.
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'This stored procedure updates [DbInfo].[TableStorage] with the latest per-table storage and structure metrics.',
    @level0type = N'SCHEMA', @level0name = N'DbInfo',
    @level1type = N'PROCEDURE', @level1name = N'uspFillTableStorage';
GO