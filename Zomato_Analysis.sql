/* 1. What is the total amount each customer spent on zomato? */

SELECT u.user_first_name || ' ' || u.user_last_name AS "Customer name", SUM(i.Item_Price) AS "Total spent"
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN item i ON o.item_id = i.item_id
GROUP BY u.user_first_name || ' ' || u.user_last_name;


/* 2. How many days each customer visited zomato? */

SELECT user_id AS Customer_id, COUNT(order_date) AS "Total count"
FROM orders
GROUP BY user_id
ORDER BY COUNT(order_date) DESC;


/* 3. What was the first product purchased by each customer? */

SELECT u.user_first_name || ' ' || u.user_last_name AS "Customer Name",
       i.item_name
FROM (
    SELECT o.*,
           RANK() OVER (PARTITION BY user_id ORDER BY order_date) AS rank
    FROM orders o
) subquery
JOIN users u ON u.user_id = subquery.user_id
JOIN item i ON i.item_id = subquery.item_id
WHERE rank = 1;



/* 4.Which is the most purchase item on the menu and how many times was it purchased by all the customer */

SELECT i.item_name,
       COUNT(*) AS total_purchases
FROM item i
JOIN orders o ON i.item_id = o.item_id
GROUP BY i.item_name
ORDER BY total_purchases DESC
LIMIT 1;


/* 5.Which item was the most popular fo each customer? */

SELECT 
    Customer_name, 
    Most_popular_item, 
    Total_purchase
FROM 
    (
        SELECT 
            u.user_first_name || ' ' || u.user_last_name AS Customer_name, 
            i.item_name AS Most_popular_item, 
            COUNT(*) AS Total_purchase, 
            RANK() OVER (PARTITION BY u.user_id ORDER BY COUNT(*) DESC) AS rank 
        FROM 
            users u 
            JOIN orders o ON u.user_id = o.user_id 
            JOIN item i ON o.item_id = i.item_id 
        GROUP BY 
            u.user_id,
            u.user_first_name || ' ' || u.user_last_name,
            i.item_name 
    ) t 
WHERE 
    rank = 1;

    
/* 6. Which item was first purchased by the customer after becoming the gold member? */

SELECT user_id AS Customer_id,
       item_name AS first_gold_purchase
FROM (
    SELECT subquery.*,
           RANK() OVER (PARTITION BY user_id ORDER BY order_date) AS rank
    FROM (
        SELECT o.user_id, g.membership_signup_date, o.order_date, o.item_id, i.item_name, i.item_price
        FROM gold_users g
         JOIN orders o ON g.user_id = o.user_id
        JOIN item i ON o.item_id = i.item_id
        WHERE o.order_date >= g.membership_signup_date
    ) subquery
) t
WHERE rank = 1;


/* 7. Which item was purchased by customer before becoming the member? */

SELECT user_id AS Customer_id,
       item_name
FROM (
    SELECT subquery.*,
           RANK() OVER (PARTITION BY user_id ORDER BY order_date) AS rank
    FROM (
        SELECT o.user_id, g.membership_signup_date, o.order_date, o.item_id, i.item_name, i.item_price
        FROM gold_users g
        INNER JOIN orders o ON g.user_id = o.user_id
        JOIN item i ON o.item_id = i.item_id
        WHERE o.order_date <= g.membership_signup_date
        ORDER BY o.order_date
    ) subquery
) t
WHERE rank = 1;


/* 8. What is the total order and amount spent by each customer befor they become a gold user member? */

SELECT user_id AS Customer_id,
       COUNT(user_id) AS Total_order,
       SUM(item_price) AS Total_amount 
FROM (
    SELECT o.user_id, g.membership_signup_date, o.order_date, o.item_id, i.item_name, i.item_price
    FROM gold_users g
    INNER JOIN orders o ON g.user_id = o.user_id
    JOIN item i ON o.item_id = i.item_id
    WHERE o.order_date <= g.membership_signup_date
) subquery
GROUP BY user_id;


/* 9. If buying each product generate points for example 5 Rs = 2 zomato point 
   and each product has different purchasing points 
   for example for p1 and p3 5rs = 1 zomato point for p2 10 Rs = 5 zomato point */

SELECT user_id AS Customer_id,
       SUM(
           CASE
               WHEN item_name IN ('Zhunka bhakar', 'Roti') THEN item_price / 5 * 1
               WHEN item_name = 'Veg pulao' THEN item_price / 10 * 5
               ELSE 0
           END
       ) * 2.5 AS Total_cashback_earned
FROM orders o
JOIN item i ON o.item_id = i.item_id
GROUP BY user_id
ORDER BY user_id;



/* 10. In the first one year after customer joins the gold program (including there joining date)
 irresepective of what the customer has purchased they earn 5 zomato points for every 10 Rs spent
 who earned more and what was their points earning in the first year */

SELECT o.user_id AS Customer_id, SUM(i.item_price / 10 * 5) AS Total_points
FROM gold_users g
JOIN orders o ON g.user_id = o.user_id
JOIN item i ON o.item_id = i.item_id
WHERE o.order_date >= g.membership_signup_date
AND o.order_date <= DATE_TRUNC('year', g.membership_signup_date) + INTERVAL '1 year'
GROUP BY o.user_id;


/* 11. Rank all the transaction of cutomer. */

SELECT user_id AS Customer_id,
       order_date,
       RANK() OVER (PARTITION BY user_id ORDER BY order_date) transaction_rank
FROM orders;


/* 12. Rank all the transaction for each member whenever they are a zomato gold member
     for every non gold member transaction mark as Na */

SELECT o.user_id AS Customer_id,
       (CASE
           WHEN g.membership_signup_date IS NOT NULL THEN RANK() OVER (PARTITION BY o.user_id ORDER BY o.order_date)::TEXT
           ELSE 'Na'
        END) AS Transaction_rank
FROM orders o
LEFT JOIN gold_users g ON o.user_id = g.user_id;
