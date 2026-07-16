/*
    Creating a master customer table (dimension)

*/
DROP VIEW IF EXISTS gold.dim_customers;
CREATE VIEW gold.dim_customer AS
    SELECT
        ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
        ci.cst_id AS customer_id,
        ci.cst_key AS customer_number,
        ci.cst_firstname AS first_name,
        ci.cst_lastname AS last_name,
        ci.cst_marital_status AS marital_status,
        ca.bdate AS birthdate, -- Getting customer birthdate from erp_cust_az12 table
        la.cntry AS country, -- Getting customer country from erp_loc_a101 table
        CASE WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr  -- crm_cust_info has most updated information
        ELSE COALESCE(ca.gen, 'Unknown') END AS gender,
        ci.cst_create_date AS create_date
    FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 ca 
    ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid

DROP VIEW IF EXISTS gold.dim_products;
CREATE VIEW gold.dim_products AS
    SELECT 
        ROW_NUMBER() OVER (ORDER BY p.prd_start_dt, p.prd_key) AS product_key,
        p.prd_id AS product_id,
        p.prd_key AS product_number,
        p.cat_id AS category_id,
        p.prd_nm AS product_name,
        p.prd_line AS product_line,
        p.prd_cost AS cost,
        p.prd_start_dt AS start_date,
        e.cat AS category,
        e.subcat AS subcategory,
        e.maintenance AS maintenance
    FROM silver.crm_prd_info p
    LEFT JOIN silver.erp_px_cat_g1v2 e
    ON p.cat_id = e.id
    WHERE p.prd_end_dt IS NULL -- Only include products that are currently active (end date is null)

DROP VIEW IF EXISTS gold.fact_sales;
CREATE VIEW gold.fact_sales AS
    SELECT
        s.sls_ord_num AS order_number,
        p.product_key AS product_key,
        c.customer_key AS customer_key,
        s.sls_cust_id AS customer_id,
        s.sls_order_dt AS order_date,
        s.sls_ship_dt AS ship_date,
        s.sls_due_dt AS due_date,
        s.sls_sales AS sales_amount,
        s.sls_quantity AS quantity,
        s.sls_price AS price
    FROM silver.crm_sales_details s
    LEFT JOIN gold.dim_products p
    ON s.sls_prd_key = p.product_number
    LEFT JOIN gold.dim_customer c
    ON s.sls_cust_id = c.customer_id