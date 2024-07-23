--select
--    *
--from ecrdba.cl_status_history
--where COLLISION_ID = '1050'
--order by effective_date desc


select *
from ecrdba.collisions
where case_nbr = '13'