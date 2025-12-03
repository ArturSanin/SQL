USE [DatabaseName];
GO

CREATE SCHEMA [Silver];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stores cleaned, standardized, and enriched data. Serves as a reliable intermediate layer for downstream analytics and reporting.',
	@level0type=N'SCHEMA', @level0name=N'Silver';
GO