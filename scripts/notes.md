crm_cust_info - Contains customer information
    cst_id is the primary key
    cst_key can also be a reference key
    cst_firstname
    cst_lastname
    cst_marital_status
    cst_gndr
    cst_create_date

    -- things to check:
        - white spaces around cst_firstname and cst_lastname
        - cst_marital_status spell out status, set unknown for NULL
        - cst_gndr spell out gender, set unknown for NULL
        - cst_create_date check for NULL or 0

crm_prd_info - Contains information about the product
    prd_id
    prd_key - primary key - 7th character til end (first 5 characters are category id)
    prd_nm
    prd_cost
    prd_line
    prd_start_dt
    prd_end_dt

    -- Things to check:
        - Create cat_id column from the first 5 char of prod_key
        - set prod_key from 7-last char
        - prd_start_dt check for NULL or 0
        - check if prd_end_dt is after prd_start_dt
        - check if date is valid - must be 8 char

cst_sales_details - Contains information on sales/orders
    sls_ord_num - primary key
    sls_prd_key - foreign key to prd_key in crm_prd_info
    sls_cust_id - foreign key to cst_id in crm_cust_info
    sls_order_dt
    sls_ship_dt
    sls_due_dt
    sls_sales
    sls_quantity
    sls_price

    -- Things to check:
        - sls_prd_key must exist in crm_prd_info - prd_key
        - sls_cst_id must exist in crm_cust_info - cst_id
        - sls_order_dt, sls_due_dt, sls_due_dt check for 0 or negatives, check if date is valid - must be 8 char, check if sls_order_dt<= sls_due_dt <= sls_due_dt

erp_cust_az12
    cid - foreign key to cst_key in crm_cust_info
    bdate
    gen

    -- Things to check:
        - cid = crm_cust_info cst_id
        - gen = crm_cust_info cst_gndr

erp_loc_a101
    cid - foreign key to cst_key in crm_cust_info
    cntry

    -- Things to check:
        - cid = crm_cust_info cst_id

erp_px_cat_g1v2
    id - primary key
    cat
    subcat

    -- Things to check:
        - id = crm_prd_info cat_id