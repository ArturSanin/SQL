**Table description:** This table provides an overview of each table’s structure and storage usage, including the number of columns, row count, and the amount of reserved, used, unused, data, and index space.

| Column Name | Data Type | Description |
| :----- | :----- | :----- |
| TableId | int | Object ID of the table. | 
| TableSchema | nvarchar(128) | Name of the schema the table belongs to. |
| TableName | sysname(nvarchar(128)) | Name of the table. |
| TableFullyQualifiedName | nvarchar(517) | Fully qualified table name in the form [Schema].[TableName]. |
| TableColumnCount | int | Number of columns in the table. |
| TableRowCount | bigint | Total number of rows in the table. |
| ReservedSpaceKB | bigint | Total reserved space of the table in KB. |
| ReservedSpaceMB | numeric(29,6) | Total reserved space of the table in MB. |
| ReservedSpaceGB | numeric(34,11) | Total reserved space of the table in GB. |
| UsedSpaceKB | bigint | Total used space of the table in KB. |
| UsedSpaceMB | numeric(29,6) | Total used space of the table in MB. |
| UsedSpaceGB | numeric(34,11) | Total used space of the table in GB. |
| UnusedSpaceKB | bigint | Total unused (allocated but not used) space of the table in KB. |
| UnusedSpaceMB | numeric(29,6) | Total unused (allocated but not used) space of the table in MB. |
| UnusedSpaceGB | numeric(34,11) | Total unused (allocated but not used) space of the table in GB. |
| IndexSizeKB | bigint | Space used by indexes in the table in KB. |
| IndexSizeMB | numeric(29,6) | Space used by indexes in the table in MB. |
| IndexSizeGB | numeric(34,11) | Space used by indexes in the table in GB. |
| DataSizeKB | bigint | Space used by actual table data (heap or clustered index) in KB. |
| DataSizeMB | numeric(29,6) | Space used by actual table data (heap or clustered index) in MB. |
| DataSizeGB | numeric(34,11) | Space used by actual table data (heap or clustered index) in GB. |