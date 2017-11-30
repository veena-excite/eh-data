drop table if exists hotel_chains
;
create table hotel_chains as 
select 
a.id as id_chain,
a.name as hotel_chain,
a.name as hotel_brand,
b.id as id_group,
b.name as hotel_group
from public.hotel_chain a 
left join public.hotel_group b on a.hotel_group_id = b."id"
