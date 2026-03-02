SET search_path TO olist;

-- What is the total revenue generated?
SELECT ROUND(SUM(total_revenue_per_item), 2) AS total_revenue
FROM order_items;

-- What is the monthly revenue trend?
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.total_revenue_per_item),2) AS revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- Which month had the highest revenue?
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.total_revenue_per_item),2) AS revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY revenue desc
limit 1;

-- What is the average order value (AOV)?
SELECT 
    ROUND(
        SUM(oi.total_revenue_per_item) 
        / COUNT(DISTINCT o.order_id),
    2) AS avg_order_value
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- What is the revenue growth rate month-over-month?
SELECT 
    month,
    ROUND(revenue,2) AS revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100,
    2) AS mom_growth_percent
FROM (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.total_revenue_per_item) AS revenue
    FROM orders o
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
) t
ORDER BY month;

-- How many total orders were placed?
SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) 
FROM orders
WHERE order_status = 'delivered';

-- What is the average revenue per customer?
SELECT 
    ROUND(
        SUM(oi.total_revenue_per_item) 
        / COUNT(DISTINCT o.customer_id),
    2) AS avg_revenue_per_customer
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- What percentage of orders are delivered vs canceled?
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
    2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY percentage DESC;

-- Which product categories generate the highest revenue?
SELECT 
    pct.product_category_name_english AS category,
    ROUND(SUM(oi.total_revenue_per_item),2) AS total_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC;

-- Which product categories have the highest number of orders?
SELECT 
    pct.product_category_name_english AS category,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_orders DESC;

-- What are the top 10 best-selling products?
SELECT 
    oi.product_id,
    COUNT(*) AS total_units_sold
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_units_sold DESC
LIMIT 10;

-- Which products generate high revenue but low order volume?
SELECT 
    oi.product_id,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.total_revenue_per_item),2) AS total_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
HAVING COUNT(*) < 10   -- low volume threshold
ORDER BY total_revenue DESC
LIMIT 10;

-- What is the average price per category?
SELECT 
    pct.product_category_name_english AS category,
    ROUND(AVG(oi.price),2) AS avg_price
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY avg_price DESC;

-- Which categories have the highest freight cost?
SELECT 
    pct.product_category_name_english AS category,
    ROUND(AVG(oi.freight_value),2) AS avg_freight
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY avg_freight DESC;

-- Are larger/heavier products associated with higher freight charges?
SELECT 
    CORR(p.product_weight_g, oi.freight_value) AS weight_freight_correlation
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
AND p.product_weight_g IS NOT NULL;

-- Which sellers have poor customer review scores (avg review < 3)?
SELECT 
    oi.seller_id,
    ROUND(AVG(r.review_score),2) AS avg_review_score
FROM order_items oi
JOIN order_reviews r 
    ON oi.order_id = r.order_id
GROUP BY oi.seller_id
HAVING AVG(r.review_score) < 3
ORDER BY avg_review_score;

-- Is there a relationship between seller revenue and average review score?
SELECT 
    seller_id,
    ROUND(SUM(total_revenue_per_item),2) AS total_revenue,
    ROUND(AVG(review_score),2) AS avg_review_score
FROM order_items oi
JOIN order_reviews r 
    ON oi.order_id = r.order_id
GROUP BY seller_id
ORDER BY total_revenue DESC;

-- Which states have the most active sellers?
SELECT 
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS total_sellers
FROM sellers s
GROUP BY s.seller_state
ORDER BY total_sellers DESC;

-- What is the average delivery time per seller?
SELECT 
    oi.seller_id,
    AVG(o.order_delivered_customer_date-o.order_purchase_timestamp) AS avg_delivery_days
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY avg_delivery_days DESC;

-- Which states generate the highest revenue?
SELECT 
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- What percentage of customers are repeat customers?
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),2
    ) AS repeat_customer_percentage
FROM customer_orders;

-- What is the customer lifetime value (CLV)?
SELECT 
    c.customer_id,
    ROUND(SUM(oi.price + oi.freight_value),2) AS customer_lifetime_value
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_id
ORDER BY customer_lifetime_value DESC;

-- Which states have the highest cancellation rate?
SELECT 
    c.customer_state,
    ROUND(
        100.0 * SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END)
        / COUNT(o.order_id),2
    ) AS cancellation_rate_percent
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY cancellation_rate_percent DESC;

-- How many orders were delivered late?
SELECT 
    COUNT(*) AS late_deliveries
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date > order_estimated_delivery_date;

-- Does longer delivery time impact review score?
SELECT 
        AVG(order_delivered_customer_date - order_purchase_timestamp) AS avg_delivery_days,
    ROUND(AVG(r.review_score),2) AS avg_review_score
FROM orders o
JOIN order_reviews r 
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY avg_delivery_days DESC;

-- Which states have the longest delivery time?
SELECT 
    c.customer_state,
    AVG(o.order_delivered_customer_date 
        - o.order_purchase_timestamp) AS avg_delivery_days
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- Which categories receive the most 1-star reviews?
SELECT 
    pct.product_category_name_english,
    COUNT(*) AS one_star_reviews
FROM order_reviews r
JOIN orders o 
    ON r.order_id = o.order_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE r.review_score = 1
GROUP BY pct.product_category_name_english
ORDER BY one_star_reviews DESC;

-- Do higher installment payments correlate with higher order value?
SELECT 
    payment_installments,
    ROUND(AVG(payment_value),2) AS avg_order_value
FROM order_payments
GROUP BY payment_installments
ORDER BY payment_installments;
