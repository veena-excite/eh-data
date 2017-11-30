SET search_path to profit_opt,public
;
drop table if exists profit_opt_tableau cascade
;
create table profit_opt_tableau as 

select 
--items.created_gr,
date_trunc('week', items.created)::date 										as week,
items.old_buy_price - items.new_buy_price 									AS profit,
statusaliases.name[1]                                       AS statusalias,
users.email                                                 AS email,
items.*,
--get_human_readable_item_status(items.status)                AS status,
bookings_sp.departure_date::date,
concat(suppliers_from.name[1],'->', suppliers_to.name[1])   AS supplier_pair,
sources.name[1]                                             AS hotel_name,
suppliers_to.name[1]                                        AS new_supplier,
suppliers_from.name[1]                                      AS old_supplier,
bookings_sp.product_name                                    AS product_name,
bookings_sp.source_name                                     AS source_name,
bookings_sp.net_price                                       AS net_price,
bookings_sp.net_currency                                    AS net_currency,
bookings_sp.id_hotel                                        AS id_hotel,
bookings_sp.product_type_name                               AS product,
regexp_replace(bookings_sp.pax_names,'\s*[\r\n]+\s*',', ','g') AS pax_names

FROM
( 
	SELECT
	log_itemprices.created  AT TIME ZONE 'Australia/Sydney' AS created,
	log_itemprices.created  AT TIME ZONE 'EET'  						as created_gr,
	log_itemprices.profit_opt               AS po_status,
	old_basket.id_booking                   AS id_booking,
	coalesce(old_basket.po_original_id_basket,old_basket.id_basket)         AS orig_id_item,
	old_basket.po_original_id_basket,
	old_basket.id_basket                    AS old_id_item,
	old_basket.id_basket_linked,
	new_basket.id_basket                    AS new_id_item,
	new_basket.id_basket_status             AS id_item_status,

	log_itemprices.id_log_itemprice         AS id_log_itemprice,
	old_basket.id_supplier                  AS id_supplier,
	log_itemprices.old_buy_price            AS old_buy_price,
	log_itemprices.old_buy_currency         AS old_buy_currency,
	log_itemprices.new_buy_price            AS new_buy_price,
	log_itemprices.new_buy_currency         AS new_buy_currency,

	log_itemprices.old_supplier_price       AS old_supplier_price,
	log_itemprices.old_supplier_currency    AS old_supplier_currency,
	log_itemprices.new_supplier_price       AS new_supplier_price,
	log_itemprices.new_supplier_currency    AS new_supplier_currency,
	log_itemprices.old_id_supplier          AS old_id_supplier,
	log_itemprices.new_id_supplier          AS new_id_supplier,
	log_itemprices.id_user                  AS id_user
	FROM log_itemprices
	JOIN baskets AS old_basket ON log_itemprices.id_basket = old_basket.id_basket
	JOIN baskets AS new_basket ON old_basket.id_basket_linked = new_basket.id_basket AND new_basket.confirmed IS NOT NULL
	JOIN basket_status ON new_basket.id_basket_status = basket_status.id_basket_status
	WHERE log_itemprices.id_basket IS NOT NULL AND log_itemprices.deleted IS NULL and old_buy_price is not null
	AND (log_itemprices.profit_opt in ('A/C') and log_itemprices.created >= date '2014-02-17')

	UNION ALL 

	SELECT
	log_itemprices.created  AT TIME ZONE 'Australia/Sydney' 				AS created,
	log_itemprices.created  AT TIME ZONE 'EET'  										as created_gr,
	log_itemprices.profit_opt               												AS po_status,
	old_basket.id_booking                   												AS id_booking,
	coalesce(old_basket.po_original_id_basket,old_basket.id_basket) AS orig_id_item,
	old_basket.po_original_id_basket,
	old_basket.id_basket                    AS old_id_item,
	old_basket.id_basket_linked,
	old_basket.id_basket                    AS new_id_item,
	old_basket.id_basket_status             AS id_item_status,
	log_itemprices.id_log_itemprice         AS id_log_itemprice,
	old_basket.id_supplier                     AS id_supplier,
	log_itemprices.old_buy_price            AS old_buy_price,
	log_itemprices.old_buy_currency         AS old_buy_currency,
	log_itemprices.new_buy_price            AS new_buy_price,
	log_itemprices.new_buy_currency         AS new_buy_currency,
	log_itemprices.old_supplier_price       AS old_supplier_price,
	log_itemprices.old_supplier_currency    AS old_supplier_currency,
	log_itemprices.new_supplier_price       AS new_supplier_price,
	log_itemprices.new_supplier_currency    AS new_supplier_currency,
	log_itemprices.old_id_supplier          AS old_id_supplier,
	log_itemprices.new_id_supplier          AS new_id_supplier,
	log_itemprices.id_user                  AS id_user
	FROM log_itemprices
	JOIN baskets AS old_basket ON log_itemprices.id_basket = old_basket.id_basket
	JOIN basket_status ON old_basket.id_basket_status = basket_status.id_basket_status
	WHERE log_itemprices.id_basket IS NOT NULL AND log_itemprices.deleted IS NULL and old_buy_price is not null
	AND (
	(log_itemprices.profit_opt = 'zzA/C' AND log_itemprices.created < date '2014-02-17') --#5354
	OR (log_itemprices.profit_opt = 'M/C')
	)
) as items

LEFT JOIN users ON users.id_user = items.id_user
-- log_itemprices -> suppliers (new supplier)
LEFT JOIN suppliers AS suppliers_to ON items.new_id_supplier = suppliers_to.id_supplier
-- log_itemprices -> suppliers (previous supplier)
LEFT JOIN suppliers AS suppliers_from ON items.old_id_supplier = suppliers_from.id_supplier
-- log_itemprices -> bookings_sp
LEFT JOIN bookings_sp ON bookings_sp.id_basket = items.old_id_item
-- bookings_sp -> hotels
LEFT JOIN hotels ON hotels.id_hotel = bookings_sp.id_hotel
-- hotels -> sources
LEFT JOIN sources ON sources.id_source = bookings_sp.id_source
-- log_itemprices -> statusaliases
LEFT JOIN statusaliases ON items.id_item_status = ANY(statusaliases.id_basket_status)
order by id_booking,orig_id_item,created
;
create index on profit_opt_tableau (created) ;
create index on profit_opt_tableau (orig_id_item);
;
select po_status,count(*) 
from profit_opt_tableau  
group by 1
limit 50 ;
;
select * from profit_opt_tableau limit 10 ;
select count(*) from profit_opt_tableau
;
drop table if exists profit_opt_complete cascade
;
create table profit_opt_complete as
select 
date_trunc('week', b.created)::date as week,
b.created,
a.id_booking,
i.*,
a."old_id_item" ,
b."new_id_item" ,
b."statusalias" ,
b."po_status" ,
a."old_buy_price"-b."new_buy_price"  as total_profit,
a."old_buy_price" ,
b."new_buy_price" ,
a."old_buy_currency" ,
b."new_buy_currency" ,
b."email" ,
concat(a.old_supplier,'->', b.new_supplier)   AS supplier_pair,
b."hotel_name" ,
b."id_log_itemprice" ,
b."id_item_status" ,
b."id_supplier" ,
a."old_supplier_price" ,
a."old_supplier_currency" ,
b."new_supplier_price" ,
b."new_supplier_currency" ,
a."old_id_supplier" ,
b."new_id_supplier" ,
b."new_supplier" ,
a."old_supplier" ,
b."product_name" ,
b."source_name" ,
b."net_price" ,
b."net_currency" ,
b."id_hotel" ,
b."product" ,
b."pax_names" 
from (
	select orig_id_item,
	min(created) as orig_created,
	max(created) as last_created,
	string_agg(distinct po_status,',') as po_statuses,
	count(*) as transactions
	from profit_opt_tableau 
--where id_booking = 2505011
	group by 1
) i
join profit_opt_tableau a on a.created = i.orig_created and i.orig_id_item=a.orig_id_item
join profit_opt_tableau b on b.created = i.last_created and i.orig_id_item=b.orig_id_item
;

create index on profit_opt_complete(orig_id_item);
create index on profit_opt_complete(week);
create index on profit_opt_complete(created);
create index on profit_opt_complete(email);
create index on profit_opt_complete(new_id_item);
create index on profit_opt_complete(id_booking);
create index on profit_opt_complete(statusalias);

;
select * from profit_opt_complete order by created desc
limit 10
;
drop table if exists profit_opt_enhanced
;
create table profit_opt_enhanced as
select 
b.total_profit,
b.transactions,
b.orig_created,
b.last_created,
b.old_buy_price as first_buy_price,
b.new_buy_price as last_buy_price,
b.po_statuses,
a.* from profit_opt_tableau a
left join profit_opt_complete b using(created,new_id_item)
--where a.id_booking = 2505011
order by a.created
;
create index on profit_opt_enhanced (created);
create index on profit_opt_enhanced (orig_id_item)
;
select max(week),count(*) from profit_opt_enhanced limit 10


