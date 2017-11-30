-- select count(*) from (
select 
basket_hotel_reference.id_hotel,

suppliers.name[1] as supplier,
products.text[1] as product,

tableau_rewards.promos as rewards_promotion,

tableau_dates.datetime_cancelled    AS cancelled_date,
tableau_dates.datetime_agent_paid   AS paid_date,
tableau_dates.datetime_confirmed    AS confirmed_date,
tableau_dates.datetime_instant_purchase AS instant_purchase_date,
tableau_dates.datetime_supplier_paid AS supplier_paid_date,

--get_human_readable_item_status(basket_status.name[1]) AS item_status,
-- statusaliases.name[1]       AS item_statusalias,
-- cancellationpolicy.date     AS cancellation_policy,
-- agent_user.email            AS agent_user,
-- 
t.*
from tableau_baskets t
LEFT JOIN tableau_dates 					ON tableau_dates.item_id = t.id_item AND t.item_type = tableau_dates.item_type
left join tableau_rewards 				on tableau_rewards.id_item=t.id_item and tableau_rewards.item_type=t.item_type
left join suppliers using(id_supplier) 
left join products using(id_product) 
left join basket_hotel_reference using(id_basket)

where id_booking = 2947115

-- ) s

