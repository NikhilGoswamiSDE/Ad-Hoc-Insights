-- Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 
SELECT market
FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";



-- What is the percentage of unique product increase in 2021 vs. 2020?
WITH product_cnt_2020 AS 
		(SELECT
		       COUNT(DISTINCT s.product_code) AS unique_products_2020
			   FROM fact_sales_monthly s
               WHERE YEAR(s.date) = 2020),
product_cnt_2021 AS
        (SELECT
		       COUNT(DISTINCT s.product_code) AS unique_products_2021
			   FROM fact_sales_monthly s
               WHERE YEAR(s.date) = 2021)
SELECT product_cnt_2020.unique_products_2020 AS unique_products_2020,
       product_cnt_2021.unique_products_2021 AS unique_products_2021,
       ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as pct_change
FROM product_cnt_2020, product_cnt_2021;




--  Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts.
SELECT segment, COUNT(product_code) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;




--  Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

WITH product_cnt_2020 AS 
		(SELECT p.segment,
		       COUNT(DISTINCT s.product_code) AS unique_products_2020
			   FROM fact_sales_monthly s
               JOIN dim_product p ON s.product_code = p.product_code
               WHERE s.fiscal_year = 2020
               GROUP BY p.segment
               ),
product_cnt_2021 AS
        (SELECT p.segment,
		       COUNT(DISTINCT s.product_code) AS unique_products_2021
			   FROM fact_sales_monthly s
               JOIN dim_product p ON s.product_code = p.product_code
               WHERE s.fiscal_year = 2021
               GROUP BY p.segment)

SELECT product_cnt_2020.segment, product_cnt_2020.unique_products_2020, product_cnt_2021.unique_products_2021,
       ( product_cnt_2021.unique_products_2021 - product_cnt_2020.unique_products_2020) as difference
FROM product_cnt_2020 JOIN product_cnt_2021 ON product_cnt_2020.segment = product_cnt_2021.segment
ORDER BY difference DESC;




--  Get the products that have the highest and lowest manufacturing costs.
WITH max_cost AS
			(SELECT p.product_code, p.product, m.manufacturing_cost
             from fact_manufacturing_cost m 
             JOIN dim_product p ON m.product_code = p.product_code
             ORDER BY m.manufacturing_cost DESC 
             LIMIT 1),
min_cost AS
			(SELECT p.product_code, p.product, m.manufacturing_cost
             from fact_manufacturing_cost m 
             JOIN dim_product p ON m.product_code = p.product_code
             ORDER BY m.manufacturing_cost ASC 
             LIMIT 1)

SELECT * FROM max_cost
UNION ALL
SELECT * from min_cost;





--  Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct  
-- for the  fiscal  year 2021  and in the Indian  market.
SELECT 
       pinv.customer_code, 
       c.customer,
       AVG(pinv.pre_invoice_discount_pct) AS avg_discount
FROM fact_pre_invoice_deductions pinv 
JOIN dim_customer c
ON pinv.customer_code = c.customer_code
WHERE pinv.fiscal_year = 2021 AND c.market = 'India'
GROUP BY pinv.customer_code, c.customer
ORDER BY avg_discount DESC
LIMIT 5;




--  Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month.
-- This analysis helps to  get an idea of low and high-performing months and take strategic decisions.
SELECT 
     MONTH(fsm.date) AS Month, 
     YEAR(fsm.date) AS Year,
     ROUND(SUM((g.gross_price*fsm.sold_quantity)),2) as total_gross_amount
FROM fact_sales_monthly fsm 
JOIN fact_gross_price g
ON fsm.product_code = g.product_code
JOIN dim_customer c
ON c.customer_code = fsm.customer_code 
WHERE c.customer = "Atliq Exclusive"
GROUP BY  Year, Month
ORDER BY Year, Month;




--  In which quarter of 2020, got the maximum total_sold_quantity?
SELECT 
    CASE 
        WHEN MONTH(s.date) IN (9, 10, 11) THEN 'Q1'
        WHEN MONTH(s.date) IN (12, 1, 2) THEN 'Q2'
        WHEN MONTH(s.date) IN (3, 4, 5) THEN 'Q3'
        WHEN MONTH(s.date) IN (6, 7, 8) THEN 'Q4'
    END AS Quarter,
    SUM(s.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly s
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;




--  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH Channel_gross_price AS 
(SELECT 
		c.channel AS Channel, 
        SUM((g.gross_price*s.sold_quantity)/1000000) as Gross_price
FROM fact_sales_monthly s
JOIN fact_gross_price g ON s.product_code = g.product_code
JOIN dim_customer c ON s.customer_code = c.customer_code
WHERE s.fiscal_year = 2021
GROUP BY Channel),
Total_gross_price AS 
(
    SELECT SUM(Gross_price) AS Total_gross_price
    FROM Channel_gross_price
)
SELECT 
		cgp.Channel AS Channel,
        cgp.Gross_price AS gross_price_mln,
        ROUND((cgp.Gross_price*100/tgp.Total_gross_price),2) AS pct_contribution
FROM Channel_gross_price cgp
CROSS JOIN Total_gross_price tgp
ORDER BY gross_price_mln DESC
LIMIT 1;





--  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
WITH cte1 AS 
(SELECT p.division AS Division, 
       p.product_code As Product_Code, 
       p.product AS Product,
       SUM(s.sold_quantity) AS Sold_Quantity
FROM fact_sales_monthly s 
JOIN dim_product p 
ON s.product_code = p.product_code
WHERE s.fiscal_year = 2021
GROUP BY Division, Product_Code, Product),
ranked_data AS
(SELECT * , dense_rank() over ( partition by cte1.Division order by cte1.Sold_Quantity desc) 
       as rank_order
FROM cte1)
SELECT * 
FROM ranked_data
WHERE rank_order <=3
ORDER BY Division, rank_, Sold_Quantity DESC;

