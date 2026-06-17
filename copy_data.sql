COPY bronze.crm_cust_info FROM '/tmp/datasets/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

COPY bronze.crm_prd_info FROM '/tmp/datasets/source_crm/prd_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

COPY bronze.crm_sales_details FROM '/tmp/datasets/source_crm/sales_details.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Converting columns to DATE data type, handling empty strings and invalid formats by setting them to NULL
ALTER TABLE bronze.crm_sales_details
    ALTER COLUMN sls_order_dt TYPE DATE
    USING (
        CASE
            WHEN sls_order_dt = '' OR length(sls_order_dt) < 8 THEN NULL
            ELSE TO_DATE(sls_order_dt, 'YYYYMMDD')
        END
    ),
    ALTER COLUMN sls_ship_dt TYPE DATE
    USING (
        CASE
            WHEN sls_ship_dt = '' OR length(sls_ship_dt) < 8 THEN NULL
            ELSE TO_DATE(sls_ship_dt, 'YYYYMMDD')
        END
    ),
    ALTER COLUMN sls_due_dt TYPE DATE
    USING (
        CASE
            WHEN sls_due_dt = '' OR length(sls_due_dt) < 8 THEN NULL
            ELSE TO_DATE(sls_due_dt, 'YYYYMMDD')
        END
    );

COPY bronze.erp_cust_az12 FROM '/tmp/datasets/source_erp/CUST_AZ12.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

COPY bronze.erp_loc_a101 FROM '/tmp/datasets/source_erp/LOC_A101.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

COPY bronze.erp_px_cat_g1v2 FROM '/tmp/datasets/source_erp/PX_CAT_G1V2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');