
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
	  ,CASE WHEN LOC_HWY_NBR in ('1','1A','1X','2','2A','3','3A','4','4E','5','6','7','8','9','10','10X'
						,'11','11A','12','12A','13','13A','14','14X','15','16','16A','16X','17','18','19','20','20A'
						,'21','22','22X','23','24','25','26','27','28','28A','29'
						,'31','32','`33','33','34','35','36','37','38','39'
						,'40','41','41A','42','43','43X','44','45','47','49'
						,'50','52','53','54','55','56','58','59'
						,'60','61','62','63','64','64A','66','68','69'
						,'72','78/0','80','82','88','93','93A','93N','96','97'
						,'100','103','112','121','130','153','155','162','178','192','194'
						,'201','203','216','222','240','243','249','254','266','272','360','400','423','443')
			THEN  'Y'
			ELSE 'N'
		END	Primary_HW_Flag						--SAS Code 1-499 = 'PRIMARY HIGHWAY'; 500-999 = 'SECONDARY HIGHWAY'; Alberta provincial highway 1-216
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
	  ,CASE WHEN obj.OBJECT_TYPE_ID = '10' THEN (SELECT obj1.OBJECT_TYPE_ID from [ECRDBA].[CL_OBJECTS] obj1 where obj1.ID = obj.PARENT_OBJECT_ID)
			ELSE obj.OBJECT_TYPE_ID
		END as OBJECT_TYPE_ID_TIRF			--If Object ID is passenger, then use Parent Object ID, Don't Know Why
	  ,obj.[SEQ_NBR]
	  ,CASE WHEN obj.OBJECT_TYPE_ID ='10' THEN cond.Object_NBR			-- Object Number for Passenger
			ELSE SEQ_NBR
		END Object_NBR
	  ,Case WHEN obj.[OBJECT_TYPE_ID]=5 THEN pro1.[OBJECT_IDENTIFICATION_TYPE_ID]		--Parked Vehicle
			WHEN obj.[OBJECT_TYPE_ID]=10 THEN v.[OBJECT_IDENTIFICATION_TYPE_ID]			--Passenger  
			WHEN obj.[OBJECT_TYPE_ID]=2 THEN 130										--Pedestrian
			WHEN obj.[OBJECT_TYPE_ID]=7 THEN 138										--Animal
			WHEN obj.[OBJECT_TYPE_ID]=6 THEN 137										--Train
			WHEN obj.[OBJECT_TYPE_ID]=9 THEN 136										--Fixed Object
			ELSE pro.[OBJECT_IDENTIFICATION_TYPE_ID]
		END [OBJECT_IDENTIFICATION_TYPE_ID]												--Add Vehicle Type to Parked Vehicle and Passenger
	  ,CASE WHEN obj.[OBJECT_TYPE_ID]=5 THEN 'Y'
			WHEN v.Flag_ParkedVehicle='Y' THEN 'Y'
			ELSE 'N'
		END Flag_ParkedVehicle
	  ,obj.DESCRIPTION Obj_Description
	  ,Case WHEN obj.[OBJECT_TYPE_ID]=5 THEN pro1.[ATTACHMENT_ID] ELSE pro.ATTACHMENT_ID END ATTACHMENT_ID		--Add ATTACHMENT_ID to Parked Vehicle
	  ,CASE WHEN Anim.Flag_Animal is NULL THEN 'N' ELSE Anim.Flag_Animal END Flag_Animal
	  --,CASE WHEN Anim.Flag_Animal='Y' THEN Anim.DESCRIPTION END Anim_Description								--Need to fix it as a collision could have more than one animal
	  ,CASE WHEN Oth_Prop.Flag_Oth_Property is NULL THEN 'N' ELSE Oth_Prop.Flag_Oth_Property END Flag_Oth_Property
	  --,CASE WHEN Oth_Prop.Flag_Oth_Property='Y' THEN Oth_Prop.DESCRIPTION END Oth_Prop_Description				--Need to fix it, as a collision could have more than one Other Property.
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
	  ,d.SHORT_DESC [DRIVER_ACTION]
	  --,par.[DRIVER_PEDESTR_COND_ID]
	  ,CASE WHEN obj.[OBJECT_TYPE_ID]=10 THEN cond.DRIVER_PEDESTR_COND_ID		--Add Driver/Pedestrian Condition to Passenger
	   ELSE par.[DRIVER_PEDESTR_COND_ID]
	   END [DRIVER_PEDESTR_COND_ID]
	  ,par.[POSITION_IN_VEHICLE_ID]
	  ,p.SHORT_DESC [Position_in_Vehicle]
	  ,p.CODE	[Position_in_Vehicle_Code]
	  ,CASE WHEN par.POSITION_IN_VEHICLE_ID=77 THEN 'Driver'
			WHEN par.POSITION_IN_VEHICLE_ID in (78,241,242,243,244,245,246,247) THEN 'Passengers'
			WHEN par.POSITION_IN_VEHICLE_ID=81 THEN 'Pedestrians'
			WHEN par.POSITION_IN_VEHICLE_ID=79 THEN 'Motorcyclists'
			WHEN par.POSITION_IN_VEHICLE_ID=80 THEN 'Bicyclists'
			WHEN par.POSITION_IN_VEHICLE_ID=82 THEN 'Other'
			WHEN par.POSITION_IN_VEHICLE_ID=83 THEN 'Unknown'
		END Road_User
	  ,par.[UNSAFE_SPEED_ID]
	  ,par.[DRIVER_DISTRACTION_ID]
	  ,par.[EJECTION_TYPE_ID]
	  ,par.[SAFETY_EQUIPMENT_ID]
	  ,s.SHORT_DESC [SAFETY_EQUIPMENT]
	  ,s.CODE [SAFETY_EQUIPMENT_Code]
	  ,CASE WHEN par.[POSITION_IN_VEHICLE_ID] in (77,78,241,242,243,244,245,246,247) and par.[SAFETY_EQUIPMENT_ID]=91 THEN 'Y'			--[SAFETY_EQUIPMENT_ID]=91 'None'
	   END [Unbelted_Flag]
	  ,CASE WHEN par.[SAFETY_EQUIPMENT_ID]=91 Then 'Unbelted'
			WHEN par.[SAFETY_EQUIPMENT_ID] in (84,85,86,87,88,89) Then 'Belted'
			WHEN par.[SAFETY_EQUIPMENT_ID]=90 Then 'Helmet'
			WHEN par.[SAFETY_EQUIPMENT_ID]=92 Then 'Other'
			WHEN par.[SAFETY_EQUIPMENT_ID]=93 Then 'Unknown'
		END SAFETY_EQUIPMENT_Category
	  ,CASE WHEN par.[POSITION_IN_VEHICLE_ID] in (77) THEN 'Driver'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (78,241,242,243,244,245,246,247) THEN 'Passenger'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (79) THEN 'Motorcyclist'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (80) THEN 'Bicyclist'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (81) THEN 'Pedestrian'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (82) THEN 'Other'
			WHEN par.[POSITION_IN_VEHICLE_ID] in (83) THEN 'Unknown'
		END Posn_Obj
	  ,c.[VEHICLES_NBR]
	  ,c.[INJURED_NBR]
      ,c.[FATALITIES_NBR]
	  ,par.[AGE]
	  ,CASE WHEN par.MALE_FLAG=1 THEN 'M'
			WHEN par.MALE_FLAG=2 THEN 'F'
			WHEN par.MALE_FLAG=3 THEN 'U'
			WHEN par.MALE_FLAG=4 THEN 'O'
			ELSE 'U'
		END [Sex]
	  ,par.LAST_NAME
	  ,par.FIRST_NAME
	  ,par.MIDDLE_NAME
	  ,c.COLLISION_LOCATION_ID
	  ,c.POLICE_SERVICE_CODE
	  ,loc.SHORT_DESC Collision_Location 
	  ,plot.COLLISION_SUB_TYPE_ID
	  ,sub.SHORT_DESC Collision_Sub_Type
	  ,plot.CONTROL_SECTION
	  ,plot.KM_POST
	  ,c.ENVIRONMENTAL_CONDITION_ID
	  ,c.SURFACE_COND_ID
	  ,surf.SHORT_DESC SURFACE_COND
	  ,obj.CONTRIB_ROAD_COND_ID
	  ,road.SHORT_DESC Road_Cond
	  ,[OCCURENCE_TIMESTRING]
	  ,c.OCCURENCE_TIMESTAMP
	  ,c.OCCURENCE_TIME
	  ,CONVERT(char(5),OCCURENCE_TIMESTAMP,108) [Time]
	  ,Month(OCCURENCE_TIMESTAMP) Month
	  ,DATEPART(WEEKDAY,OCCURENCE_TIMESTAMP) Week_num
	  ,Week_Name=CASE DATEPART(WEEKDAY,OCCURENCE_TIMESTAMP)
	   WHEN 1 Then 'Sunday'  
	   WHEN 2 Then 'Monday'
	   WHEN 3 Then 'Tuesday'
	   WHEN 4 Then 'Wednesday'
	   WHEN 5 Then 'Thursday'
	   WHEN 6 Then 'Friday'
	   WHEN 7 Then 'Saturday'
	   END 
	  ,dt.FiscalYear
	  ,CASE												----This is for the School Year Name. Need to use SchoolYearFlag=1 to filter out the months of July and August.
		WHEN MONTH(OCCURENCE_TIMESTAMP)<=6 THEN convert(varchar(5),YEAR(OCCURENCE_TIMESTAMP)-1) +'/'+ convert(varchar(5),YEAR(OCCURENCE_TIMESTAMP))
		WHEN MONTH(OCCURENCE_TIMESTAMP)>=9 THEN convert(varchar(5),YEAR(OCCURENCE_TIMESTAMP)) +'/'+ convert(varchar(5),YEAR(OCCURENCE_TIMESTAMP)+1)
		ELSE convert(varchar(5),YEAR(OCCURENCE_TIMESTAMP))+'/'+ convert(varchar(5),Month(OCCURENCE_TIMESTAMP))	----List July and August
	   END AS SchoolYear									
	  ,dt.SchoolYearFlag
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
	   END Time_Period1
	  ,CASE WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108)='00:00' THEN 'Unspecified'			--Use OCCURENCE_TIMESTAMP to get Time instead of using Occurrence Time. There are many NULLs under OCCURENCE_TIME for 2019 data.
			ELSE CASE
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) >='23:00' OR CONVERT(char(5),OCCURENCE_TIMESTAMP,108)<'03:00' THEN '1 11:00 pm - 2:59 am'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '03:00' AND '06:59' THEN '2 3:00 am - 6:59 am'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '07:00' AND '10:59' THEN '3 7:00 am - 10:59 am'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '11:00' AND '14:59' THEN '4 11:00 am - 2:59 pm'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '15:00' AND '18:59' THEN '5 3:00 pm - 6:59 pm'
			WHEN CONVERT(char(5),OCCURENCE_TIMESTAMP,108) BETWEEN '19:00' AND '22:59' THEN '6 7:00 pm - 10:59 pm'
			ELSE 'Unspecified'
			END
	   END Time_Period
	   ,CASE WHEN OCCURENCE_TIMESTRING ='2020/01/01' THEN '1 New Years Day(Jan 1)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/02/14' AND '2020/02/17' THEN '2 Family Day (Feb 14-17)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/04/09' AND '2020/04/13' THEN '3 Easter Long Weekend (Apr 9-Apr 13)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/05/15' AND '2020/05/18' THEN '4 Victoria Day (May 15-18)'
			 WHEN OCCURENCE_TIMESTRING ='2020/07/01' THEN '5 Canada Day(Jul 1)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/07/31' AND '2020/08/03' THEN '5.5 August Long Weekend (Jul 31-Aug 3)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/09/04' AND '2020/09/07' THEN '6 Labour Day Long Weekend (Sep 4-Sep 7)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/10/09' AND '2020/10/12' THEN '7 Thanksgiving Long Weekend (Oct 9-12)'
			 WHEN OCCURENCE_TIMESTRING ='2020/11/11' THEN '8 Remembrance Day(Nov 11)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2020/12/24' AND '2020/12/28' THEN '9 Christmas Season (Dec 24-28)'
		END Holiday2020
	   ,CASE WHEN OCCURENCE_TIMESTRING ='2021/01/01' THEN '1 New Years Day(Jan 1)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/02/12' AND '2021/02/15' THEN '2 Family Day (Feb 12-15)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/04/01' AND '2021/04/05' THEN '3 Easter Long Weekend (Apr 1-Apr 5)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/05/21' AND '2021/05/24' THEN '4 Victoria Day (May 21-24)'
			 WHEN OCCURENCE_TIMESTRING ='2021/07/01' THEN '5 Canada Day(Jul 1)'
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/07/30' AND '2021/08/02' THEN '5.5 August Long Weekend (Jul 30-Aug 2)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/09/03' AND '2021/09/06' THEN '6 Labour Day Long Weekend (Sep 3-Sep 6)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/10/08' AND '2021/10/11' THEN '7 Thanksgiving Long Weekend (Oct 8-11)'
			 WHEN OCCURENCE_TIMESTRING ='2021/11/11' THEN '8 Remembrance Day(Nov 11)'	
			 WHEN OCCURENCE_TIMESTRING BETWEEN '2021/12/24' AND '2021/12/28' THEN '9 Christmas Season (Dec 24-28)'
		END Holiday2021
	   ,CASE WHEN AGE is NULL THEN 'Unspecified'
			WHEN par.AGE<5 THEN 'Under 5'
			WHEN AGE<10 THEN '5-9'
			WHEN AGE<15 THEN '10-14'
			WHEN AGE<20 THEN '15-19'
			WHEN AGE<25 THEN '20-24'
			WHEN AGE<30 THEN '25-29'	
			WHEN AGE<35 THEN '30-34'
			WHEN AGE<45 THEN '35-44'
			WHEN AGE<55 THEN '45-54'
			WHEN AGE<65 THEN '55-64'
			ELSE '65 and over'
		END Age_Group
	   ,CASE WHEN AGE is NULL THEN 'Unspecified'
			WHEN par.AGE<16 THEN 'Under 16'
			WHEN AGE<18 THEN '16-17'
			WHEN AGE<20 THEN '18-19'
			WHEN AGE<25 THEN '20-24'	
			WHEN AGE<35 THEN '25-34'
			WHEN AGE<45 THEN '35-44'
			WHEN AGE<55 THEN '45-54'
			WHEN AGE<65 THEN '55-64'
			ELSE '65 and over'
		END Driver_AgeGroup
	   ,CASE WHEN AGE is NULL THEN 'Unspecified'
			WHEN par.AGE<16 THEN 'Under 16'
			WHEN AGE<18 THEN '16-17'
			WHEN AGE<20 THEN '18-19'
			WHEN AGE<22 THEN '20-21'
			WHEN AGE<25 THEN '22-24'
			WHEN AGE<30 THEN '25-29'	
			WHEN AGE<35 THEN '30-34'
			WHEN AGE<45 THEN '35-44'
			WHEN AGE<55 THEN '45-54'
			WHEN AGE<65 THEN '55-64'
			ELSE '65 and over'
		END Driver_AgeGroup1
	   ,CASE WHEN obj.[OBJECT_TYPE_ID]=5 THEN pro1.VEH_COND_CONTRIB_ID ELSE pro.VEH_COND_CONTRIB_ID END VEH_COND_CONTRIB_ID		--Add VEH_COND_CONTRIB_ID to Parked Vehicle
	   ,CASE WHEN obj.[OBJECT_TYPE_ID]=5 THEN pro1.INITIAL_POINT_OF_IMPACT_ID ELSE pro.INITIAL_POINT_OF_IMPACT_ID END INITIAL_POINT_OF_IMPACT_ID		--Add INITIAL_POINT_OF_IMPACT_ID to Parked Vehicle
	   
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
				 --,b.DESCRIPTION												--Need to fix it as a collision could have more than one animal
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

LEFT JOIN [eCollisionAnalytics].[EDADIM].[Dates] dt on c.OCCURENCE_TIMESTRING=dt.DateString 
--LEFT JOIN [eCollisionAnalytics_REPUAT].[EDADIM].[HighWay] b on c.LOC_HWY_NBR=b.Name
LEFT JOIN [ECRDBA].[ECR_COLL_PLOTTING_INFO] plot on c.ID = plot.COLLISION_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] p on p.ID=par.POSITION_IN_VEHICLE_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] s on s.ID=par.SAFETY_EQUIPMENT_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] sub on sub.ID=plot.COLLISION_SUB_TYPE_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] loc on loc.ID=c.COLLISION_LOCATION_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] d on d.ID=par.DRIVER_ACTION_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] surf on surf.ID=c.SURFACE_COND_ID
LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] road on road.id=obj.CONTRIB_ROAD_COND_ID

WHERE 1=1
--AND c.CASE_YEAR between 2014 and 2018
AND c.Case_Year in (2000, 2001, 2002, 2014, 2015, 2016)

)

------Traffic Collision Summary-----------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 1.1'
--		,TableName='Alberta Traffic Collisions'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--UNION
--SELECT Distinct CASE_YEAR
--		,INJURY_SEVERITY
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 1.1'
--		,TableName='Alberta Traffic Casualties'
--FROM MainTable 
--WHERE 1=1
--AND INJURY_SEVERITY_ID in (95,96,97)
--GROUP BY CASE_YEAR
--		,INJURY_SEVERITY

-- Aggregate by case year
--SELECT Distinct CASE_YEAR
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 1.1'
--		,TableName='Alberta Traffic Casualties'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR

-- Flat file
select
	ID as COLLISION_ID
	, CASE_NBR
	, PFN_FILE_NBR
	, FORM_CASE_NBR
	, CASE_YEAR
	, OCCURENCE_TIMESTAMP
	, HIGHWAY
	, POLICE_SERVICE_CODE
from MainTable

------------------------------------------------------------
------When the collisions occurred---------
--SELECT Distinct CASE_YEAR
--		,Month
--		,COLLISION_SEVERITY
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 2.1'
--		,TableName='Collision Occurrence by Month'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,Month
--		,COLLISION_SEVERITY
--UNION
--SELECT Distinct CASE_YEAR
--		,Week_Name
--		,COLLISION_SEVERITY
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 2.2'
--		,TableName='Collision Occurrence by Day of Week'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,Week_Name
--		,COLLISION_SEVERITY
--UNION
--SELECT Distinct CASE_YEAR
--		,Time_Period
--		,COLLISION_SEVERITY
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 2.3'
--		,TableName='Collision Occurrence by Time Period'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,Time_Period
--		,COLLISION_SEVERITY	
--UNION
--SELECT Distinct CASE_YEAR
--		,Holiday2021
--		--,INJURY_Category
--		--,COUNT(DISTINCT Party_ID) Total			--for Casualities
--		--,COLLISION_SEVERITY
--		,COUNT(DISTINCT Collision_ID) Total			--for Collisions
--		,TableNum='Table 2.4'
--		,TableName='Collisions During 2021 Holidays'
--FROM MainTable 
--WHERE 1=1
--AND Holiday2021 is NOT NULL
--GROUP BY CASE_YEAR
--		,Holiday2021
--		--,INJURY_Category
--		--,COLLISION_SEVERITY	
--ORDER BY 2,3
---------------------------------------------------------------------------------
------Victims-----------
--SELECT Distinct CASE_YEAR
--		,Road_User					--using [POSITION_IN_VEHICLE_ID]
--		,INJURY_Category
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 3.1'
--		,TableName='Injuries and Fatalities by Road User Class'
--FROM MainTable 
--WHERE 1=1
--AND INJURY_Category in ('Fatal','Injury')
--GROUP BY CASE_YEAR
--		,Road_User
--		,INJURY_Category
--UNION
--SELECT Distinct CASE_YEAR
--		,Age_Group				
--		,INJURY_Category
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 3.2'
--		,TableName='Age of Casualties'
--FROM MainTable 
--WHERE 1=1
--AND INJURY_Category in ('Fatal','Injury')
--GROUP BY CASE_YEAR
--		,Age_Group
--		,INJURY_Category
-------------------------------------------------------------------------
------Driver----------
--SELECT Distinct CASE_YEAR
--		,Driver_AgeGroup			
--		--,Sex
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 4.1'
--		,TableName='Age and Gender of Drivers Involved in Casualty Collisions'
--FROM MainTable a
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,Driver_AgeGroup
--		--,Sex


--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION			
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 4.2'
--		,TableName='Improper Actions of Drivers Involved in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--------------------------------------------------------------------------------
--------Vehicles----------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,objID.SHORT_DESC Vehicle_Type		
--		,COUNT(distinct [OBJ_ID]) Total			
--		,TableNum='Table 5.1'
--		,TableName='Types of Vehicles Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,objID.SHORT_DESC

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC VEH_COND_CONTRIB			--include Parked Vehicle
--		,COUNT(DISTINCT [OBJ_ID]) Total			
--		,TableNum='Table 5.2'
--		,TableName='Vehicle Factors Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Vcond on Vcond.ID=a.VEH_COND_CONTRIB_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,Impact.SHORT_DESC INITIAL_POINT_OF_IMPACT			--include Parked Vehicle
--		,COUNT(DISTINCT [OBJ_ID]) Total			
--		,TableNum='Table 5.3'
--		,TableName='Point of Impact on Vehicles Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Impact on Impact.ID=a.INITIAL_POINT_OF_IMPACT_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,Impact.SHORT_DESC
--------------------------------------------------------------
-------Environment------------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,LOC_IN_CITY_FLAG
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 6.1'
--		,TableName='Location of Collisions'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,LOC_IN_CITY_FLAG

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,SURFACE_COND
--		,COUNT(DISTINCT Collision_ID) Total
--		,TableNum='Table 6.2'
--		,TableName='Casualty Collision Occurrence by Surface Condition'
--FROM MainTable 
--WHERE 1=1
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,SURFACE_COND
-----------------------------------------------------------
---------Special types of vehicles - motorcycles------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
----		,objID.SHORT_DESC Vehicle_Type		
--		,COUNT(distinct [OBJ_ID]) Total			
--		,TableNum='Table 7.1'
--		,TableName='Motorcycles Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND a.OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,objID.SHORT_DESC
--UNION
--SELECT Distinct CASE_YEAR
--		,INJURY_Category
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.1'
--		,TableName='Casualties in Collisions Involving Motorcycles'
--FROM MainTable a
--INNER JOIN (SELECT DISTINCT Collision_ID
--		   FROM MainTable a
--		   LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--		   WHERE 1=1
--		   AND a.OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--		   ) b on b.Collision_ID=a.Collision_ID
--WHERE 1=1
--AND INJURY_SEVERITY_ID in (95,96,97)
--GROUP BY CASE_YEAR
--		,INJURY_Category

--SELECT Distinct CASE_YEAR
--		,Driver_AgeGroup
--		,Sex
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.2'
--		,TableName='Age and Gender of Motorcycle Operators Involved in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,Driver_AgeGroup
--		,Sex

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.3'
--		,TableName='Improper Actions of Motorcycle Operators Involved in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION

--SELECT Distinct CASE_YEAR				--Impaired Driving - Motorcyclist
--		--,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END DRIVER_PEDESTR_COND
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.4'
--		,TableName='Condition of Motorcycle Operators Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)			--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
----AND a.OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END 

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC VEH_COND_CONTRIB			--include Parked Vehicle
--		,COUNT(DISTINCT [OBJ_ID]) Total			
--		,TableNum='Table 7.5'
--		,TableName='Motorcycle Vehicle Factors in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Vcond on Vcond.ID=a.VEH_COND_CONTRIB_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 7.6'
--		,TableName='Casualty Collisions Involving Motorcycles: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,SURFACE_COND
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 7.7'
--		,TableName='Casualty Collisions Involving Motorcycles: Road Surface Condition'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND OBJECT_IDENTIFICATION_TYPE_ID=129		--129 Motorcycle/Scooter
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,SURFACE_COND
-----------------------------------------------------------
---------Special types of vehicles - truck tractors------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
----		,objID.SHORT_DESC Vehicle_Type		
--		,COUNT(distinct [OBJ_ID]) Total			
--		,TableNum='Table 7.8'
--		,TableName='Truck Tractors Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND a.OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,objID.SHORT_DESC
--UNION
--SELECT Distinct CASE_YEAR
--		,INJURY_Category
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.8'
--		,TableName='Casualties in Collisions Involving Truck Tractors'
--FROM MainTable a
--INNER JOIN (SELECT DISTINCT Collision_ID
--		   FROM MainTable a
--		   LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--		   WHERE 1=1
--		   AND a.OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--		   ) b on b.Collision_ID=a.Collision_ID
--WHERE 1=1
--AND INJURY_SEVERITY_ID in (95,96,97)
--GROUP BY CASE_YEAR
--		,INJURY_Category

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.9'
--		,TableName='Improper Actions of Truck Tractor Drivers Involved in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION

--SELECT Distinct CASE_YEAR				--Impaired Driving - Truck Tractor
--		--,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Alcohol and Drug Impaired'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Drugs Impaired'
--		 WHEN Dcon.LONG_DESC = 'Impaired By Drugs' THEN 'Drugs Impaired'
--		 WHEN Dcon.LONG_DESC = 'Impaired By Alcohol' THEN 'Alcohol Impaired'
--		 ELSE Dcon.LONG_DESC
--		 END DRIVER_PEDESTR_COND
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.10'
--		,TableName='Condition of Truck Tractor Drivers Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)			--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND a.OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Alcohol and Drug Impaired'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Drugs Impaired'
--		 WHEN Dcon.LONG_DESC = 'Impaired By Drugs' THEN 'Drugs Impaired'
--		 WHEN Dcon.LONG_DESC = 'Impaired By Alcohol' THEN 'Alcohol Impaired'
--		 ELSE Dcon.LONG_DESC
--		 END 

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC VEH_COND_CONTRIB			--include Parked Vehicle
--		,COUNT(DISTINCT [OBJ_ID]) Total			
--		,TableNum='Table 7.11'
--		,TableName='Vehicle Factors of Truck Tractors Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Vcond on Vcond.ID=a.VEH_COND_CONTRIB_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Vcond.SHORT_DESC

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 7.12'
--		,TableName='Casualty Collisions Involving Truck Tractors: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND OBJECT_IDENTIFICATION_TYPE_ID=128		--128 Truck Tractor
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)
------------------------------------------------------------------
---------Special types of vehicles - trains------
--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
----		,objID.SHORT_DESC Vehicle_Type		
--		,COUNT(distinct [OBJ_ID]) Total			
--		,TableNum='Table 7.13'
--		,TableName='Trains Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID=6		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
----AND a.OBJECT_IDENTIFICATION_TYPE_ID=137		--137 Train  /**Case_NBR 5023282 had the object train with a passenage, so need to use OBJECT_TYPE_ID=6**/
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,objID.SHORT_DESC
--UNION
--SELECT Distinct CASE_YEAR
--		,INJURY_Category
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.13'
--		,TableName='Casualties in Collisions Involving Trains'
--FROM MainTable a
--INNER JOIN (SELECT DISTINCT Collision_ID
--		   FROM MainTable a
--		   LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] objID on objID.ID=a.OBJECT_IDENTIFICATION_TYPE_ID
--		   WHERE 1=1
--		   AND a.OBJECT_IDENTIFICATION_TYPE_ID=137		--137 Trains
--		   ) b on b.Collision_ID=a.Collision_ID
--WHERE 1=1
--AND INJURY_SEVERITY_ID in (95,96,97)
--GROUP BY CASE_YEAR
--		,INJURY_Category

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 7.14'
--		,TableName='Casualty Collisions Involving Trains: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (6)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 7.15'
--		,TableName='Actions of Drivers Involved in Casualty Collisions with Trains'
--FROM MainTable a
--INNER JOIN (SELECT DISTINCT Collision_ID
--			FROM MainTable
--			WHERE 1=1
--			AND OBJECT_TYPE_ID in (6)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--			) b on b.Collision_ID=a.Collision_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,5,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
----------------------------------------------------------------------------------------
----------Pedestrians----------------------
--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 8.1'
--		,TableName='Casualty Collisions Involving Pedestrians: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)
--ORDER BY 2

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Week_Name
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 8.2'
--		,TableName='Casualty Collisions Involving Pedestrians: Day of Week'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Week_Name

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Time_Period
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 8.3'
--		,TableName='Casualty Collisions Involving Pedestrians: Time Period'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Time_Period

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,LOC_IN_CITY_FLAG
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 8.4'
--		,TableName='Casualty Collisions Involving Pedestrians: Location'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
		--,LOC_IN_CITY_FLAG

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 8.5'
--		,TableName='Actions of Drivers Involved in Casualty Collisions with Pedestrians'
--FROM MainTable a
--INNER JOIN (SELECT DISTINCT Collision_ID
--			FROM MainTable
--			WHERE 1=1
--			AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--			) b on b.Collision_ID=a.Collision_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,4,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION

--SELECT Distinct CASE_YEAR
--		,INJURY_Category
--		,Age_Group
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 8.6'
--		,TableName='Age of Pedestrian Casualties'
--FROM MainTable 
--WHERE 1=1
----AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND OBJECT_IDENTIFICATION_TYPE_ID=130
--AND INJURY_Category in ('Fatal','Injury')
--GROUP BY CASE_YEAR
--		,INJURY_Category
--		,Age_Group

--SELECT Distinct CASE_YEAR				--Impaired Driving 
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END DRIVER_PEDESTR_COND
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 8.7'
--		,TableName='Condition of Pedestrians Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END 

--SELECT Distinct CASE_YEAR				--Impaired Driving by Age
--		--,COLLISION_SEVERITY
--		,Age_Group
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 8.8'
--		,TableName='Age of Impaired Pedestrians Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (2)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--AND a.DRIVER_PEDESTR_COND_ID in (179,180,1327,1326,1325,1324,1323,1322,1321,1320,1313,1314,1315,1316,1317,1318,1319)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Age_Group
---------------------------------------------------------------
-----------Bicyclists-----------
--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 9.1'
--		,TableName='Casualty Collisions Involving Bicycles: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (4)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)
--ORDER BY 2

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Week_Name
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 9.2'
--		,TableName='Casualty Collisions Involving Bicycles: Day of Week'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (4)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Week_Name

--SELECT Distinct CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Time_Period
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 9.3'
--		,TableName='Casualty Collisions Involving Bicycles: Time Period'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (4)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		--,COLLISION_SEVERITY
--		,Time_Period

--SELECT Distinct CASE_YEAR
--		,INJURY_Category
--		,Age_Group
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 9.4'
--		,TableName='Age of Bicyclist Casualties'
--FROM MainTable 
--WHERE 1=1
----AND OBJECT_TYPE_ID in (4)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND OBJECT_IDENTIFICATION_TYPE_ID=131		--131 Bicycle
--AND INJURY_Category in ('Fatal','Injury')
--GROUP BY CASE_YEAR
--		,INJURY_Category
--		,Age_Group

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 9.5'
--		,TableName='Improper Actions of Bicyclists Involved in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (4)		--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,DRIVER_ACTION

--SELECT Distinct CASE_YEAR				--Impaired Driving 
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END DRIVER_PEDESTR_COND
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 9.6'
--		,TableName='Condition of Bicyclists Involved in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (4)		--1 Driver;2 Pedestrian;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;6 Train;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END
-----------------------------------------------------------------------------
--------Traffic safety issues-----------------

--SELECT Distinct CASE_YEAR				--Impaired Driving
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END DRIVER_PEDESTR_COND
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 10.1'
--		,TableName='Condition of Drivers in Casualty Collisions'
--FROM MainTable a
--LEFT JOIN [ECRDBA].[CODE_TYPE_VALUES] Dcon on Dcon.ID=a.DRIVER_PEDESTR_COND_ID
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,8)			--1 Driver;3 Motorcyclist;4 Bicyclist;5 Parked Vehicle;8 Other Vehicle
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,CASE
--		 WHEN Dcon.LONG_DESC in ('Had Been Drinking','Medical Defect','Other/Specify') THEN 'Other' 
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs and Alcohol%' THEN 'Impaired by Drugs and Alcohol'
--		 WHEN Dcon.LONG_DESC like 'Impaired by Drugs -%' THEN 'Impaired by Drugs'
--		 ELSE Dcon.LONG_DESC
--		 END 

--SELECT Distinct CASE_YEAR
--		,Driver_AgeGroup1			
--		,Sex
--		,COUNT(DISTINCT Party_ID) Total			
--		,TableNum='Table 10.2'
--		,TableName='Age and Gender of Impaired Drivers in Casualty Collisions'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND DRIVER_PEDESTR_COND_ID in (179,180,1327,1326,1325,1324,1323,1322,1321,1320,1313,1314,1315,1316,1317,1318,1319)
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,Driver_AgeGroup1
--		,Sex

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP) Month
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 10.3'
--		,TableName='Impaired Driving Casualty Collisions: Month of Occurrence'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND DRIVER_PEDESTR_COND_ID in (179,180,1327,1326,1325,1324,1323,1322,1321,1320,1313,1314,1315,1316,1317,1318,1319)
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,MONTH(OCCURENCE_TIMESTAMP)

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,Week_Name
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 10.4'
--		,TableName='Impaired Driving Casualty Collisions: Day of Week'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND DRIVER_PEDESTR_COND_ID in (179,180,1327,1326,1325,1324,1323,1322,1321,1320,1313,1314,1315,1316,1317,1318,1319)
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,Week_Name

--SELECT Distinct CASE_YEAR
--		,COLLISION_SEVERITY
--		,Time_Period
--		,COUNT(DISTINCT Collision_ID) Total			
--		,TableNum='Table 10.5'
--		,TableName='Impaired Driving Casualty Collisions: Time Period'
--FROM MainTable 
--WHERE 1=1
--AND OBJECT_TYPE_ID in (1,3,8)		--1 Driver;3 Motorcyclist;4 Bicyclist;8 Other Vehicle
--AND DRIVER_PEDESTR_COND_ID in (179,180,1327,1326,1325,1324,1323,1322,1321,1320,1313,1314,1315,1316,1317,1318,1319)
--AND [SEVERITY_OF_COLLISION_ID] in (4,5)
--GROUP BY CASE_YEAR
--		,COLLISION_SEVERITY
--		,Time_Period
-----------------------------------------------------------------
--------Traffic safety issues - Restraint use---------------
--SELECT Distinct CASE_YEAR
--		,INJURY_SEVERITY
--		,SAFETY_EQUIPMENT_Category
--		,COUNT(DISTINCT Party_ID) Total
--		,TableNum='Table 10.6'
--		,TableName='Restraint Use of Vehicle Occupants and Injury Severity* (Use versus Non-Use)'
--FROM MainTable 
--WHERE 1=1
--AND [POSITION_IN_VEHICLE_ID] in (77,78,241,242,243,244,245,246,247)		--Driver and Passenger
--AND INJURY_SEVERITY_ID in (94,95,96,97)			--94 None;95 Minor;96 Major;97 Fatal
--AND SAFETY_EQUIPMENT_ID NOT IN (90,92,93)		--90 Helmet;92 Other/Specify;93 Unknown
--GROUP BY CASE_YEAR
--		,INJURY_SEVERITY
--		,SAFETY_EQUIPMENT_Category