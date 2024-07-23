select * from ecrdba.ecr_synchronization_action_log
where 1=1
    and case_number in ('13')
    --and collision_id = '1050'
order by create_timestamp desc