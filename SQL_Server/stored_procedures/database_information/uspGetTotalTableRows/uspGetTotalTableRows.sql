USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-08-30
-- Description:	Returns the total number of rows
--				in user-defined tables in the database.
-- =============================================
CREATE OR ALTER PROCEDURE [DbInfo].[uspGetTotalTableRows]
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE @SqlCommand nvarchar(max) = N'';

	SELECT
		@SqlCommand =
		N'WITH [cteRowCounts] AS (' + CHAR(13) + CHAR(10) + 
		STRING_AGG(
			CHAR(9) + CAST(N'SELECT COUNT(*) AS [RowCount] FROM ' AS nvarchar(max)) + QUOTENAME(SCHEMA_NAME([t].[schema_id])) + N'.' + QUOTENAME([t].[name]),
			CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10) + 
			CHAR(9) + N'UNION ALL' + CHAR(13) + CHAR(10) + 
			CHAR(13) + CHAR(10)
		) + CHAR(13) + CHAR(10) + 
		N')' + CHAR(13) + CHAR(10) +
		CHAR(13) + CHAR(10) +
		N'SELECT' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'SUM([RowCount]) AS [Total Table Rows in ' + DB_NAME() + N']' + CHAR(13) + CHAR(10) +
		N'FROM' + CHAR(13) + CHAR(10) +
		CHAR(9) + N'[cteRowCounts];'
	FROM
		[sys].[tables] [t]
	WHERE
		[t].[is_ms_shipped] = 0;

	IF @SqlCommand IS NULL BEGIN
		SET @SqlCommand = N'SELECT 0 AS [Total Table Rows in ' + DB_NAME() + N']';
	END;

	EXEC [sys].[sp_executesql] @SqlCommand;
END;
GO



-- =============================================
-- MS_Description for procedure: DbInfo.uspGetTotalTableRows
-- =============================================

-- Description for procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns the total number of rows in user-defined tables in the database.',
	 @level0type = N'SCHEMA', @level0name = N'DbInfo',
	 @level1type = N'PROCEDURE', @level1name = N'uspGetTotalTableRows';
GO