--SUPPLIERS:
SET search_path to lookups,public
;
--NEW SUPPLIERS FOUND:>0
select distinct supplier from public.tableau_bookings where id_supplier not in (select id_supplier from lookups.suppliers)
;
--NEW SUPPLIERS INSERTED:>0
insert into suppliers
select id_supplier,supplier,'Other','PostPaid','_Unclassified','Regular'
from (
	select distinct id_supplier,supplier 
	from public.tableau_bookings 
	where id_supplier not in (select id_supplier from lookups.suppliers)
	and id_supplier is not null 
) s
;
select distinct supplier from public.tableau_bookings where id_supplier not in (select id_supplier from lookups.suppliers)
;
--select * from suppliers  order by id_supplier desc limit 1
