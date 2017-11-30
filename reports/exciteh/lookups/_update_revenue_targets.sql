SET search_path to lookups,public
;
select
min(created),max(created),
sum("a".net_price),
sum(a.net_price*c.rate) as base
from public.tableau_bookings a
left join lookups.currencies_simple c on a.net_currency = c.currency
where  created >= '2016-07-01' and created < '2017-07-01' 
and item_statusalias = 'paid'
;
update bdms set base = s.base
from (
	select
	email,
	sum(a.net_price*c.rate) as base
	from public.tableau_bookings a
	left join lookups.currencies_simple c on a.net_currency = c.currency
	where  created >= '2016-07-01' and created < '2017-07-01' 
	and item_statusalias = 'paid'
	group by 1
) s
where bdms.email=s.email
;
update bdms set base = s.base
from (
	select
	sum(a.net_price*c.rate) as base,
	sum(net_price) as net_price
	from public.tableau_bookings a
	left join lookups.currencies_simple c on a.net_currency = c.currency
	where  created >= '2016-07-01' and created < '2017-07-01' 
	and item_statusalias = 'paid' 
) s
where bdms.email='global'
;
update bdms set "target%" = ((target-base)/base) where base > 0
;
--global check should be 145
select base*(1+"target%") as "check"
from bdms where email = 'global'
;
select sum("check") from (
	select s.base*(1+b."target%") as "check",b.*
	from (
		select
		email,
		sum(a.net_price*c.rate) as base
		from public.tableau_bookings a
		left join lookups.currencies_simple c on a.net_currency = c.currency
		where  created >= '2016-07-01' and created < '2017-07-01' 
		and item_statusalias = 'paid'
		group by 1
	) s
	left join bdms b using(email)
--where b.email is null
) foo
