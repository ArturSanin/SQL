USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-09-12
-- Description:	Returns the current size of all 
--				user-created databases (database ID > 4) 
--				on the server in kilobytes, megabytes, 
--				and gigabytes.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspGetDatabaseSizes] 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SqlCommand nvarchar(max) = N'';

	SELECT
		@SqlCommand =
		STRING_AGG(
			CAST(N'SELECT' AS nvarchar(max)) + CHAR(13) + CHAR(10) +
			CHAR(9) + N'N''' + REPLACE([d].[name], N'''', N'''''') + N''' COLLATE DATABASE_DEFAULT AS [DatabaseName],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'CAST(8 * SUM([df].[size]) AS decimal(18,2)) AS [DatabaseSizeKB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'CAST((8 * SUM([df].[size])) / 1024.0 AS decimal(18,2)) AS [DatabaseSizeMB],' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'CAST((8 * SUM([df].[size])) / 1024.0 / 1024.0 AS decimal(18,2)) AS [DatabaseSizeGB]' + CHAR(13) + CHAR(10) +
			N'FROM' + CHAR(13) + CHAR(10) +
			CHAR(9) + QUOTENAME([d].[name]) + N'.[sys].[database_files] [df]',
			CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10) +
			N'UNION ALL' + CHAR(13) + CHAR(10) +
			CHAR(13) + CHAR(10)
		) + CHAR(13) + CHAR(10) +
		N'ORDER BY' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[DatabaseName] ASC;'
	FROM
		[sys].[databases] [d]
	WHERE
		[d].[database_id] > 4;
	
	EXEC [sys].[sp_executesql] @SqlCommand;
END;
GO



-- =============================================
-- MS_Description for stored procedure:
-- dbo.uspGetDatabaseSizes
-- =============================================

-- Description for stored procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the current size of all user-created databases (database ID > 4) on the server in kilobytes, megabytes, and gigabytes.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetDatabaseSizes';
GO