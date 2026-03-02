--Create Schema
CREATE SCHEMA olist;
SET search_path TO olist;

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
	delivery_days int,
	clean_delivery_days int,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
	total_revenue_per_item NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2)
);


--add remaining foreign key after importing data
ALTER TABLE order_items
ADD CONSTRAINT fk_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_payments
ADD CONSTRAINT fk_payment_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);

SELECT count(DISTINCT oi.seller_id)
FROM order_items oi
LEFT JOIN sellers s 
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT DISTINCT oi.seller_id
FROM order_items oi
LEFT JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

INSERT INTO sellers (seller_id)
SELECT DISTINCT oi.seller_id
FROM order_items oi
LEFT JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

ALTER TABLE order_items
ADD CONSTRAINT fk_seller
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);


CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);


CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

ALTER TABLE order_reviews
ADD CONSTRAINT fk_review_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);


--Row Count Validation
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(*) FROM geolocation;
SELECT COUNT(*) FROM product_category_name_translation;



--Check Orphan Records (Must Be 0)

-- Orders without customers
SELECT COUNT(*)
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Items without orders
SELECT COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews without orders
SELECT COUNT(*)
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;