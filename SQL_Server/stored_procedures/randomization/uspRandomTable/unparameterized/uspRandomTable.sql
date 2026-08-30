USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-08-30
-- Description:	Returns a random number of
--				columns and rows (up to 10,000 each) 
--				from a randomly chosen user-defined table or view. 
--				The name of the chosen table or view is printed in 
--				the Messages tab (SSMS).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspRandomTable]
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE
		@NumberOfColumns int = FLOOR(1 + 9999 * RAND()),
		@RandomColumnOrder bit = CAST(ROUND(RAND(), 0) AS bit),
		@Rows int = FLOOR(1 + 9999 * RAND());

	DECLARE 
		@Schema sysname,
		@Name sysname,
		@TypeDescription nvarchar(60);

	SELECT TOP (1)
		@Schema = SCHEMA_NAME([o].[schema_id]),
		@Name = [o].[name],
		@TypeDescription = [o].[type_desc] 
	FROM
		[sys].[objects] [o]
	WHERE
		[o].[is_ms_shipped] = 0
	AND
		[o].[type] IN (N'U', N'V')
	ORDER BY
		NEWID();

	DECLARE @QuotedName nvarchar(512) = QUOTENAME(@Schema) + N'.' + QUOTENAME(@Name);
	DECLARE @ObjectId int = OBJECT_ID(@QuotedName);

	DECLARE
		@SqlSetCommand nvarchar(max) = N'',
		@SqlCommand nvarchar(max) = N'';

	SET @SqlSetCommand =
	N'
	SELECT
		@SqlCommand =
		CAST(N''SELECT TOP ('' AS nvarchar(max)) + CAST(@Rows AS nvarchar(128)) + N'')'' + CHAR(13) + CHAR(10) +
		CHAR(9) + STRING_AGG(
			QUOTENAME([ac].[ColumnName]),
			N'', '' + CHAR(13) + CHAR(10) + CHAR(9)
		) ' + CASE WHEN @RandomColumnOrder = 0 THEN N'WITHIN GROUP(ORDER BY [ac].[OrdinalPosition] ASC)' WHEN @RandomColumnOrder = 1 THEN N'' END + N' + CHAR(13) + CHAR(10) + 
		N''FROM'' + CHAR(13) + CHAR(10) + 
		CHAR(9) + @QuotedName + CHAR(13) + CHAR(10) +
		N''ORDER BY'' + CHAR(13) + CHAR(10) +
		CHAR(9) + N''NEWID();''
	FROM (
		SELECT TOP (@NumberOfColumns)
			COLUMNPROPERTY([object_id], [name], N''ordinal'') AS [OrdinalPosition],
			[name] AS [ColumnName]
		FROM
			[sys].[all_columns]
		WHERE
			[object_id] = @ObjectId
		ORDER BY
			NEWID()
	) [ac];'

	EXEC [sys].[sp_executesql]
			@SqlSetCommand,
			N'@SqlCommand nvarchar(max) OUTPUT,
			@NumberOfColumns int,
			@Rows int,
			@ObjectId int,
			@QuotedName nvarchar(512)',
			@SqlCommand = @SqlCommand OUTPUT,
			@NumberOfColumns = @NumberOfColumns,
			@Rows = @Rows,
			@ObjectId = @ObjectId,
			@QuotedName = @QuotedName;

	EXEC [sys].[sp_executesql] @SqlCommand;

	PRINT N'Source object: ' + @Schema + N'.' + @Name + N' (' + @TypeDescription + N')';
END;
GO



-- =============================================
-- MS_Description for procedure: dbo.uspRandomTable
-- =============================================

-- Description for procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns a random number of columns and rows (up to 10,000 each) from a randomly chosen user-defined table or view.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomTable';
GO