create database coffee_shop_sales_db;
use coffee_shop_sales_db;
select * from css;
describe css;
set sql_safe_updates = 0;
update css
set transaction_date = str_to_date(transaction_date, '%d-%m-%Y');
alter table css
modify column transaction_date date;

update css
set transaction_time = str_to_date(transaction_time, '%H:%i:%s');
alter table css
modify column transaction_time time;

alter table css
change column ï»¿transaction_id transaction_id int;

-- KPI's Requirements
# 1) Total sales analysis:
     -- Calculate total sales for each respective month
	
select round(sum(unit_price * transaction_qty)) as total_sales
from css
where
month(transaction_date) = 3;

	-- Determine the month on month increase or decrease in sales.
    
select month(transaction_date) as month,
		round(sum(unit_price * transaction_qty)) as total_sales,
		(sum(unit_price * transaction_qty) - lag(sum(unit_price * transaction_qty),1)
		over (order by month(transaction_date)))/ lag(sum(unit_price * transaction_qty),1)
		over (order by month(transaction_date)) * 100 as MOM_increase_percent
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);
    
    -- Calculate the difference in sales between selected month and previous month

select month(transaction_date) as month,
	   (sum(unit_price * transaction_qty) - lag(sum(unit_price * transaction_qty),1)
	    over (order by month(transaction_date))) as difference
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);
    
# 2) Total Order Analysis:
	-- Calculate the total number of orders for each respective month
    
select count(transaction_id) as Total_orders
from css
where month(transaction_date) = 5;
    
    -- Determine the month on month increase or decrease in number of orders

select month(transaction_date) as month,
	   round(count(transaction_id)) as Total_orders,
       (count(transaction_id) - lag(count(transaction_id),1)
       over (order by month(transaction_date)))/ lag(count(transaction_id),1)
       over (order by month(transaction_date))*100 as mom_increase_percent
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);

	-- Calcualte the difference in the number of orders between selected month n previous month
    
select month(transaction_date) as month,
	   (count(transaction_id) - lag(count(transaction_id),1)
       over (order by month(transaction_date))) as Difference_in_orders
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);

# 3) Total Quantity sold Analysis:
	-- Calculate the total quantity sold for each respective month
    
select sum(transaction_qty) as Total_qty_sold
from css
where
month(transaction_date) = 5;

	-- Determine the month on month increase or decrease in sales.
    
select month(transaction_date) as month,
	   sum(transaction_qty) as Total_qty_sold,
       (sum(transaction_qty) - lag(sum(transaction_qty),1)
       over (order by month(transaction_date))) / lag(sum(transaction_qty),1)
       over (order by month(transaction_date)) * 100 as mom_increase_percent
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);

	-- Calculate the difference in total quantity sold between selected month and previous month
    
select month(transaction_date) as month,
	   (sum(transaction_qty) - lag(sum(transaction_qty),1)
       over (order by month(transaction_date))) as Difference_in_qty_sold
from css
where
month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);

-- Chart Requirements
# 1) Calender Heat Map:
	-- First two will be done on Power BI
    -- Detailed matrics(sales, orders, qty) over specific day
    
select concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales,
	   concat(round(count(transaction_id)/1000,1),'k') as Total_Orders,
       concat(round(sum(transaction_qty)/1000,1),'k') as Total_qty
from css
where
transaction_date = '2023-02-27';

# 2) Sales Analysis by weekdays and weekends:
	-- weekends = sat, sun
    -- weekdays = mon, tue, wed, thur, fri
    -- For SQL sun = 1, mon = 2......sat = 7
    
select 
	case when dayofweek(transaction_date) in (1,7) then 'weekends'
    else 'weekdays'
    end as day_type,
    concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales
from css
where month(transaction_date) = 5
group by day_type;

# 3) Sales analysis by Store Location
	-- Sales data based on different location
    
select store_location,
	   concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales
from css
where month(transaction_date) = 5
group by store_location
order by Total_sales desc;

/*	-- Month on month increase in percenatge based on location

select month(transaction_date) as month,
		store_location,
		concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as total_sales,
		(sum(unit_price * transaction_qty) - lag(sum(unit_price * transaction_qty),1)
		over (order by month(transaction_date)))/ lag(sum(unit_price * transaction_qty),1)
		over (order by month(transaction_date)) * 100 as MOM_increase_percent
from css
where month(transaction_date) in (4,5) 
group by month(transaction_date), store_location
order by Total_sales;*/

# 4) Daily Sales analysis with Average line:

select 
	concat(round(avg(total_sales)/1000,1),'k') as Avg_sales
from(
		select sum(unit_price * transaction_qty) as total_sales
		from css
        where month(transaction_date) = 5
        group by transaction_date
) as inner_query;
		
select day(transaction_date) as day_of_month,
		sum(unit_price * transaction_qty) as total_sales
from css
where month(transaction_date) = 5
group by day_of_month
order by day_of_month;

SELECT 
    day_of_month,
    total_sales,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Equal to Average'
    END AS sales_status
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM css
    WHERE 
        MONTH(transaction_date) = 5  
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
    
# 5) Sales analysis by product categories:

select product_category,
	concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales
from css
where month(transaction_date) = 5
group by product_category
order by Total_sales desc;

# 6) Top 10 product by sales:

select product_type,
	concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales
from css
where month(transaction_date) = 5 and product_category = 'Coffee'
group by product_type
order by sum(unit_price * transaction_qty) desc
limit 10;

# 7) Sales analysis by Days and hour:
	-- For day of week
select concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales,
	   count(transaction_id) as Total_Orders,
       sum(transaction_qty) as Total_qty
from css
where month(transaction_date) = 5
and dayofweek(transaction_date) = 2
and hour(transaction_time) = 8;

	-- For hour of the day

select hour(transaction_time),
	   concat(round(sum(unit_price * transaction_qty)/1000,1),'k') as Total_sales
from css
where month(transaction_date) = 5
group by hour(transaction_time)
order by hour(transaction_time);













    
    
    
    
