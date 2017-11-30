select max(created) as max_created from "public".tableau_bookings;
select max(snapshot_date) as max_snap,max(created) as max_created from tableau_bookings_history ;
select max(snapshot_date) as max_snap,max(created) as max_created from bookings_standardised
;
--truncate bookings_standardised

--delete from bookings_standardised where snapshot_date > '2017-11-21'
;
insert into bookings_standardised
select * from tableau_bookings_history
where created::date = DATEADD('day', -1, snapshot_date)
and snapshot_date in (
	select distinct snapshot_date 
	from tableau_bookings_history 
	where snapshot_date not in (select distinct snapshot_date from bookings_standardised)
	and snapshot_date > '2017-08-01'
)
;
drop table if exists agent_bdm
;
create table agent_bdm as 
select distinct id_agent,created,email 
from public.tableau_bookings
join (
	select id_agent,max(created) as created
	from public.tableau_bookings
	group by 1
) s using(id_agent,created)
;
update bookings_standardised
set email=agent_bdm.email
from agent_bdm 
where bookings_standardised.id_agent=agent_bdm.id_agent
;
update bookings_standardised
set 
country=tableau_bookings.country,
state=tableau_bookings.state,
city=tableau_bookings.city,
citydistrict=tableau_bookings.citydistrict,
item_name = tableau_bookings.item_name
from "public".tableau_bookings 
where bookings_standardised.id_booking="public".tableau_bookings.id_booking
and bookings_standardised.id_item="public".tableau_bookings.id_item
and bookings_standardised.item_type="public".tableau_bookings.item_type
;

select max(created) as max_created from "public".tableau_bookings;
select max(snapshot_date) as max_snap,max(created) as max_created from tableau_bookings_history ;
select max(snapshot_date) as max_snap,max(created) as max_created from bookings_standardised
