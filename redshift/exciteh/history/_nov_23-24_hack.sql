_nov_23-24_hack
insert into tableau_bookings_history 
select '2017-11-23',convert_timezone('Australia/Sydney',sysdate)::date,* from public.tableau_bookings

create table temp as select * from tableau_bookings_history where snapshot_date = '2017-11-24'

update temp set snapshot_date = '2017-11-23' ;

insert into tableau_bookings_history select * from temp ;
update temp set snapshot_date = '2017-11-25' ;
insert into tableau_bookings_history select * from temp ;
delete from tableau_bookings_history where snapshot_date = '2017-11-25' ;