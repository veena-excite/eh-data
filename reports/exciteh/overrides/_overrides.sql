SET search_path to overrides,public
;
DROP VIEW IF EXISTS v_tableau_supplier_overrides
;
CREATE VIEW v_tableau_supplier_overrides AS
SELECT
    items.id_contract                                                                               AS id_contract,
    items.contract_name                                                                             AS contract_name,
    items.id_item                                                                                   AS id_item,
    items.item_type                                                                                 AS item_type,
    items.supplier_price                                                                            AS supplier_price,
    items.supplier_currency                                                                         AS supplier_currency,
    items.contract_value                                                                            AS contract_value,
    round(items.contract_value / items.contract_exchange_rate, 2)                                   AS contract_value_AUD,
    items.contract_total_value                                                                      AS contract_total_value,
    items.supplier_paid_date                                                                        AS supplier_paid_date,
    items.checkout_date                                                                             AS checkout_date,
    items.contract_exchange_rate                                                                    AS contract_exchange_rate,
    array_to_string(
        ARRAY[
            items.override_currency,
            to_char(lower(override_contract_tiers.range), 'FM999,999,999'),
            'to',
            items.override_currency,
            coalesce(to_char(upper(override_contract_tiers.range), 'FM999,999,999'), '∞')
        ]::varchar[],
        ' '
    )                                                                                               AS tier_description,
    calculate_override_rate(items.id_contract, contract_total_value) / 100                          AS tier_rate,
    calculate_override_rate(items.id_contract, contract_total_value) * contract_value / 100         AS override_value,
    round(
        (calculate_override_rate(items.id_contract, contract_total_value) * contract_value / 100 / items.contract_exchange_rate)::numeric,
        2
    )                                                                                               AS override_value_AUD,
    items.override_currency                                                                         AS override_currency
FROM (
    SELECT
        override_contracts.id_contract                                          AS id_contract,
        override_contracts.name                                                 AS contract_name,
        tableau_bookings.id_item                                                AS id_item,
        tableau_bookings.item_type                                              AS item_type,
        supplier_price                                                          AS supplier_price,
        supplier_currency                                                       AS supplier_currency,
        round(supplier_price * exchangerate_b.value / exchangerate_a.value, 2)  AS contract_value,
        SUM(round(supplier_price * exchangerate_b.value / exchangerate_a.value, 2)) OVER (PARTITION BY override_contracts.id_contract) AS contract_total_value,
        override_contracts.currency                                             AS override_currency,
        tableau_dates.date_supplier_paid                                        AS supplier_paid_date,
        date(departure)                                                         AS checkout_date,
        exchangerate_override_contract.value                                    AS contract_exchange_rate
    FROM
        public.tableau_bookings
        JOIN override_contracts
            ON tableau_bookings.id_supplier = ANY(override_contracts.id_supplier)
            AND override_contracts.daterange @> tableau_bookings.departure::date
        LEFT JOIN public.tableau_dates
            ON tableau_dates.item_id = tableau_bookings.id_item
            AND tableau_dates.item_type = tableau_bookings.item_type

        -- exchangerate_a: supplier_currency -> AUD
        -- if supplier has: been paid      on the date the supplier was paid
        --                  not been paid  yesterday's date
        JOIN public.currencyhistorical AS exchangerate_a
            ON date(exchangerate_a.created AT TIME ZONE 'Australia/Sydney') = coalesce(tableau_dates.date_supplier_paid, now()::date - 1)
            AND exchangerate_a.iso = supplier_currency
        -- exchangerate_b: AUD -> override currency
        -- if supplier has:  been paid      on the date the supplier was paid
        --                   not been paid  yesterday's date
        JOIN public.currencyhistorical AS exchangerate_b
            ON date(exchangerate_b.created AT TIME ZONE 'Australia/Sydney') = coalesce(tableau_dates.date_supplier_paid, now()::date - 1)
            AND exchangerate_b.iso = override_contracts.currency

        -- exchangerate_override_contract
        -- if the contract:  is still going  yesterday's date
        --                   has finished    the contract end date
        LEFT JOIN public.currencyhistorical AS exchangerate_override_contract
            ON ((
                    now()::date > upper(override_contracts.daterange)::date
                    AND exchangerate_override_contract.created::date = upper(override_contracts.daterange)
                )
                OR (
                    now()::date <= upper(override_contracts.daterange)::date
                    AND exchangerate_override_contract.created::date = now()::date - 1
                )
            )
            AND exchangerate_override_contract.iso = override_contracts.currency
    WHERE
        item_statusalias = 'paid'
) AS items
LEFT JOIN override_contract_tiers
ON items.id_contract = override_contract_tiers.id_contract
AND override_contract_tiers.range @> items.contract_total_value::integer
;
drop table if exists x_supplier_overrides 
;
create table x_supplier_overrides as 
select * from v_tableau_supplier_overrides
;
select count(*) from x_supplier_overrides
