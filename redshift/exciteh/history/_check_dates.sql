select max(created) as max_created from "public".tableau_bookings
;
select max(snapshot_date) as max_snap,max(created) as max_created from tableau_bookings_history 
;
select max(snapshot_date) as max_snap,max(created) as max_created from bookings_standardised 
;
select snapshot_date,max(created),count(*)
from tableau_bookings_history
where snapshot_date > '2017-11-18'
group by 1
order by 1 asc
