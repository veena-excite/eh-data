SET search_path to lookups,public
;
select distinct id_headoffice,agent_headoffice from "public".tableau_bookings where id_headoffice is not null and id_headoffice not in (select id_headoffice from agent_headoffices)
;
--select distinct id_headoffice,agent_headoffice from "public".tableau_bookings where id_headoffice is not null and id_headoffice not in (select id_headoffice from agent_headoffices)
--select distinct agent_headoffice from "public".tableau_bookings  where agent_headoffice not in (select agent_id_headoffice from "public".tableau_bookings)
truncate table agent_headoffices 
;
insert into agent_headoffices 
select id_headoffice,agent_headoffice,agent_headoffice as "agent_consortia",count(distinct id_agent) as agent_count,sum(net_price)::int as net_price
from "public".tableau_bookings
where id_headoffice is not null
--and id_headoffice not in (select id_headoffice from agent_headoffices)
group by 1,2,3
;
select count(*) from agent_headoffices
;
update agent_headoffices set agent_consortia = 'Independent' where lower(agent_headoffice) ~ 'independent' ;
update agent_headoffices set agent_consortia = 'Independent' where lower(agent_headoffice) ~ 'independant' ;

update agent_headoffices set agent_consortia = 'Advantage' where agent_headoffice ~ 'Advantage' ;
update agent_headoffices set agent_consortia = 'ATAC' where agent_headoffice ~ 'ATAC' ;
update agent_headoffices set agent_consortia = 'ETG' where agent_headoffice ~ 'ETG' ;
update agent_headoffices set agent_consortia = 'iTravel' where agent_headoffice ~ 'i travel' ;
update agent_headoffices set agent_consortia = 'Travel Partners' where agent_headoffice ~ 'Travel Partners' ;

update agent_headoffices set agent_consortia = 'Phil Hoffman' where agent_headoffice ~ 'Phil Hoffman' ;
update agent_headoffices set agent_consortia = 'Helloworld' where agent_headoffice ~ 'helloworld' ;

update agent_headoffices set agent_consortia = 'FCL' where agent_headoffice ~ 'FCL' ;
update agent_headoffices set agent_consortia = 'FCL' where lower(agent_headoffice) ~ 'flight centre' ;

update agent_headoffices set agent_consortia = 'MTA' where agent_headoffice ~ 'MTA' ;
update agent_headoffices set agent_consortia = 'Magellan' where agent_headoffice ~ 'Magellan' ;

update agent_headoffices set agent_consortia = 'HO - Test' where agent_headoffice ~ 'Testing Agencies' ;
update agent_headoffices set agent_consortia = 'HO - Staff' where agent_headoffice ~ 'Family & Friends' ;
update agent_headoffices set agent_consortia = 'HO - Staff' where agent_headoffice ~ 'Internal Agencies' ;
update agent_headoffices set agent_consortia = 'XX' where lower(agent_headoffice) ~ 'do not use' 
;
select distinct id_headoffice,agent_headoffice from "public".tableau_bookings where id_headoffice is not null and id_headoffice not in (select id_headoffice from agent_headoffices)
;
select agent_headoffice from tableau_bookings where agent_headoffice is null
;
select * from agent_headoffices a
left join tableau_bookings b using(agent_headoffice)
where b.agent_headoffice is null
;
select agent_consortia,count(*) 
from agent_headoffices
group by 1
