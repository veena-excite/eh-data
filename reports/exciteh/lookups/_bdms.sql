SET search_path to lookups,public
;
--new bdm found:>0
insert into bdms (email)
select distinct email from public.tableau_bookings
where created > '2017-03-01'
and email not in (select email from bdms)
;
update bdms
set from_date = s.from_date,
to_date = s.to_date
from (
	select email,count(*),min(created)::date as from_date ,max(created)::date as to_date
	from tableau_bookings
	group by 1
) s 
where bdms.email = s.email
;
select count(*) from bdms
