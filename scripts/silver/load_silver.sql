CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $BODY$
DECLARE 
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
BEGIN   
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '========================================';

    -- CRM: cust_info
    RAISE NOTICE 'Loading silver.crm_cust_info...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    WITH no_duplicates AS (
        SELECT *
        FROM (
            SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rank
            FROM bronze.crm_cust_info
        ) rownumbered
        WHERE rank = 1 
        ) 
    SELECT cst_id, -- Remove duplicates based on cst_id, keeping the most recent record based on cst
        cst_key,
        TRIM(cst_firstname) AS cst_firstname, -- Trim whitespace from cst_firstname
        TRIM(cst_lastname) AS cst_lastname,-- Trim whitespace from cst_lastname
        CASE 
            WHEN cst_marital_status = 'M' THEN 'Married'
            WHEN cst_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS cst_marital_status, -- Convert cst_marital_status to more readable formats
        CASE 
            WHEN cst_gndr = 'M' THEN 'Male'
            WHEN cst_gndr = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS cst_gndr, -- Convert cst_gndr to more readable formats
        cst_create_date
    FROM no_duplicates
    ORDER BY cst_id;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- CRM: prd_info
    RAISE NOTICE 'Loading silver.crm_prd_info...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
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
    FROM bronze.crm_prd_info;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- CRM: sales_details
    RAISE NOTICE 'Loading silver.crm_sales_details...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        CASE WHEN sls_sales::numeric <= 0 OR sls_sales::numeric != (sls_quantity::numeric * sls_price::numeric) OR sls_sales IS NULL 
            THEN ABS(sls_quantity::numeric * sls_price::numeric)
        ELSE sls_sales::numeric
        END AS sls_sales, -- Correcting sls_sales values based on quantity and price
        sls_quantity,
        CASE WHEN sls_price::numeric <= 0 OR sls_price IS NULL
            THEN ABS(sls_sales::numeric / NULLIF(sls_quantity::numeric, 0))
        ELSE sls_price END AS sls_price -- Correcting sls_price values based on sales and quantity
    FROM bronze.crm_sales_details;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: erp_cust_az12
    RAISE NOTICE 'Loading silver.erp_cust_az12...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (
        cid, 
        bdate, 
        gen
    )
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) 
        ELSE cid END AS cid, -- Removing 'NAS' prefix from cid values
        CASE WHEN bdate > NOW() THEN NULL ELSE bdate END AS bdate, -- Setting bdate to NULL if it is in the future
        CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            ELSE 'Unknown' END AS gen -- Converting gen values to more readable formats
    FROM bronze.erp_cust_az12;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: erp_loc_a101
    RAISE NOTICE 'Loading silver.erp_loc_a101...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT REPLACE(cid, '-', '') AS cid, -- Removing hyphens from cid values
        CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'Unknown'
            ELSE TRIM(cntry) END AS cntry -- Standardizing country names and replacing NULL or empty strings with 'Unknown'
    FROM bronze.erp_loc_a101;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: erp_px_cat_g1v2
    RAISE NOTICE 'Loading silver.erp_px_cat_g1v2...';
    v_start_time := clock_timestamp();

    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT *
    FROM bronze.erp_px_cat_g1v2;
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));
        
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Silver layer load complete';
    RAISE NOTICE '========================================';

EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE 'ERROR: % %', SQLERRM, SQLSTATE;
    RAISE;

END;
$BODY$;

ALTER PROCEDURE silver.load_silver()
    OWNER TO postgres;

CALL silver.load_silver();