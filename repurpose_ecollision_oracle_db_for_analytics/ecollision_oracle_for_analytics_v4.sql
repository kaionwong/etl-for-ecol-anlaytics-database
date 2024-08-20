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
        ,plot.ROAD_ID -- [] need checking/debugging
--        ,plot.HIGHWAY -- [] need checking/debugging
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
          --,par.DRIVER_PEDESTR_COND_ID
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
          --,c.OCCURENCE_TIMESTRING -- [x] checking/debuging; this exists in eCollision Analytics but not in eCollision Oracle db
          ,c.OCCURENCE_TIMESTAMP
          --,d.FiscalYear
          --,d.SchoolYearFlag
          ,CASE 
                WHEN TO_CHAR(c.OCCURENCE_TIMESTAMP, 'MM') IN ('01', '02', '12') THEN '4 Winter (DEC-FEB)'
                WHEN TO_CHAR(c.OCCURENCE_TIMESTAMP, 'MM') IN ('03', '04', '05') THEN '1 Spring (MAR-MAY)'
                WHEN TO_CHAR(c.OCCURENCE_TIMESTAMP, 'MM') IN ('06', '07', '08') THEN '2 Summer (JUN-AUG)'
                WHEN TO_CHAR(c.OCCURENCE_TIMESTAMP, 'MM') IN ('09', '10', '11') THEN '3 Fall (SEP-NOV)'
            END AS Seasons
          ,CASE 
                WHEN c.OCCURENCE_TIME = '0000' THEN 'Unspecified'
                ELSE CASE
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) >= 2300 
                      OR TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) < 300 THEN '5 11:00 pm - 2:59 am (Late Evening)'
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) BETWEEN 300 AND 659 THEN '6 3:00 am - 6:59 am (Early Morning)'
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) BETWEEN 700 AND 1059 THEN '1 7:00 am - 10:59 am (Morning Rush Hour)'
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) BETWEEN 1100 AND 1459 THEN '2 11:00 am - 2:59 pm (Midday)'
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) BETWEEN 1500 AND 1859 THEN '3 3:00 pm - 6:59 pm (Evening Rush Hour)'
                    WHEN TO_NUMBER(SUBSTR(c.OCCURENCE_TIME, 1, 2) || SUBSTR(c.OCCURENCE_TIME, 3, 2)) BETWEEN 1900 AND 2259 THEN '4 7:00 pm - 10:59 pm (Evening)'
                    ELSE 'Unspecified'
                END
            END AS Time_Group -- [] needs checking/debugging
    
    from ValidCollision c
        left join ECRDBA.CL_OBJECTS obj on c.ID = obj.Collision_ID
        left join ECRDBA.CLOBJ_PARTY_INFO par on par.ID=obj.Party_ID
        left join ECRDBA.CLOBJ_PROPERTY_INFO pro on pro.ID=par.OPERATED_PROPERTY_ID
        left join ECRDBA.CLOBJ_PROPERTY_INFO pro1 on pro1.ID=obj.Property_ID	
        left join ECRDBA.ECR_COLL_PLOTTING_INFO plot on c.ID = plot.COLLISION_ID

        LEFT JOIN (SELECT b.ID Obj_ID													----add Vehicle Type to Passenger, no Parked Vehicle
                         ,d.OBJECT_IDENTIFICATION_TYPE_ID
                         --,Flag_ParkedVehicle='N'
                         ,'N' AS Flag_ParkedVehicle
                   FROM ECRDBA.CL_OBJECTS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.PARENT_OBJECT_ID
                   INNER JOIN ECRDBA.CLOBJ_PARTY_INFO c on a.Party_ID=c.ID
                   INNER JOIN ECRDBA.CLOBJ_PROPERTY_INFO d on  c.OPERATED_PROPERTY_ID=d.ID
                   WHERE 1=1
                   UNION
                   SELECT b.ID Obj_ID													----add Vehicle Type to Passenger with Parked Vehicle
                         ,c.OBJECT_IDENTIFICATION_TYPE_ID
                         --,Flag_ParkedVehicle='Y'
                         ,'Y' AS Flag_ParkedVehicle
                   FROM ECRDBA.CL_OBJECTS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.PARENT_OBJECT_ID
                   INNER JOIN ECRDBA.CLOBJ_PROPERTY_INFO c on  a.Property_ID=c.ID
                   WHERE 1=1
                   ) v on v.Obj_ID=obj.ID
        
        LEFT JOIN (SELECT b.ID Obj_ID													----add Driver/Pedestrian Condition and Object Number to Passenger, no Parked Vehicle
                         ,c.DRIVER_PEDESTR_COND_ID
                         ,a.SEQ_NBR Object_NBR
                   FROM ECRDBA.CL_OBJECTS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.PARENT_OBJECT_ID
                   INNER JOIN ECRDBA.CLOBJ_PARTY_INFO c on a.Party_ID=c.ID
                   INNER JOIN ECRDBA.CLOBJ_PROPERTY_INFO d on  c.OPERATED_PROPERTY_ID=d.ID
                   WHERE 1=1 
                   UNION
                   SELECT b.ID Obj_ID													----add Object Number to Passenger with Parked Vehicle, no Driver/Pedestrian Condition
                         --,DRIVER_PEDESTR_COND_ID=NULL
                         ,NULL as DRIVER_PEDESTR_COND_ID
                         ,a.SEQ_NBR Object_NBR
                   FROM ECRDBA.CL_OBJECTS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.PARENT_OBJECT_ID
                   INNER JOIN ECRDBA.CLOBJ_PROPERTY_INFO c on  a.Property_ID=c.ID
                   WHERE 1=1
                   ) Cond on Cond.Obj_ID=obj.ID
        
        LEFT JOIN (SELECT DISTINCT a.ID													----add Animal Flag to Collision
                         ,b.DESCRIPTION
                         --,Flag_Animal='Y'
                         ,'Y' AS Flag_Animal
                   FROM ECRDBA.COLLISIONS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.COLLISION_ID
                   WHERE 1=1 
                   AND b.OBJECT_TYPE_ID='7'		--7 Animal
                   ) Anim on c.ID=Anim.ID 
        
        LEFT JOIN (SELECT DISTINCT a.ID													----add Other Property Flag to Collision
                         --,b.DESCRIPTION												----a collision could have more than one Other Property
                         --,Flag_Oth_Property='Y'
                         ,'Y' AS Flag_Oth_Property
                   FROM ECRDBA.COLLISIONS a
                   INNER JOIN ECRDBA.CL_OBJECTS b on a.ID=b.COLLISION_ID
                   WHERE 1=1 
                   AND b.OBJECT_TYPE_ID='9'		--9	Other Property
                   ) Oth_Prop on c.ID=Oth_Prop.ID
        
        --LEFT JOIN [eCollisionAnalytics].[EDADIM].[Dates] d on c.OCCURENCE_TIMESTRING=d.DateString 
        --LEFT JOIN [eCollisionAnalytics_REPUAT].[EDADIM].[HighWay] b on c.LOC_HWY_NBR=b.Name
        LEFT JOIN ECRDBA.ECR_COLL_PLOTTING_INFO plot on c.ID = plot.COLLISION_ID
        LEFT JOIN ECRDBA.CODE_TYPE_VALUES p on p.ID=par.POSITION_IN_VEHICLE_ID
        LEFT JOIN ECRDBA.CODE_TYPE_VALUES s on s.ID=par.SAFETY_EQUIPMENT_ID
        LEFT JOIN ECRDBA.CODE_TYPE_VALUES sub on sub.ID=plot.COLLISION_SUB_TYPE_ID
        LEFT JOIN ECRDBA.CODE_TYPE_VALUES loc on loc.ID=c.COLLISION_LOCATION_ID
        
        WHERE 1=1
            AND c.CASE_YEAR between 2017 and 2021
            --AND c.Case_Year=2016
            AND ((c.POLICE_SERVICE_CODE in ('1624','1631') AND c.LOC_IN_CITY_FLAG IN ('0'))
            OR (c.POLICE_SERVICE_CODE in ('1624','1631') AND c.LOC_IN_CITY_FLAG IN ('1') AND c.LOC_DESC like '%GEON%'))
            -- AND c.LOC_IN_CITY_FLAG IN ('1','0')
            -- AND c.LOC_DESC like 'STURGEON%'
            -- AND (c.LOC_DESC like 'CCHRANE%' OR c.LOC_DESC like 'COC%')
)

-- Output option #1:
--select
--    *
--from MainTable
--ORDER BY Collision_ID

-- Output option #2:
	SELECT CASE_YEAR
		  ,COLLISION_SEVERITY as Category
		  ,COUNT(DISTINCT Collision_ID) COUNT
		  ,'Collision Severity' as TableName
		  ,1 as TableOrder
	FROM MainTable 
	WHERE 1=1
	GROUP BY CASE_YEAR, COLLISION_SEVERITY
	UNION
	SELECT CASE_YEAR
		  ,INJURY_Severity
		  ,COUNT(DISTINCT Party_ID) COUNT
		  ,'Injury Severity' as TableName
		  ,2 as TableOrder
	FROM MainTable 
	WHERE 1=1
	AND INJURY_SEVERITY is NOT NULL
	AND INJURY_SEVERITY Not in ('None','Unknown')
	GROUP BY CASE_YEAR,INJURY_Severity
	UNION
	SELECT CASE_YEAR
		  ,'Unsafe Speed' as Category
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Unsafe Speed' as TableName
		  ,3 as TableOrder
	FROM MainTable 
	WHERE 1=1
	AND UNSAFE_SPEED_ID=231
	AND COLLISION_SEVERITY <>'Fatal'
	AND Object_type in ('Driver','Motorcyclist','Other Vehicle')
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,'Intersections' as Category
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Intersections' as TableName
		  ,4 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND TRAFFIC_CTRL_DEVICE_ID in (201,202,203,204)
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,'Weather-Related' as Category
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Weather-Related' as TableName
		  ,5 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND ENVIRONMENTAL_CONDITION_ID in (50,51,52,53,54,55)		
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,'Surface Condition' as Category
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Surface Condition' as TableName
		  ,6 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND SURFACE_COND_ID in (58,59,60,61,62)		
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,'Animal-Related' as Category
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Animal-Related' as TableName
		  ,7 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND OBJECT_TYPE='Animal'	
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,'Drivers Performing Improper Actions' as Category
		  ,COUNT(Distinct Party_ID) as Total
		  ,'Drivers Performing Improper Actions' as TableName
		  ,8 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND DRIVER_ACTION_ID NOT IN (155,161,171)		--155 Driving Properly 161 Parked Vehicle 171 Unknown
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Seasons
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Seasons' as TableName
		  ,8 as TableOrder
	FROM MainTable
	WHERE 1=1
	GROUP BY CASE_YEAR,Seasons
	UNION
	SELECT CASE_YEAR
		  ,Time_Group
		  ,COUNT(Distinct Collision_ID) as Total
		  ,'Time' as TableName
		  ,9 as TableOrder
	FROM MainTable
	WHERE 1=1
	GROUP BY CASE_YEAR,Time_Group
	UNION
	SELECT CASE_YEAR
		  ,Sex
		  ,COUNT(Distinct Party_ID) as Total
		  ,'Sex' as TableName
		  ,10 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND INJURY_Category in ('Injury','Fatal')
	GROUP BY CASE_YEAR,Sex
	UNION
	SELECT CASE_YEAR
		  ,Sex
		  ,COUNT(Distinct Party_ID) as Total
		  ,'Not Wearing Seatbelt' as TableName
		  ,11 as TableOrder
	FROM MainTable
	WHERE 1=1
	AND Unbelted_Flag='Y'
	AND INJURY_Category in ('Injury','Fatal')
	GROUP BY CASE_YEAR,Sex
	-- ORDER BY 1,2




