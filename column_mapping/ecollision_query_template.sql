/****** Script for SelectTopNRows command from SSMS  ******/
-------
--SELECT top (100) [ID]
--		,[CASE_NBR]
      --,[OBJ_VERSION]
      --,[DISTRICT_ID]
      --,[USER_ROLE_ASSIGNMENT_ID]
      --,[FILE_STATUS_ID]
      --,[SEVERITY_OF_COLLISION_ID]
      --,[SPECIAL_FACILITY_ID]
      --,[ROAD_ALIGNMENT_A_ID]
      --,[ROAD_ALIGNMENT_B_ID]
      --,[ROAD_CLASS_ID]
      --,[COLLISION_LOCATION_ID]
      --,[PRIMARY_EVENT_ID]
      --,[ENVIRONMENTAL_CONDITION_ID]
      --,[SURFACE_COND_ID]
      --,[FILE_ID]
      --,[ZONE_NBR]
      --,[CASE_NBR]
      --,[PFN_FILE_NBR]
      --,[PFN_RCMP_ZONE_NBR]
      --,[UNIT_NBR]
      --,[OCCURENCE_TIMESTAMP]
      --,[REPORTED_TIMESTAMP]
      --,[DIARY_DATE]
      --,[VEHICLES_NBR]
      --,[INJURED_NBR]
      --,[FATALITIES_NBR]
      --,[ORIG_REPORT_FLAG]
      --,[HIT_AND_RUN_FLAG]
      --,[SCENE_VISITED_FLAG]
      --,[LOC_IN_CITY_FLAG]
      --,[LOC_DESC]
      --,[LOC_HWY_NBR]
      --,[LOC_STREET_NBR]
      --,[LOC_STREET_AVE]
      --,[LOC_STREET_TYPE]
      --,[LOC_STREET_QUADRANT]
      --,[LOC_INT_HWY_NBR]
      --,[LOC_INT_STREET_AVE]
      --,[LOC_INT_STREET_TYPE]
      --,[LOC_INT_STREET_QUADRANT]
      --,[LOC_DISTANCE_KM_FLAG]
      --,[LOC_DISTANCE]
      --,[LOC_NORTH_FLAG]
      --,[LOC_SOUTH_FLAG]
      --,[LOC_EAST_FLAG]
      --,[LOC_WEST_FLAG]
      --,[LOC_REF_STREET_AVE]
      --,[LOC_REF_SPECIAL_DESC]
      --,[LOC_GPS_LAT]
      --,[LOC_GPS_LONG]
      --,[SPECIAL_STUDIES_FLAG]
      --,[PRIMARY_EVENT_DESC]
      --,[SURFACE_CONDITION_DESC]
      --,[ENV_CONDITION_DESC]
      --,[FILE_STATUS_DESC]
      --,[COLLISION_DESCRIPTION]
      --,[PROPOSED_POLICE_ACTION]
      --,[ORIGINATOR_SUBMIT_FLAG]
      --,[CREATED_USER_ID]
      --,[CREATED_TIMESTAMP]
      --,[MODIFIED_USER_ID]
      --,[MODIFIED_TIMESTAMP]
      --,[MODIFIED_FROM_IP_ADDR]
      --,[ACIS_EXTRACT_TIMESTAMP]
      --,[AGENCY_EXTRACT_TIMESTAMP]
      --,[OBJECT_COUNT]
      --,[OCCURENCE_TIME]
      --,[CITY_EXTRACT_TIMESTAMP]
      --,[PDF_EXTRACT_TIMESTAMP]
      --,[BUSINESS_AREA]
      --,[TRANS_DISTRICT_ID]
      --,[FF_NBR]
      --,[SITE_VISIT_APPLICABLE_FLAG]
      --,[SITE_VISIT_RPT_RECEIVED_FLAG]
      --,[VEHICLE_SEIZED]
      --,[OFFENDER_PAINT]
      --,[OFFENDER_VEHICLE_PARTS]
      --,[DEBRIS_SEIZED]
      --,[PHOTOS_TAKEN]
      --,[OFFENDER_PAINT_TRANSFER]
      --,[MEASUREMENTS_TAKEN]
      --,[MEASUREMENTS_TAKEN_HEIGHT]
      --,[EPS_INJURY]
      --,[EPS_INJURY_DESCRIPTION]
      --,[DAMAGE_LOCATION_DESCRIPTION]
      --,[INVESTIGATION_NOTE]
      --,[VICTIM_VEHICLE_PAINT]
      --,[VICTIM_VEHICLE_PARTS]
      --,[DEBRIS_LOCATION]
      --,[FORM_CASE_NBR]
      --,[CREATED_BY_DATA_ENTRY_FIRM]
      --,[POLICE_SERVICE_CODE]
      --,[INV_REG_NBR]
      --,[APPROVER_REG_NBR]
      --,[APPROVE_DATE]
      --,[RCMP_ZONE_NBR]
      --,[Z_FORM]
      --,[PLOTTING_INFO_ID]
      --,[CURRENT_PLOTTER_ID]
      --,[PLOTTING_STATUS_ID]
      --,[LOC_STREET_DIRECTION]
      --,[LOC_INT_STREET_DIRECTION]
      --,[ROAD_CLASS_DESC]
      --,[FATAL_COMMENTS]
      --,[FATAL_DESCRIPTION]
      --,[CASE_YEAR]
      --,[SPL_STUDY_DESC]
      --,[CPS_FILE]
      --,[FATAL_REPORT_DATE]
      --,[ENG_NOTIFIED_DATE]
      --,[ENG_REPORT_DATE]
      --,[FATAL_POL_RCMP_CODE ]
      --,[LOC_TYPE_DESC]
      --,[OCCURENCE_TIMESTRING]
      --,[COMPLETE_INDICATOR]
      --,[ADDL_WITNESS]
      --,[DISTRICT_NAME]
      --,[RADIUS_OF_CURVE]
      --,[PROP_DAMAGE_ONLY]
      --,[SPL_STUDY_NO]
      --,[MUNICIPALITY_TYPE]
      --,[BATCH_NUMBER]
      --,[LEGAL_CLASSIFICATION]
      --,[COLLISION_LOCATION_DESC]
  --FROM [eCollisionAnalytics].[ECRDBA].[COLLISIONS]
  --where 1=1 and 
  ----ID in ('626434')
  --case_year in (2017)
  --order by case_year asc


-------
--  with CaseNbrByYear as (
--	select case_nbr
--		from [eCollisionAnalytics].[ECRDBA].[COLLISIONS]
--	where case_year = 2015
--  ),
--  Duplicate as (
--	  select 
--		[CASE_NBR], 
--		count(*) as DuplicateCount
--	  from [eCollisionAnalytics].[ECRDBA].[COLLISIONS]
--	  group by [CASE_NBR]
--	  having count(*) > 1
--  )

--SELECT
--    CNBY.case_nbr
--FROM
--    CaseNbrByYear CNBY
--INNER JOIN
--    Duplicate DUP ON CNBY.case_nbr = DUP.[CASE_NBR]


------------------
--select
--	*
--	--id, case_nbr
--from
--	[eCollisionAnalytics].[ECRDBA].[COLLISIONS]
--where 1=1
--	and case_year = 2016
--	and case_nbr = '480202'

------------------
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
    c.ORDINAL_POSITION;