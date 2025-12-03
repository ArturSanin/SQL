USE [DatabaseName];
GO

CREATE SCHEMA [Bronze];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stores raw, ingested data in its original form. Serves as the source for downstream layers and preserves a complete, auditable record of the source data.',
	@level0type=N'SCHEMA', @level0name=N'Bronze';
GO