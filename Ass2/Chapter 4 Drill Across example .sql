 c-- EXAMPLE FROM CHAPTER 4		

-- Using names order_facts1 and shipment_facts1
-- to avoid conflict with other tables in database

drop table if exists order_facts1;

create table order_facts1(
	day_key integer,
	customer_key integer,
	product_key integer,
	quantity_ordered integer
);

drop table if exists shipment_facts1;

create table shipment_facts1(
	day_key integer,
	customer_key integer,
	product_key integer,
	quantity_shipped integer
);

insert into order_facts1 (day_key, customer_key, product_key, quantity_ordered)
values
	(123, 777, 111, 100),
	(123, 777, 222, 200),
	(123, 777, 333, 50);

insert into shipment_facts1 (day_key, customer_key, product_key, quantity_shipped)
values
	(456, 777, 111, 100),
	(456, 777, 222, 75),
	(789, 777, 222, 125);

---------------------------------------------------------------------
-- this full outer join FAILS
-- ... double counts product 222 giving total of 400
-- ....................................should be 200
-- see next query for correct result
select coalesce(o.product_key, s.product_key) as pkey, 
sum(o.quantity_ordered) as ordered,
sum(s.quantity_shipped) as shipped
from order_facts1 as o full outer join shipment_facts1 as s
on (o.product_key=s.product_key)
group by pkey;

---------------------------------------------------------------------
-- do two separate temporary grouping queries
-- outer join the results
with 
Ordered_Sums as (
	select o.product_key as pkey, 
	sum(o.quantity_ordered) as ordered
	from order_facts1 as o 
	group by pkey),

Shipped_Sums as (
	select s.product_key as pkey, 
	sum(s.quantity_shipped) as shipped
	from shipment_facts1 as s 
	group by pkey)
-- now, use the two results directly above
select coalesce(o.pkey, s.pkey) as pkey
, ordered, shipped
from Ordered_Sums as o full outer join Shipped_Sums as s 
on (o.pkey=s.pkey)
order by pkey;

------------------------------------------------------------------------------------
-- similar to the above but uses derived tables in the FROM clause

SELECT COALESCE ( orders_query.product_key, shipments_query.product_key) as pkey, 
orders_query.quantity_ordered, shipments_query.quantity_shipped 

FROM 
( 
	SELECT o.product_key, SUM (o.quantity_ordered) as quantity_ordered 
	FROM order_facts1 as o
	group by o.product_key
) 
orders_query 

FULL OUTER JOIN 
( 
	SELECT s.product_key, SUM (s.quantity_shipped) as quantity_shipped 
	FROM shipment_facts1 as s
	group by s.product_key
) 
shipments_query 

ON orders_query.product_key = shipments_query.product_key
order by pkey;
