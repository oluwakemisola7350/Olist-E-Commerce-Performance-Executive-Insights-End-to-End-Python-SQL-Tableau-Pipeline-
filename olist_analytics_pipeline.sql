
CREATE VIEW vCustomer_Seller_Metrics AS 

--===================================--
	--Group Customer by segment--
--===================================--


WITH CTE_customer_metrics AS (
		SELECT
			customer_unique_id,
			MAX(CAST(o.order_purchase_timestamp AS DATE)) customer_last_purchase,
			COUNT(DISTINCT o.order_id) order_frequency,
			SUM(payment_value) total_customer_money_spent
		FROM dbo.olist_customers c
		LEFT JOIN dbo.olist_orders o
		ON c.customer_id = o.customer_id
		LEFT JOIN dbo.olist_order_payments op
		ON op.order_id = o.order_id
		LEFT JOIN dbo.olist_order_items oi
		ON oi.order_id = o.order_id
		LEFT JOIN dbo.olist_sellers s
		ON s.seller_id = oi.seller_id
		GROUP BY c.customer_unique_id
),

--==============================================================--
	--Find the average seller review and seller performance--
--==============================================================--

	CTE_seller_metrics AS (
		SELECT DISTINCT
			oi.seller_id,
			SUM(oi.price) seller_total_revenue,
			ROUND(AVG(review_score * 1.0),1)  avg_seller_review_score
		FROM dbo.olist_order_items oi
		LEFT JOIN dbo.olist_order_reviews oor
		ON oor.order_id = oi.order_id
		GROUP BY oi.seller_id
		
)

--====================--
	--Main Query--
--====================--
	
	SELECT DISTINCT
			o.order_id,
			o.customer_id,
			o.order_status,
			CAST(o.order_purchase_timestamp AS DATE) order_date,
			DATEPART(year,CAST(o.order_purchase_timestamp AS DATE)) order_year,
			DATENAME(month,CAST(o.order_purchase_timestamp AS DATE)) order_month,
			COALESCE(CAST(o.order_approved_at AS DATE), '8080-12-12') order_approved,
			COALESCE(CAST(o.order_delivered_carrier_date AS DATE), '8080-12-12') order_delivered_carrier_date,
			COALESCE(CAST(o.order_delivered_customer_date AS DATE), '8080-12-12') order_delivered_cust_date,
			CAST(o.order_estimated_delivery_date AS DATE) order_estimated_delivery_date,
			cm.customer_unique_id,
			c.customer_zip_code_prefix customer_zipcode,
			c.customer_city,
			c.customer_state,
			op.payment_sequential,
			op.payment_type,
			op.payment_installments,
			op.payment_value,
			cm.order_frequency,
			cm.total_customer_money_spent,
		CASE 
			WHEN cm.total_customer_money_spent >= 2000 THEN 'VIP Customer'
			WHEN cm.total_customer_money_spent > 1000 AND cm.order_frequency <= 3 THEN 'High Value Customer'
			WHEN cm.order_frequency > 3 THEN 'Repeat Buyer Customer'
			ELSE 'Single Purchase Customer'
		END customer_segment,
	COALESCE(DATEDIFF(day, CAST(o.order_delivered_customer_date AS DATE), CAST(o.order_estimated_delivery_date AS DATE)), -1.0) AS delivery_variance_days,
		CASE 
			WHEN DATEDIFF(day, CAST(o.order_delivered_customer_date AS DATE), CAST(o.order_estimated_delivery_date AS DATE)) < 0 
			THEN ABS(DATEDIFF(day, CAST(o.order_delivered_customer_date AS DATE), CAST(o.order_estimated_delivery_date AS DATE)))
			ELSE 0 
		END AS late_delivery_days,
			COALESCE(oor.review_comment_message, 'No Comment') review_comment_message,
			COALESCE(s.seller_id, 'Unknown') seller_id,
			COALESCE(sm.seller_total_revenue, -1.0) seller_total_revenue,
			ROUND(COALESCE(sm.avg_seller_review_score, -1.0),2) avg_seller_review_score,
		CASE 
			WHEN sm.seller_total_revenue >= 2000 AND sm.avg_seller_review_score < 3 THEN 'High Risk Sellers'
			WHEN sm.seller_total_revenue >= 2000 AND sm.avg_seller_review_score >= 3 THEN 'Top Sellers'
			WHEN sm.seller_total_revenue < 2000 AND sm.avg_seller_review_score >= 3 THEN 'Potential Sellers'
			WHEN sm.seller_total_revenue < 2000 AND sm.avg_seller_review_score < 3 THEN 'Low Sellers'
			ELSE 'Unclassified Sellers'
		END seller_performance,
		pcnt.product_category_name_english,
		pcnt.product_category_name,
		s.seller_city,
		s.seller_state,oor.review_score
		FROM dbo.olist_orders o
		LEFT JOIN dbo.olist_customers c
		ON C.customer_id = o.customer_id
		LEFT JOIN CTE_customer_metrics cm
		ON c.customer_unique_id = cm.customer_unique_id
		LEFT JOIN dbo.olist_order_payments op
		ON op.order_id = o.order_id
		LEFT JOIN dbo.olist_order_items oi
		ON oi.order_id = o.order_id
		LEFT JOIN dbo.olist_sellers s
		ON s.seller_id = oi.seller_id
		LEFT JOIN dbo.olist_order_reviews oor
		ON oor.order_id = oi.order_id
		LEFT JOIN CTE_seller_metrics sm
		ON sm.seller_id = oi.seller_id
		LEFT JOIN [dbo].[olist_products] dop
		ON dop.product_id = oi.product_id
		LEFT JOIN product_category_name_translation pcnt
		ON pcnt.product_category_name = dop.product_category_name



--=========================================================================================--
		/*Customers who pay via installment plans(boleto or credit card installments)
		do they buy more expensive items than those who pay via vouchers or debit card? */
--=========================================================================================--

CREATE VIEW vPayment_Behaviour_Analysis AS (

SELECT
		CASE
			WHEN payment_type IN ('boleto', 'credit_card') THEN 'installment plan'
			WHEN payment_type IN ('voucher', 'debit_card') THEN 'voucher/instant'
			ELSE 'other'
		END Payment_Behaviour_Group,
			ROUND(AVG(oi.price), 3) avg_invidual_item_price,
			MAX(oi.price) most_expensive_item_sold,
			COUNT(oi.product_id) total_items_bought,
			CAST(o.order_purchase_timestamp AS DATE) order_date
FROM dbo.olist_order_payments op
INNER JOIN dbo.olist_order_items oi
ON 	oi.order_id = op.order_id
INNER JOIN [dbo].[olist_orders] o
ON oi.order_id = o.order_id
GROUP BY 	
	CAST(o.order_purchase_timestamp AS DATE),
	CASE
		WHEN payment_type IN ('boleto', 'credit_card') THEN 'installment plan'
		WHEN payment_type IN ('voucher', 'debit_card') THEN 'voucher/instant'
		ELSE 'other'
	END 
)

    
--=============================================================--
	--Things customers adds to their carts at the same time--
--=============================================================--

CREATE VIEW vMarket_Basket_Analysis AS (

	SELECT
		COALESCE(op.Product_category_name,'Unknown') Product_Name_itemA,
		COALESCE(dop.Product_category_name, 'Unknown') Product_Name_itemB,
	COUNT(*) Times_Bought_Together
	FROM [dbo].[olist_order_items] itemA
	INNER JOIN [dbo].[olist_order_items] itemB
	ON itemA.order_id = itemB.order_id AND itemA.Product_id < itemB.Product_id
	INNER JOIN [dbo].[olist_products] op
	ON op.product_id = itemA.product_id 
	INNER JOIN [dbo].[olist_products] dop
	ON dop.product_id = itemB.product_id
	GROUP BY op.Product_category_name,dop.Product_category_name,
			 CAST(o.order_purchase_timestamp AS DATE)
	
)
