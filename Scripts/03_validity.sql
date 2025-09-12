-- Validity Check
-- Generic data rules (IDs > 0, Dates valid, No negative numerics, No empty strings)
-- Creates a view: DQ_InvalidData

DECLARE @SchemaName NVARCHAR(128) = 'dbo';
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @ViewName NVARCHAR(128) = 'DQ_InvalidData';  -- view name

-- Drop the view if it already exists
IF OBJECT_ID(@ViewName, 'V') IS NOT NULL
    EXEC('DROP VIEW ' + @ViewName);

-- Collect column-level validation rules based on data type
SELECT @sql = COALESCE(@sql, '') + '
SELECT ''' + c.TABLE_SCHEMA + '.' + c.TABLE_NAME + ''' AS TableName,
       ''' + c.COLUMN_NAME + ''' AS ColumnName,
       COUNT(*) AS InvalidCount,
       ''' + DATA_TYPE + ''' AS DataType,
       ''' + 
            CASE 
                WHEN c.COLUMN_NAME LIKE '%id%' AND DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint') THEN 'ID <= 0'
                WHEN DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real') THEN 'Value < 0'
                WHEN DATA_TYPE IN ('date', 'datetime', 'smalldatetime') THEN 'Date out of range (before 1900-01-01 or after 10 years)'
                WHEN DATA_TYPE IN ('nvarchar', 'varchar', 'char', 'nchar', 'text', 'ntext') THEN 'Empty or whitespace string'
                ELSE 'No check'
            END + ''' AS Validity_Rule
FROM [' + c.TABLE_SCHEMA + '].[' + c.TABLE_NAME + ']
WHERE ' +
            CASE 
                WHEN c.COLUMN_NAME LIKE '%id%' AND DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint') THEN '[' + c.COLUMN_NAME + '] <= 0'
                WHEN DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real') THEN '[' + c.COLUMN_NAME + '] < 0'
                WHEN DATA_TYPE IN ('date', 'datetime', 'smalldatetime') THEN '([' + c.COLUMN_NAME + '] IS NOT NULL AND ([' + c.COLUMN_NAME + '] < ''1900-01-01'' OR [' + c.COLUMN_NAME + '] > DATEADD(YEAR, 10, GETDATE())))'
                WHEN DATA_TYPE IN ('nvarchar', 'varchar', 'char', 'nchar', 'text', 'ntext') THEN 'LTRIM(RTRIM([' + c.COLUMN_NAME + '])) = '''''
                ELSE '1=0'
            END + '
HAVING COUNT(*) > 0
UNION ALL
'
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES AS t ON t.TABLE_NAME = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = @SchemaName
  AND c.DATA_TYPE IN (
        'int', 'bigint', 'smallint', 'tinyint',
        'decimal', 'numeric', 'float', 'real',
        'date', 'datetime', 'smalldatetime',
        'nvarchar', 'varchar', 'char', 'nchar',
        'text', 'ntext'
  )
  AND TABLE_TYPE='BASE TABLE';

-- Remove trailing UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 11);

-- Wrap in a view
-- Step 2: Create the view dynamically
SET @sql = 'CREATE VIEW ' + @ViewName + ' AS '+ CHAR(13) + @sql;
--SET @sql = 'CREATE VIEW DQ_InvalidData AS ' + CHAR(13) + @sql;

-- Execute it
EXEC sp_executesql @sql;
