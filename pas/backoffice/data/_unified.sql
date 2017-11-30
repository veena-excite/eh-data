drop table if exists "unified"
;
create table "unified" (
"hotel_id" varchar ,
"source" varchar ,
"enabled" varchar ,
"verified" varchar ,
"external_id" varchar ,
"giata_id" varchar ,
"name" varchar ,
"country" varchar ,
"state" varchar ,
"city" varchar ,
"address" varchar ,
"post_code" varchar ,
"score" numeric ,
"lat" varchar ,
"lon" varchar ,
"phones" varchar ,
"rating" varchar ,
"country_code" varchar ,
"hotel_chain" varchar ,
"email" varchar ,
"website" varchar ,
"id_supplier" int ,
"sort_order" int )
;
insert into unified ("hotel_id","source","enabled","giata_id","name","country","state","city","address","post_code","lat","lon","phones","rating","hotel_chain","email","website","sort_order")
select
hotel_id::varchar as "hotel_id",
'HOTEL'::varchar as "source",
active::varchar as "enabled",
giata_id::varchar as "giata_id",
name::varchar as "name",
country::varchar as "country",
state::varchar as "state",
city::varchar as "city",
address::varchar as "address",
postcode::varchar as "post_code",
lat::varchar as "lat",
lon::varchar as "lon",
phone::varchar as "phones",
rating::varchar as "rating",
hotel_chain::varchar as "hotel_chain",
email::varchar as "email",
website::varchar as "website",
1::int as "sort_order"
from "hotels"
WHERE deleted is false;
insert into unified ("hotel_id","source","giata_id","name","country","city","address","post_code","lat","lon","phones","country_code","hotel_chain","email","website","sort_order")
select
hotel_id::varchar as "hotel_id",
'GIATA'::varchar as "source",
giata_id::varchar as "giata_id",
name::varchar as "name",
country::varchar as "country",
city::varchar as "city",
address::varchar as "address",
post_code::varchar as "post_code",
lat::varchar as "lat",
lon::varchar as "lon",
phone::varchar as "phones",
country_code::varchar as "country_code",
chain_name::varchar as "hotel_chain",
email::varchar as "email",
hotel_url::varchar as "website",
2::int as "sort_order"
from "x_giata"
;
insert into unified ("hotel_id","source","enabled","verified","external_id","giata_id","name","country","state","city","address","post_code","score","lat","lon","phones","rating","country_code","id_supplier","sort_order")
select
hotel_id::varchar as "hotel_id",
supplier::varchar as "source",
enable::varchar as "enabled",
verified::varchar as "verified",
external_id::varchar as "external_id",
giata_id::varchar as "giata_id",
name::varchar as "name",
country::varchar as "country",
state::varchar as "state",
city::varchar as "city",
address::varchar as "address",
post_code::varchar as "post_code",
score::numeric as "score",
lat::varchar as "lat",
lon::varchar as "lon",
phones::varchar as "phones",
rating::varchar as "rating",
country_code::varchar as "country_code",
supplier_id::int as "id_supplier",
4::int as "sort_order"
from "x_sources"
;
insert into unified ("hotel_id","source","external_id","giata_id","name","country","state","city","address","post_code","lat","lon","phones","rating","hotel_chain","email","website","sort_order")
select
id_hotel::varchar as "hotel_id",
'BACKOFFICE'::varchar as "source",
id_external::varchar as "external_id",
id_giata::varchar as "giata_id",
hotel_name::varchar as "name",
country::varchar as "country",
state::varchar as "state",
city::varchar as "city",
address::varchar as "address",
post_code::varchar as "post_code",
lat::varchar as "lat",
lon::varchar as "lon",
phone::varchar as "phones",
ranking::varchar as "rating",
hotel_chain::varchar as "hotel_chain",
email::varchar as "email",
website::varchar as "website",
5::int as "sort_order"
from "eh_hotels"
WHERE deleted is null;

