CREATE TABLE "tableau_bookings_history" (
"snapshot_date" DATE NOT NULL,
"id_tableau_item" int,
"item_type" varchar (255) ,
"id_item" int,
"id_booking" int,
"id_supplier" int,
"is_packaged_rate" bool,
"id_source" int,
"id_user" int,
"id_agent" int,
"supplier" varchar (255) ,
"takeoff_contract" bool,
"item_name" varchar (255) ,
"arrival" timestamp,
"departure" timestamp,
"product" varchar (255) ,
"product_subproduct" varchar (255) ,
"id_item_status" int,
"is_booked_by_po" bool,
"is_cancelled_by_po" bool,
"is_paid_unavailable" bool,
"item_status" varchar (255) ,
"item_statusalias" varchar (255) ,
"id_client" int,
"id_client_type" int,
"id_client_ab" varchar (255) ,
"client_type" varchar (255) ,
"agent" varchar (255) ,
"agent_postal_code" varchar (255) ,
"id_headoffice" int,
"agent_headoffice" varchar (255) ,
"agent_region" varchar (255) ,
"agent_country" varchar (255) ,
"agent_state" varchar (255) ,
"agent_city" varchar (255) ,
"agent_citydistrict" varchar (255) ,
"agent_user" varchar (255) ,
"is_preferred_agent" bool,
"id_hotel" int,
"stars" float8,
"hotel_chain" varchar (255) ,
"room_description" varchar (255) ,
"account_owner" int,
"email" varchar (255) ,
"region" varchar (255) ,
"country" varchar (255) ,
"state" varchar (255) ,
"city" varchar (255) ,
"citydistrict" varchar (255) ,
"agent_sales_area" varchar (255) ,
"lat" float8,
"lon" float8,
"cancelled_date" timestamp,
"paid_date" timestamp,
"confirmed_date" timestamp,
"payment_due_date" timestamp,
"instant_purchase_date" timestamp,
"supplier_paid_date" timestamp,
"rewards_promotion" varchar (255) ,
"buy_price" numeric(18,2),
"buy_currency" varchar (255) ,
"supplier_price" numeric(18,2),
"supplier_currency" varchar (255) ,
"net_price" numeric(18,2),
"net_currency" varchar (255) ,
"commission_price" numeric(18,2),
"commission_currency" varchar (255) ,
"gross_price" numeric(18,2),
"gross_currency" varchar (255) ,
"intelirates" bool,
"cancellation_policy" timestamp,
"ap_markup" float4,
"ap_email_sent" timestamp,
"ap_qualified" timestamp,
"ap_expired" timestamp,
"created" timestamp,
"modified" timestamp,
"deleted" timestamp,
"fy2015_category" varchar (255) ,
"fy2015_subcategory" varchar (255) ,
"fy2015_value_paid" float8,
"fy2015_number_paid" int,
"hot_deal" varchar (255) 
)
