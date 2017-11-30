SET search_path to data,public
;
--drop table if exists hotel_sellable ;
truncate hotel_sellable
;
insert into hotel_sellable
select h.id as hotel_id,
case when b.id is not null then true else false end as "sellable"
from "public".hotel h
left join (
	SELECT distinct h."id"
	FROM "public".hotel AS h
	INNER JOIN "public".hotel_source_mapping AS "m" ON h."id" = "m".hotel_id
	INNER JOIN "public".hotel_source_additional AS "a" ON "m".external_id = "a".external_id AND "m".supplier_id = "a".supplier_id
	WHERE "a".deleted is false
	and "a"."enable" is true
	and h.active is true
	and h.deleted is false
) b on h.id=b.id
;
select active,deleted from hotel where id = '333643';
--create index on hotel_sellable(hotel_id)
;
select sellable,count(*) 
from hotel_sellable
group by 1
;
select * from hotel_sellable limit 10
;
select count(*) from hotel_sellable
