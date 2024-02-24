CREATE DATABASE IF NOT EXISTS Walmartsales;
USE Walmartsales;

CREATE TABLE IF NOT EXISTS sales(
invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
branch VARCHAR(5) NOT NULL,
city VARCHAR(40) NOT NULL,
customer_type VARCHAR(30) NOT NULL,
gender VARCHAR(30) NOT NULL,
product_line VARCHAR(135) NOT NULL,
unit_price DECIMAL(20,2) NOT NULL,
quantity INT NOT NULL,
tax_pct FLOAT(6,4) NOT NULL,
total DECIMAL(20,4) NOT NULL,
date DATE NOT NULL,
time TIME NOT NULL,
payment VARCHAR(30) NOT NULL,
cogs FLOAT(15,2) NOT NULL,
gross_margin_pct DECIMAL(11,9),
gross_income DECIMAL(12,4),
rating FLOAT(2,1)
);
#we've used NOT NULL for almost every column, when creating table. so, null values would be filtered out automatically
SELECT * FROM sales;

#------------------- FEATURE ENGINNERING -------------------------

-- creating time_of_day column which specifies if the time is morning, afternoon, evening or night
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(25);
UPDATE sales SET time_of_day=
(CASE
    WHEN `time` BETWEEN "06:00:00" AND "12:00:00" THEN "Morning"
	WHEN `time` BETWEEN "12:00:00" AND "18:00:00" THEN "Afternoon"
    WHEN `time` BETWEEN "18:00:00" AND "21:00:00" THEN "Evening"
	ELSE "Night"
 END);

-- creating 'day_name' column to have day names(like Monday, Tuesday, etc.) as per the date column
ALTER TABLE sales ADD COLUMN day_name VARCHAR(20);
UPDATE sales SET day_name= DAYNAME(date);

-- creating 'month_name' COLUMN to have month names(like January,February, etc.) as per the date column
ALTER TABLE sales ADD COLUMN month_name VARCHAR(30);
UPDATE sales SET month_name= monthname(date);


-------------------------- EDA(EXPLORATORY DATA ANALYSIS) -------------------------------
-----------------------------------------------------------------------------------------
SELECT * FROM sales;

-- How many unique cities does the data have?
SELECT COUNT(DISTINCT(city)) FROM sales;

-- in which city is each branch?
SELECT DISTINCT city, branch FROM sales;

-- show unique product lines does the data have?
SELECT DISTINCT product_line FROM sales;

-- what is the most common payment method?
SELECT payment, COUNT(payment) AS count FROM sales
GROUP BY payment ORDER BY count DESC LIMIT 1;

-- what is the most selling product line?
SELECT product_line, SUM(quantity) as quantity_sold FROM sales
GROUP BY product_line ORDER BY quantity_sold DESC LIMIT 1;

-- what is total revenue by month?
SELECT month_name, SUM(total) FROM sales
GROUP BY month_name ;

-- which month had largest COGS?
SELECT month_name, SUM(cogs) from sales 
GROUP BY month_name ORDER BY SUM(cogs) DESC LIMIT 1;

-- Which product line has the largest revenue?
SELECT product_line, SUM(total) AS revenue FROM sales
GROUP BY product_line ORDER BY revenue DESC LIMIT 1;

-- Which product line has the largest VAT?
SELECT product_line, AVG(tax_pct) AS avg_tax FROM sales
GROUP BY product_line ORDER BY avg_tax DESC LIMIT 1;

-- Fetch each product line and add a column to those product line showing "Good", "Bad". 
-- Good if its greater than average sales


-- Which branch sold more products than average product sold
SELECT branch, SUM(quantity) AS qty_sold FROM sales 
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- What is the most common product line by gender
SELECT gender, product_line, COUNT(gender) AS total_count FROM sales
GROUP BY gender, product_line
ORDER BY total_count, gender DESC;

-- What is the average rating of each product line?
SELECT product_line, AVG(rating) AS average_rating FROM sales
GROUP BY product_line;

-- Number of sales made in each time of the day per weekday
SELECT day_name, time_of_day ,COUNT(*) AS no_of_sales FROM sales
GROUP BY time_of_day, day_name ;

-- Which customer type brings the most revenue
SELECT customer_type, SUM(total) AS revenue FROM sales
GROUP BY customer_type ORDER BY revenue DESC;

-- Which city has largest tax percent/VAT
SELECT city, AVG(tax_pct) FROM sales
GROUP BY city ORDER BY AVG(tax_pct) DESC LIMIT 1;

-- which customer type pays the most in VAT(i.e, tax)?
SELECT customer_type, AVG(tax_pct) FROM sales
GROUP BY customer_type ORDER BY AVG(tax_pct) DESC;

-- How many unique customer types?
SELECT COUNT(DISTINCT customer_type) FROM sales;

-- show all unique payment methods
SELECT DISTINCT payment FROM sales;

-- which customer type has most transactions?
SELECT customer_type, COUNT(*) FROM sales
GROUP BY customer_type ORDER BY COUNT(*) DESC ;

-- what is gender of most of the customers?
SELECT gender, COUNT(*) FROM sales
GROUP BY gender ORDER BY COUNT(*) DESC;

-- what is gender distribution per branch
SELECT branch, gender, COUNT(*) as gender_count FROM sales
GROUP BY branch, gender;

-- which time of day do customers give most ratings?
SELECT time_of_day, COUNT(rating) FROM sales
GROUP BY time_of_day ORDER BY COUNT(rating) DESC;

-- which time of day do customers give most ratings per branch?
SELECT branch, time_of_day, COUNT(rating) FROM sales
GROUP BY branch, time_of_day ORDER BY COUNT(rating) DESC;

-- Which day of the week has best avg ratings?
SELECT day_name, AVG(rating) FROM sales
GROUP BY day_name ORDER BY AVG(rating) DESC;

-- Which day of the week has best average ratings per branch?
SELECT branch, day_name, AVG(rating) FROM sales
GROUP BY branch, day_name ORDER BY AVG(rating) DESC;

--  Find the sales of weekdays, considering only total sales and gross income while accounting for potential weekday variations, also show percent of variations for both columns.
SELECT * FROM sales;
WITH weekday_sales AS (SELECT day_name, SUM(total) as weekday_total_sales, SUM(gross_income) AS weekday_gross_income FROM sales
GROUP BY day_name )
SELECT day_name, weekday_total_sales, weekday_gross_income,
( weekday_total_sales/AVG(weekday_total_sales) OVER () ) AS sales_variations,
( weekday_gross_income/AVG(weekday_gross_income) OVER() ) AS grossincome_variations,
(weekday_total_sales*100/AVG(weekday_total_sales) OVER() ) AS sales_variations_pct,
(weekday_gross_income*100/AVG(weekday_gross_income) OVER() ) AS grossincome_variations_pct
FROM weekday_sales;

-- Find branch and month combinations with respective growth rate
WITH monthly_income_per_branch AS(
SELECT branch, month_name, SUM(gross_income) AS gross_income FROM sales 
GROUP BY branch, month_name )
SELECT branch, month_name,
(gross_income - LAG(gross_income) OVER (PARTITION BY branch ORDER BY month_name))/LAG(gross_income) OVER (PARTITION BY branch ORDER BY month_name) AS growth_rate
FROM monthly_income_per_branch;

-- Find the top 3 branches with most consistent growth in gross income over consecutive months
WITH monthly_income_per_branch AS(
SELECT branch, month_name, SUM(gross_income) AS gross_income FROM sales
GROUP BY branch, month_name ),
month_growth AS (
SELECT branch, month_name,
( gross_income - LAG(gross_income) OVER(PARTITION BY branch ORDER BY month_name))
/LAG(gross_income) OVER(PARTITION BY branch ORDER BY month_name) AS growth_rate
FROM monthly_income_per_branch )
SELECT branch, COUNT(*) AS conistent_growth_months FROM month_growth
WHERE growth_rate>0 
GROUP BY branch ORDER BY conistent_growth_months DESC 
LIMIT 3;

-- Identify product line & gender combinations that generate significantly higher average ratings
SELECT product_line, gender, AVG(rating) AS avg_rating
FROM sales
GROUP BY product_line, gender
HAVING AVG(rating) > (SELECT AVG(rating) FROM sales);



-- Identify dates of unusually high or low sales volume for each branch, potentially indicating seasonal trends.
WITH daily_sales_per_branch AS ( SELECT branch, date, SUM(total) AS daily_sales FROM sales
GROUP  BY branch, date ORDER BY daily_sales DESC )
SELECT branch, date, daily_sales FROM daily_sales_per_branch 
WHERE daily_sales > (SELECT AVG(daily_sales) FROM daily_sales_per_branch)*1.5
OR daily_sales < (SELECT AVG(daily_sales) FROM daily_sales_per_branch)*0.5 ;

-- Identify months with more than 10% variation in sales volume for each branch, potentially indicating seasonal trends.
WITH monthly_sales_per_branch AS ( SELECT branch, month_name, SUM(total) AS monthly_sales FROM sales
GROUP BY branch, month_name ORDER BY monthly_sales DESC )
SELECT * FROM monthly_sales_per_branch 
WHERE monthly_sales > (SELECT AVG(monthly_sales) FROM monthly_sales_per_branch)*1.1
OR monthly_sales < (SELECT AVG(monthly_sales) FROM monthly_sales_per_branch)*0.9;

-- What is  the impact of time of day on sales patterns and customer behavior, including average transaction value, no. of product preferences, and no. of payment methods
SELECT time_of_day, AVG(total) as avg_transaction_value, COUNT(DISTINCT product_line), COUNT(DISTINCT payment)
FROM sales GROUP BY time_of_day ;

