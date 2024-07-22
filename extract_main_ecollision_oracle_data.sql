-- Save the output of this .sql to "main_extract_ecollision_oracle_data_2000-2024_snapshot_from_YYYY-MM-DD.csv" in the "ecollision-analytics-assessment" directory

WITH MainTable AS (
    SELECT
        ID as Collision_ID,
        CASE_NBR,
        OCCURENCE_TIMESTAMP,
        REPORTED_TIMESTAMP,
        CASE 
            WHEN REGEXP_LIKE(OCCURENCE_TIMESTAMP, '^\d{2}-\d{2}-\d{2}$') THEN
                -- Extract year from OCCURENCE_TIMESTAMP if format is correct
                CASE WHEN EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(OCCURENCE_TIMESTAMP, 1, 2), 'YYYY')) >= 2000 THEN
                    EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(OCCURENCE_TIMESTAMP, 1, 2) || '-' ||
                                              SUBSTR(OCCURENCE_TIMESTAMP, 4, 2) || '-' ||
                                              SUBSTR(OCCURENCE_TIMESTAMP, 7, 2),
                                              'YYYY-MM-DD'))
                ELSE
                    NULL
                END
            WHEN REGEXP_LIKE(REPORTED_TIMESTAMP, '^\d{2}-\d{2}-\d{2}$') THEN
                -- Extract year from REPORTED_TIMESTAMP if OCCURENCE_TIMESTAMP is not valid
                CASE WHEN EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(REPORTED_TIMESTAMP, 1, 2), 'YYYY')) >= 2000 THEN
                    EXTRACT(YEAR FROM TO_DATE('20' || SUBSTR(REPORTED_TIMESTAMP, 1, 2) || '-' ||
                                              SUBSTR(REPORTED_TIMESTAMP, 4, 2) || '-' ||
                                              SUBSTR(REPORTED_TIMESTAMP, 7, 2),
                                              'YYYY-MM-DD'))
                ELSE
                    NULL
                END
            ELSE
                NULL -- Neither timestamp is valid
        END AS CASE_YEAR,
        FORM_CASE_NBR,
        POLICE_SERVICE_CODE
    FROM
        ECRDBA.COLLISIONS
)
SELECT
    *
FROM
    MainTable
ORDER BY
    CASE_YEAR DESC;