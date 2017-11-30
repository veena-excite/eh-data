SET search_path to lookups,public
;
--new status found, not handled:>0
select id_item_status,item_status,* from tableau_bookings where id_item_status not in (select id_item_status from status)
;
select item_status_alias,string_agg(id_item_status::varchar,',') 
from status
group by 1
