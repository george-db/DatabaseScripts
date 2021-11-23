--Apriori algorithm..

--Set up tables i have account_id with 1000 rows and each has used a product_name....
--account_id is not the primary key of this table, as the detials of products and accounts is stored row-wise...
create table accounts_products as 
select  level as account_id 
       ,decode(floor(dbms_random.value(1,7)) 
               ,1,'Barclays Customer Loan' 
               ,2,'Credit Card Loan' 
               ,3,'Fixed Income Bond' 
               ,4,'Auto Loan' 
               ,5,'Student Loan' 
               ,6,'Life Insurance' 
               ) 
         as product_name 
from dual 
connect by level<=1000 
order by 1;

--Going to add Life Insurance product to the accounts who also have Auto Loan..(95%)
insert into accounts_products 
select account_id 
      ,'Life Insurance' 
  from accounts_products 
where product_name='Auto Loan' 
  and rownum<=(select count(*) 
                 from accounts_products 
                where product_name='Auto Loan'  
               )*0.95;

--Going to add Student Loan to those who have Credit card loan (65%)
insert into accounts_products 
select account_id 
      ,'Student Loan' 
  from accounts_products 
where product_name='Credit Card Loan' 
  and rownum<=(select count(*) 
                 from accounts_products 
                where product_name='Credit Card Loan'  
               )*0.65;
			   
--Going to create a table by account_id	and indicate with bit columns if they posses the list of products...
create table accounts_data  
as 
select account_id 
      ,max(case when product_name='Barclays Customer Loan' then 1 end) as Barclays_Cust_Loan 
      ,max(case when product_name='Credit Card Loan' then 1 end) as Credit_card_loan 
      ,max(case when product_name='Fixed Income Bond' then 1 end) as Fixed_Income_Bond 
      ,max(case when product_name='Auto Loan' then 1 end) as Auto_Loan 
      ,max(case when product_name='Student Loan' then 1 end) as Student_loan 
      ,max(case when product_name='Life Insurance' then 1 end) as Life_Insurance 
from accounts_products 
group by account_id;

--Here comes my apriori - algorithm...
--In case the account does not have a product, the table accounts_data would indicate that product with column as null.
--bitand(1 and null) will result in null. count(null) is 0
with auto_life 
  as (--Find accounts that have both Auto Loan and Life Insurance to find the support of the combination of the products..
      select count(bitand(Auto_Loan,Life_Insurance))/count(*)   as supp_auto_life 
		    ,count(Auto_Loan)/count(*)           as supp_auto 
		    ,count(Life_Insurance)/count(*)      as supp_life	  
	    from accounts_data 
	  ), 
	  credit_student as  
	  (--Find accounts that have both Credit Card Loan and Student Loan to find the support of the combination of the products..
	    select count(bitand(Credit_card_loan,Student_loan))/count(*)   as supp_credit_student 
		      ,count(Credit_card_loan)/count(*)            as supp_credit 
		      ,count(Student_loan)/count(*)      		   as supp_student	  
	    from accounts_data 
	   ) 
  select  
         a.supp_auto_life									   as support_auto_life 
		,a.supp_auto_life/a.supp_auto                          as confidence_auto_life 
        ,a.supp_auto_life/(a.supp_auto*a.supp_life)            as lift_auto_life 
		,b.supp_credit_student								   as support_credit_student 
        ,b.supp_credit_student/b.supp_credit                   as confidence_credit_student 
        ,b.supp_credit_student/(b.supp_credit*b.supp_student)  as lift_credit_student 
    from auto_life a 
    join credit_student b 
      on 1=1
	  
--output is as follows...
/*
+-------------------+-------------------------------------------+------------------------------------------+------------------------+-------------------------------------------+------------------------------------------+
| SUPPORT_AUTO_LIFE |           CONFIDENCE_AUTO_LIFE            |              LIFT_AUTO_LIFE              | SUPPORT_CREDIT_STUDENT |         CONFIDENCE_CREDIT_STUDENT         |           LIFT_CREDIT_STUDENT            |
+-------------------+-------------------------------------------+------------------------------------------+------------------------+-------------------------------------------+------------------------------------------+
|              .179 | .9470899470899470899470899470899470899471 | 2.72936584175777259350746382446670631109 |                   .113 | .6457142857142857142857142857142857142857 | 2.35662148070907194994786235662148070907 |
+-------------------+-------------------------------------------+------------------------------------------+------------------------+-------------------------------------------+------------------------------------------+

*/	  
