**Table description:** Table that stores the relationships between foreign key constraints and the primary key or unique key constraints they reference. Each row represents one foreign key definition, including the table where it is defined and the table and key it points to..

| Column Name | Data Type | Description |
| :----- | :----- | :----- |
| ReferencingTableID | int | The object ID of the table that contains the foreign key. | 
| ReferencingTableSchema | sysname(nvarchar(128)) | The schema of the referencing table. | 
| ReferencingTableName | sysname(nvarchar(128)) | The name of the referencing table. |
| ForeignKeyID | int | The object ID of the foreign key constraint. |
| ForeignKeyName | sysname(nvarchar(128)) | The number of columns included in the foreign key. |
| ForeignKeyColumnCount | int | Number of columns that are included in the foreign key. |
| ForeignKeyColumns | nvarchar(4000) | List of columns forming the foreign key, formatted as (Foreign Key Column ID, Column Name, Ordinal Position in the Table). |
| ReferencedTableID | int | The object ID of the table containing the referenced primary or unique key. |
| ReferencedTableSchema | sysname(nvarchar(128)) | The schema of the referenced table. |
| ReferencedTableName | sysname(nvarchar(128)) | The name of the referenced table. |
| ReferencedKeyType | nvarchar(128) | Type of the referenced constraint (Primary Key or Unique). |
| ReferencedKeyID | int | The object ID of the referenced primary key or unique constraint. |
| ReferencedKeyName | sysname(nvarchar(128)) | The name of the referenced primary key or unique constraint. |
| ReferencedKeyColumnCount | int | The number of columns included in the referenced key constraint. |
| ReferencedKeyColumns | nvarchar(4000) | Columns forming the referenced primary key or unique constraint, formatted as (Key Column ID, Column Name, Ordinal Position in the Table). |