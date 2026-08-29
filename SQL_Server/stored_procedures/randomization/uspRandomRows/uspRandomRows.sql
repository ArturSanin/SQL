USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Returns a specified number of random rows
--				from the specified table or view.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[uspRandomRows]
(
	@Schema sysname,
	@Name sysname,
	@Rows int = 1
)
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE @QuotedName nvarchar(512) = QUOTENAME(@Schema) + N'.' + QUOTENAME(@Name);
	DECLARE @ObjectId int = OBJECT_ID(@QuotedName);
	DECLARE 
		@Type char(2),
		@TypeDescription nvarchar(60);

	SELECT
		@Type = [ao].[type],
		@TypeDescription = [ao].[type_desc]
	FROM
		[sys].[all_objects] [ao]
	WHERE
		[ao].[object_id] = @ObjectId;

	IF @ObjectId IS NULL BEGIN
		DECLARE @ObjectError nvarchar(512) = N'The object ' + @QuotedName + N' does not exist in the database.';
		THROW 50000, @ObjectError, 1;
	END
	ELSE IF @Type NOT IN (N'U', N'V') BEGIN
		DECLARE @TypeError nvarchar(512) = N'The specified object must be a user table or view. Current object type: ' + @TypeDescription;
		THROW 51000, @TypeError, 1;
	END
	ELSE IF @Rows <= 0 BEGIN
		DECLARE @RowError nvarchar(512) = N'The number of rows must be greater than 0. Number of rows provided: ' + CAST(@Rows AS nvarchar(128));
		THROW 51000, @RowError, 1;
	END
	ELSE BEGIN
		DECLARE @SqlCommand nvarchar(max) = N'';

		SELECT
			@SqlCommand =
			CAST(N'SELECT TOP (' AS nvarchar(max)) + CAST(@Rows AS nvarchar(128)) + N')' + CHAR(13) + CHAR(10) +
			CHAR(9) + STRING_AGG(
				QUOTENAME([ac].[name]),
				N', ' + CHAR(13) + CHAR(10) + CHAR(9)
			) + CHAR(13) + CHAR(10) + 
			N'FROM' + CHAR(13) + CHAR(10) + 
			CHAR(9) + @QuotedName + CHAR(13) + CHAR(10) +
			N'ORDER BY' + CHAR(13) + CHAR(10) +
			CHAR(9) + N'NEWID();'
		FROM
			[sys].[all_columns] [ac]
		WHERE
			[ac].[object_id] = @ObjectId;

		EXEC [sys].[sp_executesql] @SqlCommand;
	END;
END;
GO



-- =============================================
-- MS_Description for procedure and its parameters: dbo.uspRandomRows
-- =============================================

-- Description for procedure
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'Returns a specified number of random rows from the specified table or view.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomRows';
GO

-- Description for parameter: @Schema
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the schema containing the table or view.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomRows',
	 @level2type = N'PARAMETER', @level2name = N'@Schema';
GO

-- Description for parameter: @Name
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The name of the table or view.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomRows',
	 @level2type = N'PARAMETER', @level2name = N'@Name';
GO

-- Description for parameter: @Rows
EXEC [sys].[sp_addextendedproperty]
	 @name = N'MS_Description',
	 @value = N'The number of random rows to return. Must be greater than 0.',
	 @level0type = N'SCHEMA', @level0name = N'dbo',
	 @level1type = N'PROCEDURE', @level1name = N'uspRandomRows',
	 @level2type = N'PARAMETER', @level2name = N'@Rows';
GO