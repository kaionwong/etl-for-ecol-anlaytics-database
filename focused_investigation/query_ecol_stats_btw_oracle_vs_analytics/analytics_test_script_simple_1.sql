WITH FinalTable AS (
    SELECT 
        ID AS [Collision_ID],
        [CASE_NBR],
        [CASE_YEAR],
        [SEVERITY_OF_COLLISION_ID],
        CASE 
            WHEN [SEVERITY_OF_COLLISION_ID] = 4 THEN 'Fatal'
            WHEN [SEVERITY_OF_COLLISION_ID] = 5 THEN 'Injury'
            WHEN [SEVERITY_OF_COLLISION_ID] = 6 THEN 'Property Damage'
        END AS [COLLISION_SEVERITY],
        [LOC_DESC]
    FROM 
        [ECRDBA].[COLLISIONS]
    WHERE 
        CASE_YEAR IN (2018)
        AND LOWER(LOC_DESC) LIKE '%edmonton%'
)

-- Version 1 --
-- select
--     *
-- from FinalTable
-- order by Case_Nbr asc

-- Version 2 --
select
    count(*)
from FinalTable
