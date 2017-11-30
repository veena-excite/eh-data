SET search_path to data,public
;
drop table if exists data.hotels cascade
;
create table data.hotels as 

select 
a.id as hotel_id,
case when a.id ~ '\D' then null else a.id::int end as id_hotel,
a.name as hotel_name,
hg.id as id_group,
hg.name as "group",
a.*,
b.name as country,
ST_Y(a.geom) as "lat",
ST_X(a.geom) as "lon",
case when hs.id is not null then true else false end as "sellable"
from public.hotel a
left join public.country b ON a.country_id =b."id"
left join data.hotel_sellable c on a.id=c.hotel_id
left join public.hotel_chain hc on a.hotel_chain_id = hc.id
left join public.hotel_group hg on hc.hotel_group_id = hg."id"
left join (
	SELECT distinct h."id"
	FROM "public".hotel AS h
	INNER JOIN "public".hotel_source_mapping AS "m" ON h."id" = "m".hotel_id
	INNER JOIN "public".hotel_source_additional AS "a" ON "m".external_id = "a".external_id AND "m".supplier_id = "a".supplier_id
	WHERE "a".deleted is false
	and "a"."enable" is true
	and h.active is true
	and h.deleted is false
) hs on a.id=hs.id
;
update data.hotels set room_night_sold = 0 where room_night_sold = 1
;
--
select * from "public".hotel a
left join data.hotels b using(google_place_id)
where a.google_place_id is not null
and b.google_place_id is null
;
select * from hotels 
where id_hotel is null
limit 10
;
select count(*) from hotels limit 10
;
select * from hotels where id_hotel = 3304