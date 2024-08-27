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
),
CollisionWithValidFlag as (
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
        --and VALID_AT_CUTOFF_FLAG = 1
        --and COLL_STATUS_TYPE_ID = 221
        --and case_nbr = '13'
      
    order by
      csoc.collision_id
),
ValidCollision as (
    select
        cwvf.COLLISION_ID COLLISION_ID_PT2, 
        cwvf.CASE_NBR CASE_NBR_PT2, 
        cwvf.CASE_YEAR,
        c.*
    from CollisionWithValidFlag cwvf
    left join ecrdba.collisions c on c.id = cwvf.collision_id and c.case_nbr = cwvf.case_nbr
    where 1=1
        and CWVF.VALID_AT_CUTOFF_FLAG = 1
),
MainTable as (
    select 
        c.ID COLLISION_ID
        ,c.CASE_NBR
        ,c.CASE_YEAR
        ,c.SEVERITY_OF_COLLISION_ID
        ,CASE WHEN c.SEVERITY_OF_COLLISION_ID=4 THEN 'Fatal'
			WHEN c.SEVERITY_OF_COLLISION_ID=5 THEN 'Injury'
			WHEN c.SEVERITY_OF_COLLISION_ID=6 THEN 'Property Damage'
        END COLLISION_SEVERITY
        ,c.LOC_IN_CITY_FLAG
        ,c.LOC_DESC
        ,c.LOC_HWY_NBR
        --,plot.ROAD_ID
        -- ,plot.HIGHWAY -- [] need checking/debugging
        ,obj.TRAFFIC_CTRL_DEVICE_ID
        ,obj.OBJECT_TYPE_ID
        ,CASE WHEN obj.OBJECT_TYPE_ID=1 THEN 'Driver'
                WHEN obj.OBJECT_TYPE_ID=2 THEN 'Pedestrian'
                WHEN obj.OBJECT_TYPE_ID=3 THEN 'Motorcyclist'
                WHEN obj.OBJECT_TYPE_ID=4 THEN 'Bicyclist'
                WHEN obj.OBJECT_TYPE_ID=5 THEN 'Parked Vehicle'
                WHEN obj.OBJECT_TYPE_ID=6 THEN 'Train'
                WHEN obj.OBJECT_TYPE_ID=7 THEN 'Animal'
                WHEN obj.OBJECT_TYPE_ID=8 THEN 'Other Vehicle'
                WHEN obj.OBJECT_TYPE_ID=9 THEN 'Other Property'
                WHEN obj.OBJECT_TYPE_ID=10 THEN 'Passenger'
            END OBJECT_TYPE	      
          ,obj.SEQ_NBR
          ,CASE WHEN obj.OBJECT_TYPE_ID ='10' THEN cond.Object_NBR			-- Object Number for Passenger
                ELSE SEQ_NBR
            END Object_NBR
          ,Case WHEN obj.OBJECT_TYPE_ID=5 THEN pro1.OBJECT_IDENTIFICATION_TYPE_ID		--Parked Vehicle
                WHEN obj.OBJECT_TYPE_ID=10 THEN v.OBJECT_IDENTIFICATION_TYPE_ID			--Passenger  
                WHEN obj.OBJECT_TYPE_ID=2 THEN 130										--Pedestrian
                WHEN obj.OBJECT_TYPE_ID=7 THEN 138										--Animal
                WHEN obj.OBJECT_TYPE_ID=6 THEN 137										--Train
                ELSE pro.OBJECT_IDENTIFICATION_TYPE_ID
            END OBJECT_IDENTIFICATION_TYPE_ID												--Add Vehicle Type to Parked Vehicle and Passenger
          ,CASE WHEN obj.OBJECT_TYPE_ID=5 THEN 'Y'
                WHEN v.Flag_ParkedVehicle='Y' THEN 'Y'
                ELSE 'N'
            END Flag_ParkedVehicle
          ,obj.DESCRIPTION Obj_Description
          ,CASE WHEN Anim.Flag_Animal is NULL THEN 'N' ELSE Anim.Flag_Animal END Flag_Animal
          ,CASE WHEN Anim.Flag_Animal='Y' THEN Anim.DESCRIPTION END Anim_Description
          ,CASE WHEN Oth_Prop.Flag_Oth_Property is NULL THEN 'N' ELSE Oth_Prop.Flag_Oth_Property END Flag_Oth_Property
          ,obj.ID Obj_ID
          ,obj.PARENT_OBJECT_ID
          ,obj.Property_ID
          ,par.ID Party_ID
          ,par.INJURY_SEVERITY_ID
          ,CASE WHEN INJURY_SEVERITY_ID=94 THEN 'None'
                WHEN INJURY_SEVERITY_ID=95 THEN 'Minor Injuries'
                WHEN INJURY_SEVERITY_ID=96 THEN 'Major Injuries'
                WHEN INJURY_SEVERITY_ID=97 THEN 'Fatalities'
                WHEN INJURY_SEVERITY_ID=-13 THEN 'Unknown'
            END INJURY_SEVERITY
          ,CASE WHEN par.INJURY_SEVERITY_ID=94 THEN 'None'
                WHEN par.INJURY_SEVERITY_ID in (95,96) THEN 'Injury'
                WHEN par.INJURY_SEVERITY_ID=97 THEN 'Fatal'
                WHEN par.INJURY_SEVERITY_ID=-13 THEN 'Unknown'
            END INJURY_Category
          ,CASE WHEN INJURY_SEVERITY_ID=94 THEN '1'
                WHEN INJURY_SEVERITY_ID=95 THEN '2'
                WHEN INJURY_SEVERITY_ID=96 THEN '3'
                WHEN INJURY_SEVERITY_ID=97 THEN '4'
                WHEN INJURY_SEVERITY_ID=-13 THEN '9'
            END INJURY_SEVERITY_CODE
          ,par.DRIVER_ACTION_ID
          --,par.[DRIVER_PEDESTR_COND_ID]
          ,CASE WHEN obj.OBJECT_TYPE_ID=10 THEN cond.DRIVER_PEDESTR_COND_ID		--Add Driver/Pedestrian Condition to Passenger
           ELSE par.DRIVER_PEDESTR_COND_ID
           END DRIVER_PEDESTR_COND_ID
          ,par.POSITION_IN_VEHICLE_ID
          ,p.SHORT_DESC Position_in_Vehicle
          ,p.CODE	Position_in_Vehicle_Code
          ,par.UNSAFE_SPEED_ID
          ,par.DRIVER_DISTRACTION_ID
          ,par.EJECTION_TYPE_ID
          ,par.SAFETY_EQUIPMENT_ID
          ,s.SHORT_DESC SAFETY_EQUIPMENT
          ,s.CODE SAFETY_EQUIPMENT_Code
          ,CASE WHEN par.POSITION_IN_VEHICLE_ID in (77,78,241,242,243,244,245,246,247) and par.SAFETY_EQUIPMENT_ID=91 THEN 'Y'			--[SAFETY_EQUIPMENT_ID]=91 'None'
           END Unbelted_Flag
    
          ,c.VEHICLES_NBR
          ,c.INJURED_NBR
          ,c.FATALITIES_NBR
          ,par.AGE
          ,CASE WHEN par.MALE_FLAG=1 THEN 'M'
                WHEN par.MALE_FLAG=2 THEN 'F'
                WHEN par.MALE_FLAG=4 THEN 'O'
                ELSE 'U'
            END Sex
          ,par.LAST_NAME
          ,par.FIRST_NAME
          ,par.MIDDLE_NAME
          ,c.COLLISION_LOCATION_ID
          ,loc.SHORT_DESC Collision_Location 
          ,plot.COLLISION_SUB_TYPE_ID
          ,sub.SHORT_DESC Collision_Sub_Type
          ,plot.CONTROL_SECTION
          ,plot.KM_POST
          ,c.ENVIRONMENTAL_CONDITION_ID
          ,c.SURFACE_COND_ID
          ,c.OCCURENCE_TIMESTRING
          ,c.OCCURENCE_TIMESTAMP
          --,d.FiscalYear
          --,d.SchoolYearFlag
          ,CASE WHEN Month(c.OCCURENCE_TIMESTAMP) in (1,2,12) THEN '4 Winter (DEC-FEB)'
                WHEN Month(c.OCCURENCE_TIMESTAMP) in (3,4,5) THEN '1 Spring (MAR-MAY)'
                WHEN Month(c.OCCURENCE_TIMESTAMP) in (6,7,8) THEN '2 Summer (JUN-AUG)'
                WHEN Month(c.OCCURENCE_TIMESTAMP) in (9,10,11) THEN '3 Fall (SEP-NOV)'
           END Seasons
          ,CASE WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108)='00:00' THEN 'Unspecified'			--Use OCCURENCE_TIMESTAMP to get Time instead of using Occurrence Time. There are many NULLs under OCCURENCE_TIME for 2019 data.
                ELSE CASE
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) >='23:00' OR CONVERT(char(5),OCCURENCE_TIMESTAMP,108)<'03:00' THEN '5 11:00 pm - 2:59 am (Late Evening)'
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '03:00' AND '06:59' THEN '6 3:00 am - 6:59 am (Early Morning)'
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '07:00' AND '10:59' THEN '1 7:00 am - 10:59 am (Morning Rush Hour)'
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '11:00' AND '14:59' THEN '2 11:00 am - 2:59 pm (Midday)'
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '15:00' AND '18:59' THEN '3 3:00 pm - 6:59 pm (Evening Rush Hour)'
                WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '19:00' AND '22:59' THEN '4 7:00 pm - 10:59 pm (Evening)'
                ELSE 'Unspecified'
                END
           END Time_Group	
    
    
    
    
    
    
    
    from ValidCollision c
    left join ECRDBA.CL_OBJECTS obj on c.ID = obj.Collision_ID
    left join ECRDBA.CLOBJ_PARTY_INFO par on par.ID=obj.Party_ID
    left join ECRDBA.CLOBJ_PROPERTY_INFO pro on pro.ID=par.OPERATED_PROPERTY_ID
    left join ECRDBA.CLOBJ_PROPERTY_INFO pro1 on pro1.ID=obj.Property_ID	











)

select
    *
from MainTable