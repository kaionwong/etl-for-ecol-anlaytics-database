WITH LatestCases AS (
    SELECT 
        ID, 
        COLLISION_ID, 
        CASE_YEAR, 
        ACTION_TYPE, 
        CREATE_TIMESTAMP, 
        FINISH_TIMESTAMP, 
        CASE_NUMBER,
        ROW_NUMBER() OVER (PARTITION BY CASE_NUMBER ORDER BY CREATE_TIMESTAMP DESC) AS rn
    FROM 
        ecrdba.ecr_synchronization_action_log
    WHERE 
        CASE_NUMBER IN (
            '1447500', '1446310', '1447195', '1446203', '1448854', '1441250', '1446272', '1448726'
        )
)
SELECT 
    ID, 
    COLLISION_ID, 
    CASE_YEAR, 
    ACTION_TYPE, 
    CREATE_TIMESTAMP, 
    FINISH_TIMESTAMP, 
    CASE_NUMBER
FROM 
    LatestCases
WHERE 
    rn = 1 AND ACTION_TYPE <> 'D';