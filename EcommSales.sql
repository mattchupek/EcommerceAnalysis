/* In this SQL, I'm querying a database with multiple tables in it to quantify ecom statistics about customer and order data. 
I began by cleaning the data and performing EDA then I answered 14 questions about the data, showcasing a wide variety of SQL functions.
*/

--I want to combine all the tables into 1 table to make it easier to visualize on Tableau:
-- 1.Create a new table called'CombinedSales'
CREATE TABLE CombinedSales (
    orderID INTEGER,
    Product TEXT,
    Quantity INTEGER,
    price REAL,
    orderdate TEXT,
    location TEXT
);

-- 2.Add all the sales data from each month into the new table.
INSERT INTO CombinedSales (orderID, Product, Quantity, price, orderdate, location)
SELECT orderID, Product, Quantity, price, orderdate, location FROM JanSales
UNION ALL
SELECT orderID, Product, Quantity, price, orderdate, location FROM FebSales
UNION ALL
SELECT orderID, Product, Quantity, price, orderdate, location FROM MarSales
UNION ALL
SELECT orderID, Product, Quantity, price, orderdate, location FROM AprSales
UNION ALL
SELECT orderID, Product, Quantity, price, orderdate, location FROM MaySales;

--EDA: Select all columns from Table
SELECT * FROM CombinedSales LIMIT 10;
----------------------------------------------

--#Q1. How many orders were placed in January? 
SELECT COUNT(orderid) as num_of_orders
FROM CombinedSales
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID'
  AND orderdate LIKE '01%'
  ;

--#Q2. How many of those orders were for an iPhone? 
SELECT COUNT(orderid)
FROM JanSales
WHERE Product='iPhone'
  AND length(orderid) = 6 
  AND orderid <> 'Order ID';

--#Q3. Select the customer account numbers for all the orders that were placed in February. 
SELECT DISTINCT acctnum
FROM customers cust

INNER JOIN FebSales Feb ON cust.order_id = Feb.orderid
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID';

--#Q4.(Subquery) Which product was the cheapest one sold in January, and what was the price? 
SELECT DISTINCT 
  product
  ,price
FROM JanSales
WHERE price in (
  SELECT MIN(price) FROM BIT_DB.JanSales
);

--#OR 

SELECT DISTINCT 
  product
  ,price 
FROM JanSales 
ORDER BY price ASC LIMIT 1;

--#Q5. What is the total revenue for each product sold in January?
SELECT 
  ROUND(SUM(quantity)*price,2) as revenue
  ,product
FROM JanSales
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID'
GROUP BY product;

--#Q6. Which products were sold in February at 548 Lincoln St, Seattle, WA 98101, 
--how many of each were sold, and what was the total revenue?
SELECT 
  product
  ,SUM(quantity)
  ,SUM(quantity)*price as revenue
FROM FebSales 
WHERE location = '548 Lincoln St, Seattle, WA 98101'
GROUP BY product;

--#Q7. How many customers ordered more than 2 products at a time, and what was the average amount spent for those customers? 
SELECT 
  COUNT(DISTINCT cust.acctnum) AS num_of_customers
  ,AVG(quantity*price) as amount_spent
FROM FebSales feb
LEFT JOIN BIT_DB.customers cust ON cust.order_id=feb.orderid
WHERE feb.quantity > 2
  AND length(orderid) = 6 
  AND orderid <> 'Order ID';

--#Q8. List all the products sold in Los Angeles in February and include how many of each were sold.
SELECT 
  DISTINCT product
  ,SUM(quantity)
FROM FEBSales
WHERE location LIKE '%Los Angeles%'
GROUP BY product
ORDER BY SUM(quantity) desc;

--#Q9. Which locations in New York received at least 3 orders in January, and how many orders did they each receive?
SELECT
  DISTINCT location
  ,COUNT(orderid)
FROM JANSales
WHERE length(orderid) = 6
  AND orderid <> ('Order ID')
  AND location LIKE '%New York%'
GROUP BY location
  HAVING COUNT(orderid) >= 3;

--#Q10. How many of each type of headphone were sold in February and what was the revenue?
SELECT 
  SUM(quantity) as quantity
  ,ROUND(SUM(quantity*price)) AS revenue
  ,product
FROM FEBSales
WHERE product LIKE '%headphone%'
GROUP BY product
ORDER BY revenue desc;


#--Q11. What was the average amount spent per account in February? 
--(We want the average amount spent per the number of accounts, not the overall average spent)
SELECT 
  ROUND(SUM(quantity*price)/COUNT(acctnum)) as average_spent
FROM FEBSales s
JOIN customers c ON c.order_id = s.orderid
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID';
--A:$190

--#Q12. What was the average quantity of products purchased per account in February? 
--(We want the overall average, not the average for each account individually)
SELECT 
  ROUND(AVG(quantity),1)
FROM FEBSales s
LEFT JOIN customers c ON c.order_id = s.orderid
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID';
--A: 1

--#Q13. Which product brought in the most revenue in January and how much revenue did it bring in total?
SELECT 
  product
  ,SUM(quantity*price) as revenue
FROM JANSales
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID'
GROUP BY product
ORDER BY revenue desc LIMIT 1
;
--A: Macbook Pro Laptop, $399,500

--#Q14. Which product brought in the least revenue in January and how much revenue did it bring in total?
SELECT 
  product
  ,SUM(quantity*price) as revenue
FROM JANSales
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID'
GROUP BY product
ORDER BY revenue asc LIMIT 1;
--A: AAA Batteries (4-pack), $4,772

--------------------------------------------------

--Top Products: Most sold products by quantity and revenue.
SELECT 
product
,ROUND(SUM(quantity*price)) as revenue
FROM CombinedSales
WHERE length(orderid) = 6 
  AND orderid <> 'Order ID'
GROUP BY Product
ORDER BY SUM(quantity*price) DESC LIMIT 10
;

--Customer Analysis: Number of unique customers, average order value per customer.
SELECT 
COUNT(DISTINCT acctnum) AS NumUniqueCustomers
,ROUND(AVG(quantity*price))
FROM CombinedSales cs
JOIN customers c ON c.order_id = cs.orderid;

--Clean database
DELETE FROM CombinedSales
WHERE length(orderid) != 6
AND orderid = 'Order ID';

--Now the cleaned and combined database is ready to be extracted and opened in Tableau to visualize.
