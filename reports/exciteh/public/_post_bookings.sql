--Rewards Promotions
UPDATE tableau_bookings
SET rewards_promotion = tableau_rewards.promos
FROM tableau_rewards
WHERE
    tableau_bookings.item_type = tableau_rewards.item_type
    AND tableau_bookings.id_item = tableau_rewards.id_item
;

-- EH-1001: Paid unavailables
UPDATE tableau_bookings
SET is_paid_unavailable = (unavailable.id_basket IS NOT NULL AND paid.id_basket IS NOT NULL)
FROM
    baskets
    LEFT JOIN (
        SELECT
            id_basket,
            min(created) AS date
        FROM
            log_bookings
        WHERE
            id_status_to = 80
        GROUP BY id_basket
    ) AS unavailable ON unavailable.id_basket = baskets.id_basket
    LEFT JOIN (
        SELECT
            id_basket,
            min(created) AS date
        FROM
            payment_baskets
        WHERE
            deleted IS NULL
        GROUP BY id_basket
    ) AS paid ON paid.id_basket = baskets.id_basket
        AND paid.date <= unavailable.date
WHERE
    tableau_bookings.item_type = 'basket'
    AND tableau_bookings.id_item = baskets.id_basket
;

--agent_details
UPDATE tableau_bookings
SET
    id_client = bookings.id_client,
    id_client_type = clients.id_client_type,
    client_type = client_types.name,
    agent = clients.name[1],
    account_owner = agents.account_owner,
    id_agent = agents.id_agent,
    id_headoffice = agents.id_headoffice,
    is_preferred_agent = coalesce(agents.preferred, FALSE),
    agent_headoffice = headoffices.name[1],
    agent_region = location.region,
    agent_country = location.country,
    agent_state = location.state,
    agent_city = location.city,
    agent_citydistrict = location.citydistrict,
    agent_postal_code = primarycontact.zip,
    agent_sales_area = agents.sales_area,
    email = bdm.email
FROM
    bookings
    LEFT JOIN clients ON bookings.id_client = clients.id_client
    LEFT JOIN agents ON agents.id_client = clients.id_client
    LEFT JOIN headoffices ON headoffices.id_headoffice = agents.id_headoffice
    LEFT JOIN contacts AS primarycontact ON agents.id_contact = primarycontact.id_contact
    LEFT JOIN v_region_parts AS location ON primarycontact.id_region = location.id_region
    LEFT JOIN client_types ON clients.id_client_type = client_types.id_client_type
    LEFT JOIN users AS bdm ON agents.account_owner = bdm.id_user
WHERE bookings.id_booking = tableau_bookings.id_booking
;

--HACK:-- removes old items without a valid client #4891
DELETE FROM tableau_bookings WHERE  created < date '2013-01-01' AND id_client IS NULL
;

--update supplier details
UPDATE tableau_bookings
SET supplier = suppliers.name[1]
FROM suppliers
WHERE suppliers.id_supplier = tableau_bookings.id_supplier
and suppliers.name[1] != tableau_bookings.supplier
;

--fix products
update tableau_bookings
set product = s.product
from 
	(select id_basket,'basket' as item_type,text[1] as product
	from baskets
	join products using(id_product)
	) s
where tableau_bookings.id_item=s.id_basket
and tableau_bookings.item_type = 'basket'
;
CREATE INDEX ON tableau_bookings (product) 
;

--id_hotel
update tableau_bookings
set id_hotel = s.id_hotel
from 	(
	select id_basket,id_hotel
	from baskets
	join basket_hotel_reference using(id_basket)
	where id_hotel is not null
	) s
where tableau_bookings.id_item=s.id_basket
and tableau_bookings.item_type = 'basket'
;
CREATE INDEX ON tableau_bookings (id_hotel)
;

update tableau_bookings set hotel_chain = null where hotel_chain is not null
;
update tableau_bookings set id_hotel = NULL where product != 'Hotel' and id_hotel is not null
;

--hotel_details
UPDATE tableau_bookings
SET
    item_name = primarysource.name[1],
    product_subproduct = coalesce(categories.name[1], 'Hotel'),
    region = location.region,
    country = location.country,
    state = location.state,
    city = location.city,
    citydistrict = location.citydistrict,
    lat = primarysource.lat,
    lon = primarysource.lng,
    stars = primarysource.ranking
FROM
    hotels
    JOIN sources AS primarysource ON hotels.id_source = primarysource.id_source
    LEFT JOIN hotel_categories ON hotels.id_hotel = hotel_categories.id_hotel
    LEFT JOIN categories ON categories.id_category = hotel_categories.id_category
    LEFT JOIN v_region_parts AS location ON location.id_region = hotels.id_region
WHERE
    hotels.id_hotel = tableau_bookings.id_hotel AND
    tableau_bookings.product = 'Hotel'
;

--update from transfer details
-- -> baskets -> basket_transfers -> transfer_destinations -> transfer_sources -> transfers -> vehicletypes
UPDATE tableau_bookings
SET
    product_subproduct =
        (CASE
            WHEN person_price IS NOT NULL AND vehicle_price IS NULL     THEN    'priced per person'
            WHEN person_price IS NULL     AND vehicle_price IS NOT NULL THEN    'priced per vehicle'
            ELSE                                                                NULL
        END),
    region       = coalesce(location.region,       oldlocation.region),
    country      = coalesce(location.country,      oldlocation.country),
    state        = coalesce(location.state,        oldlocation.state),
    city         = coalesce(location.city,         oldlocation.city),
    citydistrict = coalesce(location.citydistrict, oldlocation.citydistrict)
FROM
    basket_transfers
    -- new transfers (subproduct and region)
    LEFT JOIN transfer_destinations ON transfer_destinations.id_transfer_destination = basket_transfers.id_transfer_destination
    LEFT JOIN transfer_sources ON transfer_destinations.id_source = transfer_sources.id_source
    LEFT JOIN transfers ON transfer_sources.id_transfer = transfers.id_transfer
    LEFT JOIN v_region_parts AS location ON transfers.id_region = location.id_region
    -- old transfers (region only)
    LEFT JOIN v_region_parts AS oldlocation ON basket_transfers.id_pick_up_region = oldlocation.id_region
WHERE
    tableau_bookings.product = 'Transfer'
    AND tableau_bookings.item_type = 'basket'
    AND basket_transfers.id_basket = tableau_bookings.id_item
;

-- update from tour details
-- -> baskets -> sources -> source_tours -> regionexternals -> v_region_parts
--                                       -> source_tourtypes
UPDATE tableau_bookings
SET
    item_name = sources.name[1],
    product_subproduct = source_tourtypes.name,
    region = location.region,
    country = location.country,
    state = location.state,
    city = location.city,
    citydistrict = location.citydistrict
FROM
    baskets
    JOIN sources ON baskets.id_source = sources.id_source
    JOIN source_tours
        ON source_tours.id_source = sources.id_source
        AND source_tours.deleted IS NULL
    JOIN regionexternals ON regionexternals.id_regionexternal = source_tours.id_regionexternal
    JOIN v_region_parts AS location ON location.id_region = regionexternals.id_region
    LEFT JOIN source_tourtypes ON source_tourtypes.id_source_tourtype = source_tours.id_source_tourtype
WHERE
    baskets.id_basket = tableau_bookings.id_item
    AND tableau_bookings.item_type = 'basket'
    AND tableau_bookings.id_hotel IS NULL
;

-- booked by PO
UPDATE tableau_bookings
SET is_booked_by_po = q.is_booked_by_po
FROM (
    SELECT
        baskets_new.id_basket   AS id_basket,
        EXISTS (
            SELECT 1
            FROM baskets AS baskets_old
            WHERE
                baskets_old.id_basket_linked = baskets_new.id_basket
                AND po_rebooking IS NOT NULL
        )                       AS is_booked_by_po
        FROM
            baskets AS baskets_new
) AS q
WHERE
    tableau_bookings.item_type = 'basket'
    AND tableau_bookings.id_item = q.id_basket
;

-- cancelled by PO
UPDATE tableau_bookings
SET is_cancelled_by_po = q.is_cancelled_by_po
FROM (
    SELECT
        baskets.id_basket   AS id_basket,
        (
            baskets.po_rebooking IS NOT NULL
            AND id_basket_linked IS NOT NULL
        )                   AS is_cancelled_by_po
        FROM baskets
) AS q
WHERE
    tableau_bookings.id_item_status = ANY(get_cancelled_statuses())
    AND tableau_bookings.item_type = 'basket'
    AND tableau_bookings.id_item = q.id_basket
;

--hacks
update tableau_bookings set citydistrict = 'Santa Monica' where city = 'Los Angeles (and area)' and citydistrict is null ;
update tableau_bookings set lat = NULL,lon = NULL  where (lon = 0 or lat = 0 or lat is NULL or lon IS NULL) ;


update tableau_bookings set agent_headoffice = '_No Headoffice',id_headoffice=0 where agent_headoffice is null ;
update tableau_bookings set net_currency = 'AUD' where net_currency not in (select distinct currency from lookups.currencies_simple) or net_price is null;
delete from agent_roles where id_agent_role = 50067 
;
update tableau_bookings set lat = NULL,lon = NULL  where (lon = 0 or lat = 0 or lat is NULL or lon IS NULL) 
;
update tableau_bookings set item_statusalias = 'cancelled' 
where (item_statusalias is null or item_statusalias = 'historical' or item_statusalias = '0')
;
select distinct item_statusalias from tableau_bookings
;

-- GEO data from reference where missing
update tableau_bookings
set city = s.city,
country=s.country
from 	(
	select item_type,id_item,country,regexp_replace(location_name,'\s*([^,]),.+','\1') as city,location_name
	from tableau_reference
	where location_name > ''
	) s
where tableau_bookings.id_item=s.id_item
and tableau_bookings.item_type = s.item_type
and tableau_bookings.city is null
and s.city is not null
;

-- GEO data from reference where missing
update tableau_bookings
set country=s.country
from 	(
	select item_type,id_item,country
	from tableau_reference
	) s
where tableau_bookings.id_item=s.id_item
and tableau_bookings.item_type = s.item_type
and s.country is not null
and tableau_bookings.country is null
;

update tableau_bookings set country = 'United States of America' where country ilike '%united states%usa';
;

-- Transfer details
update tableau_bookings
set item_name = basket_transfers.transfer_description[1],
product_subproduct = vehicle_description,
room_description = pick_up_location||'->'||drop_off_location
from basket_transfers
where product = 'Transfer'
and item_type='basket' and id_item=basket_transfers.id_basket
--and id_item =  '1989931'
--select * from tableau_bookings where id_item = 1989931

;
--New PAS Hotels GEO
update tableau_bookings a
set 
country=b.country,
state=b.state,
city=b.city,
citydistrict=b.citydistrict,
item_name = b.name
from hacks.hacked b
where a.id_hotel = b.id_hotel
--and a.id_hotel = 709033
;
select * from tableau_bookings where id_hotel = 9000963
;

--tableau_linked
drop table if exists tableau_linked
;
create table tableau_linked as
select a.id_charges,a.id_basket_linked,b.id_basket,
c.*
from charges a
left join baskets b on a.id_basket_linked = b.id_basket
left join tableau_bookings c on b.id_basket = c.id_item and c.item_type = 'basket'
where a.deleted is null
;
select item_type,product,country,id_basket_linked from tableau_linked
where id_charges = 936821 
;
select item_type,product,country from tableau_bookings
where id_item = 1872880
;
update tableau_bookings
set 
region= s.region,
country = s.country,
city= s.city,
citydistrict = s.citydistrict
from tableau_linked s
where tableau_bookings.id_item=s.id_charges
and tableau_bookings.item_type = 'charge'
and tableau_bookings.country is null
and s.country is not null
;
select item_type,product,country from tableau_bookings
where item_type = 'charge' and id_item = 936821
;
update tableau_bookings set email = 'brooke@exciteholidays.com' where email = 'brooke.brindle@exciteholidays.com'
;

--Fix problem in source data
delete from charge_reference where id_charge_reference not in (
	select id_charge_reference from charge_reference
	join (
		select id_charges,max(created) as created from charge_reference
		group by 1
	) b using(id_charges,created)
)
