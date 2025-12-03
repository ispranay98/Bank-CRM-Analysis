CREATE DATABASE Customer;
USE Customer;
create table Customerinfo(
CustomerId	int,
Surname	varchar(100),
Age int,
GenderID int,
EstimatedSalary int,
GeographyID int,
Bank_DOJ date);
create table activecustomer(
ActiveID int,ActiveCategory varchar(100));
create table creditcard(
CreditID int,Category varchar(100));
create table exitcustomer(
ExitID int,ExitCategory varchar(100));
create table bank_churn(
CustomerId	int,CreditScore	int,Tenure	int,Balance	int,NumOfProducts	int,HasCrCard	int,IsActiveMember	int,Exited int);
create table gender(
GenderID	int,GenderCategory varchar(100));
create table geography(
GeographyID	int,GeographyLocation varchar(100));
drop table customerinfo;
select * from activecustomer; 
select * from bank_churn; 
select * from creditcard; 
select * from customerinfo;  
select * from exitcustomer; 
select * from gender; 
select * from geography; 
select str_to_date(Bank_DOJ,"%Y-%m-%d") as Bank_DOJ from customerinfo;

-- :::OBJECTIVE QUESTIONS:::
-- 1.What is the distribution of account balances across different regions?
SELECT g.GeographyLocation AS Region,
    COUNT(*) AS NumCustomers,
    MIN(b.Balance) AS MinBalance,
    MAX(b.Balance) AS MaxBalance,
    AVG(b.Balance) AS AvgBalance
FROM bank_churn b
JOIN customerinfo ci ON b.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
GROUP BY g.GeographyLocation;

-- 2.	Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
SELECT Surname, sum(EstimatedSalary )
FROM customerinfo
WHERe Bank_DOJ BETWEEN '01-09-2019' AND '31-12-2019'
GROUP BY Surname
ORDER BY sum(EstimatedSalary) DESC
LIMIT 5; 

-- 3.Calculate the average number of products used by customers who have a credit card. (SQL)
SELECT AVG(NumOfProducts) AS avg_product_by_credit_card
FROM bank_churn bc
LEFT JOIN customerinfo ci ON ci.CustomerId = bc.CustomerId
INNER JOIN gender gen ON ci.GenderID = gen.GenderID
INNER JOIN exitcustomer ec ON ec.ExitID = bc.Exited
INNER JOIN creditcard cc ON cc.CreditID = bc.HasCrCard
INNER JOIN geography geo ON geo.GeographyID = ci.GeographyID
INNER JOIN activecustomer ac ON ac.ActiveID = bc.IsActiveMember
WHERE cc.Category = 'credit card holder';

-- 4. IN powerbi
-- 5.Compare the average credit score of customers who have exited and those who remain. (SQL)
SELECT ec.ExitCategory, avg(bc.CreditScore) as avg_credit_score
FROM bank_churn bc
INNER JOIN exitcustomer ec ON bc.Exited = ec.ExitID
Group by ec.ExitCategory;

-- 6.Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
WITH ActiveAccounts AS (
    SELECT CustomerId,COUNT(*) AS ActiveAccounts
    FROM Bank_Churn
    WHERE IsActiveMember = 1
    GROUP BY customerId
)
SELECT CASE WHEN c.GenderID = 1 THEN 'Male' ELSE 'Female' END AS Gender,
COUNT(aa.CustomerId) AS ActiveAccounts, round(AVG(c.EstimatedSalary),2) AS AvgSalary
FROM customerinfo c
LEFT JOIN ActiveAccounts aa ON c.CustomerId = aa.CustomerId
GROUP BY Gender
ORDER BY AvgSalary DESC;

-- 7.Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
with cte as(
select c.CustomerID, b.Exited, case
when  b.CreditScore >= 800 then "Excellent"
when  b.CreditScore between 740 and 799 then "Very Good"
when  b.CreditScore between 670 and 739 then "Good"
when  b.CreditScore between 580 and 669 then "Fair"
else "Poor"
end as Segment
from customerinfo c
join bank_churn b on c.CustomerID = b.CustomerID
)
select Segment, COUNT(*) AS TOTALCUSTOMERS,round(count(case when Exited = 1 then 1 end)/count(*) * 100, 2) as Exit_Rate
from cte
group by Segment
order by count(case when Exited = 1 then 1 end)/count(*) desc;

-- 8.Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
select g.GeographyLocation,count(case when a.ActiveCategory= 'Active Member' then 1 end ) 
as count_active_member from customerinfo c 
inner join bank_churn b ON c.CustomerId= b.CustomerId
inner join geography g ON c.GeographyID= g.GeographyID
inner join activecustomer a ON b.IsActiveMember= a.ActiveID 
where b.Tenure>5
group by g.GeographyLocation
order by count_active_member desc 
limit 3;

-- 9.IN Powerbi
-- 10.For customers who have exited, what is the most common number of products they have used?
SELECT NumOfProducts, COUNT(*) AS Total_customers
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY Total_customers DESC;

-- 11.Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT  count(*) as new_customers,
extract(year from str_to_date(Bank_DOJ,'%d-%m-%Y')) as "Year_Joining" 
FROM customerinfo
group by  Year_Joining
order by  Year_Joining ; 

-- 12.Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT 
NumOfProducts,count(CustomerID) as totalcustomers,round(sum(Balance),0) as totalBalanace
FROM bank_churn bc
where bc.Exited = 1
group by NumOfProducts
order by totalBalanace desc;

-- --13 and 14 in powerbi 
-- 15.Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
with cte as(
select  
	ci.GeographyID,
    geo.GeographyLocation,
	round(avg(ci.EstimatedSalary),2) as average_salary,
	gen.GenderCategory,
	rank() over(partition by ci.GeographyID order by avg(ci.EstimatedSalary) desc ) gender_rank
from bank_churn bc
left join customerinfo ci on ci.CustomerId=bc.CustomerId
inner join gender gen on ci. GenderID= gen.GenderID
inner join geography geo on geo.GeographyID=ci.GeographyID
group by gen.GenderCategory, ci.GeographyID,geo.GeographyLocation
)
select GeographyLocation,average_salary,GenderCategory,gender_rank from cte;

-- 16.Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
with bracket as (
select bc.Tenure , 
case when ci.Age between 18 and 29 then "18-30"
	when ci.Age between 30 and 49 then "30-50" 
	else "50 and above"
    end as age_bracket
from bank_churn bc 
left join customerinfo ci on bc.CustomerID=ci.CustomerID
)
select age_bracket, round(avg(Tenure),2) avg_tenure 
from bracket
group by age_bracket
order by age_bracket asc;

-- 17.in powerbi
-- 18.Is there any correlation between the salary and the Credit score of customers?
SELECT 
    c.CustomerId,
    Surname AS Customername,
    EstimatedSalary AS customersalary,
    b.CreditScore
FROM
    customerinfo c
        INNER JOIN
    bank_churn b ON b.CustomerId = c.CustomerId;

-- 19.Rank each bucket of credit score as per the number of customers who have churned the bank.
with creditbucket as
(
select *,
case when creditscore between 0 and 579 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 800 then 'Very Good'
    else 'Excellent'
	end as creditBucket
from bank_churn
where exited = 1
)
select creditbucket, count(customerid) as total_count,
dense_rank() over(order by count(customerid) desc) as ranking  
from creditbucket
group by creditbucket;

-- 20.According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.
 WITH creditinfo AS (
    SELECT 
        CASE 
            WHEN age BETWEEN 18 AND 30 THEN 'Adult'
            WHEN age BETWEEN 31 AND 50 THEN 'Middle-Aged'
            ELSE 'Old-Aged'
        END AS AgeBrackets,
        COUNT(c.CustomerId) AS HasCrCard
    FROM customerinfo c
    JOIN bank_churn b ON c.CustomerId = b.CustomerId
    WHERE b.HasCrcard = 1 
    GROUP BY AgeBrackets
)
SELECT * FROM creditinfo
WHERE HasCrCard < (SELECT AVG(HasCrCard) FROM creditinfo);

-- 21.Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
select  
geo.GeographyLocation, 
count(bc.Exited) as churned,
round(avg(bc.Balance),2) average_balance,
rank() over(order by count(bc.Exited) desc) as ranking
from bank_churn bc
left join customerinfo ci on ci.CustomerId=bc.CustomerId
inner join geography geo on geo.GeographyID=ci.GeographyID
where bc.Exited=1
group by geo.GeographyLocation ;

-- 22.As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
select CustomerID,Surname,
concat(CustomerID, '  ' ,Surname) as CustomerID_Surname 
from customerinfo;

-- 23.   Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
select * 
from bank_churn,exitcustomer 
where exitcustomer.ExitID=bank_churn.Exited;

-- 24. in doc
-- 25.Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
SELECT bc.CustomerID, ci.Surname AS Last_Name, ac.ActiveCategory
FROM bank_churn bc
LEFT JOIN customerinfo ci ON ci.CustomerId = bc.CustomerId
INNER JOIN gender gen ON ci.GenderID = gen.GenderID
INNER JOIN exitcustomer ec ON ec.ExitID = bc.Exited
INNER JOIN creditcard cc ON cc.CreditID = bc.Hascrcard
INNER JOIN geography geo ON geo.GeographyID = ci.GeographyID
INNER JOIN activecustomer ac ON ac.ActiveID = bc.IsActiveMember
WHERE ci.Surname LIKE '%on';

-- 26.Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. One more point to consider is that the data in the Exited Column is absolutely correct and accurate.
SELECT *
FROM bank_churn b 
WHERE b.Exited =1 and b.IsActiveMember =1;

-- SUBJECTIVE QUESTIONS:-- 
-- 5.Customer Tenure Value Forecast:How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments? 
SELECT c.CustomerID,c.Age,c.EstimatedSalary,
b.CreditScore,b.Tenure,b.Balance,b.NumOfProducts,
cc.Category AS CreditCardCategory,a.ActiveCategory,
e.ExitCategory,
TIMESTAMPDIFF(YEAR, STR_TO_DATE(c.Bank_DOJ, '%Y-%m-%d'), CURDATE()) AS Years 
FROM customerinfo c
JOIN geography geo ON c.GeographyID = geo.GeographyID
JOIN bank_churn b ON c.CustomerID = b.CustomerID
LEFT JOIN creditcard cc ON b.HasCrCard = cc.CreditID
LEFT JOIN activecustomer a ON b.IsActiveMember = a.ActiveID
LEFT JOIN exitcustomer e ON b.Exited = e.ExitID;

-- 9.Utilize SQL queries to segment customers based on demographics and account details.
SELECT c.CustomerID, c.Age,b.CreditScore,
b.Balance,b.Tenure,g.GenderCategory,geo.GeographyLocation,
	CASE 
		WHEN c.Age < 25 THEN 'Youth (Under 25)'
		WHEN c.Age BETWEEN 25 AND 35 THEN 'Young Adults (25-35)'
		WHEN c.Age BETWEEN 36 AND 50 THEN 'Middle Age (36-50)'
		ELSE 'Senior (Above 50)' END AS AgeGroup,
	CASE 
		WHEN b.CreditScore < 500 THEN 'Poor Credit'
		WHEN b.CreditScore BETWEEN 500 AND 700 THEN 'Average Credit'
		ELSE 'Good Credit' END AS CreditScoreCategory,
	CASE 
		WHEN b.Balance < 10000 THEN 'Low Balance'
		WHEN b.Balance BETWEEN 10000 AND 50000 THEN 'Medium Balance'
		ELSE 'High Balance' END AS BalanceCategory,
	CASE 
		WHEN b.Tenure < 2 THEN 'New Customer'
		WHEN b.Tenure BETWEEN 2 AND 5 THEN 'Moderate Customer'
		ELSE 'Loyal Customer' END AS TenureSegment,
	CASE 
		WHEN cc.CreditID = 1 THEN 'Credit Card Holder'
		ELSE 'Non-Credit Card Holder' END AS CreditCardSegment
FROM bank_churn b
JOIN customerinfo c on c.CustomerID=b.CustomerID
JOIN gender g on g.GenderID=c.GenderID
JOIN geography geo on geo.GeographyID=c.GeographyID
JOIN creditcard cc on cc.CreditID=b.HasCrCard;

-- Sub Q14. In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?
 Alter table bank_churn
 rename column HasCrCard to Has_creditcard;
SELECT *
FROM bank_churn;




