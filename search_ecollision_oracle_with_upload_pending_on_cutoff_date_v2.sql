WITH CollisionCutoffDates AS (
    SELECT 2024 AS case_year, TO_DATE('2026-06-30', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2023, TO_DATE('2025-06-30', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2022, TO_DATE('2024-06-30', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2021, TO_DATE('2023-02-06', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2020, TO_DATE('2022-06-15', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2019, TO_DATE('2021-10-23', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2018, TO_DATE('2020-01-23', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2017, TO_DATE('2019-02-11', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2016, TO_DATE('2018-01-26', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2015, TO_DATE('2016-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2014, TO_DATE('2015-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2013, TO_DATE('2014-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2012, TO_DATE('2013-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2011, TO_DATE('2012-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2010, TO_DATE('2011-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2009, TO_DATE('2010-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2008, TO_DATE('2009-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2007, TO_DATE('2008-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2006, TO_DATE('2007-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2005, TO_DATE('2006-01-02', 'YYYY-MM-DD') FROM DUAL UNION ALL
    SELECT 2004, TO_DATE('2005-01-02', 'YYYY-MM-DD') FROM DUAL
),
CollisionEarliestDate AS (
    SELECT 
        collision_id, 
        MIN(TO_DATE(CREATED_TIMESTAMP, 'YY-MM-DD')) AS earliest_created_date
    FROM ecrdba.cl_status_history
    GROUP BY collision_id
),
CollisionCaseYear AS (
    SELECT 
        ced.collision_id,
        EXTRACT(YEAR FROM ced.earliest_created_date) AS case_year,
        ced.earliest_created_date
    FROM CollisionEarliestDate ced
),
CollisionWithCutoff AS (
    SELECT 
        ccy.collision_id,
        ccy.case_year,
        ccd.cutoff_end_date
    FROM CollisionCaseYear ccy
    JOIN CollisionCutoffDates ccd ON ccy.case_year = ccd.case_year
),
CollisionStatusOnCutoff AS (
    SELECT
        cwc.collision_id,
        cwc.case_year,
        cwc.cutoff_end_date,
        csh.COLL_STATUS_TYPE_ID,
        csh.EFFECTIVE_DATE,
        ROW_NUMBER() OVER (
            PARTITION BY cwc.collision_id 
            ORDER BY TO_DATE(csh.EFFECTIVE_DATE, 'YY-MM-DD') DESC
        ) AS rn
    FROM CollisionWithCutoff cwc
    JOIN ecrdba.cl_status_history csh 
        ON cwc.collision_id = csh.collision_id 
        AND TO_DATE(csh.EFFECTIVE_DATE, 'YY-MM-DD') <= cwc.cutoff_end_date
    WHERE TO_DATE(csh.CREATED_TIMESTAMP, 'YY-MM-DD') <= cwc.cutoff_end_date
)
SELECT 
    cwc.collision_id, 
    cwc.case_year,
    cwc.cutoff_end_date,
    MAX(csoc.COLL_STATUS_TYPE_ID) AS COLL_STATUS_TYPE_ID,
    c.case_nbr,
    c.occurence_timestamp,
    c.reported_timestamp,
    CASE 
        WHEN MAX(CASE WHEN csoc.COLL_STATUS_TYPE_ID = 220 THEN 1 ELSE 0 END) = 1 THEN 1
        ELSE 0
    END AS cutoff_upload_pending_flag
FROM CollisionStatusOnCutoff csoc
JOIN CollisionWithCutoff cwc 
    ON csoc.collision_id = cwc.collision_id
JOIN ecrdba.collisions c 
    ON csoc.collision_id = c.id
WHERE csoc.rn = 1
GROUP BY 
    cwc.collision_id, 
    cwc.case_year,
    cwc.cutoff_end_date,
    c.case_nbr,
    c.occurence_timestamp,
    c.reported_timestamp,
    csoc.COLL_STATUS_TYPE_ID
ORDER BY cwc.collision_id;

