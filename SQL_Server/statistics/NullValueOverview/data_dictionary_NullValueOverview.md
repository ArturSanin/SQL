**Table description:** Table that stores NULL and NOT NULL statistics of all user-defined tables and views in the database.

| Column Name | Data Type | Description |
| :----- | :----- | :----- |
| TableType | nvarchar(60) | Type of the table (User table, View). | 
| TableSchema | sysname(nvarchar(128)) | Schema of the table/view. | 
| TableName | sysname(nvarchar(128)) | Name of the table/view. |
| CellCount | bigint | Number of cells in the table/view (Rows × Columns). | 
| NullCount | int | Total number of NULL values in the table/view. | 
| NullRatio | decimal(18,6) | Ratio of NULL values (NullCount / CellCount). |
| NullPercentage | decimal(5,2) | Percentage of NULL values in the table/view. | 
| NotNullCount | int | Total number of NOT NULL values in the table/view. | 
| NotNullRatio | decimal(18,6) | Ratio of NOT NULL values (NotNullCount / CellCount). |
| NotNullPercentage | decimal(5,2) | Percentage of NOT NULL values in the table/view. |