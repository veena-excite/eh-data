SET search_path to lookups,public
;
drop table if exists lookups.tableau_hotels cascade ;
create table lookups.tableau_hotels as select * from data.hotels ;
alter table tableau_hotels add primary key (id_hotel);

drop table if exists lookups.hotel_chains cascade ; 
create table lookups.hotel_chains as select * from data.hotel_chains ;
alter table hotel_chains add primary key (id_chain);
;
update hotel_chains set id_group=14,hotel_group='Other'
where id_group is null
;
insert into hotel_chains 
select 0,'No Chain','No Chain',0,'No Chain'
;
select * from hotel_chains order by id_group limit 10
;

drop table if exists v_hotel_to_chain
;
create table v_hotel_to_chain as
select id_hotel,coalesce(hotel_chain_id::int,0) as id_chain
from lookups.tableau_hotels
where id_hotel is not null 
;
select * from v_hotel_to_chain where id_chain is null
;
insert into v_hotel_to_chain
select distinct id_hotel,0
from public.tableau_bookings a
left join tableau_hotels b using(id_hotel)
where a.id_hotel is not null and b.id_hotel is null
;
select distinct id_hotel
from public.tableau_bookings a
left join v_hotel_to_chain b using(id_hotel)
where a.id_hotel is not null and b.id_hotel is null
;
select product,sum(net_price),count(*)
from tableau_bookings a
left join tableau_hotels b using(id_hotel)
where a.id_hotel is not null and b.id_hotel is null
group by 1
;
create or replace view tableau_reference as select * from public.tableau_reference ;
create or replace view tableau_sp as select * from public.tableau_sp ;
create or replace view tableau_additional as select * from public.tableau_additional ;

