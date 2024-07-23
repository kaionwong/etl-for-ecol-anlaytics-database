------ Pull all collision case status changes for a specific collision case
--select
--    s.Collision_id,
--    s.Coll_status_type_id,
--    s.Created_timestamp,
--    s.Effective_date,
--    s.Csth_comment,
--    s.Created_user_id
--from ECRDBA.cl_status_history s
--left join ECRDBA.Collisions c on s.Collision_id = c.id
--where c.Case_nbr = '1449587'
--order by Created_timestamp desc

------ Pull all syunchronization log history for a collision case
--select Action_type, Case_number, Create_timestamp, Finish_timestamp
--from ECRDBA.ECR_synchronization_action_log
--where Case_number = '1449587'

------ Pull all audit table for eCollision for a collision case
select created_timestamp
from ECRDBA.Au_Collisions
where Case_nbr = '2'
order by created_timestamp