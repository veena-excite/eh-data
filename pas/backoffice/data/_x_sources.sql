SET search_path to data,public
;
drop table if exists x_sources 
;
create table x_sources as
select h.hotel_id,
h.hotel_id::int as id_hotel,
scores.score,
su.name as supplier,
cs.name as country,
m.verified,
ST_Y(s.geom) as "lat",
ST_X(s.geom) as "lon",
ST_Y(h.geom) as "hotel_lat",
ST_X(h.geom) as "hotel_lon",
g.giata_id,
s.*
FROM hotels AS h
JOIN "public".hotel_source_mapping AS "m" ON h."id" = "m".hotel_id
JOIN "public".hotel_source_view AS s using(external_id,supplier_id)
LEFT JOIN "public".supplier AS su ON s.supplier_id = su.id 
LEFT JOIN "public".country AS cs ON s.country_code = cs.code
LEFT JOIN scores using(id_hotel,external_id,supplier_id)
LEFT JOIN (
	select external_id,supplier_id,string_agg(distinct giata_id::varchar,',')::varchar as giata_id
	from "public".giata_supplier_view
	where deleted is false
	group by 1,2
) g using(external_id,supplier_id)
where s.external_id is not null
--and s.external_id = '593842'
--and h.id = '23297'
;
alter table x_sources add primary key (hotel_id,supplier_id,external_id)
;
update x_sources
set lat = NULL, lon = NULL
where lat < -180 or lat > 180
or lon < -180 or lon > 180
;
update x_sources set lat = NULL, lon = NULL
where lat = 0 or lon = 0
;
select * from x_sources where lat =0 
;
drop table if exists y_sources
;
create table y_sources as
select distinct 
ST_DistanceSphere(
	st_makepoint(hotel_lon,hotel_lat),
	st_makepoint(s.lon,s.lat)
	)::int as distance,
s.*,
supplier_id::int as id_supplier,
external_id as id_external
FROM x_sources s
;
alter table y_sources add primary key (hotel_id,supplier_id,external_id)
;
select min(lon),max(lat),
max(lon),max(lat)
from y_sources 
;
select * from y_sources limit 10
;
select count(*) from y_sources limit 10
