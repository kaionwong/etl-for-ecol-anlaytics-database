-- Save the output of this .sql to "main_extract_ecollision_analytics_data_2000-2024_snapshot_from_YYYY-MM-DD.csv" in the "ecollision-analytics-assessment" directory

SELECT c.ID [Collision_ID]
    ,c.[CASE_NBR]
	  ,c.[CASE_YEAR]
	  ,c.[FORM_CASE_NBR]
	  ,c.POLICE_SERVICE_CODE
	  ,c.[SEVERITY_OF_COLLISION_ID]
	  ,c.[PFN_FILE_NBR]
	  ,c.OCCURENCE_TIMESTRING
	  ,c.OCCURENCE_TIMESTAMP
	  ,c.CREATED_TIMESTAMP
	  ,c.APPROVE_DATE
	  ,c.REPORTED_TIMESTAMP
--	  ,plot.HIGHWAY
	 
FROM [ECRDBA].[COLLISIONS] c
--	LEFT JOIN [ECRDBA].[ECR_COLL_PLOTTING_INFO] plot on c.ID = plot.COLLISION_ID

WHERE 1=1
	AND c.Case_Year in (1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 
	2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024)
	--AND c.ID in (2258993, '2258993')

order by Collision_ID, Case_Year