USE [DatabaseName];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Calculates the age in full years based on the given birth date.
-- =============================================
CREATE FUNCTION [SchemaName].[ufnAge] 
(
	@BirthDate date
)
RETURNS int
AS
BEGIN
	
	DECLARE @Age int;

	SET @Age = CASE
					WHEN (@BirthDate IS NULL OR CAST(GETDATE() as date) IS NULL) THEN NULL
					WHEN MONTH(CAST(GETDATE() as date)) - MONTH(@BirthDate) < 0 THEN DATEDIFF(YEAR, @BirthDate, CAST(GETDATE() as date)) - 1
					WHEN MONTH(CAST(GETDATE() as date)) - MONTH(@BirthDate) > 0 THEN DATEDIFF(YEAR, @BirthDate, CAST(GETDATE() as date))
					WHEN DAY(CAST(GETDATE() as date)) - DAY(@BirthDate) < 0 THEN DATEDIFF(YEAR, @BirthDate, CAST(GETDATE() as date)) - 1
					ELSE DATEDIFF(YEAR, @BirthDate, CAST(GETDATE() as date))
				END;
	
	RETURN @Age;

END
GO

-- =============================================
-- MS_Description for the function.
-- =============================================

-- Description for the function itself.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Calculates the age in full years based on the input birth date. Returns an integer value or NULL if the input is NULL.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'FUNCTION', @level1name = N'ufnAge';

-- Description for the parameter @BirthDate.
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Date of birth used to calculate the age.',
    @level0type = N'SCHEMA', @level0name = N'SchemaName',
    @level1type = N'FUNCTION', @level1name = N'ufnAge',
    @level2type = N'PARAMETER', @level2name = N'@BirthDate';
GO