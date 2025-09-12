
-- Uniqueness Check
-- Verifies that PK/Unique columns have no duplicates
-- Creates a view: DQ_DistinctCountView

DECLARE @SchemaName NVARCHAR(128) = 'dbo';  -- Schema name (adjust if necessary)
DECLARE @ViewName NVARCHAR(128) = 'DQ_DistinctCountView';  -- view name
DECLARE @sql NVARCHAR(MAX) = N''; -- string to store the output

-- Drop the view if it already exists
IF OBJECT_ID(@ViewName, 'V') IS NOT NULL
    EXEC('DROP VIEW ' + @ViewName);

-- Step 1: Build dynamic SQL to check for columns with PRIMARY KEY or UNIQUE constraints
SELECT @sql = COALESCE(@sql, '') + '
SELECT ''' + t.TABLE_SCHEMA + '.' + t.TABLE_NAME + ''' AS TableName,
       ''' + c.COLUMN_NAME + ''' AS ColumnName,
       COUNT(DISTINCT [' + c.COLUMN_NAME + ']) AS DistinctCount
FROM [' + t.TABLE_SCHEMA + '].[' + t.TABLE_NAME + ']
WHERE [' + c.COLUMN_NAME + '] IS NOT NULL
GROUP BY [' + c.COLUMN_NAME + ']
HAVING COUNT(DISTINCT [' + c.COLUMN_NAME + ']) > 1
UNION ALL '
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.COLUMNS AS c ON c.TABLE_NAME = ccu.TABLE_NAME AND c.COLUMN_NAME = ccu.COLUMN_NAME
JOIN INFORMATION_SCHEMA.TABLES AS t ON t.TABLE_NAME = c.TABLE_NAME
WHERE (tc.CONSTRAINT_TYPE = 'PRIMARY KEY' OR tc.CONSTRAINT_TYPE = 'UNIQUE')
  AND t.TABLE_SCHEMA = @SchemaName;

-- Remove the final trailing "UNION ALL"
SET @sql = LEFT(@sql, LEN(@sql) - 10);

-- Step 2: Create the view dynamically
SET @sql = 'CREATE VIEW ' + @ViewName + ' AS ' + @sql;

-- Step 3: Execute the SQL to create the view
EXEC sp_executesql @sql;

-- Step 4: Select from the created view
EXEC('SELECT * FROM ' + @ViewName);
