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
    fiscal_period character(6)
);



-- the following needs modification for day range and for fiscal_period
with recursive days (fulldate) as
(
    select min(order_date) from orders
    union
    select fullDate + integer '1' from days
    where fullDate < (select max(order_date) from orders)
)

insert into DimensionDay (fullDate,month_name,month_abbr,quarter,year, fiscal_period)
select fullDate ,
    TO_CHAR (fullDate, 'Month') as month_name,
    TO_CHAR (fullDate, 'Mon') as month_abbr,
    extract (QUARTER from fullDate) as quarter,
    extract (YEAR from fullDate) as year,
    'FY' || extract(YEAR FROM fulldate) AS fiscal_period

--
-- need to get the fiscal period too
--
from days;


--


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

insert into DimensionEmployee (employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code, country, home_phone, reports_to)
select employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code, country, home_phone, reports_to
from employees;


--


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


--

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

--



DROP TABLE if exists Order_Facts;
CREATE TABLE Order_Facts(
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


--


SELECT category_name, product_name,
SUM( order_dollars ) AS "ORDER DOLLARS"
FROM DimensionDay, DimensionProduct, order_facts
WHERE
TRIM(month_name) = 'January' AND
year = 1997 AND
order_facts.day_key = DimensionDay.day_key AND
order_facts.product_key = DimensionProduct.product_key
GROUP BY DimensionProduct.category_name, DimensionProduct.product_name
ORDER BY DimensionProduct.category_name, DimensionProduct.product_name


--



SELECT c.category_name, p.product_name,
SUM( od.unit_price*od.quantity ) AS "ORDER DOLLARS"
FROM orders o inner join order_details od on (o.order_id = od.order_id)
inner join products p on (od.product_id = p.product_id)
inner join categories c on (p.category_id = c.category_id)
WHERE
extract(MONTH FROM order_DATE) = 1 and
extract(YEAR FROM order_DATE) = 1997
GROUP BY c.category_name, p.product_name
ORDER BY c.category_name, p.product_name


--


select dp.product_name, ofs.product_key, dp.category_id, dd.month_name, de.title, dc.country, ofs.order_dollars
FROM order_facts ofs INNER JOIN DimensionProduct dp ON ofs.product_key = dp.product_key
INNER JOIN Dimensionday dd on ofs.day_key = dd.day_key
INNER JOIN DimensionEmployee de on ofs.employee_key = de.employee_key
INNER JOIN DimensionCustomer dc on ofs.customer_key = dc.customer_key
WHERE dp.category_name = 'Beverages' and TRIM(dd.month_name) = 'April' and de.title = 'Sales Representative' and (dc.country = 'Germany' or dc.country = 'France')


SELECT sum(ofs.order_dollars) as total_sales
FROM order_facts ofs INNER JOIN DimensionProduct dp ON ofs.product_key = ndp.product_key
INNER JOIN Dimensionday dd ON ofs.day_key = dd.day_key
INNER JOIN DimensionEmployee de ON ofs.employee_key = de.employee_key
INNER JOIN DimensionCustomer dc ON ofs.customer_key = dc.customer_key
WHERE dp.category_name = 'Beverages' AND TRIM(dd.month_name) = 'April' AND de.title = 'Sales Representative' AND (dc.country = 'Germany' OR dc.country = 'France')




select * from order_facts

select * from DimensionProduct

select * from Dimensionday

select * from DimensionEmployee

select * from DimensionCustomer




select * from order_details

select * from categories

select * from products

select * from orders

select * from employees

select * from customers

select od.order_id, p.product_name, c.category_id, o.order_date, e.title, cu.country
from order_details od inner join products p on od.product_id = p.product_id
inner join categories c on p.category_id = c.category_id
inner join orders o on od.order_id = o.order_id
inner join employees e on o.employee_id = e.employee_id
inner join customers cu on o.customer_id = cu.customer_id 
where c.category_name = 'Beverages' and extract(MONTH from o.order_date) = 4 and e.title = 'Sales Representative' and (cu.country = 'Germany' or cu.country = 'France')


SELECT SUM(od.unit_price * od.quantity) as total_sales
FROM order_details od INNER JOIN products p ON od.product_id = p.product_id
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN orders o ON od.order_id = o.order_id
INNER JOIN employees e ON o.employee_id = e.employee_id
INNER JOIN customers cu ON o.customer_id = cu.customer_id 
WHERE c.category_name = 'Beverages' AND EXTRACT(MONTH from o.order_date) = 4 AND e.title = 'Sales Representative' AND (cu.country = 'Germany' OR cu.country = 'France')


-------------------------------------------NN
