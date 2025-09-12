-- Completeness Check
-- Detects NULLs in non-nullable columns
-- Creates a view: DQ_NullCountsView

DECLARE @SchemaName NVARCHAR(128) = 'dbo';  -- Schema owner
DECLARE @ViewName NVARCHAR(128) = 'DQ_NullCountsView';  -- view name
DECLARE @sql NVARCHAR(MAX) = N'';  -- string to store the output

-- Drop the view if it already exists
IF OBJECT_ID(@ViewName, 'V') IS NOT NULL
    EXEC('DROP VIEW ' + @ViewName);

-- Step 1: Build dynamic SQL for creating the view
SELECT @sql = COALESCE(@sql, '') + 
--COALESCE approach to concatenate dynamic SQL line-by-line
'SELECT ''' + TABLE_SCHEMA + '.' + TABLE_NAME + ''' AS TableName,
       ''' + COLUMN_NAME + ''' AS ColumnName,
       COUNT(*) AS NullCount
FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']
WHERE [' + COLUMN_NAME + '] IS NULL
HAVING COUNT(*) > 0
UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE IS_NULLABLE = 'NO'
  AND TABLE_SCHEMA = @SchemaName;

-- Remove the final trailing "UNION ALL"
SET @sql = LEFT(@sql, LEN(@sql) - 10);

-- Step 2: Create the view dynamically
SET @sql = 'CREATE VIEW ' + @ViewName + ' AS ' + @sql;

-- Step 3: Execute the SQL to create the view
EXEC sp_executesql @sql;

-- Step 4: Select from the created view
EXEC('SELECT * FROM ' + @ViewName);
