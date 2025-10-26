USE [DatabaseName];
GO

/*
	============================== Description ==============================
	This query summarizes various pieces of information in the database at the 
	schema level. 
*/

SELECT
	[s].[schema_id]
FROM
	[sys].[schemas] [s]
ORDER BY
	[s].[schema_id];