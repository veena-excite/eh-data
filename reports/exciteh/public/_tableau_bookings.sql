--tableau_bookings
DROP TABLE IF EXISTS tableau_bookings
;
CREATE TABLE tableau_bookings (
    id_tableau_item     serial PRIMARY KEY,
    item_type           varchar,
    id_item             integer,
    id_booking          integer,
    id_supplier         integer,
    is_packaged_rate    boolean,
    id_source           integer,
    id_user             integer,
    id_agent            integer,
    supplier            varchar,
    takeoff_contract    boolean,
    item_name           varchar,
    arrival             timestamp without time zone,
    departure           timestamp without time zone,
    product             varchar,
    product_subproduct  varchar,
    id_item_status      integer,
    is_booked_by_po     boolean,
    is_cancelled_by_po  boolean,
    is_paid_unavailable boolean,
    item_status         varchar,
    item_statusalias    varchar,
    id_client           integer,
    id_client_type      integer,
    id_client_ab        varchar,
    client_type         varchar,
    agent               varchar,
    agent_postal_code   varchar,
    id_headoffice       integer,
    agent_headoffice    varchar,
    agent_region        varchar,
    agent_country       varchar,
    agent_state         varchar,
    agent_city          varchar,
    agent_citydistrict  varchar,
    agent_user          varchar,
    is_preferred_agent  boolean,
    id_hotel            integer,
    stars               double precision,
    hotel_chain         varchar,
    room_description    varchar,
    account_owner       integer,
    email               varchar,
    region              varchar,
    country             varchar,
    state               varchar,
    city                varchar,
    citydistrict        varchar,
    agent_sales_area    varchar,
    lat                 double precision,
    lon                 double precision,
    cancelled_date      timestamp without time zone,
    paid_date           timestamp without time zone,
    confirmed_date      timestamp without time zone,
    payment_due_date    timestamp without time zone,
    instant_purchase_date timestamp without time zone,
    supplier_paid_date  timestamp without time zone,
    rewards_promotion   varchar,
    buy_price           numeric,
    buy_currency        varchar,
    supplier_price      numeric,
    supplier_currency   varchar,
    net_price           numeric,
    net_currency        varchar,
    commission_price    numeric,
    commission_currency varchar,
    gross_price         numeric,
    gross_currency      varchar,
    intelirates         boolean,
    cancellation_policy timestamp without time zone,
    ap_markup           real,
    ap_email_sent       timestamp without time zone,
    ap_qualified        timestamp without time zone,
    ap_expired          timestamp without time zone,
    created             timestamp without time zone,
    modified            timestamp without time zone,
    deleted             timestamp without time zone,
    fy2015_category     varchar,
    fy2015_subcategory  varchar,
    fy2015_value_paid   double precision,
    fy2015_number_paid  integer,
    hot_deal            varchar
);

--tableau_bookings:baskets
INSERT INTO tableau_bookings (
    item_type, id_item, id_booking, id_supplier, id_source, id_item_status,
    id_user, created, modified, deleted, arrival, departure,
    buy_price, buy_currency, supplier_price, supplier_currency, net_price,
    net_currency, commission_price, commission_currency, gross_price,
    gross_currency, intelirates, ap_markup, ap_email_sent, ap_qualified,
    ap_expired, takeoff_contract, item_status, cancelled_date, paid_date,
    confirmed_date, instant_purchase_date, cancellation_policy, agent_user,
    item_statusalias, payment_due_date, supplier_paid_date, hot_deal
)
    SELECT
        'basket'                    AS item_type,
        baskets.id_basket           AS id_item,
        id_booking                  AS id_booking,
        id_supplier                 AS id_supplier,
        id_source                   AS id_source,
        baskets.id_basket_status    AS id_item_status,
        baskets.id_user             AS id_user,
        baskets.created             AS created,
        baskets.modified            AS modified,
        baskets.deleted             AS deleted,
        arrival_date                AS arrival,
        departure_date              AS departure,
        buy_price                   AS buy_price,
        buy_currency                AS buy_currency,
        supplier_price              AS supplier_price,
        supplier_currency           AS supplier_currency,
        net_price                   AS net_price,
        net_currency                AS net_currency,
        commission_price            AS commission_price,
        commission_currency         AS commission_currency,
        gross_price                 AS gross_price,
        gross_currency              AS gross_currency,
        intelirates                 AS intelirates,
        ap_markup                   AS ap_markup,
        ap_email_sent               AS ap_email_sent,
        ap_qualified                AS ap_qualified,
        ap_expired                  AS ap_expired,
        takeoff_contract            AS takeoff_contract,
        get_human_readable_item_status(basket_status.name[1]) AS item_status,
        dates.datetime_cancelled    AS cancelled_date,
        dates.datetime_agent_paid   AS paid_date,
        dates.datetime_confirmed    AS confirmed_date,
        dates.datetime_instant_purchase AS instant_purchase_date,
        cancellationpolicy.date     AS cancellation_policy,
        agent_user.email            AS agent_user,
        statusaliases.name[1]       AS item_statusalias,
        baskets.payment_due_date AT TIME ZONE 'Australia/Sydney' AS payment_due_date,
        dates.datetime_supplier_paid AS supplier_paid_date,
        (CASE
            WHEN baskets.hot_deal = 1 THEN 'Hot deal'
            ELSE 'Not a hot deal'
        END)                        AS hot_deal
    FROM
        baskets
        LEFT JOIN basket_status ON baskets.id_basket_status = basket_status.id_basket_status
        LEFT JOIN tableau_dates AS dates ON dates.item_id = baskets.id_basket AND dates.item_type = 'basket'
        LEFT JOIN (
            SELECT id_basket, min(date) AT TIME ZONE 'Australia/Sydney' AS date
            FROM basket_cancel_policy
            WHERE NOT is_default_policy
            GROUP BY id_basket
        ) AS cancellationpolicy ON baskets.id_basket = cancellationpolicy.id_basket
        LEFT JOIN users AS agent_user ON agent_user.id_user = baskets.id_user
        LEFT JOIN statusaliases ON baskets.id_basket_status = ANY(statusaliases.id_basket_status)
    WHERE
        baskets.deleted IS NULL
;

--tableau_bookings:charges
INSERT INTO tableau_bookings (
    item_type, id_item, id_booking, id_supplier, id_source, id_item_status,
    id_user, created, modified, deleted, arrival, departure,
    buy_price, buy_currency, supplier_price, supplier_currency, net_price,
    net_currency, commission_price, commission_currency, gross_price,
    gross_currency, intelirates, ap_markup, ap_email_sent, ap_qualified,
    ap_expired, takeoff_contract, item_status, cancelled_date, paid_date,
    confirmed_date, instant_purchase_date, id_hotel, product, item_name,
    region, country, state, city, citydistrict, agent_user, item_statusalias,
    payment_due_date, supplier_paid_date, hot_deal
)
    SELECT
        'charge'                    AS item_type,
        charges.id_charges          AS id_item,
        id_booking                  AS id_booking,
        id_supplier                 AS id_supplier,
        NULL                        AS id_source,
        charges.id_charge_status    AS id_item_status,
        charges.id_user             AS id_user,
        charges.created             AS created,
        charges.modified            AS modified,
        charges.deleted             AS deleted,
        charges.date                AS arrival,
        charges.date_checkout       AS departure,
        buy_price                   AS buy_price,
        buy_currency                AS buy_currency,
        supplier_price              AS supplier_price,
        supplier_currency           AS supplier_currency,
        net_price                   AS net_price,
        net_currency                AS net_currency,
        commission_price            AS commission_price,
        commission_currency         AS commission_currency,
        gross_price                 AS gross_price,
        gross_currency              AS gross_currency,
        intelirates                 AS intelirates,
        ap_markup                   AS ap_markup,
        ap_email_sent               AS ap_email_sent,
        ap_qualified                AS ap_qualified,
        ap_expired                  AS ap_expired,
        TRUE                        AS takeoff_contract,
        get_human_readable_item_status(charge_status.name[1])
                                    AS item_status,
        dates.datetime_cancelled    AS cancelled_date,
        dates.datetime_agent_paid   AS paid_date,
        dates.datetime_confirmed    AS confirmed_date,
        dates.datetime_instant_purchase AS instant_purchase_date,
        charges.id_hotel            AS id_hotel,
        (CASE
            WHEN charge_type.name[1] = 'Activity' THEN 'Tour'
            ELSE charge_type.name[1]
        END)                        AS product,
        service_description         AS item_name,
        location.region             AS region,
        location.country            AS country,
        location.state              AS state,
        location.city               AS city,
        location.citydistrict       AS citydistrict,
        agent_user.email            AS agent_user,
        statusaliases.name[1]       AS item_statusalias,
        charges.payment_due_date AT TIME ZONE 'Australia/Sydney'
                                    AS payment_due_date,
        dates.datetime_supplier_paid AS supplier_paid_date,
        'Not a hot deal'            AS hot_deal
    FROM
        charges
        LEFT JOIN charge_status ON charges.id_charge_status = charge_status.id_charge_status
        LEFT JOIN charge_type ON charges.id_charge_type = charge_type.id_charge_type
        LEFT JOIN tableau_dates AS dates ON dates.item_id = charges.id_charges AND dates.item_type = 'charge'
        LEFT JOIN v_region_parts AS location ON location.id_region = charges.id_region
        LEFT JOIN users AS agent_user ON agent_user.id_user = charges.id_user
        LEFT JOIN statusaliases ON charges.id_charge_status = ANY(statusaliases.id_basket_status)
    WHERE
        charges.deleted IS NULL
;
CREATE INDEX ON tableau_bookings (item_type, id_item);
CREATE INDEX ON tableau_bookings (id_item_status);
CREATE INDEX ON tableau_bookings (id_booking);
CREATE INDEX ON tableau_bookings (id_user);
CREATE INDEX ON tableau_bookings (id_source);
CREATE INDEX ON tableau_bookings (created);
CREATE INDEX ON tableau_bookings (id_client);
CREATE INDEX ON tableau_bookings (id_supplier);

VACUUM ANALYZE tableau_bookings;
