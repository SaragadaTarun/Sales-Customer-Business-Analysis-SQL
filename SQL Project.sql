-- 1)What are the total sales, total cost, total profit,and  total orders for each year?D 
select 
D.CalendarYear,
SUM(F.SalesAmount) as Totalsales,
SUM(F.TotalProductCost) as TotalCost,
SUM(F.SalesAmount)-SUM(F.TotalProductCost) as TotalProfit,
COUNT(f.SalesOrderNumber) as TotalOrders
from FactInternetSales as F
inner join DimDate as D 
ON D.DateKey= F.OrderDateKey
group by D.CalendarYear order by CalendarYear

-- 2)Which 10 products generated the highest total sales, and how much quantity of each product was sold?
with cte1 as (select
P.ProductKey as ID,
P.EnglishProductName as Products ,
SUM(F.SalesAmount) as totalsales,
SUM(F.OrderQuantity) as Quantity,
ROW_NUMBER() over (order by SUM(F.SalesAmount) desc) as RN
from FactInternetSales as F
inner join DimProduct as P 
ON F.ProductKey=P.ProductKey
group by P.ProductKey,P.EnglishProductName )
select ID,Products,Quantity,totalsales from cte1 where RN<=11

-- 3)How much revenue and profit did each product category generate, and which category performed the best?
select 
PC.EnglishProductCategoryName,
SUM(F.SalesAmount) as Revenue,
SUM(F.SalesAmount)-SUM(F.TotalProductCost) as Profit
from 
FactInternetSales as F
inner join DimProduct as P
ON F.ProductKey=P.ProductKey
inner join DimProductSubcategory as PS
ON P.ProductSubcategoryKey = PS.ProductSubcategoryKey
inner join DimProductCategory as PC 
ON PC.ProductCategoryKey=PS.ProductCategoryKey
group by PC.EnglishProductCategoryName order by SUM(F.SalesAmount)-SUM(F.TotalProductCost) desc

-- 4)Who are the top 10 customers by total spending, and how many orders did each customer place?
with cte1 as (select
C.CustomerKey as ID,
C.FirstName as Name ,
SUM(F.SalesAmount) as totalsales,
SUM(F.OrderQuantity) as Quantity,
ROW_NUMBER() over (order by SUM(F.SalesAmount) desc) as RN
from FactInternetSales as F
inner join DimCustomer as C 
ON F.CustomerKey= C.CustomerKey
group by  C.CustomerKey,C.FirstName)
select ID,Name,Quantity,totalsales from cte1 where RN<=10

-- 5)What percentage of total sales comes from each product category?
select 
PC.EnglishProductCategoryName,
SUM(F.SalesAmount) as Revenue,
(SUM(F.SalesAmount*100)/SUM(SUM(F.SalesAmount)) over())*100 as totalPercentage_of_sales
from 
FactInternetSales as F
inner join DimProduct as P
ON F.ProductKey=P.ProductKey
inner join DimProductSubcategory as PS
ON P.ProductSubcategoryKey = PS.ProductSubcategoryKey
inner join DimProductCategory as PC 
ON PC.ProductCategoryKey=PS.ProductCategoryKey
group by PC.EnglishProductCategoryName;

-- 6)What are the monthly sales and month-over-month sales changes for each year?
with cte3 as (select 
D.CalendarYear,
D.MonthNumberOfYear,
SUM(F.SalesAmount) as Sales,
LAG(SUM(F.SalesAmount)) over(partition by D.CalendarYear order by D.MonthNumberOfYear ) as PM
from 
FactInternetSales as F
inner join DimDate as D 
ON F.OrderDateKey=D.DateKey
group by D.MonthNumberOfYear,d.CalendarYear)
select * , sales-pm as MOM from cte3;

-- 7)Which products rank in the Top 3 within each product category based on sales?
with cte4 as (select 
Pc.EnglishProductcategoryName,
P.EnglishProductName,
SUM(F.SalesAmount) as sales,
ROW_NUMBER() over(partition by Pc.EnglishProductcategoryName order by SUM(F.SalesAmount) desc) as RN
from 
FactInternetSales as F
inner join DimProduct as P
ON F.ProductKey=P.ProductKey
inner join DimProductSubcategory as PS
ON P.ProductSubcategoryKey = PS.ProductSubcategoryKey
inner join DimProductCategory as PC 
ON PC.ProductCategoryKey=PS.ProductCategoryKey
group by P.EnglishProductName,Pc.EnglishProductcategoryName)
select * from cte4 where RN <= 3 
-- 8)Which customers have spent more than the average customer spending? doubt 

select
C.CustomerKey,
C.FirstName,
SUM(SalesAmount) as sales
from 
FactInternetSales as I
inner join DimCustomer as C
ON I.CustomerKey=C.CustomerKey
group by 
C.CustomerKey,
C.FirstName having SUM(SalesAmount) >(select AVG(SalesAmount) from FactInternetSales);

-- 9)Which customers made their first purchase in each year, and what was their first purchased product?
select
D.CalendarYear,
C.CustomerKey,
C.FirstName,
min(F.OrderDate) over(partition by D.CalendarYear order by F.OrderDate) as first_order_date,
P.EnglishProductName as First_product
from 
	FactInternetSales as F
	inner join DimCustomer as C
	ON F.CustomerKey=C.CustomerKey
	inner join DimDate as D
	ON D.DateKey=F.OrderDateKey
	inner join DimProduct as P
	ON F.ProductKey = P.ProductKey;

-- 10)How long does it take to ship orders, and which products or territories have the longest average shipping time? doubt
select
P.EnglishProductName,
DATEDIFF(DAY,OrderDate,ShipDate) as shipping_time
from 
	FactInternetSales as F
	inner join DimProduct as P
	ON F.ProductKey=P.ProductKey 
	order by DATEDIFF(DAY,OrderDate,ShipDate) desc

-- 11)What was the total sales for each year, and what was the year-over-year percentage growth?
select
D.CalendarYear,
SUM(F.SalesAmount) as Totalsales,
LAG(SUM(F.SalesAmount)) over(order by D.CalendarYear) as PY,
SUM(F.SalesAmount)-LAG(SUM(F.SalesAmount)) over(order by D.CalendarYear) as YOY
from 
FactInternetSales as F
inner join DimDate as D 
ON f.OrderDateKey=D.DateKey
group by D.CalendarYear;
-- 12)Rank customers within each country based on their total sales and identify the top 5 customers from every country.
with cte5 as (select 
ST.SalesTerritoryCountry,
C.CustomerKey,
C.FirstName,
SUM(SalesAmount) as sales,
ROW_NUMBER() over(partition by ST.SalesTerritoryCountry order by SUM(SalesAmount) desc) as RN
from
FactInternetSales as F
inner join DimCustomer as C
ON F.CustomerKey=C.CustomerKey
inner join DimSalesTerritory as ST
ON ST.SalesTerritoryKey=F.SalesTerritoryKey
group by C.CustomerKey,
C.FirstName,ST.SalesTerritoryCountry)
select * from cte5 where RN<=5;

-- 13)Which countries generated the highest Internet Sales, and how many customers does each country have?
select
ST.SalesTerritoryCountry,
SUM(SalesAmount) as sales,
count(C.CustomerKey) as total_cust
from 
FactInternetSales as F
inner join DimCustomer as C
ON C.CustomerKey=F.CustomerKey
inner join DimSalesTerritory as ST
ON ST.SalesTerritoryKey=F.SalesTerritoryKey
group by ST.SalesTerritoryCountry order by SUM(SalesAmount) desc

-- 14) Find customers who have never placed an order.
select
C.CustomerKey,
SUM(SalesAmount) as sales
from 
FactInternetSales as F
left join DimCustomer as C
ON C.CustomerKey=F.CustomerKey
where F.CustomerKey IS null
group by C.CustomerKey

--15) Find countries that have customers who have never made an purchase.
select
G.EnglishCountryRegionName,
C.CustomerKey,
C.FirstName
from 
	DimCustomer as C
	left join DimGeography as G
	ON C.GeographyKey=G.GeographyKey
	left join FactInternetSales as F
	ON F.CustomerKey=C.CustomerKey
	where F.CustomerKey IS null