
USE walmart_db;

SELECT * FROM walmart;

-- DROP TABLE walmart;


-- Count total records
SELECT COUNT(*) FROM walmart;

-- Show payment methods and number of transactions by payment method

SELECT 
    payment_method,
    COUNT(*) AS no_payments
FROM walmart
GROUP BY payment_method;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) 
FROM walmart;

-- Find the minimum quantity sold
SELECT category,MIN(quantity) 
FROM walmart
GROUP BY category;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments, 
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Project Question #2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating
SELECT branch, category, avg_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as ran_k
    FROM walmart
    GROUP BY branch, category
) AS ranked
WHERE ran_k = 1;


-- Q3: Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ran_k
    FROM walmart
    GROUP BY branch, day_name
) AS ranked
WHERE ran_k = 1;

-- Q4: Calculate the total quantity of items sold per payment method
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q5: Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;

-- Q6: Calculate the total profit for each category
SELECT 
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

 /* Q7: Branch Comparison
Which branch performs best in terms of revenue and average customer rating? */

-- Q8: Determine the most common payment method for each branch
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ran_k
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE ran_k = 1;
-- second approach ----------
select branch, payment_method
from(select branch, payment_method, 
count(payment_method),
rank() over( partition by branch order by count(payment_method) desc) as ran
from walmart
group by branch, payment_method)as ranked
where ran =1;

     
-- Advanced Level (Business Insights) ----

/* Q9: Profitability Analysis
Which product category has the highest average profit margin across branches? */
SELECT branch, category, AVG(profit_margin)
FROM(
	SELECT branch, category, AVG(profit_margin),
    RANK() OVER(PARTITION BY category ORDER BY AVG(profit_margin) DESC) AS RAN
	FROM walmart
	GROUP BY category) AS RANKED
WHERE RAN =1;    
WITH category_avg AS (
    SELECT category, AVG(profit_margin) AS avg_profit_margin
    FROM walmart
    GROUP BY category
)
SELECT w.branch, w.category, w.profit_margin
FROM walmart w
JOIN category_avg c
ON w.category = c.category
WHERE c.avg_profit_margin = (SELECT MAX(avg_profit_margin) FROM category_avg);

-- Q10: Categorize sales into Morning, Afternoon, and Evening shifts
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;


/* Q13: Branch-City InsightWhich city consistently brings in the highest profit margin for the company?*/
SELECT city, AVG(profit_margin) AS avg_profit_margin
FROM walmart
GROUP BY city
ORDER BY avg_profit_margin DESC
LIMIT 1;


/* Q14: Branch Optimization
If management wants to shut down the least profitable branch, which one should it be?*/
SELECT branch, SUM(profit_margin) AS total_profit
FROM walmart
GROUP BY branch
ORDER BY total_profit ASC
LIMIT 1;

/* Q15: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023) */
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
