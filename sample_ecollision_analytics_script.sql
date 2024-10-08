/****** Script for SelectTopNRows command from SSMS  ******/

DECLARE @TestString NVARCHAR (50);
SET @TestString = '%1311532%'

SELECT TOP (1000) [ID]
      ,[CASE_NBR]
	  ,[CASE_YEAR]
	  ,[FORM_CASE_NBR]
      ,[PFN_FILE_NBR]
      ,[DISTRICT_ID]
      ,[FILE_STATUS_ID]
      ,[SEVERITY_OF_COLLISION_ID]
      ,[SPECIAL_FACILITY_ID]
      ,[ROAD_ALIGNMENT_A_ID]
      ,[ROAD_ALIGNMENT_B_ID]
      ,[ROAD_CLASS_ID]
      ,[COLLISION_LOCATION_ID]
      ,[PRIMARY_EVENT_ID]
      ,[ENVIRONMENTAL_CONDITION_ID]
      ,[SURFACE_COND_ID]
      ,[FILE_ID]
      ,[ZONE_NBR]
      ,[PFN_RCMP_ZONE_NBR]
      ,[UNIT_NBR]
      ,[OCCURENCE_TIMESTAMP]
      ,[REPORTED_TIMESTAMP]
      ,[DIARY_DATE]
      ,[VEHICLES_NBR]
      ,[INJURED_NBR]
      ,[FATALITIES_NBR]
      ,[ORIG_REPORT_FLAG]
      ,[HIT_AND_RUN_FLAG]
      ,[SCENE_VISITED_FLAG]
      ,[LOC_IN_CITY_FLAG]
      ,[LOC_DESC]
      ,[LOC_HWY_NBR]
      ,[LOC_STREET_NBR]
      ,[LOC_STREET_AVE]
      ,[LOC_STREET_TYPE]
      ,[LOC_STREET_QUADRANT]
      ,[LOC_INT_HWY_NBR]
      ,[LOC_INT_STREET_AVE]
      ,[LOC_INT_STREET_TYPE]
      ,[LOC_INT_STREET_QUADRANT]
      ,[LOC_DISTANCE_KM_FLAG]
      ,[LOC_DISTANCE]
      ,[LOC_NORTH_FLAG]
      ,[LOC_SOUTH_FLAG]
      ,[LOC_EAST_FLAG]
      ,[LOC_WEST_FLAG]
      ,[LOC_REF_STREET_AVE]
      ,[LOC_REF_SPECIAL_DESC]
      ,[LOC_GPS_LAT]
      ,[LOC_GPS_LONG]
      ,[SPECIAL_STUDIES_FLAG]
      ,[PRIMARY_EVENT_DESC]
      ,[SURFACE_CONDITION_DESC]
      ,[ENV_CONDITION_DESC]
      ,[FILE_STATUS_DESC]
      ,[COLLISION_DESCRIPTION]
      ,[PROPOSED_POLICE_ACTION]
      ,[ORIGINATOR_SUBMIT_FLAG]
      ,[CREATED_USER_ID]
      ,[CREATED_TIMESTAMP]
      ,[MODIFIED_USER_ID]
      ,[MODIFIED_TIMESTAMP]
      ,[MODIFIED_FROM_IP_ADDR]
      ,[ACIS_EXTRACT_TIMESTAMP]
      ,[AGENCY_EXTRACT_TIMESTAMP]
      ,[OBJECT_COUNT]
      ,[OCCURENCE_TIME]
      ,[CITY_EXTRACT_TIMESTAMP]
      ,[PDF_EXTRACT_TIMESTAMP]
      ,[BUSINESS_AREA]
      ,[TRANS_DISTRICT_ID]
      ,[FF_NBR]
      ,[SITE_VISIT_APPLICABLE_FLAG]
      ,[SITE_VISIT_RPT_RECEIVED_FLAG]
      ,[VEHICLE_SEIZED]
      ,[OFFENDER_PAINT]
      ,[OFFENDER_VEHICLE_PARTS]
      ,[DEBRIS_SEIZED]
      ,[PHOTOS_TAKEN]
      ,[OFFENDER_PAINT_TRANSFER]
      ,[MEASUREMENTS_TAKEN]
      ,[MEASUREMENTS_TAKEN_HEIGHT]
      ,[EPS_INJURY]
      ,[EPS_INJURY_DESCRIPTION]
      ,[DAMAGE_LOCATION_DESCRIPTION]
      ,[INVESTIGATION_NOTE]
      ,[VICTIM_VEHICLE_PAINT]
      ,[VICTIM_VEHICLE_PARTS]
      ,[DEBRIS_LOCATION]
      ,[CREATED_BY_DATA_ENTRY_FIRM]
      ,[POLICE_SERVICE_CODE]
      ,[INV_REG_NBR]
      ,[APPROVER_REG_NBR]
      ,[APPROVE_DATE]
      ,[RCMP_ZONE_NBR]
      ,[Z_FORM]
      ,[PLOTTING_INFO_ID]
      ,[CURRENT_PLOTTER_ID]
      ,[PLOTTING_STATUS_ID]
      ,[LOC_STREET_DIRECTION]
      ,[LOC_INT_STREET_DIRECTION]
      ,[ROAD_CLASS_DESC]
      ,[FATAL_COMMENTS]
      ,[FATAL_DESCRIPTION]
      ,[SPL_STUDY_DESC]
      ,[CPS_FILE]
      ,[FATAL_REPORT_DATE]
      ,[ENG_NOTIFIED_DATE]
      ,[ENG_REPORT_DATE]
      ,[FATAL_POL_RCMP_CODE ]
      ,[LOC_TYPE_DESC]
      ,[OCCURENCE_TIMESTRING]
      ,[COMPLETE_INDICATOR]
      ,[ADDL_WITNESS]
      ,[DISTRICT_NAME]
      ,[RADIUS_OF_CURVE]
      ,[PROP_DAMAGE_ONLY]
      ,[SPL_STUDY_NO]
      ,[MUNICIPALITY_TYPE]
      ,[BATCH_NUMBER]
      ,[LEGAL_CLASSIFICATION]
      ,[COLLISION_LOCATION_DESC]
  FROM [eCollisionAnalytics].[ECRDBA].[COLLISIONS]
  where 1=1
	and CASE_NBR like @TestString
	or FORM_CASE_NBR like @TestString