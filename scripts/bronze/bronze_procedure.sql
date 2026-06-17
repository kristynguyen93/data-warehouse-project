CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '========================================';

    -- CRM: cust_info
    RAISE NOTICE 'Loading bronze.crm_cust_info...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;
    COPY bronze.crm_cust_info FROM '/tmp/datasets/source_crm/cust_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- CRM: prd_info
    RAISE NOTICE 'Loading bronze.crm_prd_info...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;
    COPY bronze.crm_prd_info FROM '/tmp/datasets/source_crm/prd_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- CRM: sales_details
    RAISE NOTICE 'Loading bronze.crm_sales_details...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;

    -- Reset date columns to TEXT so COPY loads raw values without parsing
    ALTER TABLE bronze.crm_sales_details
        ALTER COLUMN sls_order_dt TYPE TEXT USING sls_order_dt::TEXT,
        ALTER COLUMN sls_ship_dt  TYPE TEXT USING sls_ship_dt::TEXT,
        ALTER COLUMN sls_due_dt   TYPE TEXT USING sls_due_dt::TEXT;

    COPY bronze.crm_sales_details FROM '/tmp/datasets/source_crm/sales_details.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

    -- Safely cast to DATE, nullifying invalid values
    ALTER TABLE bronze.crm_sales_details
        ALTER COLUMN sls_order_dt TYPE DATE
        USING (CASE WHEN sls_order_dt IS NULL OR sls_order_dt = ''
                      OR length(sls_order_dt) < 8
                      OR sls_order_dt ~ '[^0-9]'
                    THEN NULL
                    ELSE TO_DATE(sls_order_dt, 'YYYYMMDD') END),
        ALTER COLUMN sls_ship_dt TYPE DATE
        USING (CASE WHEN sls_ship_dt IS NULL OR sls_ship_dt = ''
                      OR length(sls_ship_dt) < 8
                      OR sls_ship_dt ~ '[^0-9]'
                    THEN NULL
                    ELSE TO_DATE(sls_ship_dt, 'YYYYMMDD') END),
        ALTER COLUMN sls_due_dt TYPE DATE
        USING (CASE WHEN sls_due_dt IS NULL OR sls_due_dt = ''
                      OR length(sls_due_dt) < 8
                      OR sls_due_dt ~ '[^0-9]'
                    THEN NULL
                    ELSE TO_DATE(sls_due_dt, 'YYYYMMDD') END);

    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: cust_az12
    RAISE NOTICE 'Loading bronze.erp_cust_az12...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;
    COPY bronze.erp_cust_az12 FROM '/tmp/datasets/source_erp/CUST_AZ12.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: loc_a101
    RAISE NOTICE 'Loading bronze.erp_loc_a101...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;
    COPY bronze.erp_loc_a101 FROM '/tmp/datasets/source_erp/LOC_A101.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- ERP: px_cat_g1v2
    RAISE NOTICE 'Loading bronze.erp_px_cat_g1v2...';
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    COPY bronze.erp_px_cat_g1v2 FROM '/tmp/datasets/source_erp/PX_CAT_G1V2.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
    v_end_time := clock_timestamp();
    RAISE NOTICE '>> Done in % seconds', EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Bronze layer load complete';
    RAISE NOTICE '========================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: % %', SQLERRM, SQLSTATE;
        RAISE;
END;
$BODY$;

ALTER PROCEDURE bronze.load_bronze()
    OWNER TO postgres;

CALL bronze.load_bronze();