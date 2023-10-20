--DAY Dimension, Figure 1-5 – modify this for range of days, and for the fiscal period
DROP TABLE IF EXISTS DimensionDay;
-- Day dimension as shown in Figure 1-5
CREATE TABLE IF NOT EXISTS DimensionDay
(
day_key serial primary key,
fullDate date ,
month_name character varying(20) ,
month_abbr character(3) ,
quarter integer ,
year integer ,
fiscal_period integer
);


-- the following needs modification for day range and for fiscal_period
with recursive days (fulldate) as
(
values (to_date('1997-01-01','YYYYMMDD'))
union
select fullDate + integer '1' from days
where fullDate < '1997-12-31'
)
-- to list values in days
--select fullDate,
--TO_CHAR (fullDate, 'Month') as month_name,
--TO_CHAR (fullDate, 'Mon') as month_abbr,
--extract (QUARTER from fullDate) as quarter,
--extract (YEAR from fullDate) as year
-- need to get the fiscal period too
--from days;
-- to insert rows into DimensionDay
insert into DimensionDay (fullDate,month_name,month_abbr,quarter,year)
select fullDate ,
TO_CHAR (fullDate, 'Month') as month_name,
TO_CHAR (fullDate, 'Mon') as month_abbr,
extract (QUARTER from fullDate) as quarter,
extract (YEAR from fullDate) as year
--
-- need to get the fiscal period too
--
from days;
select * from DimensionDay;



DROP TABLE IF EXISTS DimensionCustomer;
-- Day dimension as shown in Figure 1-5
CREATE TABLE IF NOT EXISTS DimensionCustomer
(
customer_key serial primary key,
customer_id character varying(5) NOT NULL,
company_name character varying(40) NOT NULL,
contact_name character varying(30),
contact_title character varying(30),
city character varying(15),
region character varying(15),
postal_code character varying(10),
country character varying(15),
phone character varying(24),
fax character varying(24)
);
insert into DimensionCustomer (customer_id, company_name, contact_name , contact_title , city ,
region , postal_code , country , phone , fax)
select customer_id, company_name, contact_name , contact_title , city , region , postal_code , country
, phone , fax
from customers;
select * from DimensionCustomer;



DROP TABLE IF EXISTS DimensionEmployee;
CREATE TABLE DimensionEmployee
(
employee_key serial primary key,
employee_id smallint NOT NULL,
last_name character varying(20) NOT NULL,
first_name character varying(10) NOT NULL,
title character varying(30),
title_of_courtesy character varying(25),
birth_date date,
hire_date date,
address character varying(60),
city character varying(15),
region character varying(15),
postal_code character varying(10),
country character varying(15),
home_phone character varying(24),
reports_to smallint
);
insert into DimensionEmployee (employee_id, last_name, first_name,
title, title_of_courtesy, birth_date, hire_date, address, city,
region, postal_code, country, home_phone, reports_to)
select employee_id, last_name, first_name,
title, title_of_courtesy, birth_date, hire_date, address, city,
region, postal_code, country, home_phone, reports_to
from employees;
select * from DimensionEmployee;


--Needs one row for each product
--This table is not normalized – it contains Category data too
--To generate a row a natural join Product x Category is performed
--(ok since only field in common is category_id)
--The result is inserted into the dimension
--Note the PK is automatically generated
drop table if exists DimensionProduct;
create table DimensionProduct (
product_key serial primary key,
product_id smallint ,
product_name character varying(40) ,
unit_price real,
category_id smallint ,
category_name character varying(15) ,
description text
);
insert into DimensionProduct (product_id, product_name, unit_price, category_id, category_name,
description)
select product_id, product_name, unit_price, c.category_id, category_name, description
from products p natural join categories c;
select * from DimensionProduct;



-- Create DimensionShipper
DROP TABLE IF EXISTS DimensionShipper;
CREATE TABLE IF NOT EXISTS DimensionShipper(
    shipper_key serial primary key,
    shipper_id smallint,
    company_name character varying(40),
    phone character varying(24)
);


INSERT INTO DimensionShipper (shipper_id, company_name, phone)
SELECT shipper_id, company_name, phone
FROM Shippers;


-- Order_Facts
DROP TABLE if exists order_facts;
CREATE TABLE IF NOT EXISTS order_facts(
product_key integer,
customer_key integer,
day_key integer,
quantity_ordered integer
);


INSERT INTO order_facts
SELECT p.product_key, c.customer_key,d.day_key, sum(quantity)
FROM order_details od
inner join DimensionProduct p on (p.product_id = od.product_id)
inner join orders o on (o.order_id = od.order_id)
inner join DimensionDay d on (o.order_date = d.fullDate)
inner join DimensionCustomer c on (o.customer_id = c.customer_id)
GROUP BY p.product_key, c.customer_key,d.day_key
;


-- shipment fact
DROP TABLE if exists shipment_facts;
CREATE TABLE IF NOT EXISTS shipment_facts(
product_key integer,
customer_key integer,
day_key integer,
shipper_key integer,
quantity_shipped integer
);


INSERT INTO shipment_facts
SELECT p.product_key, c.customer_key,d.day_key, s.shipper_key, sum(od.quantity) as quantity_shipped
FROM order_details od
inner join DimensionProduct p on (p.product_id = od.product_id)
inner join orders o on (o.order_id = od.order_id)
inner join DimensionDay d on (o.order_date = d.fullDate)
inner join DimensionShipper s on (o.ship_via = s.shipper_id)
inner join DimensionCustomer c on (o.customer_id = c.customer_id)
WHERE o.shipped_date IS NOT NULL
GROUP BY p.product_key, s.shipper_key, c.customer_key,d.day_key
;


--b
/* There is no problem running the queries but I don’t think 
that the result is correct. It is because if there are 
more than one records of a specific product_key being purchased 
or shipped, the full outer join will create duplication to match 
the join and the result will be exaggerated many time by using sum(). */

select coalesce(o.product_key, s.product_key) as pkey, 
sum(o.quantity_ordered) as ordered,
sum(s.quantity_shipped) as shipped
from order_facts as o full outer join shipment_facts as s
on (o.product_key=s.product_key)
group by pkey
order by pkey;

--c

WITH 
    o AS(
        SELECT product_key, sum(quantity_ordered) as ordered
        FROM order_facts 
        GROUP BY product_key
    ),
    s AS(
        SELECT product_key, sum(quantity_shipped) as shipped
        FROM shipment_facts
        GROUP BY product_key
    )
    SELECT COALESCE(o.product_key, s.product_key) as pkey, ordered, shipped
    FROM o FULL OUTER JOIN s ON (o.product_key = s.product_key)
    ORDER BY pkey







-- Recreate DimensionShipper
DROP TABLE IF EXISTS DimensionShipper;
CREATE TABLE IF NOT EXISTS DimensionShipper(
    shipper_key serial primary key,
    shipper_id smallint,
    company_name character varying(40),
    phone character varying(24),
    effective_date date,
    expiry_date date,
    is_current BOOLEAN
);



INSERT INTO DimensionShipper (shipper_id, company_name, phone, effective_date, expiry_date, is_current)
SELECT shipper_id, company_name, phone, '1999-01-01', '9999-12-31', true
FROM Shippers;


select * from DimensionShipper;




-- 2a

DROP TABLE IF EXISTS Changes;
CREATE TABLE IF NOT EXISTS changes(
    changes_key serial primary key,
    changes_id smallint,
    change_type character varying(10) CHECK(change_type = 'Update' or change_type = 'Insert'),
    change_date date,
    shipper_id smallint,
    company_name character VARYING(40),
    phone character varying(24)
);


INSERT INTO changes(changes_id, change_type, change_date, shipper_id, company_name, phone)
VALUES(1, 'Update', '2000-01-01', 1, 'Speedy aaa', '(503) 555-9831'),
(1, 'Insert', '2000-01-01', 7, 'Canada Post', '123-456-7890');


-- 2b

DROP FUNCTION IF EXISTS migrate_change();

CREATE OR REPLACE FUNCTION migrate_change()
RETURNS void as $$
DECLARE
change_row record;
BEGIN 
    
    FOR change_row IN (SELECT * FROM Changes) LOOP
        IF change_row.change_type = 'Update' THEN 

            UPDATE DimensionShipper
            SET is_current = FALSE, expiry_date = change_row.change_date
            WHERE shipper_id = change_row.shipper_id AND is_current = TRUE;
        END IF;

        INSERT INTO DimensionShipper (shipper_id, company_name, phone, effective_date, expiry_date, is_current)
        VALUES (change_row.shipper_id, change_row.company_name, change_row.phone, change_row.change_date, '9999-12-31', true);

    END LOOP;

    --
END;
$$ LANGUAGE plpgsql;


SELECT migrate_change();


select * from DimensionShipper;
