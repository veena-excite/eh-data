SET search_path to basket_issues,public
;
drop table if exists y_sources
;
create table y_sources as
select distinct * from data.y_sources
where verified is false
;
update y_sources set distance = 0 where distance is null
;
alter table y_sources add primary key (id_hotel,id_supplier,id_external)
;
insert into hidden_baskets
select id_basket,id_hotel,master.status 
from master
join detail using(id_hotel)
where master.status != 'todo'
and id_basket not in (select id_basket from hidden_baskets)
;
insert into hidden_sources
select distinct id_hotel,id_supplier,id_external,master.status 
from master
join detail using(id_hotel)
where master.status != 'todo'
and id_hotel::varchar||id_supplier::varchar||id_external not in (select id_hotel::varchar||id_supplier::varchar||id_external from hidden_sources)
;
insert into hidden_sources
select distinct id_hotel,id_supplier,id_external,status
from sources
where status != 'todo'
and id_hotel::varchar||id_supplier::varchar||id_external not in (select id_hotel::varchar||id_supplier::varchar||id_external from hidden_sources)
;
insert into hidden_baskets
select id_basket,id_hotel,sources.status 
from sources
join detail using(id_hotel,id_external,id_supplier)
where sources.status != 'todo'
and id_basket not in (select id_basket from hidden_baskets)
;
drop table if exists detail
; 
create table detail as 
select 
least(name_score,pas_name_score,address_score,country_score,city_score) as min_score,
(pas_name_score+name_score+address_score+country_score+city_score)/5 as avg_score,
*
from (
--select count(*) from (
	SELECT id_booking,baskets.id_basket,basket_hotel_reference.id_hotel,s.id_hotel as pas_hotel_id,item_status_alias as status,id_supplier,id_external,arrival_date,
	basket_hotel_reference.name,source_name,similarity(basket_hotel_reference.name, source_name) As name_score,
	coalesce(s.name,'NO SOURCE') as pas_name,similarity(s.name,coalesce(basket_hotel_reference.name, s.name)) As pas_name_score,	
	basket_hotel_reference.country, source_country,similarity(basket_hotel_reference.country, coalesce(source_country,basket_hotel_reference.country)) as country_score,
	basket_hotel_reference.city,source_city,similarity(basket_hotel_reference.city,coalesce(source_city,basket_hotel_reference.city)) as city_score,
	basket_hotel_reference.address,source_address,similarity(basket_hotel_reference.address,coalesce(source_address,basket_hotel_reference.address)) as address_score,
	net_price,
	s.score::int as pas_score,
	s.distance,
	s.lat as source_lat,s.lon as source_lon,
	h.lat as hotel_lat,h.lon as hotel_lon,
	'https://backoffice.exciteholidays.com/backoffice/booking/view/' || id_booking || '#basket_' || baskets.id_basket::varchar as "hyperlink"
	FROM basket_hotel_reference
	JOIN baskets on baskets.id_basket = basket_hotel_reference.id_basket
	left join lookups.status on baskets.id_basket_status = status.id_item_status
	LEFT JOIN y_sources s using(id_external,id_supplier)
	left join data.hotels h on basket_hotel_reference.id_hotel = h.id_hotel
	LEFT JOIN hidden_baskets hb on baskets.id_basket = hb.id_basket
	LEFT JOIN hidden_sources hs using(id_external,id_supplier)
	WHERE 
 ( (similarity(basket_hotel_reference.name, source_name) < .4)   OR (similarity(basket_hotel_reference.country, source_country) != 1) 
 	OR (similarity(basket_hotel_reference.address, source_address) < .4) or (similarity(basket_hotel_reference.city, source_city) < .4)
 ) AND 
 	baskets.id_basket_status in (40,50,65,70,69,120,20,51,60,41,46,10)
	AND baskets.arrival_date > now()
	and hb.id_basket is null
	and hs.id_supplier is null
--	and baskets.id_basket = 2156856
--	and id_hotel = 	153244
	order by arrival_date,id_supplier,id_external
) s
;
alter table detail add primary key (id_booking,id_basket)
;
update detail set distance = 0 where distance is NULL
;
select status,count(*)
from detail
group by 1
;
select * from detail limit 100
;
drop table if exists master
;
create table master as
select 
id_hotel,
'todo'::varchar(16) as status,
min(pas_score) as min_pas_score,
min(avg_score) as min_avg_score,
min(min_score) as min_min_score,
min(name_score) as min_name_score,
min(pas_name_score) as min_pas_name_score,
max(distance) as max_distance,
count(*) as basket_count,
min(arrival_date) as min_arrival_date,

sum(net_price) as net_price,
string_agg(distinct name,'<BR>') as name,
string_agg(distinct source_name,'<BR>') as source_names,
string_agg(distinct pas_name,'<BR>') as pas_names,
string_agg(distinct country,'<BR>') as country,
string_agg(distinct source_country,'<BR>') as source_countries,

string_agg(distinct city,'<BR>') as city,
string_agg(distinct source_city,'<BR>') as source_cities,

string_agg(distinct address,'<BR>') as address,
string_agg(distinct source_address,'<BR>') as source_addresses

from detail
group by 1,2
;
alter table master add primary key (id_hotel)
;
drop table if exists basket_issues.sources
;
create table basket_issues.sources as
select
'todo'::varchar(16) as status,
h.name as hotel_name,
basket_count,net_price,
s.*
from y_sources s
join data.hotels h using(id_hotel)
LEFT JOIN hidden_sources hs using(id_hotel,id_external,id_supplier)
join (
	select id_hotel,id_supplier,id_external,
	count(*) as basket_count,sum(net_price) as net_price,min(arrival_date) as min_arrival_date
	from detail 
	group by 1,2,3
	) b using(id_hotel,id_supplier,id_external)
where hs.id_hotel is null
order by distance desc
;
select count(*) from basket_issues.sources
;
select 'master',count(*)
from master
union all
select 'detail',count(*)
from detail
