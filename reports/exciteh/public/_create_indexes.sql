CREATE INDEX ON baskets (id_user);
CREATE INDEX ON baskets (id_basket);
create index on baskets(id_basket_linked) ;
create index on charges (id_charges) ;
CREATE INDEX ON hotels (id_hotel);
CREATE INDEX ON hotels (id_hotelchainaffiliate);
CREATE INDEX ON suppliers(id_supplier);
CREATE INDEX ON users (id_user);
CREATE INDEX ON bookings_sp(id_basket);
CREATE INDEX ON bookings_sp(id_charges);

CREATE INDEX ON sources(id_source);
CREATE INDEX ON log_bookings (date(created AT TIME ZONE 'Australia/Sydney'));
CREATE INDEX ON log_bookings (id_charges);
CREATE INDEX ON log_bookings (id_status_to);
create index on log_itemprices (id_basket);
create index on log_itemprices (created);
create index on users(email);

