SELECT
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    ci.cst_marital_status AS marital_status,
    ca.bdate AS birthdate, -- Getting customer birthdate from erp_cust_az12 table
    ca.gen AS gender_from_erp, -- Getting customer gender from erp_cust_az12 table (Note: This may be redundant with cst_gndr from crm_cust_info)
    la.cntry AS country, -- Getting customer country from erp_loc_a101 table
    CASE WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr 
    ELSE COALESCE(ca.gen, 'Unknown') END AS final_gender,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca 
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
