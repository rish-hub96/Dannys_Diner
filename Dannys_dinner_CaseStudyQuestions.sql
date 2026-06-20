/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

-- Joining the sales and menu tables by product id to get the price of each item
-- Grouping by customer id to get total amount spent by each customer

SELECT
  	s.customer_id, sum(m.price ) total_amount
from
	dannys_diner.sales s, menu m
where s.product_id  = m.product_id 
group by s.customer_id
order by total_amount desc;

-- 2. How many days has each customer visited the restaurant?

-- Simply group by customer id and count the number of distinct dates

select s.customer_id,count(distinct s.order_date) total_days
from sales s group by s.customer_id  order by total_days desc;

-- 3. What was the first item from the menu purchased by each customer?

-- This could also be solved using the RANK function
-- However simply using the MIN function to get the first date is more concise
-- Another way to do is by using the WITH to create a subquery that will fecth the minimum order_date

select
	s1.customer_id,s1.order_date, m.product_name first_item
from
	sales s1,
	(select customer_id, min(order_date) min_date from sales group by customer_id) s2,
	menu m 
where 
	s1.customer_id = s2.customer_id 
and s1.order_date  = s2.min_date
and s1.product_id = m.product_id ;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- This can also be solved using the RANK function
-- However simply fetching the count(*) groupedby product_id, arranging in desc and limiting the records to 1
-- will fetch the first record (highest count)
-- Then simply join the subquery with sales and menu tables, group by customer_id and product name
-- to get the count of how many times the product was purchased by each customer.

select
	s1.customer_id, m.product_name, count(*)
from
	sales s1,
	(
		select
			s.product_id,count(*)
		from
			sales s
		group by
			s.product_id
		order by
			count(*) desc
		limit 1
	) s2,
	menu m
where
		s1.product_id = s2.product_id
	and s1.product_id = m.product_id
group by
	s1.customer_id, m.product_name;

-- 5. Which item was the most popular for each customer?

-- We need to use the RANK function here to find which product was bought most times by each customer
-- Using a subquery to group by customer_id and product_id to get the count of purchase of each product
-- Using the rank function to rank the counts, partition by only customer_id because
-- we are ranking the counts of product purchase for each customer
-- Then join the subquery with the menu table to get the product name ad select only the records with rank = 1
-- One thing to note here is that the rank function will settle ties by assigning the same rank
-- Example: Customer B has bought all 3 products two times.

select s1.customer_id, m.product_name most_popular_product, product_count from (
		select
			s.customer_id, s.product_id, count(*) product_count,
			rank() over(partition by s.customer_id order by count(*) desc) rank
		from sales s
		group by s.customer_id, s.product_id
		order by rank
	) s1,
	menu m
where
		s1.rank = 1
	and s1.product_id = m.product_id
order by s1.customer_id, s1.rank
;


-- 6. Which item was purchased first by the customer after they became a member?

-- This could also have been solved using the LIMIT function like we had used earlier
-- But I felt like getting some more practice with the RANK function :)
-- One thing to note here is that the sample data for this exercise is fairly simple
-- There were not ties here. Real world data can be very messy.

with date_data as (
	select	s.customer_id,
			s.order_date,
			s.product_id,
			rank() OVER (
    	PARTITION BY s.customer_id
	    ORDER BY s.order_date asc
	  ) AS rnk
	from
		sales s, members m
	where
			s.customer_id  = m.customer_id
		and s.order_date >= m.join_date
	order by s.customer_id, rnk asc
)
select
	date_data.customer_id, date_data.order_date, n.product_name first_product
from
	menu n, date_data
where
		n.product_id = date_data.product_id
	and date_data.rnk = 1
;

-- 7. Which item was purchased just before the customer became a member?

-- This is simply the opposite of the previous question

with date_data as (
	select	s.customer_id,
			s.order_date,
			s.product_id,
			rank() OVER (
    	PARTITION BY s.customer_id
	    ORDER BY s.order_date desc
	  ) AS rnk
	from
		sales s, members m
	where
			s.customer_id  = m.customer_id
		and s.order_date < m.join_date
	order by s.customer_id, rnk asc
)
select
	date_data.customer_id, date_data.order_date, n.product_name first_product
from
	menu n, date_data
where
		n.product_id = date_data.product_id
	and date_data.rnk = 1
;

-- 8. What is the total items and amount spent for each member before they became a member?

-- Simply join the sales, menu and member tables
-- filter by s.order_date < m.join_date, sum the price and take a count of the records

select
	s.customer_id,
	count(s.product_id) total_items_purchased,
	sum(n.price) total_amount_spent
from
	sales s,
	menu n,
	members m
where
		m.customer_id = s.customer_id 
	and s.order_date < m.join_date
	and s.product_id = n.product_id
group by
	s.customer_id
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- We have used the CASE condition here
-- When the product name is 'sushi', then the multiplier will be 20
-- Every other time the multiplier will be 10 only

select
	s.customer_id,
	sum(
		case
			when n.product_name = 'sushi' then n.price * 20
			else n.price * 10
		end
	)
from
	sales s,
	menu n
where
	 	s.product_id = n.product_id
group by
	s.customer_id 
;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Initially I was trying to solve this one using the BETWEEN clause in the case when condition
-- But I quickly realised that it was not very efficient here
-- It's much more simple to use the greater than or less than operators
-- Whenenever a date falls between join_date and 7 days after join_date, the multiplier is 20
-- In all other conditions we use the same logic as the previous question
-- With one added condition that the order_date falls outside the bounds of join_date and join_date + 7

select
	s.customer_id,
	sum(
		case
			when s.order_date >= m.join_date and s.order_date <= m.join_date + 7
				then n.price * 20
			when (s.order_date < m.join_date or s.order_date > m.join_date + 7) and  n.product_name = 'sushi'
				then n.price * 20
			else n.price * 10
		end
	)
from
	sales s,
	menu n,
	members m 
where
	 	s.product_id = n.product_id
	 and s.customer_id = m.customer_id
	 and to_char(s.order_date,'MON') = 'JAN'
group by
	s.customer_id 
;