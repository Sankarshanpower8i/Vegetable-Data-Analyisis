- Differentiate items seasonal & non-seasonal based on their price flactuation 

select Vegetable_Name, max( Market_Price), min(Market_Price),avg(Market_Price),
((max( Market_Price)- min(Market_Price))/min(Market_Price))*100,
case when ((max( Market_Price)- min(Market_Price))/min(Market_Price))*100 <100 then 'non-seasional'
else 'seasional' end as type
from df_noida
where year=2022
group by 1
order by 5