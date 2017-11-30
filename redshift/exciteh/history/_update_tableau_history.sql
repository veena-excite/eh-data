select convert_timezone('Australia/Sydney',sysdate)::date
;
delete from tableau_bookings_history where snapshot_date = convert_timezone('Australia/Sydney',sysdate)::date
;
select max(created),count(*) from public.tableau_bookings
;
insert into tableau_bookings_history 
select convert_timezone('Australia/Sydney',sysdate)::date,* from public.tableau_bookings
;
select count(*) from tableau_bookings_history where snapshot_date = convert_timezone('Australia/Sydney',sysdate)::date
;
select snapshot_date,max(created),count(*)
from tableau_bookings_history
where snapshot_date > '2017-11-18'
group by 1
order by 1 asc
