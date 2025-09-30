
-- Uniqueness Check
-- Verifies that PK/Unique columns have no duplicates
-- Creates a view: DQ_DistinctCountView

DECLARE @SchemaName NVARCHAR(128) = 'dbo';
DECLARE @ViewName NVARCHAR(128) = 'DQ_DistinctCountView';
DECLARE @sql NVARCHAR(MAX) = N'';

-- Drop the view if it exists
IF OBJECT_ID(@ViewName, 'V') IS NOT NULL
    EXEC('DROP VIEW ' + @ViewName);

DECLARE @PKCursor CURSOR;
DECLARE @TableName NVARCHAR(128);
DECLARE @PKName NVARCHAR(128);
DECLARE @PKType NVARCHAR(128);
DECLARE @ColumnsQuoted NVARCHAR(MAX);
DECLARE @ColumnsConcat NVARCHAR(MAX);

-- Cursor over all PKs in the schema
SET @PKCursor = CURSOR FOR
SELECT 
    t.name AS TableName,
    kc.name AS PKName,
    kc.type_desc AS PKType
FROM sys.key_constraints kc
JOIN sys.tables t ON kc.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type IN ('PK','UQ') AND s.name = @SchemaName;

OPEN @PKCursor;
FETCH NEXT FROM @PKCursor INTO @TableName, @PKName, @PKType;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build column list for quoting and for concatenation
    SET @ColumnsQuoted = NULL;
    SET @ColumnsConcat = NULL;

SELECT 
    @ColumnsQuoted = COALESCE(@ColumnsQuoted + ', ', '') + QUOTENAME(c.name),
    @ColumnsConcat = COALESCE(@ColumnsConcat + ' + '','' + ', '') + 'CAST(' + QUOTENAME(c.name) + ' AS NVARCHAR(MAX))'
FROM sys.index_columns ic
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.key_constraints kc ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
WHERE kc.name = @PKName AND ic.object_id = OBJECT_ID(@SchemaName + '.' + @TableName)
ORDER BY ic.key_ordinal;


    -- Append dynamic SELECT
    SET @sql = @sql + '
SELECT ''' + @PKName + ''' AS PKName,
       ' + @ColumnsConcat + ' AS Columns,
       COUNT(*) AS DuplicateCount
FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
GROUP BY ' + @ColumnsQuoted + '
HAVING COUNT(*) > 1
UNION ALL
';

    FETCH NEXT FROM @PKCursor INTO @TableName, @PKName, @PKType;
END;

CLOSE @PKCursor;
DEALLOCATE @PKCursor;

-- Remove trailing UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 11);

-- Create the view
SET @sql = 'CREATE VIEW ' + QUOTENAME(@ViewName) + ' AS ' + CHAR(10) + @sql;

--PRINT @sql

EXEC sp_executesql @sql;

-- Query the view
EXEC('SELECT * FROM ' + @ViewName);
