SELECT *
FROM bronze.crm_cust_info

SELECT *
FROM bronze.crm_prd_info

SELECT *
FROM bronze.crm_sales_details

SELECT *
FROM bronze.erp_cust_az12

SELECT *
FROM bronze.erp_loc_a101

SELECT *
FROM bronze.erp_px_cat_g1v2


-- Exploring crm_cust_info
-- Checking if cst_id is unique to be a primary key
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1

-- There are 6 duplicate cst_id values, let's find out why
SELECT *
FROM bronze.crm_cust_info
WHERE cst_id IN (
    SELECT cst_id
    FROM bronze.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1
)
ORDER BY cst_id

-- There are duplicates due to missing values upon first entry. Assume the latest cst_create_date is the correct one.
-- Trim whitespace from cst_firstname and cst_lastname, and convert cst_marital_status and cst_gndr to more readable formats.
WITH no_duplicates AS (
    SELECT *
    FROM (
        SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rank
        FROM bronze.crm_cust_info
    ) rownumbered
    WHERE rank = 1 
    )
SELECT cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN cst_marital_status = 'M' THEN 'Married'
        WHEN cst_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS cst_marital_status,
    CASE 
        WHEN cst_gndr = 'M' THEN 'Male'
        WHEN cst_gndr = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS cst_gndr,
    cst_create_date
FROM no_duplicates
ORDER BY cst_id

-- Exploring crm_prd_info
-- ID from erp_px_cat_g1v2 is a primary key and is a foreign key in crm_prd_info. However, the category id is part of the prd_key column. It is the first 5 characters. Category ID should be in the format XX_XX

SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extracting category ID from prd_key and replacing '-' with '_'
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key, -- Extracting the actual product key by removing the category ID and the underscore
prd_nm,
COALESCE(prd_cost, 0) AS prd_cost, -- Replacing NULL values with 0
CASE WHEN prd_line = 'M' THEN 'Mountain'
     WHEN prd_line = 'R' THEN 'Road'
     WHEN prd_line = 'S' THEN 'Other Sales'
     WHEN prd_line = 'T' THEN 'Touring'
     ELSE 'Unknown'
END AS prd_line, -- Converting prd_line codes to more readable formats
prd_start_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt -- Adding a new column to calculate the new end date based on the next start date for the same product key
FROM bronze.crm_prd_info

-- Exploring crm_sales_details

SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL
         ELSE TO_DATE(sls_order_dt, 'YYYYMMDD')
    END AS sls_order_dt,
    CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL
         ELSE TO_DATE(sls_ship_dt, 'YYYYMMDD')
    END AS sls_ship_dt,
    CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL
         ELSE TO_DATE(sls_due_dt, 'YYYYMMDD')
    END AS sls_due_dt,
    CASE WHEN sls_sales::numeric <= 0 OR sls_sales::numeric != (sls_quantity::numeric * sls_price::numeric) OR sls_sales IS NULL THEN ABS(sls_quantity::numeric * sls_price::numeric)
    ELSE sls_sales::numeric
    END AS sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details

SELECT sls_ord_num, sls_quantity, sls_price, sls_sales, (sls_quantity * sls_price) AS total_sales
FROM bronze.crm_sales_details
WHERE sls_sales::numeric != (sls_quantity * sls_price)::numeric
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales::numeric <= 0
    OR sls_quantity::numeric <= 0
    OR sls_price::numeric <= 0
ORDER BY sls_ord_num
