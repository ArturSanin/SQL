USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Artur Sanin
-- Create date: 2026-08-30
-- Description:	Returns a specified number of random 
--				columns and rows from a randomly chosen 
--				user-defined table or view. The name of the chosen
--				table or view is printed in the Messages tab (SSMS).
--				Caution: Any value greater than 1 is converted to 
--				1 for the bit parameter @RandomColumnOrder.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspRandomTable]
(
	@NumberOfColumns int = 1,
	@RandomColumnOrder bit = 0,
	@Rows int = 1
)
AS
BEGIN	
	SET NOCOUNT ON;

	IF @NumberOfColumns <= 0 BEGIN
		DECLARE @ColumnsError nvarchar(512) = N'The number of columns must be greater than 0. Number of columns provided: ' + CAST(@NumberOfColumns AS nvarchar(128));
		THROW 51000, @ColumnsError, 1;
	END
	ELSE IF @Rows <= 0 BEGIN
		DECLARE @RowError nvarchar(512) = N'The number of rows must be greater than 0. Number of rows provided: ' + CAST(@Rows AS nvarchar(128));
		THROW 51000, @RowError, 1;
	END
	ELSE BEGIN
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
END;
GO



-- =============================================
-- MS_Description for procedure and its parameters: dbo.uspRandomTable
-- =============================================

-- Description for procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns a specified number of random columns and rows from a randomly chosen user-defined table or view.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomTable';
GO

-- Description for parameter: @NumberOfColumns
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The number of random columns to return. Must be greater than 0.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomTable',
	 @level2type = N'PARAMETER', @level2name = N'@NumberOfColumns';
GO

-- Description for parameter: @RandomColumnOrder
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Specifies whether the returned columns should be ordered randomly. 0 = no, 1 = yes.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomTable',
	 @level2type = N'PARAMETER', @level2name = N'@RandomColumnOrder';
GO

-- Description for parameter: @Rows
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The number of random rows to return. Must be greater than 0.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomTable',
	 @level2type = N'PARAMETER', @level2name = N'@Rows';
GO