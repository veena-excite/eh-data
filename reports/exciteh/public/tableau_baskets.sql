drop table if exists tableau_baskets
;
create table tableau_baskets as
SELECT 
'basket'::varchar      			AS item_type,
baskets.id_basket           AS id_item,
baskets.id_basket           AS id_basket,
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
baskets.payment_due_date AT TIME ZONE 'Australia/Sydney' AS payment_due_date,
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
-- (CASE WHEN baskets.hot_deal = 1 THEN 'Hot deal' ELSE 'Not a hot deal' END)                        AS hot_deal,
id_product
FROM baskets
WHERE baskets.deleted IS NULL
