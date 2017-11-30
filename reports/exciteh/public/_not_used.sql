-- Create tableau_* tables
DROP TABLE IF EXISTS tableau_baskets;
CREATE TABLE tableau_baskets AS
SELECT
    baskets.id_booking          AS booking_id,
    baskets.id_basket           AS item_id,
    baskets.id_source           AS source_id,
    sources.id_supplier         AS supplier_id,
    baskets.id_user             AS user_id,
    baskets.id_basket_status    AS item_status_id,
    hotel_sources.id_hotel      AS product_hotel_id,
    sources.id_product          AS product_id,
    baskets.supplier_currency   AS price_supplier_currency,
    baskets.supplier_price      AS price_supplier,
    baskets.buy_currency        AS price_buy_currency,
    baskets.buy_price           AS price_buy,
    baskets.net_currency        AS price_net_currency,
    baskets.net_price           AS price_net,
    baskets.gross_currency      AS price_gross_currency,
    baskets.gross_price         AS price_gross
FROM
    baskets
    JOIN sources ON baskets.id_source = sources.id_source
    LEFT JOIN hotel_sources ON sources.id_source = hotel_sources.id_source
;

DROP TABLE IF EXISTS tableau_charges;
CREATE TABLE tableau_charges AS
SELECT
    charges.id_booking          AS booking_id,
    charges.id_charges          AS item_id,
    NULL::integer               AS source_id,
    charges.id_supplier         AS supplier_id,
    charges.id_user             AS user_id,
    charges.id_charge_status    AS item_status_id,
    charges.id_hotel            AS product_hotel_id,
    (CASE
        WHEN id_hotel IS NULL THEN NULL
        ELSE 1
    END)                        AS product_id,
    charges.supplier_currency   AS price_supplier_currency,
    charges.supplier_price      AS price_supplier,
    charges.buy_currency        AS price_buy_currency,
    charges.buy_price           AS price_buy,
    charges.net_currency        AS price_net_currency,
    charges.net_price           AS price_net,
    charges.gross_currency      AS price_gross_currency,
    charges.gross_price         AS price_gross
FROM charges
;

DROP TABLE IF EXISTS tableau_baskets_and_charges
;
CREATE TABLE tableau_baskets_and_charges AS
SELECT *, 'basket' AS item_type FROM tableau_baskets
UNION ALL
SELECT *, 'charge' AS item_type FROM tableau_charges
;


DROP TABLE IF EXISTS tableau_items;
CREATE TABLE tableau_items AS
SELECT
    items.booking_id            AS booking_id,
    items.item_id               AS item_id,
    items.item_type             AS item_type,
    items.user_id               AS user_id,
    tableau_dates.date_created  AS date_created,
    suppliers.name[1]           AS supplier_name,
    products.text[1]            AS product_name,
    items.source_id             AS source_id,
    statuses.name               AS item_status,
    statuses.alias              AS item_statusalias
FROM
    tableau_baskets_and_charges AS items
    LEFT JOIN suppliers ON suppliers.id_supplier = items.supplier_id
    LEFT JOIN (
        SELECT
            basket_status.id_basket_status                          AS item_status_id,
            get_human_readable_item_status(basket_status.name[1])   AS name,
            statusaliases.name[1]                                   AS alias
        FROM
            basket_status
            LEFT JOIN statusaliases ON basket_status.id_basket_status = ANY(statusaliases.id_basket_status)
    ) AS statuses ON items.item_status_id = statuses.item_status_id
    LEFT JOIN tableau_dates ON items.item_id = tableau_dates.item_id AND items.item_type = tableau_dates.item_type
    LEFT JOIN products ON products.id_product = items.product_id
;
CREATE INDEX ON tableau_items(booking_id);
CREATE INDEX ON tableau_items(item_id);

DROP TABLE IF EXISTS tableau_prices;
CREATE TABLE tableau_prices AS
SELECT
    'basket'::varchar           AS item_type,
    baskets.id_basket           AS item_id,
    baskets.supplier_currency   AS price_supplier_currency,
    baskets.supplier_price      AS price_supplier,
    baskets.buy_currency        AS price_buy_currency,
    baskets.buy_price           AS price_buy,
    baskets.net_currency        AS price_net_currency,
    baskets.net_price           AS price_net,
    baskets.gross_currency      AS price_gross_currency,
    baskets.gross_price         AS price_gross,
    round(baskets.supplier_price / supplier_rate.value, 2) AS price_supplier_AUD,
    round(baskets.buy_price      / buy_rate.value,      2) AS price_buy_AUD,
    round(baskets.net_price      / net_rate.value,      2) AS price_net_AUD,
    round(baskets.gross_price    / gross_rate.value,    2) AS price_gross_AUD
FROM
    baskets
    LEFT JOIN tableau_dates
        ON baskets.id_basket = tableau_dates.item_id
        AND tableau_dates.item_type = 'basket'
    LEFT JOIN currencyhistorical AS supplier_rate
        ON date(supplier_rate.created) = coalesce(tableau_dates.date_supplier_paid, date(now() AT TIME ZONE 'Australia/Sydney') - 1)
        AND supplier_rate.iso = baskets.supplier_currency
    LEFT JOIN currencyhistorical AS buy_rate
        ON date(buy_rate.created) = coalesce(tableau_dates.date_supplier_paid, date(now() AT TIME ZONE 'Australia/Sydney') - 1)
        AND buy_rate.iso = baskets.buy_currency
    LEFT JOIN currencyhistorical AS net_rate
        ON date(net_rate.created) = coalesce(tableau_dates.date_agent_paid, date(now() AT TIME ZONE 'Australia/Sydney') - 1)
        AND net_rate.iso = baskets.net_currency
    LEFT JOIN currencyhistorical AS gross_rate
        ON date(gross_rate.created) = coalesce(tableau_dates.date_agent_paid, date(now() AT TIME ZONE 'Australia/Sydney') - 1)
        AND gross_rate.iso = baskets.gross_currency
WHERE
    baskets.supplier_price IS NOT NULL
    OR baskets.buy_price IS NOT NULL
    OR baskets.net_price IS NOT NULL
    OR baskets.gross_price IS NOT NULL
;
CREATE INDEX ON tableau_prices(item_id)
;

DROP TABLE IF EXISTS tableau_agents
;
CREATE TABLE tableau_agents AS
SELECT
    agents.id_agent         AS agent_id,
    agents.id_client        AS client_id,
    clients.name[1]         AS agency_name,
    contacts.address1       AS agency_address1,
    contacts.address2       AS agency_address2,
    contacts.zip            AS agency_zip,
    coalesce(
        contacts.id_region,
        clients.id_region
    )                       AS agency_region_id,
    agents.account_owner    AS agency_bdm_user_id
FROM
    agents
    JOIN contacts ON agents.id_contact = contacts.id_contact
    JOIN clients ON clients.id_client = agents.id_client
;
CREATE INDEX ON tableau_agents(agent_id);
CREATE INDEX ON tableau_agents(client_id);

DROP TABLE IF EXISTS tableau_users
;
CREATE TABLE tableau_users AS
SELECT
    users.id_user                                           AS user_id,
    users.email                                             AS user_email,
    date(users.created)                                     AS user_joindate,
    (users.deleted IS NULL AND users.disabled IS NULL)      AS user_isactive,
    contacts.name                                           AS user_name,
    EXISTS (
        SELECT 1
        FROM user_groups
        WHERE user_groups.id_user = users.id_user AND id_group = 1
    )                                                       AS usergroup_backoffice,
    EXISTS (
        SELECT 1
        FROM user_groups
        WHERE user_groups.id_user = users.id_user AND id_group = 2
    )                                                       AS usergroup_agent,
    main_agent.id_agent                                     AS agent_id
FROM
    users
    LEFT JOIN contacts ON users.id_contact = contacts.id_contact
    LEFT JOIN (
        SELECT id_user, MIN(id_agent) AS id_agent
        FROM user_agents
        WHERE deleted IS NULL
        GROUP BY 1
    ) AS main_agent ON main_agent.id_user = users.id_user
;
CREATE INDEX ON tableau_users(user_id);
CREATE INDEX ON tableau_users(user_email);


DROP TABLE IF EXISTS tableau_hotels_eh
;
CREATE TABLE tableau_hotels_eh AS
SELECT
    hotels.id_hotel                                                 AS hotel_id,
    sources.name[1]                                                 AS hotel_name,
    coalesce(categories.name[1], 'Hotel')                           AS hotel_category,
    hotelchainaffiliates.name                                       AS hotel_chain,
    location.region                                                 AS hotel_region,
    location.country                                                AS hotel_country,
    location.state                                                  AS hotel_state,
    location.city                                                   AS hotel_city,
    location.citydistrict                                           AS hotel_citydistrict,
    -- round stars to the nearest 0.5, and discard stars outside of the range 1 to 6
    (CASE
        WHEN sources.ranking NOT BETWEEN 1 AND 6 THEN   NULL
        ELSE                                            (sources.ranking*2)::int / 2.0 
    END)::numeric(2,1)                                              AS hotel_stars,
    date(hotels.created AT TIME ZONE 'Australia/Sydney')            AS hotel_created,
    date(earliest_source.created AT TIME ZONE 'Australia/Sydney')   AS hotel_sourcecreated
FROM
    hotels 
    JOIN sources ON hotels.id_source = sources.id_source
    LEFT JOIN hotel_categories ON hotels.id_hotel = hotel_categories.id_hotel
    LEFT JOIN categories ON categories.id_category = hotel_categories.id_category
    LEFT JOIN hotelchainaffiliates ON hotels.id_hotelchainaffiliate = hotelchainaffiliates.id_hotelchainaffiliate
    LEFT JOIN v_region_parts AS location ON location.id_region = hotels.id_region
    LEFT JOIN (
        SELECT hotel_sources.id_hotel, min(sources.created) AS created
        FROM sources JOIN hotel_sources ON sources.id_source = hotel_sources.id_source
        GROUP BY hotel_sources.id_hotel
    ) AS earliest_source ON earliest_source.id_hotel = hotels.id_hotel
WHERE
    hotels.deleted IS NULL
;
CREATE INDEX ON tableau_hotels_eh(hotel_id)
;

DROP TABLE IF EXISTS tableau_pax;
CREATE TABLE tableau_pax AS
SELECT
    baskets.id_basket                 AS item_id,
    'basket'::varchar                 AS item_type,
    SUM(CASE
        WHEN age[1] < 18 THEN 1
        ELSE 0
    END)                              AS pax_children,
    SUM(CASE
        WHEN age[1] >= 18
            OR age IS NULL
            OR age[1] IS NULL THEN 1
        ELSE 0
    END)                              AS pax_adults
FROM
    baskets
    LEFT JOIN persons ON baskets.id_basket = persons.id_basket AND persons.deleted IS NULL
GROUP BY
    baskets.id_basket
;
CREATE INDEX ON tableau_pax(item_id);
