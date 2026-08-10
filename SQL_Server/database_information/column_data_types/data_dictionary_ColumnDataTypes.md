**Documentation for DbInfo.ColumnDataTypes:** Table contains data type information for columns in user-defined tables and views. It provides an overview of the data types used and can be used to identify opportunities for data type optimization and standardization.

| Column Name | Data Type | Column Description |
| -- | -- | -- |
| ObjectId | int | ID of the table or view object in the database. |
| ObjectType | nvarchar(5) | Type of the database object: Table or View. |
| SchemaId | int | ID of the schema containing the table or view. |
| SchemaName | nvarchar(128) | Name of the schema containing the table or view. |
| ObjectName | sysname(nvarchar(128)) | Name of the table or view containing the column. |
| ColumnId | int | Column ID assigned by SQL Server within the table or view. |
| ColumnName | sysname(nvarchar(128)) | Name of the column. |
| SystemTypeId | tinyint | Internal SQL Server system type ID of the column data type. |
| SystemType | nvarchar(128) | System data type of the column. |
| UserTypeId | int | Internal SQL Server user type ID of the column data type. |
| UserType | nvarchar(128) | Name of the user-defined or system data type. |
| DataType | nvarchar(517) | Detailed data type definition of the column, including length, precision, scale, MAX, XML schema collection, and user-defined type information where applicable. |