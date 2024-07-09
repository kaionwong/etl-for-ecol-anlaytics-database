WITH LatestCollisions AS (
    SELECT
        id,
        case_nbr,
        created_timestamp,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_timestamp DESC) AS rn
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
        ROW_NUMBER() OVER (PARTITION BY COLLISION_ID ORDER BY CREATED_TIMESTAMP DESC) AS rn
    FROM 
        ecrdba.cl_status_history
    WHERE 
        COLLISION_ID IN ('2436504', '2471168', '2503936', '2557569', '2474756', '2478084', '2504967', '2452237', '2545806', '2508048', '2442897', 
        '2464916', '2568470', '2557849', '2564634', '2492315', '2512028', '2558622', '2517025', '2499490', '2449830', '2512935', '2535336', 
        '2450219', '2478124', '2538667', '2461365', '2527413', '2565173', '2492600', '2472251', '2487484', '2541628', '2498495', '2488386', 
        '2473797', '2442182', '2447822', '2441679', '2466000', '2511313', '2630741', '2481365', '2598997', '2457947', '2499173', '2518505', 
        '2468331', '2433519', '2570481', '2451315', '2547829', '2538364', '2689376', '2717101', '2592078', '2689614', '2690043', '2725117')
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
        rn = 1 AND COLL_STATUS_TYPE_ID = '220' -- COLL_STATUS_TYPE_ID = '220' where 220 is "upload pending", since the COLLISION_ID to be tested are assumed to be deleted, any rows shown with this filter is the discrepancy since if a case is in "upload pending" status, it should be in both eCollision and eCollision Analytics
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
    FilteredStatusHistory fsh ON fc.id = fsh.COLLISION_ID; 