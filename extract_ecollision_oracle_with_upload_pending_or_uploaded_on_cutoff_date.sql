-- Save the output of this .sql to "extract_ecollision_oracle_with_upload_pending_or_uploaded_on_cutoff_date_YYYY-MM-DD.csv" in the "ecollision-analytics-assessment" directory

WITH CollisionCutoffDates AS (
    -- collision cut-off date is used to set a maximum time boundary for a case to be considered "valid" when they have "upload pending/uploaded" status; reference = https://ecollisionanalytics-pappa1:14501/eCollisionAnalytics_prd/app/administration/EditingCutoffDatesList.seam?cid=171&conversationPropagation=end
    SELECT 2024 AS created_year, TO_DATE('2026-06-30', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2023 AS created_year, TO_DATE('2025-06-30', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2022 AS created_year, TO_DATE('2024-06-30', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2021 AS created_year, TO_DATE('2023-02-06', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2020 AS created_year, TO_DATE('2022-06-15', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2019 AS created_year, TO_DATE('2021-10-23', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2018 AS created_year, TO_DATE('2020-01-23', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2017 AS created_year, TO_DATE('2019-02-11', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2016 AS created_year, TO_DATE('2018-01-26', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2015 AS created_year, TO_DATE('2016-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2014 AS created_year, TO_DATE('2015-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2013 AS created_year, TO_DATE('2014-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2012 AS created_year, TO_DATE('2013-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2011 AS created_year, TO_DATE('2012-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2010 AS created_year, TO_DATE('2011-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2009 AS created_year, TO_DATE('2010-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2008 AS created_year, TO_DATE('2009-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2007 AS created_year, TO_DATE('2008-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2006 AS created_year, TO_DATE('2007-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2005 AS created_year, TO_DATE('2006-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL UNION ALL
    SELECT 2004 AS created_year, TO_DATE('2005-01-02', 'YYYY-MM-DD') AS cutoff_end_date FROM DUAL
),
CollisionEarliestDate AS (
  -- pulling the earliest collision status history date. This earliest date will be mapped with the corresponding cut-off date, which gives each collision an preset cut-off date
  SELECT
    collision_id,
    TO_CHAR(MIN(created_timestamp), 'YYYY-MM-DD') AS earliest_created_date
  FROM
    ecrdba.cl_status_history
  GROUP BY
    collision_id
),
CollisionCaseYear AS (
  SELECT
    ced.collision_id,
    EXTRACT(
      YEAR
      FROM
        TO_DATE(ced.earliest_created_date, 'YYYY-MM-DD')
    ) AS created_year,
    ced.earliest_created_date
  FROM
    CollisionEarliestDate ced
),
CollisionWithCutoff AS (
  SELECT
    ccy.collision_id,
    ccy.created_year,
    ccd.cutoff_end_date
  FROM
    CollisionCaseYear ccy
    JOIN CollisionCutoffDates ccd ON ccy.created_year = ccd.created_year
),
CollisionStatusOnCutoff AS (
  SELECT
    cwc.collision_id,
    cwc.created_year,
    cwc.cutoff_end_date,
    csh.COLL_STATUS_TYPE_ID,
    csh.EFFECTIVE_DATE,
    ROW_NUMBER() OVER (
      PARTITION BY cwc.collision_id
      ORDER BY
        csh.EFFECTIVE_DATE DESC,
        csh.COLL_STATUS_TYPE_ID DESC
    ) AS rn
  FROM
    CollisionWithCutoff cwc
    JOIN ecrdba.cl_status_history csh ON cwc.collision_id = csh.collision_id
    AND TO_DATE(csh.EFFECTIVE_DATE, 'YYYY-MM-DD') <= cwc.cutoff_end_date -- may try "EFFECTIVE_DATE" or "CREATED_TIMESTAMP"
  WHERE
    TO_DATE(csh.EFFECTIVE_DATE, 'YYYY-MM-DD') <= cwc.cutoff_end_date -- may try "EFFECTIVE_DATE" or "CREATED_TIMESTAMP"
),
CollisionStatusOnCutoffFiltered AS (
  select
    *
  from
    CollisionStatusOnCutoff
  where
    effective_date <= cutoff_end_date
),
CollisionStatusOnCutoffFilteredTwice as (
  select
    collision_id,
    created_year,
    cutoff_end_date,
    coll_status_type_id,
    effective_date,
    rn,
    row_number() over (
      partition by collision_id
      order by
        rn asc
    ) as rn2
  from
    CollisionStatusOnCutoffFiltered
),
CollisionStatusOnCutoffFilteredThrice as (
  select
    *
  from
    CollisionStatusOnCutoffFilteredTwice
  where
    rn2 = 1
)
select
  csoc.collision_id,
  csoc.created_year,
  EXTRACT(YEAR FROM TO_DATE(c.OCCURENCE_TIMESTAMP, 'YY-MM-DD')) AS case_year,
  csoc.cutoff_end_date,
  csoc.COLL_STATUS_TYPE_ID,
  csoc.EFFECTIVE_DATE,
  c.case_nbr,
  c.occurence_timestamp,
  c.reported_timestamp,
  CASE
    WHEN csoc.COLL_STATUS_TYPE_ID = 220 THEN 1 -- 220 as upload pending
    WHEN csoc.COLL_STATUS_TYPE_ID = 221 THEN 1 -- 221 as uploaded
    ELSE 0
  END AS valid_at_cutoff_flag
from
  CollisionStatusOnCutoffFilteredThrice csoc
  left join ecrdba.collisions c on csoc.collision_id = c.id
  
  -- Testing below:
  where 1=1
    --and COLL_STATUS_TYPE_ID = 221
    --and case_nbr = '13'
  
order by
  csoc.collision_id

-- Testing below:
-- ORDER BY VALID_AT_CUTOFF_FLAG desc
