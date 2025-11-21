**Table description:** Table containing all primary keys in the database that are not referenced by any foreign key.

| Column Name | Data Type | Description |
| :----- | :----- | :----- |
| TableID | int | The object ID of the table that contains the unreferenced primary key. | 
| TableSchema | sysname(nvarchar(128)) | The schema name of the table that contains the unreferenced primary key. | 
| TableName | sysname(nvarchar(128)) | The name of the table that contains the unreferenced primary key. | 
| PrimaryKeyID | int | The object ID of the unreferenced primary key. | 
| PrimaryKeyName | sysname(nvarchar(128)) | The name of the unreferenced primary key. |
| PrimaryKeyColumnCount | int | Total number of columns included in the unreferenced primary key. |
| PrimaryKeyColumns | nvarchar(4000) | All columns that are part of the unreferenced primary key (excluding included columns), formatted as (Index ID, Column Name, Ordinal Position in the Table). |
