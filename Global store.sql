set sql_safe_updates = 0;
-- retrieve the first 5 records in dataset
select *
from retail
limit 5;

-- confirm number of records in dataset (representative of total of products ordered NOT sales quantity)
select count(*)
from retail;

-- total number of orders placed
select count(distinct(Order_ID), customer_id) as total_orders
from retail;

-- total sales quantity
select
	sum(quantity) as sales_quantity
from retail;

-- total quantity of items per order_ID
select
	order_id,
    customer_id,
    sum(quantity) as total_order_quantity
from retail
group by customer_id,order_id;

-- total number of unique products sold
select
    count(distinct product_id, product_name) as product_variations_total
from retail;

-- number of customers the store has
select
	count(distinct customer_id) as total_customers
from retail;

-- add total_order_quantity as a column in the retail table
create table total_quantity as
with total_quantity as(
	select
		order_id,
        customer_id,
		sum(quantity) as total_order_quantity
	from retail
	group by order_id,customer_id)
select * from total_quantity;

alter table retail
add column total_order_quantity int;

update retail as r
join total_quantity as tq
on r.order_id = tq.order_id and r.customer_id = tq.customer_id
set r.total_order_quantity = tq.total_order_quantity;

drop table total_quantity;

-- confirm the data was imputed correctly, both queries below should have the same output
select sum(total_order_quantity) as toq
from (select distinct order_id,customer_id,total_order_quantity from retail) as orders;

select sum(quantity)
from retail;

#### TEMPORAL SALES ANALYSIS
-- get earliest and most recent order dates
select
	min(order_date) as earliest_order,
    max(order_date) as recent_order
from retail;

-- get the time period between earliest and recent orders
select
	datediff(max(order_date), min(order_date)) as time_range_days
from retail;

-- get sales totals by year
select
	year(order_date) as year,
    sum(quantity) as total_sales
from retail
group by year
order by year asc;

-- get revenue by year
select
	year(order_date) as year,
    round(sum(sales),2) as total_revenue
from retail
group by year
order by year asc;

-- get profit by year
select
	year(order_date) as year,
    round(sum(profit),2) as total_profit
from retail
group by year
order by year asc;

-- aggregated profit and revenue by month
select
	month(order_date) as month,
    round(sum(sales), 2) as total_revenue,
    round(sum(profit), 2) as total_profit
from retail
group by month;

-- get profit trends by month/year
select
	year(order_date) as year,
    month(order_date) as month,
    round(sum(profit),2) as total_profit
from retail
group by month,year
order by month,year asc;

-- get sales by category by months
select
	category,
    month(order_date) as months,
    sum(quantity) as total_sales
from retail
group by category, months;

-- get the best performing sub category (sales) by months 
with sub_category_sales as(
select
	sub_category,
    month(order_date) as months,
	sum(quantity) as total_sales,
    rank() over(partition by month(order_date) order by sum(quantity) desc) as rn
from retail
group by months, sub_category)
select
	sub_category,
    months,
    total_sales,
    rn
from sub_category_sales
where rn = 1;

-- worst performing sub_category (sales) by months
with sub_category_sales as(
select
	sub_category,
    month(order_date) as months,
	sum(quantity) as total_sales,
    rank() over(partition by month(order_date) order by sum(quantity) desc) as rn
from retail
group by months, sub_category)
select
	sub_category,
    months,
    total_sales,
    rn
from sub_category_sales
where rn = 17;

-- get sales trends by sub category over the months of the year
with sub_category_sales as(
select
	sub_category,
    month(order_date) as months,
	sum(quantity) as total_sales,
    rank() over(partition by month(order_date) order by sum(quantity) desc) as rn
from retail
group by months, sub_category)
select
	sub_category,
    months,
    total_sales,
    rn
from sub_category_sales;

-- get revenue trends by sub_category over months
with sub_category_revenue as(
select
	sub_category,
    month(order_date) as months,
	round(sum(sales),2) as sales_revenue,
    rank() over(partition by month(order_date) order by sum(sales) desc) as rn
from retail
group by months, sub_category)
select
	sub_category,
    months,
    sales_revenue,
    rn
from sub_category_revenue;

-- get sub category P&L over months of year
with sub_category_profit as(
select
	sub_category,
    month(order_date) as months,
	round(sum(profit),2) as total_profit,
    rank() over(partition by month(order_date) order by sum(profit) desc) as rn
from retail
group by months, sub_category)
select
	sub_category,
    months,
    total_profit,
    rn
from sub_category_profit
where rn = 1;

#### GEOGRAPHICAL SALES ANALYSIS
-- retrieve markets
select
	distinct(market)
from retail;

-- retrieve countries
select
	distinct(Country)
from retail;

-- number of countries by market
select
	market,
	count(distinct(country)) as countries_by_market
from retail
group by market;

-- sales vs customers by market
select
	market,
    sum(quantity) as total_sales,
    count(distinct(customer_id)) as total_customers
from retail
group by market;

-- top 10 performing countries by sales
select
	country,
    sum(quantity) as total_sales
from retail
group by country
order by total_sales desc
limit 10;

-- top 10 performing countries by consumers
select
	country,
    count(distinct(customer_id)) as total_consumers
from retail
group by country
order by total_consumers desc
limit 10;

-- top 10 performing countries by sales per category
select
	category,
	country,
    sum(quantity) as total_sales
from retail
where category = 'Office Supplies'
group by country
order by total_sales desc
limit 10;

select
	category,
	country,
    sum(quantity) as total_sales
from retail
where category = 'Furniture'
group by country
order by total_sales desc
limit 10;

select
	category,
	country,
    sum(quantity) as total_sales
from retail
where category = 'Technology'
group by country
order by total_sales desc
limit 10;

-- find top performing cities by sales
select
	city,
    sum(quantity) as total_sales
from retail
group by city
order by total_sales desc
limit 10;

-- top 10 performing cities by sales per category
select
	category,
	city,
    sum(quantity) as total_sales
from retail
where category = 'Office Supplies'
group by city
order by total_sales desc
limit 10;

select
	category,
	city,
    sum(quantity) as total_sales
from retail
where category = 'Furniture'
group by city
order by total_sales desc
limit 10;

select
	category,
	city,
    sum(quantity) as total_sales
from retail
where category = 'Technology'
group by city
order by total_sales desc
limit 10;

-- top selling product by market
with products as(
select
	market,
    product_id,
    product_name,
    sum(quantity) as product_sales,
    rank() over(partition by market order by sum(quantity) desc) as rn
from retail
group by product_name,product_id, market)
select
	market,
    product_name,
    product_id,
    product_sales,
    rn
from products
where rn = 1;

-- top 10 most profitable cities
select
	city,
    round(sum(profit),2) as total_profit
from retail
group by city
order by total_profit desc
limit 10;

#### FINANCIAL PERFORMANCE ANALYSIS (INCLUSIVE OF P&L)

-- total sales revenue
select
	round(sum(sales),2) as sales_revenue
from retail;

-- total gross profit
select
	round(sum(profit),2) as gross_profit
from retail;

-- overall profit margin
select
	round(sum(profit) / sum(sales),2) *100 as profit_margin
from retail;

-- sales revenue by sub_category
select
	sub_category,
	round(sum(sales),2) as sales_revenue
from retail
group by sub_category
order by sales_revenue desc;

-- sales revenue by product
select
    product_name,
    product_id,
    sub_category,
    round(sum(sales),2) as sales_revenue
from retail
group by product_name,product_id,sub_category
order by sales_revenue desc
limit 10;

-- profit by sub_category
select
	sub_category,
	round(sum(profit),2) as total_profit
from retail
group by sub_category
order by total_profit desc;

-- profit by product
select
    product_name,
    product_id,
    sub_category,
    round(sum(profit),2) as total_profit
from retail
group by product_name,product_id,sub_category
order by total_profit desc
limit 10;

-- sub category profit margins
select
    sub_category,
    round((sum(profit) / sum(sales)* 100),2) as profit_margin,
    round(avg(profit),2) as avg_sc_profit
from retail
group by sub_category
order by profit_margin desc;

-- product with best gross profit margin
select
    product_name,
    product_id,
    round((sum(profit) / sum(sales)* 100),2) as profit_margin
from retail
group by product_name, product_id
order by profit_margin desc
limit 10;

-- product with highest loss margin
select
    product_name,
    product_id,
    round((sum(profit) / sum(sales)* 100),2) as loss_margin
from retail
group by product_name, product_id
order by loss_margin asc
limit 10;

-- sub category based discount relation to profit and sales quantity
select
	sub_category,
    avg(discount) as discount_avg,
    round(sum(profit),2) as total_profit,
    sum(quantity) as sales_quantity
from retail
group by sub_category
order by discount_avg desc;

-- shipping cost avg by sub category
select
	sub_category,
	round(avg(shipping_cost),2) as shipping_cost_avg
from retail
group by sub_category
order by shipping_cost_avg desc;

#### CUSTOMER SEGMENTATION ANALYSIS
-- customer segment
select
	segment,
    count(distinct customer_id) as total_customers
from retail
group by segment
order by total_customers desc;

-- segments sales quantity & financial analysis (p&l, discounts)
select
	segment,
    sum(quantity) as sales_quantity,
    round(sum(profit),2) as total_profit,
    round((sum(profit) / sum(sales)* 100),2) as profit_margin,
    round(avg(discount) * 100, 2) as discount_avg
from retail
group by segment;

-- customers with highest quantity of ordered items
select
    distinct customer_id,
    customer_name,
    country,
    total_order_quantity
from retail
order by total_order_quantity desc
limit 10;

#### LOGISTICS ANALYSIS
-- orders by shipmode vs average costs
select
	ship_mode,
    count(distinct(order_id), customer_id) as orders_per_shipmode,
    round(avg(shipping_cost),2) as shipping_cost_avg
from retail
group by ship_mode;

-- avg dispatch duration
select
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail;

-- top 10 slowest dispatch duration countries
select
	country,
    sum(quantity) as sales_quantity,
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail
group by country
order by avg_dispatch_time desc
limit 10;

-- top 10 fastest dispatch duration countries
select
	country,
    sum(quantity) as sales_quantity,
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail
group by country
order by avg_dispatch_time asc
limit 10;

-- dispatch durations for countries with most sales
select
	country,
    sum(quantity) as sales_quantity,
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail
group by country
order by sales_quantity desc
limit 10;

-- avg dispatch duration by order priority
select
	order_priority,
    sum(quantity) as sales_quantity,
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail
group by order_priority;

-- avg dispatch duration by ship mode
select
	ship_mode,
    sum(quantity) as sales_quantity,
	round(avg(datediff(ship_date, order_date))) as avg_dispatch_time
from retail
group by ship_mode;