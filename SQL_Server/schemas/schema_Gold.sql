USE [DatabaseName];
GO

CREATE SCHEMA [Gold];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stores curated, highly refined data optimized for analytics, reporting, and business consumption.',
	@level0type=N'SCHEMA', @level0name=N'Gold';
GO