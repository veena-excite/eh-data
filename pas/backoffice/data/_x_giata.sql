SET search_path to data,public
;
-- select * from country limit 10;
-- select * from v_hotel where id = '23297';
-- select * from eh_hotel  where id = '23297';
-- ;


drop table if exists x_giata
;
create table x_giata as 
select 
c.id as hotel_id,
a.id as giata_id,
a.*,
b.name as country,
ST_Y(a.geom) as "lat",
ST_X(a.geom) as "lon"

from  public.giata_view a
left join public.country b ON a.country_code=b."code"
left join "public".hotel c on a.id = c.giata_id
;
select * from x_giata limit 10
;
select * from x_giata where hotel_id = '23297';