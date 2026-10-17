USE amazonsale;

##To understand the store's overall sales, number of orders, quantity sold, and average customer rating.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT Order_ID) AS unique_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(AVG(Sales), 2) AS average_sales_per_record,
    SUM(Quantity) AS total_quantity_sold,
    ROUND(AVG(Rating), 2) AS average_rating
FROM salesdata;


##To identify which product category generates the highest sales.

SELECT
    Category,
    SUM(Sales) AS total_sales,
    SUM(Quantity) AS total_quantity
FROM salesdata
GROUP BY Category
ORDER BY total_sales DESC;


##To find which month generates the highest sales and understand sales performance over time.

SELECT
    Month,
    SUM(Sales) AS total_sales,
    SUM(Quantity) AS total_quantity
FROM salesdata
GROUP BY Month
ORDER BY total_sales DESC;


##To identify the customers who spend the most money on the store.

SELECT
    Customer_Name,
    SUM(Sales) AS total_spent,
    COUNT(DISTINCT Order_ID) AS total_orders
FROM salesdata
GROUP BY Customer_Name
ORDER BY total_spent DESC
LIMIT 10;



##Identify sellers with high revenue and measure how many low-rating records they receive, helping the business investigate seller quality.

SELECT
    Seller,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_revenue,
    ROUND(AVG(Rating), 2) AS avg_rating,
    SUM(CASE WHEN Rating < 3 THEN 1 ELSE 0 END)
        AS low_rating_records,
    ROUND(
        100.0 * SUM(CASE WHEN Rating < 3 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS low_rating_percentage
FROM salesdata
GROUP BY Seller
HAVING COUNT(*) >= 5
ORDER BY total_revenue DESC;



##To measure whether sales are increasing or decreasing each month and identify changes in business performance.

WITH monthly_sales AS (
    SELECT
        STR_TO_DATE(`Date`, '%d/%m/%Y') AS sales_date,
        SUM(Sales) AS total_sales
    FROM salesdata
    WHERE STR_TO_DATE(`Date`, '%d/%m/%Y') IS NOT NULL
    GROUP BY STR_TO_DATE(`Date`, '%d/%m/%Y')
),
monthly_summary AS (
    SELECT
        DATE_FORMAT(sales_date, '%Y-%m') AS sales_month,
        SUM(total_sales) AS total_sales
    FROM monthly_sales
    GROUP BY DATE_FORMAT(sales_date, '%Y-%m')
),
sales_comparison AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_summary
)
SELECT
    sales_month,
    total_sales,
    previous_month_sales,
    ROUND(
        100.0 * (total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS growth_percentage
FROM sales_comparison
ORDER BY sales_month;


##To identify the top three revenue-generating products in each category, helping the business understand which products perform best.

WITH product_sales AS (
    SELECT
        Category,
        Product,
        SUM(Sales) AS total_sales,
        SUM(Quantity) AS total_quantity
    FROM salesdata
    GROUP BY Category, Product
),
ranked_products AS (
    SELECT
        Category,
        Product,
        total_sales,
        total_quantity,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY total_sales DESC
        ) AS product_rank
    FROM product_sales
)
SELECT
    Category,
    Product,
    total_sales,
    total_quantity,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY Category, product_rank;


##To identify customers who place multiple orders and compare their total spending, helping the business understand repeat purchasing behaviour.

WITH customer_analysis AS (
    SELECT
        Customer_Name,
        COUNT(DISTINCT Order_ID) AS total_orders,
        SUM(Sales) AS total_spent,
        SUM(Quantity) AS total_quantity
    FROM salesdata
    GROUP BY Customer_Name
)
SELECT
    Customer_Name,
    total_orders,
    total_spent,
    total_quantity,
    CASE
        WHEN total_orders > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_type
FROM customer_analysis
ORDER BY total_spent DESC;