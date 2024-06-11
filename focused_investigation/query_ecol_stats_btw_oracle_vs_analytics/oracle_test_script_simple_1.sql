with MainTable as
(
    SELECT
        Id AS Collision_Id,
        Case_Nbr,
        Severity_Of_Collision_Id,
        CASE 
            WHEN Severity_Of_Collision_Id = 4 THEN 'Fatal'
            WHEN Severity_Of_Collision_Id = 5 THEN 'Injury'
            WHEN Severity_Of_Collision_Id = 6 THEN 'Property Damage'
        END AS Collision_Severity,
        CASE 
            WHEN REGEXP_LIKE(OCCURENCE_TIMESTAMP, '^\d{2}-\d{2}-\d{2}$') THEN
                -- Extract year from OCCURENCE_TIMESTAMP if format is correct
                CASE 
                    WHEN EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(OCCURENCE_TIMESTAMP, 1, 2), 'YYYY')) >= 2000 THEN
                        EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(OCCURENCE_TIMESTAMP, 1, 2) || '-' ||
                                                  SUBSTR(OCCURENCE_TIMESTAMP, 4, 2) || '-' ||
                                                  SUBSTR(OCCURENCE_TIMESTAMP, 7, 2),
                                                  'YYYY-MM-DD'))
                    ELSE
                        NULL
                END
            WHEN REGEXP_LIKE(REPORTED_TIMESTAMP, '^\d{2}-\d{2}-\d{2}$') THEN
                -- Extract year from REPORTED_TIMESTAMP if OCCURENCE_TIMESTAMP is not valid
                CASE 
                    WHEN EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(REPORTED_TIMESTAMP, 1, 2), 'YYYY')) >= 2000 THEN
                        EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(REPORTED_TIMESTAMP, 1, 2) || '-' ||
                                                  SUBSTR(REPORTED_TIMESTAMP, 4, 2) || '-' ||
                                                  SUBSTR(REPORTED_TIMESTAMP, 7, 2),
                                                  'YYYY-MM-DD'))
                    ELSE
                        NULL
                END
            ELSE
                NULL -- Neither timestamp is valid
        END AS Case_Year,
        Loc_Desc
    FROM ECRDBA.COLLISIONS
    WHERE 1 = 1
        AND LOWER(Loc_Desc) LIKE '%edmonton%'
)
select
    count(*)
from MainTable
    where Case_Year in (2022)
    
    
    
    
    