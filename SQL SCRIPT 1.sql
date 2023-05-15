create database veg_project

use veg_project

select * from df_noida

select distinct Vegetable_Name from df_noida

#seasonal
CREATE VIEW seasonal
AS

-- Differentiate items seasonal & non-seasonal based on their price flactuation 
with a as(
select Vegetable_Name, max( Market_Price), min(Market_Price),avg(Market_Price),
((max( Market_Price)- min(Market_Price))/min(Market_Price))*100,
case when ((max( Market_Price)- min(Market_Price))/min(Market_Price))*100 <100 then 'non-seasional'
else 'seasional' end as type
from df_noida
where year=2022
group by 1
order by 5)

-- taking all the seasonal items
,b as(
select * from df_noida
where Vegetable_Name in (select Vegetable_Name from a where type='seasional'))

-- determining the season of the vegetable taking two months with lowest price as season
,c as(
select Vegetable_Name, month, avg(Market_Price) as amp, avg(Average_Shoping_Mall_Price) as asmp
,avg(Average_Retail_Price) as arp
from b
group by 1,2
order by 1)


,d as(
select *, dense_rank() over (partition by Vegetable_Name order by amp) as rnk
from c)


,e as(
select Vegetable_Name, month, amp, asmp, arp from d
where rnk in (1,2))


select month, round(avg(amp),2) as amp, round(avg(asmp),2) as asmp, round(avg(arp),2) as arp
from e
where Vegetable_Name not in ( 'Onion Big','Onion Small','Green Chilli','Potato','Garlic','Ginger')
group by 1
order by 1





# Average of non-seasonal vegetable through out the year

CREATE VIEW non_seasonal
AS
-- Differentiate items seasonal & non-seasonal based on their price flactuation 
with a as(
select Vegetable_Name, max( Market_Price), min(Market_Price),avg(Market_Price),
((max( Market_Price)- min(Market_Price))/min(Market_Price))*100,
case when ((max( Market_Price)- min(Market_Price))/min(Market_Price))*100 <100 then 'non-seasional'
else 'seasional' end as type
from df_noida
where year=2022
group by 1
order by 5)
-- taking all the non-seasonal items
,b as(
select * from df_noida
where Vegetable_Name in (select Vegetable_Name from a where type='non-seasional'))

select Vegetable_Name, avg(Market_Price) as amp, avg(Average_Shoping_Mall_Price) as asmp,avg(Average_Retail_Price) as arp
from b
where Vegetable_Name not in ('Onion Big','Onion Small','Green Chilli','Potato','Garlic','Ginger')
group by 1



#Essential
CREATE VIEW essential 
AS
with a as(
select * from df_noida
where Vegetable_Name in ('Onion Big','Onion Small','Green Chilli','Potato','Garlic','Ginger'))

select Vegetable_Name, month, avg(Market_Price) as amp, avg(Average_Retail_Price) as arp, avg(Average_Shoping_Mall_Price) as asmp
from a
where year=2022
group by 1,2
order by 1,2



# splitting non seasonal items for different income group
CREATE VIEW non_seasonal_income_group
AS
with x as(
select * ,ntile(3) over (order by amp) as bucket
from non_seasonal)

select bucket, round(avg(amp),2) as amp, round(avg(arp),2) as arp, round(avg(asmp),2) as asmp
from x
group by 1



# essential ('Onion Big','Onion Small','Green Chilli','Potato','Garlic','Ginger')
-- estimate quantity per head per month
CREATE TABLE essential_quantity (
    Vegetable_Name varchar(50),
    quantity float)
    
INSERT INTO essential_quantity (Vegetable_Name, quantity)
VALUES ('Onion Big', 1),
('Onion Small',.5),
('Green Chilli',.25),
('Potato',2),
('Garlic',.25),
('Ginger',.25)


CREATE VIEW essential_total
AS
with x as(
select a.*, quantity
from essential a
left join essential_quantity b
on a.Vegetable_Name=b.Vegetable_Name)
,y as(
select Vegetable_Name, month, amp*quantity as tmp, arp*quantity as trp, asmp*quantity as tsmp
from x)

select month, round(sum(tmp),2) as tmp, round(sum(trp),2) as trp, round(sum(tsmp),2) as tsmp
from y
group by 1


#low income group

select * from essential_total
select * from non_seasonal_income_group
select * from seasonal

with x as(
select e.month, amp*2 as tmp_s, tmp, tmp_n
from seasonal s join 
essential_total e on e.month=s.month
join (select amp*6 as tmp_n from non_seasonal_income_group where bucket=1) as a
order by 1)

select month, round((tmp_s+tmp+tmp_n)*5,2) as total_spending
from x

#middle income group

select * from essential_total
select * from non_seasonal_income_group
select * from seasonal

with x as(
select e.month, amp*2 as tmp_s, asmp*2 as tsmp_s, tmp, tsmp, tmp_n, tsmp_n
from seasonal s join 
essential_total e on e.month=s.month
join (select amp*6 as tmp_n, asmp*6 as tsmp_n from non_seasonal_income_group where bucket=2) as a
order by 1)

select month, round((tmp_s+tsmp_s+tmp+tsmp+tmp_n+tsmp_n)*5/2,2) as total_spending
from x


#high income group

select * from essential_total
select * from non_seasonal_income_group
select * from seasonal

with x as(
select e.month,  asmp*2 as tsmp_s,  tsmp,  tsmp_n
from seasonal s join 
essential_total e on e.month=s.month
join (select asmp*6 as tsmp_n from non_seasonal_income_group where bucket=3) as a
order by 1)

select month, round((tsmp_s+tsmp+tsmp_n)*5,2) as total_spending
from x