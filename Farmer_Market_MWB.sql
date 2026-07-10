use farmer;
select * from booth;
select * from customer;
select * from customer_purchase_date;
select * from customer_purchases;
select * from datetime_demo;
select * from market_date_info;
select * from product;
select * from product_category;
select * from vendor;
select * from vendor_booth_assignments;
select * from vendor_inventory;


/*=============================================================
          Farmer's Market Management System using SQL
===============================================================

This file contains sample SQL queries written on the
Farmer database. The queries demonstrate fundamental
as well as advanced SQL concepts such as filtering,
sorting, joins, grouping, subqueries, window functions,
and business-oriented data analysis.

=============================================================*/

-- Select the Farmer database
USE farmer;

-- ===========================================================
-- Q1 - Simple SELECT
-- Question:
-- Display the ID, name, and type of every vendor registered
-- in the market.
-- ===========================================================

SELECT
    vendor_id,
    vendor_name,
    vendor_type
FROM vendor;


-- ===========================================================
-- Q2 - WHERE Clause
-- Question:
-- List all products that belong to the 'Fresh Produce'
-- category (Assuming product_category_id = 1).
-- ===========================================================

SELECT
    product_id,
    product_name,
    product_size,
    product_qty_type
FROM product
WHERE product_category_id = 1;


-- ===========================================================
-- Q3 - ORDER BY
-- Question:
-- List all vendors sorted alphabetically by vendor name.
-- ===========================================================

SELECT
    vendor_id,
    vendor_name,
    vendor_type
FROM vendor
ORDER BY vendor_name ASC;


-- ===========================================================
-- Q4 - DISTINCT
-- Question:
-- Find the distinct list of vendor types participating
-- in the market.
-- ===========================================================

SELECT DISTINCT
    vendor_type
FROM vendor;


-- ===========================================================
-- Q5 - Aggregate Function
-- Question:
-- Calculate the total revenue generated across all
-- customer purchases recorded in the database.
-- ===========================================================

SELECT
    SUM(quantity * cost_to_customer_per_qty) AS total_revenue
FROM customer_purchases;


-- ===========================================================
-- Q6 - GROUP BY
-- Question:
-- Find the total quantity sold for each product.
-- ===========================================================

SELECT
    product_id,
    SUM(quantity) AS total_quantity_sold
FROM customer_purchases
GROUP BY product_id;


-- ===========================================================
-- Q7 - HAVING
-- Question:
-- Identify vendors whose total revenue exceeds 5,000.
-- ===========================================================

SELECT
    vendor_id,
    SUM(quantity * cost_to_customer_per_qty) AS total_revenue
FROM customer_purchases
GROUP BY vendor_id
HAVING SUM(quantity * cost_to_customer_per_qty) > 5000;


-- ===========================================================
-- Q8 - INNER JOIN
-- Question:
-- Display each purchase transaction along with the
-- name of the product purchased.
-- ===========================================================

SELECT
    cp.customer_id,
    p.product_name,
    cp.quantity,
    cp.cost_to_customer_per_qty,
    cp.market_date
FROM customer_purchases cp
INNER JOIN product p
ON cp.product_id = p.product_id;


-- ===========================================================
-- Q9 - LEFT JOIN
-- Question:
-- Identify vendors who have never been assigned to a booth.
-- ===========================================================

SELECT
    v.vendor_id,
    v.vendor_name
FROM vendor v
LEFT JOIN vendor_booth_assignments vba
ON v.vendor_id = vba.vendor_id
WHERE vba.booth_number IS NULL;


-- ===========================================================
-- Q10 - Multiple Table JOIN
-- Question:
-- Produce a complete purchase report showing the customer's
-- name, vendor's name, product purchased and purchase details.
-- ===========================================================

SELECT
    CONCAT(c.customer_first_name,' ',c.customer_last_name) AS customer_name,
    v.vendor_name,
    p.product_name,
    cp.quantity,
    cp.cost_to_customer_per_qty,
    cp.market_date,
    cp.transaction_time
FROM customer_purchases cp
INNER JOIN customer c
ON cp.customer_id = c.customer_id
INNER JOIN vendor v
ON cp.vendor_id = v.vendor_id
INNER JOIN product p
ON cp.product_id = p.product_id;


-- ===========================================================
-- Q11 - Subquery
-- Question:
-- Find customers whose total spending is greater than the
-- average total spending across all customers.
-- ===========================================================

SELECT
    customer_id,
    SUM(quantity * cost_to_customer_per_qty) AS total_spent
FROM customer_purchases
GROUP BY customer_id
HAVING SUM(quantity * cost_to_customer_per_qty) >
(
    SELECT
        AVG(total_amount)
    FROM
    (
        SELECT
            SUM(quantity * cost_to_customer_per_qty) AS total_amount
        FROM customer_purchases
        GROUP BY customer_id
    ) AS customer_totals
);


-- ===========================================================
-- Q12 - CASE Statement
-- Question:
-- Classify each vendor into a performance tier based on
-- their total revenue.
-- ===========================================================

SELECT
    vendor_id,
    SUM(quantity * cost_to_customer_per_qty) AS total_revenue,
    CASE
        WHEN SUM(quantity * cost_to_customer_per_qty) >= 10000 THEN 'Excellent'
        WHEN SUM(quantity * cost_to_customer_per_qty) >= 5000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_tier
FROM customer_purchases
GROUP BY vendor_id;


-- ===========================================================
-- Q13 - Date Functions
-- Question:
-- Determine the total revenue generated in each
-- calendar month.
-- ===========================================================

SELECT
    MONTH(market_date) AS month_number,
    MONTHNAME(market_date) AS month_name,
    SUM(quantity * cost_to_customer_per_qty) AS total_revenue
FROM customer_purchases
GROUP BY
    MONTH(market_date),
    MONTHNAME(market_date)
ORDER BY month_number;


-- ===========================================================
-- Q14 - Ranking using Window Function
-- Question:
-- Rank all vendors by their total revenue from highest
-- to lowest.
-- ===========================================================

SELECT
    vendor_id,
    SUM(quantity * cost_to_customer_per_qty) AS total_revenue,
    RANK() OVER(
        ORDER BY SUM(quantity * cost_to_customer_per_qty) DESC
    ) AS vendor_rank
FROM customer_purchases
GROUP BY vendor_id;


-- ===========================================================
-- Q15 - Business Insight Query
-- Question:
-- For each product category, identify the vendor who
-- generated the highest revenue within that category.
-- ===========================================================

WITH category_revenue AS
(
    SELECT
        pc.product_category_name,
        v.vendor_name,
        SUM(cp.quantity * cp.cost_to_customer_per_qty) AS revenue,
        RANK() OVER(
            PARTITION BY pc.product_category_name
            ORDER BY SUM(cp.quantity * cp.cost_to_customer_per_qty) DESC
        ) AS ranking
    FROM customer_purchases cp
    INNER JOIN product p
        ON cp.product_id = p.product_id
    INNER JOIN product_category pc
        ON p.product_category_id = pc.product_category_id
    INNER JOIN vendor v
        ON cp.vendor_id = v.vendor_id
    GROUP BY
        pc.product_category_name,
        v.vendor_name
)

SELECT
    product_category_name,
    vendor_name,
    revenue
FROM category_revenue
WHERE ranking = 1;