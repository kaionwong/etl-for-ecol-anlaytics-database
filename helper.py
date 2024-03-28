import pandas as pd

# Helper function
def pandas_output_setting(max_rows=500):
    """Set pandas output display setting"""
    pd.set_option('display.max_rows', max_rows)
    pd.set_option('display.max_columns', None)
    ##pd.set_option('display.max_columns', 500)
    pd.set_option('display.width', 160)
    pd.set_option('display.max_colwidth', None)
    pd.options.mode.chained_assignment = None  # default='warn'
    
sql_string = """Select
c.CASE_YEAR
,c.CASE_NBR
,c.LOC_DESC
--,c.SEVERITY_OF_COLLISION_ID
,sev.SHORT_DESC
-- ,loc.SHORT_DESC
,plot.HIGHWAY
,plot.CONTROL_SECTION
,plot.KM_POST
-- ,plot.COLLISION_SUB_TYPE_ID
-- ,sub.SHORT_DESC
-- ,c.COLLISION_LOCATION_ID

-- ,plot.STRUCTURE_ID

from

[ECRDBA].[COLLISIONS] c
left join [ECRDBA].[ECR_COLL_PLOTTING_INFO] plot on c.id = plot.COLLISION_ID
left join [ECRDBA].[CODE_TYPE_VALUES] sev on sev.id = c.SEVERITY_OF_COLLISION_ID
left join [ECRDBA].[CODE_TYPE_VALUES] sub on sub.id = plot.COLLISION_SUB_TYPE_ID
left join [ECRDBA].[CODE_TYPE_VALUES] loc on loc.id = c.collision_location_id
WHERE 1=1
AND CASE_YEAR BETWEEN 2015 AND 2019
    AND PLOTTING_STATUS_ID=426 --425 Non Plottable;426 Plotted;427 In Progress;428 Marked For Future
    -- AND LOC_HWY_NBR ='28' AND CONTROL_SECTION =2 AND KM_POST Between 11.98 and 12.58
    -- AND LOC_HWY_NBR ='28' AND CONTROL_SECTION =2 AND KM_POST Between 14.7 and 15.28
    AND LOC_HWY_NBR ='28' AND CONTROL_SECTION =2 AND KM_POST Between 8.23 and 8.63
--     AND (
--         (LOC_HWY_NBR ='2' AND CONTROL_SECTION =72 AND KM_POST Between 6.08 and 6.98 )
-- --         OR (LOC_HWY_NBR ='791' AND CONTROL_SECTION =2 AND KM_POST Between 7.9 and 8.1 )
--         )
--     AND OBJECT_TYPE_ID<>7                --7 Animal
--and loc.SHORT_DESC like '%Intersection-related%'
-- and CASE_YEAR BETWEEN 2016 AND 2020
-- AND LOC_DESC in ('STURGEON COUNTY')
ORDER BY CASE_YEAR

"""