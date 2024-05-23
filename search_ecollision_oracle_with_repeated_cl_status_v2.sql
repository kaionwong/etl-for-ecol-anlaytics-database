WITH LatestCollisions AS (
    SELECT
        id,
        case_nbr,
        created_timestamp,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY TO_DATE(created_timestamp, 'YY-MM-DD') DESC) AS rn
    FROM
        ecrdba.collisions
),
FilteredCollisions AS (
    SELECT
        id,
        case_nbr
    FROM
        LatestCollisions
    WHERE
        rn = 1
),
StatusCount AS (
    SELECT 
        COLLISION_ID,
        COUNT(*) AS StatusCount
    FROM 
        ecrdba.cl_status_history
    WHERE 
        COLL_STATUS_TYPE_ID = '220'
    GROUP BY 
        COLLISION_ID
    HAVING 
        COUNT(*) > 1 -- this controls the "multiple" same status part. If you set it to >1, it will ouput more than 1 of the "COLL_STATUS_TYPE_ID" specified above
),
LatestEntries AS (
    SELECT 
        ID,
        OBJ_VERSION,
        COLLISION_ID,
        COLL_STATUS_TYPE_ID,
        EFFECTIVE_DATE,
        CSTH_COMMENT,
        CREATED_USER_ID,
        CREATED_TIMESTAMP,
        MODIFIED_USER_ID,
        MODIFIED_TIMESTAMP,
        MODIFIED_FROM_IP_ADDR,
        ROW_NUMBER() OVER (PARTITION BY COLLISION_ID ORDER BY TO_DATE(CREATED_TIMESTAMP, 'YY-MM-DD') DESC) AS rn
    FROM 
        ecrdba.cl_status_history
    WHERE 
        COLLISION_ID IN (SELECT COLLISION_ID FROM StatusCount)
),
FilteredStatusHistory AS (
    SELECT 
        ID AS StatusHistoryID,
        OBJ_VERSION,
        COLLISION_ID,
        COLL_STATUS_TYPE_ID,
        EFFECTIVE_DATE,
        CSTH_COMMENT,
        CREATED_USER_ID,
        CREATED_TIMESTAMP,
        MODIFIED_USER_ID,
        MODIFIED_TIMESTAMP,
        MODIFIED_FROM_IP_ADDR
    FROM 
        LatestEntries
    WHERE 
        rn = 1 AND COLL_STATUS_TYPE_ID = '220'
)
SELECT
    fc.id,
    fc.case_nbr,
    fsh.StatusHistoryID,
    fsh.OBJ_VERSION,
    fsh.COLLISION_ID,
    fsh.COLL_STATUS_TYPE_ID,
    fsh.EFFECTIVE_DATE,
    fsh.CSTH_COMMENT,
    fsh.CREATED_USER_ID,
    fsh.CREATED_TIMESTAMP,
    fsh.MODIFIED_USER_ID,
    fsh.MODIFIED_TIMESTAMP,
    fsh.MODIFIED_FROM_IP_ADDR
FROM
    FilteredCollisions fc
JOIN
    FilteredStatusHistory fsh ON fc.id = fsh.COLLISION_ID
ORDER BY TO_DATE(fsh.CREATED_TIMESTAMP, 'YY-MM-DD') DESC;
