WITH LatestEntries AS (
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
        ROW_NUMBER() OVER (PARTITION BY COLLISION_ID ORDER BY CREATED_TIMESTAMP DESC) AS rn
    FROM 
        ecrdba.cl_status_history
    WHERE 
        COLLISION_ID IN ('2436504')
)
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
    MODIFIED_FROM_IP_ADDR
FROM 
    LatestEntries
WHERE 
    rn = 1 AND COLL_STATUS_TYPE_ID = '220'; -- COLL_STATUS_TYPE_ID = '220' where 220 is "upload pending", since the COLLISION_ID to be tested are assumed to be deleted, any rows shown with this filter is the discrepancy since if a case is in "upload pending" status, it should be in both eCollision and eCollision Analytics