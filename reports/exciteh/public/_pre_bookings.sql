DROP TABLE IF EXISTS tableau_full_basket_history
;
CREATE TABLE tableau_full_basket_history AS
WITH RECURSIVE full_basket_history AS (
    SELECT
        id_basket AS id_basket,
        id_basket AS related_basket,
        0         AS basket_chain_length
    FROM baskets

    UNION ALL

    SELECT
        full_basket_history.id_basket               AS id_basket,
        baskets.id_basket                           AS related_basket,
        full_basket_history.basket_chain_length + 1 AS basket_chain_length
    FROM
        full_basket_history
        JOIN baskets ON baskets.id_basket_linked = full_basket_history.related_basket
)
SELECT
    full_basket_history.id_basket                        AS id_basket,
    full_basket_history.related_basket                   AS related_id_basket,
    log_bookings.created AT TIME ZONE 'Australia/Sydney' AS status_change_time,
    log_bookings.id_status_from                          AS id_status_from,
    log_bookings.id_status_to                            AS id_status_to
FROM
    full_basket_history
    LEFT JOIN log_bookings ON
        log_bookings.id_basket = full_basket_history.related_basket
        AND (log_bookings.id_status_from IS NOT NULL OR log_bookings.id_status_to IS NOT NULL)
;

CREATE INDEX ON tableau_full_basket_history (id_basket);
CREATE INDEX ON tableau_full_basket_history (status_change_time);
CREATE INDEX ON tableau_full_basket_history (id_status_to);
ANALYZE tableau_full_basket_history;

DROP TABLE IF EXISTS tableau_dates;
CREATE TABLE tableau_dates AS
SELECT
    'basket'                                                        AS item_type,
    baskets.id_basket                                               AS item_id,
    baskets.created AT TIME ZONE 'Australia/Sydney'                 AS datetime_created,
    date(baskets.created AT TIME ZONE 'Australia/Sydney')           AS date_created,
    date(baskets.arrival_date AT TIME ZONE 'Australia/Sydney')      AS date_checkin,
    date(coalesce(baskets.departure_date, baskets.arrival_date) AT TIME ZONE 'Australia/Sydney')
                                                                    AS date_checkout,
    date_confirmed.date AT TIME ZONE 'Australia/Sydney'             AS datetime_confirmed,
    date_agent_paid.date AT TIME ZONE 'Australia/Sydney'            AS datetime_agent_paid,
    date_supplier_paid.date AT TIME ZONE 'Australia/Sydney'         AS datetime_supplier_paid,
    date_cancelled.date AT TIME ZONE 'Australia/Sydney'             AS datetime_cancelled,
    date_instant_purchase.date AT TIME ZONE 'Australia/Sydney'      AS datetime_instant_purchase,
    date_confirmed.date::date                                       AS date_confirmed,
    date_agent_paid.date::date                                      AS date_agent_paid,
    date_supplier_paid.date::date                                   AS date_supplier_paid,
    date_cancelled.date::date                                       AS date_cancelled,
    date_instant_purchase.date::date                                AS date_instant_purchase
FROM
    baskets
    LEFT JOIN (
        SELECT id_basket, min(status_change_time) AS date
        FROM tableau_full_basket_history
        WHERE id_status_to = ANY(get_unpaid_statuses() || get_paid_statuses())
        GROUP BY 1
    ) AS date_confirmed ON baskets.id_basket = date_confirmed.id_basket
    LEFT JOIN (
        SELECT id_basket, min(status_change_time) AS date
        FROM tableau_full_basket_history
        WHERE id_status_to = ANY(get_paid_statuses())
        GROUP BY 1
    ) AS date_agent_paid ON baskets.id_basket = date_agent_paid.id_basket
    LEFT JOIN (
        SELECT id_basket, min(status_change_time) AS date
        FROM tableau_full_basket_history
        WHERE id_status_to = 60
        GROUP BY 1
    ) AS date_supplier_paid ON baskets.id_basket = date_supplier_paid.id_basket
    LEFT JOIN (
        SELECT id_basket, min(status_change_time) AS date
        FROM tableau_full_basket_history
        WHERE id_status_to = ANY(get_cancelled_statuses())
        GROUP BY 1
    ) AS date_cancelled ON baskets.id_basket = date_cancelled.id_basket
    LEFT JOIN (
        SELECT id_basket, min(status_change_time) AS date
        FROM tableau_full_basket_history
        WHERE id_status_to = 20
        GROUP BY 1
    ) AS date_instant_purchase ON baskets.id_basket = date_instant_purchase.id_basket
UNION ALL
SELECT
    'charge'                                                        AS item_type,
    charges.id_charges                                              AS item_id,
    charges.created AT TIME ZONE 'Australia/Sydney'                 AS datetime_created,
    date(charges.created AT TIME ZONE 'Australia/Sydney')           AS date_created,
    date(charges.date AT TIME ZONE 'Australia/Sydney')              AS date_checkin,
    date(coalesce(charges.date_checkout, charges.date) AT TIME ZONE 'Australia/Sydney')
                                                                    AS date_checkout,
    date_confirmed.date AT TIME ZONE 'Australia/Sydney'             AS datetime_confirmed,
    date_agent_paid.date AT TIME ZONE 'Australia/Sydney'            AS datetime_agent_paid,
    date_supplier_paid.date AT TIME ZONE 'Australia/Sydney'         AS datetime_supplier_paid,
    date_cancelled.date AT TIME ZONE 'Australia/Sydney'             AS datetime_cancelled,
    date_instant_purchase.date AT TIME ZONE 'Australia/Sydney'      AS datetime_instant_purchase,
    date_confirmed.date::date                                       AS date_confirmed,
    date_agent_paid.date::date                                      AS date_agent_paid,
    date_supplier_paid.date::date                                   AS date_supplier_paid,
    date_cancelled.date::date                                       AS date_cancelled,
    date_instant_purchase.date::date                                AS date_instant_purchase
FROM
    charges
    LEFT JOIN (
        SELECT id_charges, min(created AT TIME ZONE 'Australia/Sydney') AS date
        FROM log_bookings
        WHERE id_status_to = ANY(get_unpaid_statuses() || get_paid_statuses())
        GROUP BY 1
    ) AS date_confirmed ON charges.id_charges = date_confirmed.id_charges
    LEFT JOIN (
        SELECT id_charges, min(created AT TIME ZONE 'Australia/Sydney') AS date
        FROM log_bookings
        WHERE id_status_to = ANY(get_paid_statuses())
        GROUP BY 1
    ) AS date_agent_paid ON charges.id_charges = date_agent_paid.id_charges
    LEFT JOIN (
        SELECT id_charges, min(created AT TIME ZONE 'Australia/Sydney') AS date
        FROM log_bookings
        WHERE id_status_to = 60 -- completed
        GROUP BY 1
    ) AS date_supplier_paid ON charges.id_charges = date_supplier_paid.id_charges
    LEFT JOIN (
        SELECT id_charges, min(created AT TIME ZONE 'Australia/Sydney') AS date
        FROM log_bookings
        WHERE id_status_to = ANY(get_cancelled_statuses())
        GROUP BY 1
    ) AS date_cancelled ON charges.id_charges = date_cancelled.id_charges
    LEFT JOIN (
        SELECT id_charges, min(created AT TIME ZONE 'Australia/Sydney') AS date
        FROM log_bookings
        WHERE id_status_to = 20
        GROUP BY 1
    ) AS date_instant_purchase ON charges.id_charges = date_instant_purchase.id_charges
;
CREATE INDEX ON tableau_dates (item_id)
;




--tableau_transfer_endpoints - transfers v2 -- endpoints are either regions, airports or ports
DROP TABLE IF EXISTS tableau_transfer_endpoints
;
CREATE TABLE tableau_transfer_endpoints AS
SELECT
    transfer_endpoint_type,
    transfer_endpoint_id,
    (CASE
        WHEN transfer_endpoint_type = 'region'
            THEN region_endpoint.name
        WHEN transfer_endpoint_type = 'airport'
            THEN airport_endpoint.name
        WHEN transfer_endpoint_type = 'port'
            THEN 'Port'
    END) AS transfer_endpoint_name
FROM
    (
        SELECT DISTINCT
            origin_type         AS transfer_endpoint_type,
            id_origin           AS transfer_endpoint_id
        FROM
            transfer_destinations
        UNION
        SELECT DISTINCT
            destination_type    AS transfer_endpoint_type,
            id_destination      AS transfer_endpoint_id
        FROM
            transfer_destinations
    ) AS endpoints
    LEFT JOIN (
        SELECT
            id_region           AS id_region,
            array_to_string(
                ARRAY[citydistrict, city, state, country], ', '
            )                   AS name
        FROM v_region_parts
    ) AS region_endpoint
        ON region_endpoint.id_region = endpoints.transfer_endpoint_id 
        AND endpoints.transfer_endpoint_type = 'region'
    LEFT JOIN (
        SELECT
            id_airport                  AS id_airport,
            format(
                '%s %s(%s)',
                name[1],
                CASE WHEN strpos(lower(name[1]), 'airport') = 0 THEN 'Airport ' END,
                code
            )                           AS name
        FROM airports
    ) AS airport_endpoint
        ON airport_endpoint.id_airport = endpoints.transfer_endpoint_id
        AND endpoints.transfer_endpoint_type = 'airport'
;
CREATE INDEX ON tableau_transfer_endpoints (transfer_endpoint_id)
;

--tableau_transfer_routes
DROP TABLE IF EXISTS tableau_transfer_routes
;
CREATE TABLE tableau_transfer_routes AS
SELECT
    transfer_destinations.id_source                 AS source_id,
    transfer_destinations.id_transfer_destination   AS transfer_route_id,
    origin.transfer_endpoint_name                   AS transfer_origin_name,
    destination.transfer_endpoint_name              AS transfer_destination_name
FROM
    transfer_destinations
    LEFT JOIN tableau_transfer_endpoints AS origin
        ON origin.transfer_endpoint_type = transfer_destinations.origin_type
        AND origin.transfer_endpoint_id = transfer_destinations.id_origin
    LEFT JOIN tableau_transfer_endpoints AS destination
        ON destination.transfer_endpoint_type = transfer_destinations.destination_type
        AND destination.transfer_endpoint_id = transfer_destinations.id_destination
;
CREATE INDEX ON tableau_transfer_routes(source_id);
CREATE INDEX ON tableau_transfer_routes(transfer_route_id);

DROP TABLE IF EXISTS tableau_transfers;
CREATE TABLE tableau_transfers AS
SELECT
    sources.id_source                                   AS source_id,
    transfers.id_transfer                               AS transfer_id,
    vehicletypes.name[1]                                AS transfer_vehicle,
    transfers.id_region                                 AS transfer_region_id,
    tableau_transfer_routes.transfer_route_id           AS transfer_route_id,
    tableau_transfer_routes.transfer_origin_name        AS transfer_origin_name,
    tableau_transfer_routes.transfer_destination_name   AS transfer_destination_name
FROM
    sources
    JOIN transfer_sources ON transfer_sources.id_source = sources.id_source
    JOIN transfers ON transfers.id_transfer = transfer_sources.id_transfer
    JOIN vehicletypes ON vehicletypes.id_vehicletype = transfers.id_vehicletype
    JOIN tableau_transfer_routes ON tableau_transfer_routes.source_id = sources.id_source
;
CREATE INDEX ON tableau_transfers(source_id);
CREATE INDEX ON tableau_transfers(transfer_id);

--tableau_activities
DROP TABLE IF EXISTS tableau_activities;
CREATE TABLE tableau_activities AS
SELECT
    sources.id_source           AS source_id,
    sources.name[1]             AS activity_name,
    tourcategories.name         AS activity_category,
    source_tourtypes.name       AS activity_type,
    regionexternals.id_region   AS activity_region_id
FROM
    sources
    JOIN source_tours ON sources.id_source = source_tours.id_source
    JOIN tourcategories ON source_tours.id_tourcategory = tourcategories.id_tourcategory
    JOIN source_tourtypes ON source_tours.id_source_tourtype = source_tourtypes.id_source_tourtype
    LEFT JOIN regionexternals ON source_tours.id_regionexternal = regionexternals.id_regionexternal
WHERE
    sources.id_product = 4
;
CREATE INDEX ON tableau_activities(source_id);


--tableau_rewards:EH-2926: Rewards promotion
drop table if exists tableau_rewards;
CREATE TABLE tableau_rewards AS
SELECT
    lower(item_type)    AS item_type,
    item_id             AS id_item,
    array_to_string(
        array_agg(rewardpromotions.name ORDER BY rewardpromotions.id_rewardpromotion),
        ', '
    )                   AS promos
FROM
    rewarditems
    JOIN rewardpromotions using(id_rewardpromotion)
GROUP BY     1, 2
;
CREATE INDEX ON tableau_rewards (item_type);
CREATE INDEX ON tableau_rewards (id_item);



--tableau_reference
drop table if exists tableau_reference
;
create table tableau_reference as
SELECT
'basket' as item_type,
id_basket as id_item,
'Hotel' as product,
id_basket_hotel_reference as ref,
location_name,
location_coordinates,
regexp_replace(location_coordinates::text,'.+"lat":([^\}]+)}','\1') as lat,
regexp_replace(location_coordinates::text,'{"lon":([^,]+).+','\1') as lon,
country,
country_code,
id_hotel,
id_external,
"name",
address,
city,
"state",
postcode,
telephone,
fax,
giata_id,
created,
modified,
deleted
FROM "public".basket_hotel_reference

UNION ALL 


SELECT
'charge' as item_type,
id_charges as item_id,
NULL as product,
id_charge_reference as ref,
location_name,
location_coordinates,
regexp_replace(location_coordinates::text,'.+"lat":([^\}]+)}','\1') as lat,
regexp_replace(location_coordinates::text,'{"lon":([^,]+).+','\1') as lon,
country,
country_code,
NULL as id_hotel,
id_external,
"name",
address,
city,
"state",
postcode,
telephone,
fax,
giata_id,
created,
modified,
deleted
FROM "public".charge_reference

UNION ALL 

SELECT
'basket' as item_type,
id_basket as item_id,
'Transfer' as product,
id_basket_transfer_reference as ref,
location_name,
NULL as location_coordinates,
NULL as lat,
NULL as lon,
country,
country_code,
NULL as id_hotel,
'_missing' as id_external,
'_missing' as "name",
'_missing' as address,
'_missing' as city,
'_missing' as "state",
'_missing' as postcode,
'_missing' as telephone,
'_missing' as fax,
NULL as giata_id,
created,
modified,
deleted
FROM "public".basket_transfer_reference

UNION ALL 

SELECT
'basket' as item_type,
id_basket as item_id,
'Tour' as product,
id_basket_tour_reference as ref,
location_name,
NULL as location_coordinates,
NULL as lat,
NULL as lon,
country,
country_code,
NULL as id_hotel,
'_missing' as id_external,
"name",
'_missing' as address,
city,
'_missing' as "state",
'_missing' as postcode,
'_missing' as telephone,
'_missing' as fax,
NULL as giata_id,
created,
modified,
deleted
FROM "public".basket_tour_reference
;


--tableau_additional
drop table if exists tableau_additional
;
create table tableau_additional as
select id_booking,id_basket as id_item,'basket'::varchar as item_type,
agency_reference_number
from baskets
;
create index on tableau_additional (id_booking);
create index on tableau_additional (id_item);
create index on tableau_additional (item_type);

--tableau_sp
drop table if exists tableau_sp
;
create table tableau_sp as
select *,adults+children as pax
from (
	select id_booking,id_basket as id_item,'basket'::varchar as item_type,
	array_length(regexp_split_to_array(pax_names, '[\r\n]'),1) as adults,
	case when child_ages = '' then 0 else array_length(regexp_split_to_array(child_ages, ','),1) end as children,
	case when child_ages > '' then true  else false end as has_children,
	regexp_replace(pax_names,'\s*[\r\n]+\s*',',','g')::varchar AS pax_names,
	child_ages
	from "public".bookings_sp
	where id_basket is not null
) s
;
CREATE INDEX ON tableau_sp (id_booking);
CREATE INDEX ON tableau_sp (id_item);
CREATE INDEX ON tableau_sp (item_type)
;

--tableau_touchpoints
drop table if exists tableau_touchpoints 
;
create table tableau_touchpoints as 
select b.agent_consortia,
c.global_market,c.market,
a.* from 
(
SELECT
    agents.id_agent                                                     AS id_agent,
    clients.id_client                                                   AS id_client,
    currencies.iso                                                      AS currency,
    clients.name[1]                                                     AS name,
    (clients.status = 1 AND clients.status IS NOT NULL)                 AS is_enabled_agent,
    agents.created AT TIME ZONE 'Australia/Sydney'                      AS created,
    users.email                                                         AS bdm,
    headoffices.id_headoffice 																					AS id_headoffice,
    headoffices.name[1]                                                 AS headoffice,
    roles.name                                                          AS tier,

    -- first item detail
    first_booking.created AT TIME ZONE 'Australia/Sydney'               AS first_booking_date,
    most_recent.created AT TIME ZONE 'Australia/Sydney'                 AS last_booking_date,

    -- aggregated item detail
    coalesce(agent_aggregated.total_net, 0)                             AS total_net,
    coalesce(agent_aggregated.number_of_items, 0)                       AS booking_items,

    location.region                                                     AS region,
    location.country                                                    AS country,
    location.state                                                      AS state,
    location.city                                                       AS city,
    location.citydistrict                                               AS citydistrict,
    (touchpoints.touchpoint_date AT TIME ZONE 'Australia/Sydney')::date AS touchpoint_date,
    touchpointtypes.description                                         AS touchpoint_type
FROM
    agents
    -- agents -> users
    LEFT JOIN users ON users.id_user = agents.account_owner
    -- agents -> headoffices
    LEFT JOIN headoffices ON headoffices.id_headoffice = agents.id_headoffice
    -- agents -> contacts
    LEFT JOIN contacts ON agents.id_contact = contacts.id_contact
    -- contacts -> regions_sp
    LEFT JOIN regions_sp ON regions_sp.id_region = contacts.id_region
    -- contacts -> v_region_parts (location)
    LEFT JOIN v_region_parts AS location ON contacts.id_region = location.id_region
    -- agents -> agent_roles
    LEFT JOIN agent_roles ON agent_roles.id_agent = agents.id_agent
    -- agent_roles -> roles
    LEFT JOIN roles ON roles.id_role = agent_roles.id_role
    -- agents -> clients
    LEFT JOIN clients ON clients.id_client = agents.id_client
    -- clients -> currencies
    LEFT JOIN currencies ON currencies.id_currency = clients.id_currency
    -- clients -> bookings_sp (most recent)
    LEFT JOIN (
        -- | bookings_sp columns for the most recent item per client... |
        -- SELECT DISTINCT ON takes the first result encountered for each id_client
        -- ORDER BY DESC ensures the first result is the newest for each client
        SELECT DISTINCT ON (id_client) bookings_sp.*
        FROM bookings_sp
        WHERE id_basket_status = ANY(get_paid_statuses() || get_unpaid_statuses())
        ORDER BY id_client, created DESC
    ) AS most_recent ON clients.id_client = most_recent.id_client
    -- clients -> bookings_sp (first booking)
    LEFT JOIN (
        SELECT DISTINCT ON (id_client) bookings_sp.*
        FROM bookings_sp
        WHERE id_basket_status = ANY(get_paid_statuses() || get_unpaid_statuses())
        ORDER BY id_client, created ASC
    ) AS first_booking ON clients.id_client = first_booking.id_client
    -- clients -> bookings_sp (aggregate)
    LEFT JOIN (
        -- | id_client | sum of net prices | number of items |
        SELECT id_client, SUM(net_price) AS total_net, COUNT(id_basket) + COUNT(id_charges) AS number_of_items
        FROM bookings_sp
        WHERE bookings_sp.id_basket_status = ANY(get_paid_statuses() || get_unpaid_statuses())
        GROUP BY id_client
    ) AS agent_aggregated ON clients.id_client = agent_aggregated.id_client
    LEFT JOIN touchpoints ON touchpoints.id_client = clients.id_client
    LEFT JOIN touchpointtypes ON touchpoints.id_touchpointtype = touchpointtypes.id_touchpointtype
) a 
left join lookups.agent_headoffices b using(id_headoffice)
left join lookups.bdms c on a.bdm = c.email
;
update tableau_touchpoints 
set global_market='AU',
market = 'AU NSW/ACT',
bdm = 'brooke@exciteholidays.com' 
where bdm = 'brooke.brindle@exciteholidays.com'

