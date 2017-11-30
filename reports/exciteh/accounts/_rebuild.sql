SET search_path TO accounts
;
drop table if exists s_items
;
create table s_items as
select 
b.id_booking,
b.id_basket as id_item,

b.net_price::decimal(18,2) as amount,
b.net_currency,
b.gross_price::decimal(18,2) as gross_price,
coalesce(b.departure_date,b.arrival_date)::date as service_date,
'basket'::varchar(255) as item_type,
true as is_active,
id_basket_status as id_item_status,
s.status_backoffice as item_status,
left(t.item_name,32) as item_name,

b.id_supplier,

b.supplier_price                  AS supplier_price,
b.supplier_currency               AS supplier_currency,

b.booking_supplier as supplier_reference
FROM
public.baskets b
left join status s on b.id_basket_status = s.id_item_status
left join public.tableau_bookings t on b.id_basket = t.id_item and t.item_type='basket'
where  b.id_basket_status NOT IN (90,80,5,53) AND b.deleted IS NULL
--and b.id_booking = 2363642
;
insert into s_items
select
charges.id_booking,
charges.id_charges as id_item,

charges.net_price::decimal(18,2) as amount,
charges.net_currency,
charges.gross_price::decimal(18,2) as gross_price,
coalesce(charges.date_checkout,charges.date)::date as service_date,
'charge' as item_type,
true as is_active,
charges.id_charge_status,
s.status_backoffice as item_status,
left(charges.service_description,32) as item_name,

charges.id_supplier,

charges.supplier_price                  AS supplier_price,
charges.supplier_currency               AS supplier_currency,

charges.reference_number as supplier_reference

FROM "public".charges
LEFT JOIN public.baskets linked_basket ON charges.id_basket_linked = linked_basket.id_basket
LEFT JOIN public.charges linked_charge ON charges.id_charge_linked = linked_charge.id_charges
--join bookings i using(id_booking)
left join status s on charges.id_charge_status = s.id_item_status
WHERE (charges.id_charge_status NOT IN (90,80,5,53) OR charges.id_charge_status IS NULL)
AND charges.deleted IS NULL
AND CASE WHEN charges.id_charge_type = 11 THEN
(linked_basket.id_basket_status NOT IN (90,5) OR linked_basket.id_basket_status IS NULL)
AND (linked_charge.id_charge_status NOT IN (90,5) OR linked_charge.id_charge_status IS NULL)
ELSE true
END
--and charges.id_booking = 2363642
;
select count(*) from public.charges a
left join s_items b on a.id_charges = b.id_item and b.item_type='charge'
where b.id_item is null
;
insert into s_items
select
charges.id_booking,
charges.id_charges as id_item,

charges.net_price::decimal(18,2) as amount,
charges.net_currency,
charges.gross_price::decimal(18,2) as gross_price,
coalesce(charges.date_checkout,charges.date)::date as service_date,
'charge' as item_type,
false as is_active,
charges.id_charge_status,
s.status_backoffice as item_status,
left(charges.service_description,32) as item_name,

charges.id_supplier,

charges.supplier_price                  AS supplier_price,
charges.supplier_currency               AS supplier_currency,

charges.reference_number as supplier_reference

FROM "public".charges
left join status s on charges.id_charge_status = s.id_item_status
left join s_items b on charges.id_charges = b.id_item and b.item_type='charge'
where b.id_item is null
and charges.deleted is NULL
;
insert into s_items
select 
b.id_booking,
b.id_basket as id_item,

b.net_price::decimal(18,2) as amount,
b.net_currency,
b.gross_price::decimal(18,2) as gross_price,
coalesce(b.departure_date,b.arrival_date)::date as service_date,
'basket'::varchar(255) as item_type,
false as is_active,
id_basket_status as id_item_status,
s.status_backoffice as item_status,
left(t.item_name,32) as item_name,

b.id_supplier,

b.supplier_price                  AS supplier_price,
b.supplier_currency               AS supplier_currency,

b.booking_supplier as supplier_reference
FROM
public.baskets b
left join status s on b.id_basket_status = s.id_item_status
left join public.tableau_bookings t on b.id_basket = t.id_item and t.item_type='basket'
left join s_items r on b.id_basket = r.id_item and r.item_type='basket'
where r.id_item is null
and b.deleted IS NULL
;
update s_items set item_status = 'no_status' where item_status IS NULL
;
select is_active,count(*)
from s_items
group by 1
;
select is_active,item_type,count(*)
from s_items
group by 1,2
;
select max(created) from public.payments
;
drop table if exists s_payments
;
create table s_payments as select * from public.payments
;
drop table if exists s_payment_items
;
create table s_payment_items as 
SELECT id_payment,'basket' as item_type,id_basket as id_item,price_type,id_booking from public.payment_baskets b
left join s_items t on b.id_basket=t.id_item where t.item_type='basket' and b.deleted is null
union all
SELECT id_payment,'charge' as item_type,id_charge as id_item,price_type,id_booking from public.payment_charges c
left join s_items t on c.id_charge =t.id_item where t.item_type='charge' and c.deleted is null
;
drop table if exists t_payment_item_agg
;
create table t_payment_item_agg as
select id_booking,id_payment,
string_agg(distinct price_type::varchar,',') as price_type,
string_agg(distinct id_item::varchar,',') as id_items 
from s_payment_items
group by 1,2
;
select count(*) from s_payments 
where created >= '2017-07-01'
;
drop table if exists payments cascade
;
create table payments as
SELECT
"p".id_booking,
"p".id_payment,
"p".reference as transaction_id,
case when refund is not null then -"p".amount::decimal(18,2) else "p".amount::decimal(18,2) end as amount,
"p".currency,
"p".created::date AS "payment_date",
pi.id_items::varchar,
case when refund is not null then 'Refund' else 'Payment' end::varchar(32) as payment_type,
pt.provider,

"p".reference,
"p".reference as source,
"p".gateway,
pi.price_type::varchar,

"p"."comment"::varchar,
"p".refund as refund_date

FROM s_payments AS "p"
LEFT JOIN payment_types AS pt using(id_payment_type)
LEFT JOIN t_payment_item_agg as pi using(id_payment)
where id_payment_status in (1)
and p.deleted is null
and p.is_internal_dummy is null
and p.amount != 0
and created >= '2017-07-01'
--and p.id_booking in (select id_booking from filter)
ORDER BY 1,2
;
update payments set payment_type = 'commission' where provider = 'Paid Commission' ;
update payments set payment_type = 'switch' where payment_type != 'switch' and provider = 'SWITCH' ;
update payments set payment_type = 'switch' where payment_type != 'switch' and lower(reference)  ~ 'switch' ;
update payments set payment_type = 'switch_from' where payment_type = 'switch' and amount < 0 ;
update payments set payment_type = 'switch_to' where payment_type = 'switch' and amount >= 0 ;
update payments set payment_type = 'redeem_rewards' where provider ~ 'Redeem' ;

--create table payments_backup as select * from payments
update payments set transaction_id = null, source = null ;
update payments set reference = lower(reference);
update payments set reference = replace(reference,'-',' ') ;
update payments set reference = replace(reference,'master card','mastercard') ;
update payments set  source = 'eNett' where provider = 'eNett'
;
update payments set  
transaction_id = regexp_replace(reference,'.*(\d+)\\s+(visa|mastercard|american express|diners club).+','$1'),
source = regexp_replace(reference,'.*(\d+)\\s+(visa|mastercard|american express|diners club).+','$2')
where reference ~ '.*(\d+)\\s+(visa|mastercard|american express|diners club).+'
;
-- update payments set 
-- transaction_id = regexp_replace(reference,'^e?(\d+)$','$1')
-- where regexp_instr(reference,'^e?(\d+)$') =1
-- ;
update payments set source = 'credit card' where provider ='CREDIT CARD' and source is null ;
update payments set transaction_id = '_NO REFERENCE' where reference is null ;

update payments set transaction_id = 'E'||"reference" where "reference" ~ '^\d+$' and provider = 'eNett' ;
update payments set transaction_id = upper("reference") where "reference" ~ '^e\d+$' and provider = 'eNett' ; 

update payments set transaction_id = "reference" where "reference" ~ '^\d+$' and transaction_id is null ;
update payments set transaction_id = "reference" where "reference" ~ '^\d+/\d$' and transaction_id is null and provider = 'payment gate' ;

update payments set transaction_id = '_BAD' where transaction_id is null and reference is not null and reference != '';
update payments set source = 'Visa' where source = 'visa';
update payments set source = 'MasterCard' where source = 'mastercard';
update payments set source = 'American Express' where source = 'american express';
--update payments set source = 'Visa' where source = 'visa';

alter table payments add primary key (id_payment);
;

drop view if exists v_summary
;
create view v_summary as
select provider,payment_date,currency,sum(amount) as net_price
from accounts.payments
group by 1,2,3
order by 1,2,4
;

drop table if exists reward_items
;
create table reward_items as
select b.id_booking,a.* from public.rewarditems a
left join "public".baskets b on a.item_id=b.id_basket
--where item_id = 1911398
;
create index on reward_items (id_booking);
create index on reward_items (item_id);
;
select * from s_payments limit 10
;
select max(payment_date) from v_summary
