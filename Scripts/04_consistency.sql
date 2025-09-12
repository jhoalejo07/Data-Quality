
-- Consistency Check
-- Ensures FK values exist in referenced master tables
-- Creates a view: DQ_InconsistentRows

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @line NVARCHAR(MAX);
DECLARE @DetailSchema NVARCHAR(128);
DECLARE @DetailTable NVARCHAR(128);
DECLARE @DetailColumn NVARCHAR(128);
DECLARE @MasterSchema NVARCHAR(128);
DECLARE @MasterTable NVARCHAR(128);
DECLARE @MasterColumn NVARCHAR(128);


-- Cursor to iterate over all FK relationships
DECLARE FK_CURSOR CURSOR FOR
SELECT 
    FK.TABLE_SCHEMA AS DetailSchema,
    FK.TABLE_NAME AS DetailTable,
    CU.COLUMN_NAME AS DetailColumn,
    PK.TABLE_SCHEMA AS MasterSchema,
    PK.TABLE_NAME AS MasterTable,
    PT.COLUMN_NAME AS MasterColumn
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK
    ON RC.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK
    ON RC.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU
    ON FK.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE PT
    ON PK.CONSTRAINT_NAME = PT.CONSTRAINT_NAME
WHERE FK.CONSTRAINT_TYPE = 'FOREIGN KEY';

-- Open and fetch
OPEN FK_CURSOR;
FETCH NEXT FROM FK_CURSOR INTO 
    @DetailSchema, @DetailTable, @DetailColumn,
    @MasterSchema, @MasterTable, @MasterColumn;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Compose one part of the union
    SET @line = '
SELECT 
    ''' + @DetailSchema + '.' + @DetailTable + ''' AS DetailTable,
    ''' + @DetailColumn + ''' AS DetailColumn,
    ''' + @MasterSchema + '.' + @MasterTable + ''' AS MasterTable,
    ''' + @MasterColumn + ''' AS MasterColumn,
    COUNT(*) AS InvalidCount
FROM [' + @DetailSchema + '].[' + @DetailTable + '] AS D
LEFT JOIN [' + @MasterSchema + '].[' + @MasterTable + '] AS M
    ON D.[' + @DetailColumn + '] = M.[' + @MasterColumn + ']
WHERE D.[' + @DetailColumn + '] IS NOT NULL
  AND M.[' + @MasterColumn + '] IS NULL
HAVING COUNT(*) > 0
UNION ALL';

    -- Append to the main SQL string
    SET @sql = COALESCE(@sql, '') + @line;

    FETCH NEXT FROM FK_CURSOR INTO 
        @DetailSchema, @DetailTable, @DetailColumn,
        @MasterSchema, @MasterTable, @MasterColumn;
END;

-- Close and deallocate cursor
CLOSE FK_CURSOR;
DEALLOCATE FK_CURSOR;


-- Remove trailing UNION ALL
--IF RIGHT(@sql, 11) = 'UNION ALL'
SET @sql = LEFT(@sql, LEN(@sql) - 11)

-- Create the view dynamically
IF @sql IS NOT NULL AND LEN(@sql) > 0
BEGIN
    -- Drop old view if exists
    IF OBJECT_ID('DQ_InconsistentRows', 'V') IS NOT NULL
        DROP VIEW DQ_InconsistentRows;

    -- Wrap as CREATE VIEW
    SET @sql = 'CREATE VIEW DQ_InconsistentRows AS' + CHAR(13) + @sql;

    -- Create the view
	--PRINT @sql;
    EXEC sp_executesql @sql;

    -- Output result
    SELECT * FROM DQ_InconsistentRows;

END
ELSE
BEGIN
    PRINT 'No FK constraints found or no inconsistencies detected.';
END
