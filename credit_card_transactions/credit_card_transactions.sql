select * from credit_card_transactions;

ALTER TABLE credit_card_transactions
ALTER COLUMN transaction_id INT;

ALTER TABLE credit_card_transactions
ALTER COLUMN city VARCHAR(100);

ALTER TABLE credit_card_transactions
ALTER COLUMN transaction_date DATE;

ALTER TABLE credit_card_transactions
ALTER COLUMN card_type VARCHAR(50);

ALTER TABLE credit_card_transactions
ALTER COLUMN exp_type VARCHAR(50);

ALTER TABLE credit_card_transactions
ALTER COLUMN gender  VARCHAR(10);

ALTER TABLE credit_card_transactions
ALTER COLUMN amount DECIMAL(12,2);



/*1- write a query to print top 5 cities with highest spends and 
their percentage contribution of total credit card spends*/
with cte as(
select city,sum(amount)as city_total,(select sum(amount) from credit_card_transactions)as total
from credit_card_transactions
group by city)

SELECT top 5 city,city_total,cast((city_total / total )* 100 as decimal(10,2)) AS per
FROM cte
order by per desc

/*2- write a query to print highest spend month and amount spent in that 
month for each card type*/

select * from credit_card_transactions;

with cte as(
SELECT card_type,SUM(amount)as total,DATEPART(year,transaction_date)as yr,
DATEPART(month,transaction_date)as mth
FROM credit_card_transactions
group by card_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date)
),
cte1 as(
select *,Rank()over(partition by card_type order by total desc)as rn from cte)

select * from cte1
where rn=1

/*3- write a query to print the transaction details(all columns from the table) 
for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in 
the o/p one for each card type)*/

select * from credit_card_transactions;

with cte as(
select *,sum(amount)over(partition by card_type order by transaction_date,transaction_id)as 
total from
credit_card_transactions
),
cte1 as(
select *,Rank()over(partition by card_type order by total asc)as rn 
from cte
where total>=1000000
)
select * from cte1
where rn=1


/*4- write a query to find city which had lowest percentage spend for gold 
card type*/
with cte as(
select city,card_type,sum(amount)as total from credit_card_transactions
where card_type='Gold'
group by city,card_type),
cte1 as(
select sum(total)as whole_total from cte)

select top 1 city,total,
cast((total/(select whole_total from cte1)*100) as decimal(10,5))as per
from cte
order by per asc

/*5- write a query to print 3 columns:  city, highest_expense_type , 
lowest_expense_type
(example format : Delhi , bills, Fuel)*/
select * from credit_card_transactions;

with cte as(
select city,exp_type,sum(amount)as total from credit_card_transactions
group by city,exp_type
),
cte1 as(
select *,row_number()over(partition by city order by total desc) as high_exp 
from cte),
cte2 as(
select *,row_number()over(partition by city order by total asc) as low_exp
from cte)

SELECT c1.city,c1.exp_type AS highest_expense_type,c2.exp_type AS lowest_expense_type
FROM cte1 c1
INNER JOIN cte2 c2 ON c1.city = c2.city
WHERE c1.high_exp = 1 AND c2.low_exp = 1;

--6- write a query to find percentage contribution of spends by females for 
--each expense type
select * from credit_card_transactions;

select exp_type, 
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution 
from credit_card_transactions 
group by exp_type 
order by percentage_female_contribution desc;




--9- during weekends which city has highest total spend to total 
--no of transcations ratio

with cte as(
select *, DATEPART(WEEKDAY, transaction_date) AS day_no 
from credit_card_transactions
where DATEPART(WEEKDAY, transaction_date) in ('7','1')
),
cte1 as(
select city,count(city)as cnt,sum(amount)as total from cte
group by city
)
select top 1*,cast((total/cnt )as decimal(10,2))as avg_total from cte1
order by avg_total desc


--10- which city took least number of days to reach its 500th transaction after
--the first transaction in that city

select * from credit_card_transactions;


with cte1 as(
select transaction_date,city,row_number()over(partition by city order by transaction_date)as rn
from credit_card_transactions
),
cte2 as(
select *  from cte1 
where rn=1
),
cte3 as(
select *  from cte1 
where rn=500
),
cte4 as(
select c2.transaction_date as min_date,c3.transaction_date as max_date,
c2.rn as first_rn,c3.rn as last_rn,c2.city
from cte2 c2
inner join cte3 c3 on c2.city=c3.city
)
select top 1 city,min_date,max_date,first_rn,last_rn,datediff(day,min_date,max_date)as dys from cte4
order by dys asc

--7- which card and expense type combination saw highest month 
--over month growth in Jan-2014


with cte as(
select *,datepart(year,transaction_date)as yr,
datepart(month,transaction_date)as mth
from credit_card_transactions),

cte1 as(
select card_type,exp_type,yr,mth,sum(amount)as total
from cte
group by card_type,exp_type,yr,mth
),
cte2 as(
select card_type,exp_type,yr,mth,lag(total)over(partition by card_type,exp_type order by yr,mth)
as previous_month,total
from cte1
)

SELECT top 1*,(total - previous_month)
AS growth
FROM cte2
WHERE yr = 2014
AND mth = 1
AND previous_month IS NOT NULL
ORDER BY growth DESC;
