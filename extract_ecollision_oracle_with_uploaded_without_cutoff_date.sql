-- Save the output of this .sql to "extract_ecollision_oracle_with_uploaded_without_end_date_YYYY-MM-DD.csv" 
-- in the "ecollision-analytics-assessment" directory
-- End date has been updated to '3999-12-31' which is just a placeholder and this will disable cutoff end date - essentially this script gives a 
-- .. valid flag to cases that have "Upload" as their last collision status (regardless the date)

WITH CollisionCutoffDates AS (
    -- Define cutoff dates for each year, indicating the last date a case can be considered valid based on status
    SELECT 2030 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2029 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2028 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2027 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2026 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2025 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2024 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2023 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2022 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2021 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2020 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2019 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2018 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2017 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2016 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2015 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2014 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2013 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2012 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2011 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2010 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2009 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2008 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2007 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2006 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2005 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2004 AS created_year, TO_DATE('3999-12-31', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL
),
CollisionEarliestDate AS (
    -- Retrieve the earliest status change date for each collision from the status history
    SELECT
        collision_id,
        TO_CHAR(MIN(created_timestamp), 'YYYY-MM-DD') AS earliest_created_date
    FROM
        ecrdba.cl_status_history
    GROUP BY
        collision_id
),
CollisionCaseYear AS (
    -- Extract the created year from the earliest collision date
    SELECT
        ced.collision_id,
        EXTRACT(YEAR FROM TO_DATE(ced.earliest_created_date, 'YYYY-MM-DD')) AS created_year,
        ced.earliest_created_date
    FROM
        CollisionEarliestDate ced
),
CollisionWithCutoff AS (
    -- Join collisions with their corresponding cutoff dates based on the created year
    SELECT
        ccy.collision_id,
        ccy.created_year,
        ccd.cutoff_end_date
    FROM
        CollisionCaseYear ccy
        JOIN CollisionCutoffDates ccd ON ccy.created_year = ccd.created_year
),
CollisionStatusOnCutoff AS (
    -- Retrieve status history for collisions before or on the cutoff date, ranking by effective date
    SELECT
        cwc.collision_id,
        cwc.created_year,
        cwc.cutoff_end_date,
        csh.COLL_STATUS_TYPE_ID,
        TO_CHAR(TO_DATE(csh.EFFECTIVE_DATE, 'YYYY-MM-DD'), 'YY-MM-DD') AS EFFECTIVE_DATE,
        ROW_NUMBER() OVER (
            PARTITION BY cwc.collision_id
            ORDER BY csh.EFFECTIVE_DATE DESC, csh.COLL_STATUS_TYPE_ID DESC
        ) AS rn
    FROM
        CollisionWithCutoff cwc
        JOIN ecrdba.cl_status_history csh 
        ON cwc.collision_id = csh.collision_id AND TO_DATE(csh.EFFECTIVE_DATE, 'YYYY-MM-DD') <= cwc.cutoff_end_date
),
CollisionStatusOnCutoffFiltered AS (
    -- Filter collision status records valid at the cutoff date
    SELECT *
    FROM CollisionStatusOnCutoff
    WHERE TO_DATE(effective_date, 'YY-MM-DD') <= cutoff_end_date
),
CollisionStatusOnCutoffFilteredTwice AS (
    -- Further process the filtered statuses to rank them again
    SELECT
        collision_id,
        created_year,
        cutoff_end_date,
        coll_status_type_id,
        effective_date,
        rn,
        ROW_NUMBER() OVER (
            PARTITION BY collision_id
            ORDER BY rn ASC
        ) AS rn2
    FROM
        CollisionStatusOnCutoffFiltered
),
CollisionStatusOnCutoffFilteredThrice AS (
    -- Select the top-ranked status for each collision
    SELECT *
    FROM CollisionStatusOnCutoffFilteredTwice
    WHERE rn2 = 1
)
SELECT
    csoc.collision_id,
    csoc.created_year,
    EXTRACT(YEAR FROM TO_DATE(TO_CHAR(c.OCCURENCE_TIMESTAMP, 'YY-MM-DD'), 'YY-MM-DD')) AS case_year,
    csoc.cutoff_end_date,
    csoc.COLL_STATUS_TYPE_ID,
    csoc.EFFECTIVE_DATE,
    c.case_nbr,
    c.PFN_FILE_NBR,
    TO_CHAR(TO_DATE(c.occurence_timestamp, 'YYYY-MM-DD'), 'YY-MM-DD') AS occurence_timestamp,
    TO_CHAR(TO_DATE(c.reported_timestamp, 'YYYY-MM-DD'), 'YY-MM-DD') AS reported_timestamp,
    CASE
        -- WHEN csoc.COLL_STATUS_TYPE_ID = 220 THEN 1 -- 220 as upload pending
        WHEN csoc.COLL_STATUS_TYPE_ID = 221 THEN 1 -- 221 as uploaded
        ELSE 0
    END AS valid_at_cutoff_flag
FROM
    CollisionStatusOnCutoffFilteredThrice csoc
    LEFT JOIN ecrdba.collisions c ON csoc.collision_id = c.id
ORDER BY
    csoc.collision_id;
