USE [DatabaseName];
GO

CREATE SCHEMA [Stats];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Schema containing tables and views that provide various statistics on tables.',
	@level0type=N'SCHEMA', @level0name=N'Stats';
GO