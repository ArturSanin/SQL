USE [DatabaseName];
GO

CREATE SCHEMA [DbInfo];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Schema containing objects that provide metadata and information about the database and its objects.',
	@level0type=N'SCHEMA', @level0name=N'DbInfo';
GO