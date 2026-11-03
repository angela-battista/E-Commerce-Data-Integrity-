-- check for nulls
select name + ' IS NULL' from sys.columns
where object_id = OBJECT_ID('dbo.order_items') and is_nullable = 1

select 'SELECT * FROM dbo.order_items WHERE '
		+ STRING_AGG(
			name + ' IS NULL', ' OR ')
FROM sys.columns
where object_id = OBJECT_ID('dbo.order_items') AND is_nullable = 1
SELECT * FROM dbo.order_items WHERE order_item_id IS NULL OR order_id IS NULL OR product_name IS NULL OR category IS NULL OR quantity IS NULL OR unit_price IS NULL
-- no nulls order_items table



select name + 'IS NULL' from sys.columns
where object_id = OBJECT_ID('dbo.customers') and is_nullable = 1

select 'SELECT * FROM dbo.customers WHERE '
		+ STRING_AGG(
			name + ' IS NULL', ' OR ')
FROM sys.columns
where object_id = OBJECT_ID('dbo.customers') AND is_nullable = 1

SELECT * FROM dbo.customers WHERE customer_id IS NULL OR customer_name IS NULL OR email_domain IS NULL OR signup_date IS NULL OR region IS NULL
-- no nulls customers tables

select name + ' IS NULL' from sys.columns
where object_id = OBJECT_ID('dbo.returns') and is_nullable = 1

select 'SELECT * FROM dbo.returns WHERE '
		+ STRING_AGG(
			name + ' IS NULL', ' OR ')
FROM sys.columns
where object_id = OBJECT_ID('dbo.returns') AND is_nullable = 1
 
SELECT * FROM dbo.returns WHERE return_id IS NULL OR order_id IS NULL OR return_date IS NULL OR return_type IS NULL OR return_reason_desc IS NULL OR refund_amount IS NULL
-- no nulls returns table

select name + ' IS NULL' from sys.columns
where object_id = OBJECT_ID('dbo.orders') and is_nullable = 1

select 'SELECT * FROM dbo.orders WHERE '
		+ STRING_AGG(
			name + ' IS NULL', ' OR ')
FROM sys.columns
where object_id = OBJECT_ID('dbo.orders')
	AND is_nullable = 1

SELECT * FROM dbo.orders WHERE order_id IS NULL OR customer_id IS NULL OR order_date IS NULL OR order_status IS NULL
-- 25 nulls customer_id in orders table


Select count(*) from dbo.orders 

--Create a copy of orders before updating table
Select count(*) from dbo.orders 

CREATE TABLE orders_copy LIKE dbo.orders
insert into order_copy select * from dbo.orders

--Update 25 nulls to 0
SELECT ISNULL(customer_id, 0) FROM dbo.orders
Update dbo.orders
	Set customer_id = ISNULL(customer_id, 0)

--check for dups based on key
select customer_id, count(*) as dup
from dbo.customers
group by customer_id
having count(*)>1
-- no dups in customer table

select order_id, order_item_id, count(*) as dup
from dbo.order_items
group by order_id, order_item_id
having count(*)>1
-- no dups in order_items table

select order_id, count(*) as dup
from dbo.orders
group by order_id
having count(*)>1
-- 5 dups in orders

--Remove dups from orders
DELETE T
FROM
(
SELECT *
, DupRank = ROW_NUMBER() OVER (
              PARTITION BY order_id
              ORDER BY (SELECT NULL)
            )
FROM dbo.orders
) AS T
WHERE DupRank > 1

 
select order_id, return_id, count(*) as dup
from dbo.returns
group by order_id, return_id
having count(*)>1
-- No dups in returns table

-- standardize region column in customers table
select * from dbo.customers

UPDATE dbo.customers
SET region = CASE
        WHEN region = 'SE' THEN 'Southeast'
        WHEN region = 'SW' THEN 'Southwest'
        ELSE UPPER(LEFT(region, 1)) + LOWER(SUBSTRING(region, 2, LEN(region))) 
    END
FROM 
    dbo.customers;

select * from dbo.customers

select r.return_id, o.order_id, CAST(r.return_date AS DATE) AS rdate, r.return_reason_desc, r.refund_amount, CAST(o.order_date AS DATE) AS odate
INTO orphaned_returns
from dbo.returns as r
left join dbo.orders as o
on r.order_id = o.order_id
where o.order_id IS NULL

select * from orphaned_returns

select r.return_id, o.order_id, CAST(r.return_date AS DATE) AS rdate, r.return_reason_desc, r.refund_amount, CAST(o.order_date AS DATE) AS odate
INTO dbo.matched_returns
from dbo.returns as r
inner join dbo.orders as o
on r.order_id = o.order_id

select * from dbo.matched_returns

-- orders that have a return date before the order date
WITH order_return_dates AS (
    SELECT
        r.return_id,
        r.order_id,
        r.return_date,
        o.order_date
    FROM returns r
    JOIN orders o ON r.order_id = o.order_id
)
SELECT *
FROM order_return_dates
WHERE return_date < order_date

-- top customers with most returns
with cust_return_orders AS (
select c.customer_name
from returns r
join orders o on r.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
)
select top(5)*, count(customer_name) as total 
from cust_return_orders
group by customer_name
order by count(customer_name) desc

-- most item returned
with most_item_returned AS (
select r.return_date, r.return_reason_desc, r.Refund_amount, r.return_type, i.product_name, i.category
from returns r
join order_items as i ON r.order_id = i.order_id
)
select product_name, count(product_name) as total from most_item_returned
group by product_name
order by count(product_name) DESC