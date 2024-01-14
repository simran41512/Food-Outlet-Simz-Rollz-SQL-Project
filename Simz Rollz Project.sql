Create database Project_1;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

Use Simz_rolls;

--1. How many rolls were ordered?
Select count(roll_id) as total_rolls_ordered from customer_orders;

--2. How many customers  ordered rolls?
Select count(distinct customer_id) as number_of_customers from customer_orders;

--3. How many  orders were successfully delivered by each driver?
Select driver_id, count(order_id) as successfully_delivered_orders from driver_order 
where cancellation  not in ('cancellation','customer cancellation')
group by driver_id;

--4. How many each type of rolls were delivered?
with no_of_rolls_sold as (
Select roll_id,count(roll_id) as count_of_rolls from customer_orders where order_id in  (
Select order_id from(
Select * , case
when cancellation in ('Cancellation','Customer Cancellation') then 'c' 
else 'nc' end  as order_cancel_details
from driver_order) as a 
where order_cancel_details='nc') group by roll_id)
Select r.roll_id,r.roll_name,count_of_rolls from no_of_rolls_sold
join rolls r on r.roll_id=no_of_rolls_sold.roll_id ;

--5. How many veg and non-veg rolls  were ordered by each customer?
with customer_rolls_prefference as (
Select customer_id,roll_id,count(roll_id) as number_of_rolls from customer_orders 
group by customer_id,roll_id )
Select customer_id,r.roll_id,r.roll_name,number_of_rolls from customer_rolls_prefference c 
join rolls r on r.roll_id=c.roll_id
order by customer_id;

--6. What was the maximum number of rolls delivered in single delivery?
Select * from (
Select * , rank() over(order by number_of_rolls desc) as rnk from (
Select order_id, count(roll_id) as number_of_rolls from(
Select * from customer_orders where order_id in ( 
Select order_id from 
(Select *, case 
when cancellation in ('Cancellation','Customer Cancellation') then 'c'
else 'nc' end as order_cancel_details 
from driver_order)as a where order_cancel_details='nc'))as b group by order_id)as b) 
 as c where rnk=1 ;

 --7. For each Customer , how many rolls delivered had a change or no change?
with extra_items as (
Select customer_id,extra_items_included as e,not_include_items as n from customer_orders 
where order_id in (
Select order_id from (
Select *, case 
when cancellation in ('Cancellation','Customer Cancellation') then 'c'
else 'nc' end as order_cancel_details 
from driver_order) as a where order_cancel_details='nc') )
Select customer_id,modifications,count(modifications) as number_of_modifications from (
Select customer_id, e ,
n ,
case 
when e is not null and e<>'NaN' and e<>'' then 'yes'
when n is not null and n<>'NaN' and n<>'' then 'yes'
else 'no' end as modifications
from extra_items) as k group by customer_id, modifications;

--8. How many rolls were delivered which had both inclusions and extras?
With temp_table as (
Select order_id,roll_id,not_include_items as n,extra_items_included as e from customer_orders 
where order_id in (
Select order_id from (
Select *, case 
when cancellation in ('Cancellation','Customer Cancellation') then 'c'
else 'nc' end as order_cancel_details 
from driver_order) as a where order_cancel_details='nc'))
Select modifications,count(roll_id) as number_of_modified_rolls_sold from (
Select *, case 
when n is not null and n<>'' and n<>'NaN' then 'yes'
when e is not null and e<>'' and e<>'NaN' then 'yes'
else 'no' end as modifications from temp_table) as m  group by modifications;

--9. What was the total number of rolls ordered each hour?
Select time_stamps ,count(time_stamps) as rolls_sold_each_hour from (
Select *, concat(cast(datepart(hour,order_date)as varchar) ,'-',
cast(datepart(hour,order_date)+1 as varchar)) as time_stamps from customer_orders)as y
group by time_stamps;

--10. What was the number of orders for each day of the week?
Select day_of_week,count(distinct order_id) as number_of_orders from (
Select *,datename(dw,order_date) as day_of_week from customer_orders) as d 
group by day_of_week;

--11. What was the average  distance travelled for  each customer?
Select customer_id, round((sum(_distance_)/count(order_id)),2) as average_distance from(
Select customer_id , round(cast(dd as decimal),2) as _distance_, order_id from (
Select c.customer_id, d.distance,replace(d.distance,'km','') as dd,d.order_id
from customer_orders c 
join driver_order d on c.order_id=d.order_id where d.distance is not null) as v) as h
group by customer_id;

--12. What is the average  time taken to deliver an order?
Select  avg(time_taken) as avg_time_taken from (
Select cast(time_taken as int) as time_taken from(
Select order_id,duration,left(duration,2) as time_taken
from  driver_order where duration is not null) as v ) as u ;

--13.What is the difference  between the longest and the shortest delivery time for all orders?
Select  max(time_taken)-min(time_taken) as diff from (
Select cast(time_taken as int) as time_taken from(
Select order_id,duration,left(duration,2) as time_taken
from  driver_order where duration is not null) as v ) as u ;

--14.What  is the average speed for each driver each delivery?
Select *, concat(speed,' m/s') as 'speed in (m/s)' from (
Select order_id, driver_id,_distance_,_duration_,((_distance_*1000)/(_duration_*60)) as speed 
from (
Select order_id, driver_id,cast(round(_distance_,0) as  int) as _distance_ , 
cast(_duration_ as int) as _duration_ from (

Select order_id, driver_id, replace(distance,'km','') as _distance_, 
left(duration, 2) as _duration_ from driver_order 
where distance is not null) as a) as b) as c;

--15. What is cancellation percentage for each driver?
Select driver_id, concat(success_rate,' %') as cancellation_percentage from (
Select driver_id, ((sum(order_cancel_details)*100)/count(order_cancel_details))as success_rate
from ( Select order_id, driver_id,order_cancel_details from (
Select *, case 
when cancellation in ('Cancellation','Customer Cancellation') then 1
else 0 end as order_cancel_details 
from driver_order) as a) as v group by driver_id) as m;