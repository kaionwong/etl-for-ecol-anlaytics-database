----------
--SELECT 
--	COUNT(DISTINCT(case_year)) as distinct_value_count,
--    MIN(case_year) AS min_value,
--    MAX(case_year) AS max_value,
--    AVG(case_year) AS avg_value,
--	STDEV(case_year) AS std_deviation,
--    COUNT(case_year) AS total_count
--FROM eCollisionAnalytics.ECRDBA.COLLISIONS
--WHERE CASE_YEAR = '2000'

----------
-- Variable summary for all variables - v1
----------
SELECT
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            WHERE kcu.TABLE_SCHEMA = c.TABLE_SCHEMA
              AND kcu.TABLE_NAME = c.TABLE_NAME
              AND kcu.COLUMN_NAME = c.COLUMN_NAME
              AND OBJECTPROPERTY(OBJECT_ID(kcu.CONSTRAINT_NAME), 'IsPrimaryKey') = 1
        ) THEN 'Yes'
        ELSE 'No'
    END AS IsPrimaryKey,
    c.COLUMN_DEFAULT AS DefaultConstraint,
    COLUMNPROPERTY(OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity') AS IsIdentity,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM sys.indexes i
            INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
            WHERE i.object_id = OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME) AND col.name = c.COLUMN_NAME
        ) THEN 'Yes'
        ELSE 'No'
    END AS IsIndexed
FROM
    INFORMATION_SCHEMA.COLUMNS c
WHERE
    c.TABLE_NAME = 'COLLISIONS'
    AND c.TABLE_SCHEMA = 'ECRDBA'
ORDER BY
	c.COLUMN_NAME,
    c.ORDINAL_POSITION

----------
-- For table [ECRDBA].[COLLISIONS] 
-- For specific numeric/string column
----------
--DECLARE @tableName NVARCHAR(MAX) = 'COLLISIONS';
--DECLARE @filterYear INT = 2014;
--DECLARE @columnName NVARCHAR(MAX) = 'case_year';

--DECLARE @sqlQuery NVARCHAR(MAX) = '
--    SELECT 
--        COUNT(DISTINCT(' + @columnName + ')) as distinct_value_count,
--        MIN(' + @columnName + ') AS min_value,
--        MAX(' + @columnName + ') AS max_value,
--        NULL AS avg_value, -- No AVG for strings
--        NULL AS std_deviation, -- No STDEV for strings
--        MAX(CASE WHEN rnk = 1 THEN ' + @columnName + ' END) AS mode_value,
--        COUNT(' + @columnName + ') AS total_count
--    FROM (
--        SELECT 
--            ' + @columnName + ',
--            RANK() OVER (PARTITION BY ' + @columnName + ' ORDER BY COUNT(*) DESC) AS rnk
--        FROM eCollisionAnalytics.ECRDBA.' + @tableName + '
--        WHERE CASE_YEAR = ' + CAST(@filterYear AS NVARCHAR(4)) + '
--        GROUP BY ' + @columnName + '
--    ) ranked
--    WHERE rnk = 1';

--EXEC sp_executesql @sqlQuery;

----------
-- For 'COLLISIONS' table
-- Variable summary for all variables - v2.1
----------
--DECLARE @tableName NVARCHAR(MAX) = 'COLLISIONS';
--DECLARE @filterYear INT = 2014;
--DECLARE @columnName NVARCHAR(MAX) = 'case_nbr';

--DECLARE @sqlQuery NVARCHAR(MAX) = '
--    SELECT 
--        COUNT(DISTINCT(' + @columnName + ')) as distinct_value_count,
--        MIN(' + @columnName + ') AS min_value,
--        MAX(' + @columnName + ') AS max_value,
--        NULL AS avg_value, -- No AVG for strings
--        NULL AS std_deviation, -- No STDEV for strings,
--        MAX(CASE WHEN rnk = 1 THEN ' + @columnName + ' END) AS mode_value,
--        COUNT(' + @columnName + ') AS total_count,
--        (
--            SELECT TOP 5 '''' + CAST(value AS NVARCHAR(MAX)) + '''' AS data
--            FROM (
--                SELECT ' + @columnName + ' AS value,
--                       RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
--                FROM eCollisionAnalytics.ECRDBA.' + @tableName + '
--                WHERE CASE_YEAR = ' + CAST(@filterYear AS NVARCHAR(4)) + '
--                GROUP BY ' + @columnName + '
--            ) ranked_internal
--            WHERE ranked_internal.rnk <= 5
--            FOR XML PATH('''')
--        ) AS top_5_values
--    FROM (
--        SELECT 
--            ' + @columnName + ',
--            RANK() OVER (PARTITION BY ' + @columnName + ' ORDER BY COUNT(*) DESC) AS rnk
--        FROM eCollisionAnalytics.ECRDBA.' + @tableName + '
--        WHERE CASE_YEAR = ' + CAST(@filterYear AS NVARCHAR(4)) + '
--        GROUP BY ' + @columnName + '
--    ) ranked
--    WHERE rnk = 1';

--EXEC sp_executesql @sqlQuery;

----------
-- For 'ECR_COLL_PLOTTING_INFO' or 'CL_OBJECTS' table
-- Variable summary for all variables - v2.1
----------
DECLARE @tableName NVARCHAR(MAX) = 'ECR_COLL_PLOTTING_INFO';
DECLARE @filterYear INT = 2000;
DECLARE @columnName NVARCHAR(MAX) = 'highway';

DECLARE @sqlQuery NVARCHAR(MAX) = '
    SELECT 
        COUNT(DISTINCT(' + @columnName + ')) as distinct_value_count,
        MIN(' + @columnName + ') AS min_value,
        MAX(' + @columnName + ') AS max_value,
        NULL AS avg_value, -- No AVG for strings
        NULL AS std_deviation, -- No STDEV for strings,
        MAX(CASE WHEN rnk = 1 THEN ' + @columnName + ' END) AS mode_value,
        COUNT(' + @columnName + ') AS total_count,
        (
            SELECT TOP 5 '''' + CAST(value AS NVARCHAR(MAX)) + '''' AS data
            FROM (
                SELECT ' + @columnName + ' AS value,
                       RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
                FROM eCollisionAnalytics.ECRDBA.' + @tableName + ' hi
				LEFT JOIN eCollisionAnalytics.ECRDBA.COLLISIONS col ON col.ID = hi.COLLISION_ID
                WHERE CASE_YEAR = ' + CAST(@filterYear AS NVARCHAR(4)) + '
                GROUP BY ' + @columnName + '
            ) ranked_internal
            WHERE ranked_internal.rnk <= 5
            FOR XML PATH('''')
        ) AS top_5_values
    FROM (
        SELECT 
            ' + @columnName + ',
            RANK() OVER (PARTITION BY ' + @columnName + ' ORDER BY COUNT(*) DESC) AS rnk
        FROM eCollisionAnalytics.ECRDBA.' + @tableName + ' hi
		LEFT JOIN eCollisionAnalytics.ECRDBA.COLLISIONS col ON col.ID = hi.COLLISION_ID
        WHERE CASE_YEAR = ' + CAST(@filterYear AS NVARCHAR(4)) + '
        GROUP BY ' + @columnName + '
    ) ranked
    WHERE rnk = 1';

EXEC sp_executesql @sqlQuery;