use pizzasalesproject;
select * from pizza_sales;

-- Describing the table
describe pizza_sales;

-- Let's make changes to the data types
alter table pizza_sales
add column converted_order_date date;
alter table pizza_sales
drop column converted_order_date;

alter table pizza_sales
rename column pizza_Smallize to pizza_size;

-- Checking for duplicates using CTEs
with pizzaCTE as(select *, row_number() over(
                  partition by pizza_id, order_id, pizza_name_id, 
                  quantity, order_date, order_time, 
                  unit_price, pizza_smallize, pizza_category, 
                  pizza_ingredients,pizza_name
                  order by pizza_smallize desc) 
                  as row_num from pizza_sales)
select * from pizzaCTE where row_num > 1;

-- Checking for null values in the table
select 'pizza_id' as column_name, count(*) as null_column
from pizza_sales where pizza_id is null union
select 'order_id' as column_name, count(*) as null_column
from pizza_sales where order_id is null union
select 'pizza_name_id' as column_name, count(*) as null_column
from pizza_sales where pizza_name_id is null union
select 'quantity' as column_name, count(*) as null_column
from pizza_sales where quantity is null union
select 'order_date' as column_name, count(*) as null_column
from pizza_sales where order_date is null union
select 'order_time' as column_name, count(*) as null_column
from pizza_sales where order_time is null union
select 'unit_price' as column_name, count(*) as null_column
from pizza_sales where unit_price is null union
select 'total_price' as column_name, count(*) as null_column
from pizza_sales where total_price is null union
select 'pizza_Smallize' as column_name, count(*) as null_column
from pizza_sales where pizza_size is null union
select 'pizza_category' as column_name, count(*) as null_column
from pizza_sales where pizza_category is null union
select 'pizza_ingredients' as column_name, count(*) as null_column
from pizza_sales where pizza_ingredients is null union
select 'pizza_name' as column_name, count(*) as null_column
from pizza_sales where pizza_name is null;

-- Checking for redundancy in the pizza_sales data
select distinct* from pizza_sales;

-- DATA MANIPULATION
-- Creating Key Performance Indicators
select * from pizza_sales;

-- Total Revenue sold
select cast(sum(total_price) as decimal(10,2)) as total_revenue 
from pizza_sales;
 -- Total Order
 select count(distinct order_id) as Total_order 
 from pizza_sales;
 
  -- Average order value
 select cast(sum(total_price) as decimal(10,2)) as total_price, 
 count(distinct order_id) as total_orders, 
 convert(cast(sum(total_price) as decimal(10,2))/ 
 count(distinct order_id), decimal(10,2)) 
 as average_Order_Value 
 from pizza_sales;
 
 -- Total number of pizza sold in the year 2022
 select sum(quantity) as Total_pizza_sold 
 from pizza_sales;
 
 -- Average Pizza per order
 select cast(sum(quantity)/count(distinct order_id) 
 as decimal(10,2)) as Average_pizza_order
 from pizza_sales;
 
 -- Fetch three pizza from each pizza category mostly sold by the restaurant
select * from (select p.*, row_number() 
over(partition by pizza_category order by quantity desc) as 
pizza_row from pizza_sales p) x 
where x.pizza_row < 4;

-- Top three pizza mostly sold according to their size
select * from (select p.*, row_number() 
over (partition by pizza_size order by total_price desc) as pizza_row_size
from pizza_sales p) x where x.pizza_row_size <4;

-- Top three pizza names from each category giving the highest revenue
select * from( select p.*, rank() 
               over(partition by pizza_category 
               order by total_price desc) as pizza_ranking 
               from pizza_sales p) x 
where x.pizza_ranking < 4;

-- The increase of total revenue of pizza categories
select pizza_name,order_date, pizza_size, pizza_category, 
max(total_price) - min(total_price) as revenue_difference,
case when max(total_price) - min(total_price) > 35 then 'revenue increased'
     when max(total_price) - min(total_price) between 20 and 34 then 'revenue is average'
     when max(total_price) - min(total_price) < 19 then 'revenue improved'
     else 'revenue reduced'
end as revenue_increase
from pizza_sales group by  pizza_name, pizza_size, pizza_category, order_date
order by pizza_name desc;

 -- The most ordered pizza under each category
 select * from pizza_sales;
 select *, first_value(pizza_name) over(
           partition by pizza_category 
           order by order_id desc) as most_pizza_ordered
 from pizza_sales;
 
-- All top 10 products constituting the first 50% of data based on total price of the pizza sales table using cume_dist
-- creating cumulative distribution percentage
select *, cume_dist() over(order by total_price desc) as cum_distribution, 
round(cume_dist ()  over(order by total_price desc) * 100, 3) as perc_cumul_dist
from pizza_sales order by perc_cumul_dist desc;
-- use a subquery to get 30%
select *, (perc_cumul_dist ||'%') as perc_cumul_dist
from (select *, cume_dist() over(order by total_price desc) as cum_distribution, 
      round(cume_dist ()  over(order by total_price desc) * 100, 3) as perc_cumul_dist
	  from pizza_sales) x where x.perc_cumul_dist <=20;

-- Daily trend for total orders
select * from pizza_sales;
select dayname(str_to_date(order_date, '%m/%d/%y')) as order_date, 
count(distinct order_id) as Total_orders,
cast(sum(total_price) as decimal(10,0)) as total_sales_rev 
from pizza_sales
group by dayname(str_to_date(order_date, '%m/%d/%y'))
order by Total_orders desc;

-- Creating views
create or replace view total_orders as 
select dayname(str_to_date(order_date, '%m/%d/%y')) as order_date, 
count(distinct order_id) as Total_orders, cast(sum(total_price) as decimal(10,0)) as total_sales_rev
from pizza_sales
group by dayname(str_to_date(order_date, '%m/%d/%y'))
order by Total_orders desc;

select * from pizzasalesproject.total_orders;

-- Monthly of total orders
select monthname(str_to_date(order_date, '%m/%d/%y')) as Monthly_orders,
count(distinct order_id) as Monthly_Total_Orders
from pizza_sales 
group by monthname(str_to_date(order_date, '%m/%d/%y'))
order by Monthly_Total_Orders desc;

-- Creating monthly orders view
create or replace view monthly_total_orders as
select monthname(str_to_date(order_date, '%m/%d/%y')) as Monthly_orders,
count(distinct order_id) as Monthly_Total_Orders,
cast(sum(total_price) as decimal(10,0)) as total_monthly_sales
from pizza_sales group by monthname(str_to_date(order_date, '%m/%d/%y'))
order by Monthly_Total_Orders desc;

-- Calling the view
select * from pizzasalesproject.monthly_total_orders;

-- Monthly trend in terms of revenue
select monthname(str_to_date(order_date, '%m/%d/%y')) as Monthly_revenue,
cast(sum(total_price) as decimal(10,0)) as total_monthly_revenue
from pizza_sales
group by monthname(str_to_date(order_date, '%m/%d/%y'))
order by total_monthly_revenue desc;

-- Creating monthly trend view
create or replace view Monthly_revenue as 
select monthname(str_to_date(order_date, '%m/%d/%y')) as Monthly_revenue,
cast(sum(total_price) as decimal(10,0)) as total_monthly_revenue
from pizza_sales
group by monthname(str_to_date(order_date, '%m/%d/%y'))
order by total_monthly_revenue desc;

 
-- Top five best sellers by quantity, revenue and Orders in terms of size and category
select * from pizza_sales;
-- Quantity
select pizza_name, pizza_size, pizza_category, 
sum(quantity) as Total_quantity_sold 
from pizza_sales 
where month(str_to_date(order_date, '%m/%d/%y')) = 7
group by pizza_name, pizza_size, pizza_category
order by Total_quantity_sold desc
limit 5;

-- Total orders
select pizza_name, pizza_size, pizza_category, 
count(distinct order_id) as Total_pizza_ordered 
from pizza_sales 
group by pizza_name, pizza_size, pizza_category
order by Total_pizza_ordered desc
limit 5;
-- Total Revenue
select pizza_name, pizza_size, pizza_category, 
cast(sum(total_price) as decimal(10,2)) as Total_revenue 
from pizza_sales 
group by pizza_name, pizza_size, pizza_category
order by Total_revenue desc
limit 5;

-- Bottom five worst sellers by quantity, revenue and Orders in terms of size and category
select * from pizza_sales;
-- Quantity
select pizza_name, pizza_size, pizza_category, 
sum(quantity) as Total_quantity_sold 
from pizza_sales 
group by pizza_name, pizza_size, pizza_category
order by Total_quantity_sold asc
limit 5;

-- Total orders
select pizza_name, pizza_size, pizza_category, 
count(distinct order_id) as Total_pizza_ordered 
from pizza_sales 
group by pizza_name, pizza_size, pizza_category
order by Total_pizza_ordered asc
limit 5;

-- Total Revenue
select pizza_name, pizza_size, pizza_category, 
convert(sum(total_price), decimal(10,2))as Total_revenue 
from pizza_sales 
group by pizza_name, pizza_size, pizza_category
order by Total_revenue asc
limit 5;

-- Pizza names that have been ordered more than 1000 times in year
select * from pizza_sales;
select pizza_name, pizza_category, 
count(pizza_name) as Most_ordered_pizza
from pizza_sales 
group by pizza_name, pizza_category
having count(pizza_name) > 1000
order by Most_ordered_pizza desc
limit 10;

-- Creating most_ordered_pizza view
create or replace view most_ordered_pizza as
select pizza_name, pizza_category, 
count(pizza_name) as Most_ordered_pizza
from pizza_sales 
group by pizza_name, pizza_category
having count(pizza_name) > 1000
order by Most_ordered_pizza desc
limit 10;

-- Sales Percentage in terms of pizza category
select pizza_category, cast(sum(total_price) as decimal(10,2)) as total_sales, 
convert(sum(total_price) / (select sum(total_price) 
					from pizza_sales) * 100, decimal(10,2)) as Sales_percentage
from pizza_sales 
group by pizza_category order by sales_percentage desc;

-- Creating a view
create or replace view categ_sales_perc
as select pizza_category, cast(sum(total_price) as decimal(10,2)) as total_sales, 
convert(sum(total_price) / (select sum(total_price) 
					from pizza_sales) * 100, decimal(10,2)) as Sales_percentage
from pizza_sales 
group by pizza_category order by sales_percentage desc;

-- Percentage of sales by pizza size
select pizza_size, cast(sum(total_price) as decimal(10,2)) as Total_sales, 
convert(sum(total_price) / (select sum(total_price) 
                    from pizza_sales) * 100, decimal(10,2)) as size_sales_percentage
from pizza_sales
group by pizza_size 
order by size_sales_percentage desc;

-- Creating the view
create or replace view pizzasize_sales_perc as
select pizza_size, cast(sum(total_price) as decimal(10,2)) as Total_sales, 
convert(sum(total_price) / (select sum(total_price) 
                    from pizza_sales) * 100, decimal(10,2)) as size_sales_percentage
from pizza_sales
group by pizza_size 
order by size_sales_percentage desc;

-- Calling the view
select * from pizzasalesproject.pizzasize_sales_perc;