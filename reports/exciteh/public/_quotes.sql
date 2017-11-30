
--quotations
update tableau_bookings
set 
net_price = s.net_price,
net_currency= s.net_currency
from (
SELECT
	"t".id_booking,
	"t".id_item,
	t.item_type,
	q.net_price,
	q.net_currency,
	q.commission_price,
	q.commission_currency,
	q.gross_price,
	q.gross_currency,
	q.supplier_price,
	q.supplier_currency,
	q.buy_currency,
	q.buy_price
	FROM
	"public".baskets_quote AS q
	INNER JOIN "public".tableau_bookings AS "t" ON q.id_basket = "t".id_item
	WHERE q.deleted is null
	and t.item_type = 'basket'
	and item_statusalias = 'quotation'
	and t.net_price is null
--	and "t".id_booking = 2332709
) s 
where tableau_bookings.id_item=s.id_item
and tableau_bookings.id_booking=s.id_booking
and tableau_bookings.item_type = 'basket'
and tableau_bookings.item_statusalias = 'quotation'
;