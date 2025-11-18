
---------------- pizza project -------------------

create table order_details(order_details_id int,
                           order_id int, 
                           pizza_id varchar(50), 
                           quantity int)
bulk insert order_details
from 'C:\Users\utkar\Desktop\pizza sql project\pizza_sales\order_details.csv'
with(
     fieldterminator = ',',
     rowterminator = '\n',
     firstrow = 2,
     format = 'csv'
    );
 ----------------------------------------------

create table orders(order_id int,
                    date date,
                    time time)

bulk insert orders
from 'C:\Users\utkar\Desktop\pizza sql project\pizza_sales\orders.csv'
with(
    fieldterminator = ',',
    rowterminator = '\n',
    firstrow = 2,
    format = 'csv'
   );

--------------------------------------------------------------
drop table pizza_types
create table pizza_types(pizza_type_id varchar(70),
                         name varchar(60),
                         category varchar(20),
                         ingredients varchar(100)
                         );

bulk insert pizza_types
from 'C:\Users\utkar\Desktop\pizza sql project\pizza_sales\pizza_types.csv'
with(
     fieldterminator = ',',
     rowterminator = '\n',
     firstrow = 2,
     format = 'csv'
     );

--------------------------------------------------------------------------

create table pizzas(pizza_id varchar(40),
                    pizza_type_id varchar(50),
                    size varchar(10),
                    price decimal(10,2)
                    );

bulk insert pizzas
from 'C:\Users\utkar\Desktop\pizza sql project\pizza_sales\pizzas.csv'
with(
     fieldterminator = ',',
     rowterminator = '\n',
     firstrow = 2,
     format = 'csv'
     );

----------------------------- Basic QUESTIONS---------------------------

--1. Retrieve the total number of orders placed.
select count(order_id) as total_orders
from orders

--2. Calculate the total revenue generated from pizza sales.
select * from orders
select * from pizzas

select round(sum(order_details.quantity * pizzas.price),0) as total_revenue
from order_details
join pizzas
on order_details.pizza_id = pizzas.pizza_id

--3. Identify the highest-priced pizza.
select top 1 pizza_types.name, pizzas.price as highest_price
from pizza_types 
join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc;

--4. Identify the most common pizza size ordered.

select pizzas.size,count(order_details.order_details_id) as total_count
from pizzas 
join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size
order by total_count desc;

select p.size,count(o.order_details_id) as total_count
from pizzas p 
join order_details o
on p.pizza_id = o.pizza_id
group by p.size
order by total_count desc;

--4. List the top 5 most ordered pizza types along with their quantities.

select top 5 pizza_types.name,sum(order_details.quantity) as total_order
from pizza_types 
join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name
order by total_order desc;


select top 5 pt.name,sum(o.quantity) as quantity
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details o
on o.pizza_id = p.pizza_id
group by pt.name
order by quantity desc;

----Intermediate questions-------

--1. Join the necessary tables to find the total quantity of each pizza category ordered.
select pizza_types.category, sum(order_details.quantity) as quantity
from pizza_types
join pizzas
on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category
order by quantity desc;

--2. Determine the distribution of orders by hour of the day.
select 
format(datepart(hour,time),'00') as hour_of_day,count(order_id) as order_count
from orders
group by datepart(hour,time)
order by datepart(hour,time);

--3. Join relevant tables to find the category-wise distribution of pizzas.
select category, count(name) as distribution from pizza_types
group by category;

--4. Group the orders by date and calculate the average number of pizzas ordered per day.
select avg(quantity) as average_quantity
from
    (select 
            o.date, 
            sum(od.quantity) as quantity
     from orders o
     join order_details od
     on o.order_id = od.order_id
     group by o.date) 
as order_quantity;

--5. Determine the top 3 most ordered pizza types based on revenue.
select top 3 pt.name, 
format(sum(od.quantity * p.price),'C','en-In') as revenue
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.name
order by revenue desc;

-------------------ADVANCE QUESTIONS----------------

--1. Calculate the percentage contribution of each pizza type to total revenue.
with category_revenue as (
select pt.category, 
sum(od.quantity * p.price) as revenue
from pizza_types pt
join pizzas p 
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.category)

select category,
format(revenue,'C','en-In') as revenue,
format(revenue * 100.0/ sum(revenue) over(), 'N2') + '%' as percentage
from category_revenue
order by  revenue desc;

--2. Analyze the cumulative revenue generated over time.
with daily_revenue as (
select 
     cast(o.date as date) as order_date,
     sum(od.quantity * p.price) as revenue
from order_details od
join pizzas p
on od.pizza_id = p.pizza_id
join orders o
on o.order_id = od.order_id
group by cast(o.date as date)
)
select order_date,
       revenue,
       sum(revenue) over(order by order_date rows between unbounded preceding and current row)
       as cumulative_revenue
from daily_revenue
order by order_date;


--3. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select category, 
       name, 
       revenue, 
       rank() over(partition by category order by revenue desc) as rn
from
(select pt.category,
        pt.name,
        sum(od.quantity * p.price) as revenue
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od 
on od.pizza_id = p.pizza_id
group by pt.category,pt.name) as a;


with pizza_revenue as (
select 
       pt.category,
       pt.name,
       sum(od.quantity * p.price) as revenue,
       rank() over(partition by pt.category order by sum(od.quantity * p.price) desc
) as rn
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.category, pt.name
)
select category,
       name,
       revenue
from pizza_revenue
where rn <= 3
order by category,revenue desc;














