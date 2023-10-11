DAY Dimension, Figure 1-5 – modify this for range of days, and for the fiscal period
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







DROP TABLE if exists Order_Facts;
CREATE TABLE Order_Facts(
product_key integer,
customer_key integer,
day_key integer,
quantity_ordered integer
);


INSERT INTO Order_Facts
SELECT p.product_key, c.customer_key,d.day_key,
sum(quantity)
FROM order_details od
inner join DimensionProduct p on (p.product_id = od.product_id)
inner join orders o on (o.order_id = od.order_id)
inner join DimensionDay d on (o.order_date = d.fullDate)
inner join DimensionCustomer c on (o.customer_id = c.customer_id)
GROUP BY p.product_key, c.customer_key,d.day_key
;
select * from order_facts



DROP TABLE if exists Shipment_Facts;
CREATE TABLE Shipment_Facts(
product_key integer,
employee_key integer,
customer_key integer,
day_key integer,
quantity_ordered integer,
order_dollars real
);


INSERT INTO Order_Facts
SELECT p.product_key, e.employee_key, c.customer_key,d.day_key,
sum(quantity), sum(quantity*od.unit_price)
FROM order_details od
inner join DimensionProduct p on (p.product_id = od.product_id)
inner join orders o on (o.order_id = od.order_id)
inner join DimensionDay d on (o.order_date = d.fullDate)
inner join DimensionEmployee e on (o.employee_id = e.employee_id)
inner join DimensionCustomer c on (o.customer_id = c.customer_id)
GROUP BY p.product_key, e.employee_key, c.customer_key,d.day_key
;
select * from order_facts;