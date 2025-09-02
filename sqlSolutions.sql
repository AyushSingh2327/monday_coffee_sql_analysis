--Monday Coffee --Data Analysis
Select * from city;
Select * from products;
Select * from customers;
Select * from sales;

--reports and data analysis

--q1 Coffee Consumers Count
--how many people in each city are estimated to consume coffee,given that 25% of the population does?
select
city_name,
round((population*0.25)/1000000,2) as coffee_consumers_in_millions,
city_rank
from city
order by 2 desc;

--q2 total revenue from coffee sales
--what is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

Select 
   ci.city_name,
   SUM(s.total) as total_revenue
from sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
where
  extract(year from s.sale_date) =2023
  and
  extract(quarter from s.sale_date)=4
Group by ci.city_name 
order by 2 desc;

--q3 sales count for each product
--how many units of each coffee product have been sold?

select
 p.product_name,
 COUNT(s.sale_id) as total_orders
from products as p
left join
sales as s
on s.product_id=p.product_id
group by p.product_name
order by 2 desc;

--q4 average sales amount per city
--what is the average sales amount per customer in each city?

Select 
   ci.city_name,
   SUM(s.total) as total_revenue,
   COUNT(DISTINCT s.customer_id) as total_customer,
   ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cust
from sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
Group by ci.city_name 
order by 2 desc;

--q5 city population and coffee consumers(25%)
--provide a list of cities along with their populations and estimated coffee consumers.
--return city_name,total current cx,estimated coffee consumers(25%)
with city_table as
(
select 
   city_name,
   ROUND((population*0.25)/1000000,2) as coffee_consumers
 from city
 ),
 customers_table
 as
 (select
   ci.city_name,
   COUNT(DISTINCT c.customer_id) as unique_cx
 from sales as s
 join customers as c
 on c.customer_id=s.customer_id
 join city as ci
 on ci.city_id=c.city_id
 group by 1
 )
 select  
  ct.city_name,
  ct.coffee_consumers as coffee_consumer_in_millions,
  cit.unique_cx
 from city_table as ct
 join
 customers_table as cit
 on cit.city_name=ct.city_name;

 --q6 top selling products by city
 --What are the top 3 selling products in each city based on sales volume?

Select * from
(
select
    ci.city_name,
	p.product_name,
	count(s.sale_id) as total_orders,
	dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank
from sales as s
join products as p
on s.product_id=p.product_id
join customers as c
on c.customer_id=s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2
)as t1
where rank <=3;

--q7 customer segmentation by city
--how many unique customers are there in each city who have purchased coffee products?

select
  ci.city_name,
  count(distinct c.customer_id) as unique_cx
from city as ci
left join
customers as c
on c.city_id=ci.city_id
join sales as s
on s.customer_id=c.customer_id
where
  s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;

--q8 average sale vs rent
--find each city and their average sale per customer and avg rent per customer
with city_table
as
(
Select 
   ci.city_name,
   COUNT(DISTINCT s.customer_id) as total_customer,
   ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cust
   
from sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
Group by 1
order by 2 desc
),
city_rent
as
(select
  city_name,
  estimated_rent
 from city
 )
select
 cr.city_name,
 cr.estimated_rent,
 ct.total_customer,
 ct.avg_sale_pr_cust,
 ROUND
 (cr.estimated_rent::numeric/ct.total_customer::numeric,2) as avg_rent_per_customer
from city_rent as cr
join city_table as ct
on cr.city_name=ct.city_name
order by 4 desc;

--q9 monthly sales growth
--sales groeth rate:calcultae the percentage growth(or decline)in sales over diff time periods(monthly)
--by each city
with
monthly_sales
as
(select
ci.city_name,
extract(month from sale_date) as month,
extract(year from sale_date)as year,
sum(s.total) as total_sale
from sales as s
join customers as c
on c.customer_id=s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2,3
order by 1,2,3
),
growth_ratio
as
(
select
city_name,
month,
year,
total_sale as cr_month_sale,
lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
from monthly_sales
)
select
city_name,
month,
year,
cr_month_sale,
last_month_sale,
round((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric*100,2)
as growth_ratio
from growth_ratio
where
last_month_sale is not null;

--q10
--market potential analysis
--identify top 3 city based on highest sales,return city name,total sale,total rent,total cutomers,estimated coffee consumer

with city_table
as
(
Select 
   ci.city_name,
   sum(s.total)as total_revenue,
   COUNT(DISTINCT s.customer_id) as total_customer,
   ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cust
   
from sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
Group by 1
order by 2 desc
),
city_rent
as
(select
  city_name,
  estimated_rent,
  round((population*0.25)/1000000,2) as estimated_coffee_consumer_in_millions
 from city
 )
select
 cr.city_name,
 total_revenue,
 cr.estimated_rent as total_rent,
 ct.total_customer,
 estimated_coffee_consumer_in_millions,
 ct.avg_sale_pr_cust,
 ROUND
 (cr.estimated_rent::numeric/ct.total_customer::numeric,2) as avg_rent_per_customer
from city_rent as cr
join city_table as ct
on cr.city_name=ct.city_name
order by 2 desc;
/*
recommendation

City1: Pune
 1)Avg rent per cx is very less
 2)highest total revenue
 3)avg_sale_per cx is also very high
 
City2: Delhi
 1)Highest estimated coffee consumer which is 7.7M
 2)Highest total cx which is 68
 3)avg rent per cx is 330(still under 500)
 
City3:Jaipur
 1)Highest number of customers which is 69
 2)avg rent per cx is very less 156
 3)avg sale per cx is better which at 11.6k 
