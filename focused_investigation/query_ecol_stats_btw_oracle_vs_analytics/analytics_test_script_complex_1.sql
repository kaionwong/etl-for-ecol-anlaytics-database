use eCollisionAnalytics

;With MainTable as (
SELECT c.ID [Collision_ID]
      ,c.[CASE_NBR]
	  ,c.[CASE_YEAR]
	  ,c.[SEVERITY_OF_COLLISION_ID]
	  ,CASE WHEN [SEVERITY_OF_COLLISION_ID]=4 THEN 'Fatal'
			WHEN [SEVERITY_OF_COLLISION_ID]=5 THEN 'Injury'
			WHEN [SEVERITY_OF_COLLISION_ID]=6 THEN 'Property Damage'
	   END [COLLISION_SEVERITY]
	  ,c.[LOC_IN_CITY_FLAG]
      ,c.[LOC_DESC]
      ,c.[LOC_HWY_NBR]
	  ,c.[POLICE_SERVICE_CODE]
      ,c.[LOC_STREET_NBR]
      ,c.[LOC_STREET_AVE]
      ,c.[LOC_STREET_TYPE]
      ,c.[LOC_STREET_QUADRANT]
      ,c.[LOC_INT_HWY_NBR]
      ,c.[LOC_INT_STREET_AVE]
      ,c.[LOC_INT_STREET_TYPE]
      ,c.[LOC_INT_STREET_QUADRANT]
      ,c.[LOC_DISTANCE_KM_FLAG]
      ,c.[LOC_DISTANCE]
      ,c.[LOC_NORTH_FLAG]
      ,c.[LOC_SOUTH_FLAG]
      ,c.[LOC_EAST_FLAG]
      ,c.[LOC_WEST_FLAG]
      ,c.[LOC_REF_STREET_AVE]
      ,c.[LOC_REF_SPECIAL_DESC]
      ,c.[LOC_GPS_LAT]
      ,c.[LOC_GPS_LONG]
	  --,plot.HIGHWAY				--Many Highway numbers are NULL. It is better to use c.[LOC_HWY_NBR].
	  ,obj.[TRAFFIC_CTRL_DEVICE_ID]
	  ,obj.[OBJECT_TYPE_ID]
	  ,CASE WHEN obj.[OBJECT_TYPE_ID]=1 THEN 'Driver'
			WHEN obj.[OBJECT_TYPE_ID]=2 THEN 'Pedestrian'
			WHEN obj.[OBJECT_TYPE_ID]=3 THEN 'Motorcyclist'
			WHEN obj.[OBJECT_TYPE_ID]=4 THEN 'Bicyclist'
			WHEN obj.[OBJECT_TYPE_ID]=5 THEN 'Parked Vehicle'
			WHEN obj.[OBJECT_TYPE_ID]=6 THEN 'Train'
			WHEN obj.[OBJECT_TYPE_ID]=7 THEN 'Animal'
			WHEN obj.[OBJECT_TYPE_ID]=8 THEN 'Other Vehicle'
			WHEN obj.[OBJECT_TYPE_ID]=9 THEN 'Other Property'
			WHEN obj.[OBJECT_TYPE_ID]=10 THEN 'Passenger'
		END [OBJECT_TYPE]	  
	  ,obj.[SEQ_NBR]
	  ,CASE WHEN obj.OBJECT_TYPE_ID ='10' THEN cond.Object_NBR			-- Object Number for Passenger
			ELSE SEQ_NBR
		END Object_NBR
	  ,pro.[OBJECT_IDENTIFICATION_TYPE_ID] AS [OBJECT_IDENTIFICATION_TYPE_ID_OG]
	  ,Case WHEN obj.[OBJECT_TYPE_ID]=5 THEN pro1.[OBJECT_IDENTIFICATION_TYPE_ID]		--Parked Vehicle
			WHEN obj.[OBJECT_TYPE_ID]=10 THEN v.[OBJECT_IDENTIFICATION_TYPE_ID]			--Passenger  
			WHEN obj.[OBJECT_TYPE_ID]=2 THEN 130										--Pedestrian
			WHEN obj.[OBJECT_TYPE_ID]=7 THEN 138										--Animal
			WHEN obj.[OBJECT_TYPE_ID]=6 THEN 137										--Train
			ELSE pro.[OBJECT_IDENTIFICATION_TYPE_ID]
		END [OBJECT_IDENTIFICATION_TYPE_ID]												--Add Vehicle Type to Parked Vehicle and Passenger
	  ,CASE WHEN obj.[OBJECT_TYPE_ID]=5 THEN 'Y'
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
	  ,par.[INJURY_SEVERITY_ID]
	  ,CASE WHEN [INJURY_SEVERITY_ID]=94 THEN 'None'
			WHEN [INJURY_SEVERITY_ID]=95 THEN 'Minor Injuries'
			WHEN [INJURY_SEVERITY_ID]=96 THEN 'Major Injuries'
			WHEN [INJURY_SEVERITY_ID]=97 THEN 'Fatalities'
			WHEN [INJURY_SEVERITY_ID]=-13 THEN 'Unknown'
		END [INJURY_SEVERITY]
	  ,CASE WHEN par.[INJURY_SEVERITY_ID]=94 THEN 'None'
			WHEN par.[INJURY_SEVERITY_ID] in (95,96) THEN 'Injury'
			WHEN par.[INJURY_SEVERITY_ID]=97 THEN 'Fatal'
			WHEN par.[INJURY_SEVERITY_ID]=-13 THEN 'Unknown'
		END [INJURY_Category]
	  ,CASE WHEN [INJURY_SEVERITY_ID]=94 THEN '1'
			WHEN [INJURY_SEVERITY_ID]=95 THEN '2'
			WHEN [INJURY_SEVERITY_ID]=96 THEN '3'
			WHEN [INJURY_SEVERITY_ID]=97 THEN '4'
			WHEN [INJURY_SEVERITY_ID]=-13 THEN '9'
		END [Injury Severity Code]
	  ,par.[DRIVER_ACTION_ID]
	  --,par.[DRIVER_PEDESTR_COND_ID]
	  ,CASE WHEN obj.[OBJECT_TYPE_ID]=10 THEN cond.DRIVER_PEDESTR_COND_ID		--Add Driver/Pedestrian Condition to Passenger
	   ELSE par.[DRIVER_PEDESTR_COND_ID]
	   END [DRIVER_PEDESTR_COND_ID]
	  ,par.[POSITION_IN_VEHICLE_ID]
	  ,p.SHORT_DESC [Position_in_Vehicle]
	  ,p.CODE [Position_in_Vehicle_Code]
	  ,par.[UNSAFE_SPEED_ID]
	  ,par.[DRIVER_DISTRACTION_ID]
	  ,par.[EJECTION_TYPE_ID]
	  ,par.[SAFETY_EQUIPMENT_ID]
	  ,s.SHORT_DESC [SAFETY_EQUIPMENT]
	  ,s.CODE [SAFETY_EQUIPMENT_Code]
	  ,CASE WHEN par.[POSITION_IN_VEHICLE_ID] in (77,78,241,242,243,244,245,246,247) and par.[SAFETY_EQUIPMENT_ID]=91 THEN 'Y'			--[SAFETY_EQUIPMENT_ID]=91 'None'
	   END [Unbelted_Flag]

	  ,c.[VEHICLES_NBR]
	  ,c.[INJURED_NBR]
      ,c.[FATALITIES_NBR]
	  ,par.[AGE]
	  ,CASE WHEN par.MALE_FLAG=1 THEN 'M'
			WHEN par.MALE_FLAG=2 THEN 'F'
			WHEN par.MALE_FLAG=4 THEN 'O'
			ELSE 'U'
		END [Sex]
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
	  ,[OCCURENCE_TIMESTRING]
	  ,c.OCCURENCE_TIMESTAMP
	  --,d.FiscalYear
	  --,d.SchoolYearFlag
	  ,CASE WHEN Month(c.OCCURENCE_TIMESTAMP) in (1,2,12) THEN '4 Winter (DEC-FEB)'
			WHEN Month(c.OCCURENCE_TIMESTAMP) in (3,4,5) THEN '1 Spring (MAR-MAY)'
			WHEN Month(c.OCCURENCE_TIMESTAMP) in (6,7,8) THEN '2 Summer (JUN-AUG)'
			WHEN Month(c.OCCURENCE_TIMESTAMP) in (9,10,11) THEN '3 Fall (SEP-NOV)'
	   END Seasons
	  ,CASE WHEN Month(c.OCCURENCE_TIMESTAMP) in (1, 2, 3) THEN '1st Quarter'
			WHEN MONTH(c.OCCURENCE_TIMESTAMP) in (4, 5, 6) THEN '2nd Quarter'
			WHEN MONTH(c.OCCURENCE_TIMESTAMP) in (7, 8, 9) THEN '3rd Quarter'
			WHEN MONTH(c.OCCURENCE_TIMESTAMP) in (10, 11, 12) THEN '4th Quarter'
		END YearlyQuarter
	  ,CASE WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108)='00:00' THEN 'Unspecified' --Use OCCURENCE_TIMESTAMP to get Time instead of using Occurrence Time. There are many NULLs under OCCURENCE_TIME for 2019 data.
			ELSE CASE
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) >='23:00' OR CONVERT(char(5),OCCURENCE_TIMESTAMP,108)<'03:00' THEN '5 11:00 pm - 2:59 am (Late Evening)'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '03:00' AND '06:59' THEN '6 3:00 am - 6:59 am (Early Morning)'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '07:00' AND '10:59' THEN '1 7:00 am - 10:59 am (Morning Rush Hour)'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '11:00' AND '14:59' THEN '2 11:00 am - 2:59 pm (Midday)'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '15:00' AND '18:59' THEN '3 3:00 pm - 6:59 pm (Evening Rush Hour)'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '19:00' AND '22:59' THEN '4 7:00 pm - 10:59 pm (Evening)'
			ELSE 'Unspecified'
			END
	   END TimeGroup	

FROM [ECRDBA].[COLLISIONS] c
LEFT JOIN [ECRDBA].[CL_OBJECTS] obj on c.ID=obj.Collision_ID
LEFT JOIN [ECRDBA].[CLOBJ_PARTY_INFO] par on par.ID=obj.Party_ID
LEFT JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] pro on pro.ID=par.[OPERATED_PROPERTY_ID]
LEFT JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] pro1 on pro1.ID=obj.Property_ID			--add Vehicle Type to Parked Vehicle

LEFT JOIN (SELECT b.ID Obj_ID													----add Vehicle Type to Passenger, no Parked Vehicle
				 ,d.[OBJECT_IDENTIFICATION_TYPE_ID]
				 ,Flag_ParkedVehicle='N'
		   FROM [ECRDBA].[CL_OBJECTS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.[PARENT_OBJECT_ID]
		   INNER JOIN [ECRDBA].[CLOBJ_PARTY_INFO] c on a.Party_ID=c.ID
		   INNER JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] d on  c.[OPERATED_PROPERTY_ID]=d.ID
		   WHERE 1=1
		   UNION
		   SELECT b.ID Obj_ID													----add Vehicle Type to Passenger with Parked Vehicle
				 ,c.[OBJECT_IDENTIFICATION_TYPE_ID]
				 ,Flag_ParkedVehicle='Y'
		   FROM [ECRDBA].[CL_OBJECTS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.[PARENT_OBJECT_ID]
		   INNER JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] c on  a.Property_ID=c.ID
		   WHERE 1=1
		   ) v on v.Obj_ID=obj.ID

LEFT JOIN (SELECT b.ID Obj_ID													----add Driver/Pedestrian Condition and Object Number to Passenger, no Parked Vehicle
				 ,c.DRIVER_PEDESTR_COND_ID
				 ,a.SEQ_NBR Object_NBR
		   FROM [ECRDBA].[CL_OBJECTS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.[PARENT_OBJECT_ID]
		   INNER JOIN [ECRDBA].[CLOBJ_PARTY_INFO] c on a.Party_ID=c.ID
		   INNER JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] d on  c.[OPERATED_PROPERTY_ID]=d.ID
		   WHERE 1=1 
		   UNION
		   SELECT b.ID Obj_ID													----add Object Number to Passenger with Parked Vehicle, no Driver/Pedestrian Condition
				 ,DRIVER_PEDESTR_COND_ID=NULL
				 ,a.SEQ_NBR Object_NBR
		   FROM [ECRDBA].[CL_OBJECTS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.[PARENT_OBJECT_ID]
		   INNER JOIN [ECRDBA].[CLOBJ_PROPERTY_INFO] c on  a.Property_ID=c.ID
		   WHERE 1=1
		   ) Cond on Cond.Obj_ID=obj.ID

LEFT JOIN (SELECT DISTINCT a.ID													----add Animal Flag to Collision
				 ,b.DESCRIPTION
				 ,Flag_Animal='Y'
		   FROM [ECRDBA].[COLLISIONS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.COLLISION_ID
		   WHERE 1=1 
		   AND b.OBJECT_TYPE_ID='7'		--7 Animal
		   ) Anim on c.ID=Anim.ID 

LEFT JOIN (SELECT DISTINCT a.ID													----add Other Property Flag to Collision
				 --,b.DESCRIPTION												----a collision could have more than one Other Property
				 ,Flag_Oth_Property='Y'
		   FROM [ECRDBA].[COLLISIONS] a
		   INNER JOIN [ECRDBA].[CL_OBJECTS] b on a.ID=b.COLLISION_ID
		   WHERE 1=1 
		   AND b.OBJECT_TYPE_ID='9'		--9	Other Property
		   ) Oth_Prop on c.ID=Oth_Prop.ID

--LEFT JOIN [eCollisionAnalytics].[EDADIM].[Dates] d on c.OCCURENCE_TIMESTRING=d.DateString 
--LEFT JOIN [eCollisionAnalytics_REPUAT].[EDADIM].[HighWay] b on c.LOC_HWY_NBR=b.Name
LEFT JOIN [ECRDBA].[ECR_COLL_PLOTTING_INFO] plot on c.ID = plot.COLLISION_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] p on p.ID=par.POSITION_IN_VEHICLE_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] s on s.ID=par.SAFETY_EQUIPMENT_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] sub on sub.ID=plot.COLLISION_SUB_TYPE_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] loc on loc.ID=c.COLLISION_LOCATION_ID

WHERE 1=1
	AND c.CASE_YEAR in (2018, 2019, 2020, 2021, 2022, 2023)
	-- AND lower(c.LOC_DESC) LIKE '%ponoka%')
	-- AND (c.LOC_IN_CITY_FLAG<>1 OR (lower(c.LOC_DESC) LIKE '%sturg%') AND lower(c.LOC_DESC) LIKE '%count%')
	-- AND c.LOC_IN_CITY_FLAG<>1
	-- AND (c.LOC_DESC like 'CCHRANE%' OR c.LOC_DESC like 'COC%')
	-- AND lower(c.LOC_DESC) LIKE '%sturg%' AND lower(c.LOC_DESC) LIKE '%count%'
	-- AND (c.POLICE_SERVICE_CODE in ('3183','3197') OR lower(c.LOC_DESC) LIKE '%wetaski%')
	-- AND c.LOC_IN_CITY_FLAG = 1
), IntermediateTable as (
	select
		*
	from MainTable
	where 1=1
		-- Apply "Passenger Car" (object_identification_type_id = 124) or Motorcycle/Scooter" (object_identification_type_id = 129)
		AND OBJECT_IDENTIFICATION_TYPE_ID_OG = 129
		
)
	SELECT CASE_YEAR
		  ,[COLLISION_SEVERITY] as Category
		  ,COUNT(DISTINCT Collision_ID) COUNT
		  ,TableName='Collision Severity'
		  ,TableOrder=1
	FROM IntermediateTable 
	WHERE 1=1
	GROUP BY CASE_YEAR, COLLISION_SEVERITY
	UNION
	SELECT CASE_YEAR
		  ,INJURY_SEVERITY
		  ,COUNT(DISTINCT Party_ID) COUNT
		  ,TableName='Injury Severity'
		  ,TableOrder=2
	FROM IntermediateTable 
	WHERE 1=1
	AND [INJURY_SEVERITY] is NOT NULL
	AND [INJURY_SEVERITY] Not in ('None','Unknown')
	GROUP BY CASE_YEAR,INJURY_SEVERITY
	UNION
	SELECT CASE_YEAR
		  ,Category='Unsafe Speed'
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Unsafe Speed'
		  ,TableOrder=3
	FROM IntermediateTable 
	WHERE 1=1
	AND [UNSAFE_SPEED_ID]=231
	AND [COLLISION_SEVERITY] <>'Fatal'
	AND Object_type in  ('Driver','Motorcyclist','Other Vehicle')
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Category='Intersections'
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Intersections'
		  ,TableOrder=4
	FROM IntermediateTable
	WHERE 1=1
	AND [TRAFFIC_CTRL_DEVICE_ID] in (201,202,203,204)
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Category='Weather-Related'
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Weather-Related'
		  ,TableOrder=5
	FROM IntermediateTable
	WHERE 1=1
	AND ENVIRONMENTAL_CONDITION_ID in (50,51,52,53,54,55)		
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Category='Surface Condition'
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Surface Condition'
		  ,TableOrder=6
	FROM IntermediateTable
	WHERE 1=1
	AND SURFACE_COND_ID in (58,59,60,61,62)		
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Category='Animal-Related'
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Animal-Related'
		  ,TableOrder=7
	FROM IntermediateTable
	WHERE 1=1
	AND OBJECT_TYPE='Animal'	
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Category='Drivers Performing Improper Actions'
		  ,COUNT(Distinct Party_ID) as Total
		  ,TableName='Drivers Performing Improper Actions'
		  ,TableOrder=8
	FROM IntermediateTable
	WHERE 1=1
	AND DRIVER_ACTION_ID NOT IN (155,161,171)		--155 Driving Properly 161 Parked Vehicle 171 Unknown
	GROUP BY CASE_YEAR
	UNION
	SELECT CASE_YEAR
		  ,Seasons
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Seasons'
		  ,TableOrder=8
	FROM IntermediateTable
	WHERE 1=1
	GROUP BY CASE_YEAR,Seasons
	UNION
	SELECT CASE_YEAR
		  ,YearlyQuarter
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Quarter'
		  ,TableOrder=9
	FROM IntermediateTable
	WHERE 1=1
	GROUP BY CASE_YEAR,YearlyQuarter
	UNION
	SELECT CASE_YEAR
		  ,TimeGroup
		  ,COUNT(Distinct Collision_ID) as Total
		  ,TableName='Time'
		  ,TableOrder=10
	FROM IntermediateTable
	WHERE 1=1
	GROUP BY CASE_YEAR,TimeGroup
	UNION
	SELECT CASE_YEAR
		  ,Sex
		  ,COUNT(Distinct Party_ID) as Total
		  ,TableName='Sex'
		  ,TableOrder=11
	FROM IntermediateTable
	WHERE 1=1
	AND INJURY_Category in ('Injury','Fatal')
	GROUP BY CASE_YEAR,Sex
	UNION
	SELECT CASE_YEAR
		  ,Sex
		  ,COUNT(Distinct Party_ID) as Total
		  ,TableName='Not Wearing Seatbelt'
		  ,TableOrder=12
	FROM IntermediateTable
	WHERE 1=1
	AND [Unbelted_Flag]='Y'
	AND INJURY_Category in ('Injury','Fatal')
	GROUP BY CASE_YEAR, Sex
	ORDER BY CASE_YEAR, TableName, Category