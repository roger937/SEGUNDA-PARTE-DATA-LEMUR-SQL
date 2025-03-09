-- ejercicio 1:

SELECT
  artist_name,concert_revenue,genre,number_of_members,revenue_per_member
FROM (
  SELECT
    artist_name,concert_revenue,genre,number_of_members,concert_revenue / number_of_members AS revenue_per_member,
    RANK() OVER (PARTITION BY genre ORDER BY concert_revenue / number_of_members DESC) AS ranked_concerts
  FROM concerts) AS subquery
WHERE ranked_concerts = 1
ORDER BY revenue_per_member DESC;


--ejercicio 2:

WITH supercloud_cust AS 
(
  SELECT customers.customer_id, COUNT(DISTINCT products.product_category) AS product_count
  FROM customer_contracts AS customers
  INNER JOIN products ON customers.product_id = products.product_id
  GROUP BY customers.customer_id
)

SELECT customer_id FROM supercloud_cust
WHERE product_count = (SELECT COUNT(DISTINCT product_category) FROM products);


--ejercicio 3:

WITH order_counts AS (SELECT COUNT(order_id) AS total_orders  FROM orders)
SELECT
  CASE
    WHEN order_id % 2 != 0 AND order_id != total_orders THEN order_id + 1
    WHEN order_id % 2 != 0 AND order_id = total_orders THEN order_id
    ELSE order_id - 1
 END AS corrected_order_id,item
FROM orders CROSS JOIN order_counts ORDER BY corrected_order_id;


--ejercicio 4:

WITH card_launch AS (
  SELECT 
    card_name,issued_amount,MAKE_DATE(issue_year, issue_month, 1) AS issue_date,
    MIN(MAKE_DATE(issue_year, issue_month, 1)) OVER (PARTITION BY card_name) AS launch_date FROM monthly_cards_issued
)

SELECT card_name, issued_amount FROM card_launch
WHERE issue_date = launch_date ORDER BY issued_amount DESC;


--ejercicio 5:

WITH top_10_cte AS 
(
  SELECT artists.artist_name,
    DENSE_RANK() OVER (ORDER BY COUNT(songs.song_id) DESC) AS artist_rank
  FROM artists
  INNER JOIN songs ON artists.artist_id = songs.artist_id
  INNER JOIN global_song_rank AS ranking ON songs.song_id = ranking.song_id
  WHERE ranking.rank <= 10 GROUP BY artists.artist_name
)

SELECT artist_name, artist_rank FROM top_10_cte WHERE artist_rank <= 5;


--ejercicio 6:

WITH latest_transactions_cte AS 
(
  SELECT transaction_date, user_id, product_id, RANK() OVER ( PARTITION BY user_id ORDER BY transaction_date DESC) AS transaction_rank 
  FROM user_transactions
) 
SELECT transaction_date, user_id,COUNT(product_id) AS purchase_count
FROM latest_transactions_cte WHERE transaction_rank = 1 
GROUP BY transaction_date, user_id ORDER BY transaction_date;


--ejercicio 7:

WITH ranked_measurements AS 
(
  SELECT CAST(measurement_time AS DATE) AS measurement_day, measurement_value, 
  ROW_NUMBER() OVER (PARTITION BY CAST(measurement_time AS DATE) ORDER BY measurement_time) AS measurement_num FROM measurements
) 

SELECT measurement_day, SUM(measurement_value) FILTER (WHERE measurement_num % 2 != 0) AS odd_sum, SUM(measurement_value) FILTER (WHERE measurement_num % 2 = 0) AS even_sum 
FROM ranked_measurements GROUP BY measurement_day;


--ejercicio 8:

WITH yearly_spend_cte AS 
(
  SELECT EXTRACT(YEAR FROM transaction_date) AS year,product_id,spend AS curr_year_spend,LAG(spend) OVER (
  PARTITION BY product_id ORDER BY product_id, EXTRACT(YEAR FROM transaction_date)) AS prev_year_spend FROM user_transactions
)

SELECT year,product_id, curr_year_spend, prev_year_spend, ROUND(100 * (curr_year_spend - prev_year_spend)/ prev_year_spend, 2) AS yoy_rate FROM yearly_spend_cte;


--ejercicio 9:

WITH summary AS 
( SELECT SUM(square_footage) FILTER (WHERE item_type = 'prime_eligible') AS prime_sq_ft,COUNT(item_id) FILTER (WHERE item_type = 'prime_eligible') AS prime_item_count,
  SUM(square_footage) FILTER (WHERE item_type = 'not_prime') AS not_prime_sq_ft,COUNT(item_id) FILTER (WHERE item_type = 'not_prime') AS not_prime_item_count FROM inventory
),
prime_occupied_area AS (SELECT FLOOR(500000/prime_sq_ft)*prime_sq_ft AS max_prime_area FROM summary)
SELECT 'prime_eligible' AS item_type,FLOOR(500000/prime_sq_ft)*prime_item_count AS item_count FROM summary UNION ALL
SELECT 'not_prime' AS item_type,FLOOR((500000-(SELECT max_prime_area FROM prime_occupied_area)) / not_prime_sq_ft) * not_prime_item_count AS item_count FROM summary;


--ejercicio 10:

SELECT page_id FROM pages EXCEPT
SELECT page_id FROM page_likes;

--ejercicio 11:

SELECT * FROM customers
WHERE LOWER(customer_name) LIKE '%son' AND gender = 'Male' AND age = 20;


--ejercicio 12:

WITH drug_sales AS (
  SELECT manufacturer, SUM(total_sales) as sales FROM pharmacy_sales GROUP BY manufacturer
) 
SELECT  manufacturer, ('$' || ROUND(sales / 1000000) || ' million') AS sales_mil 
FROM drug_sales ORDER BY sales DESC, manufacturer;


