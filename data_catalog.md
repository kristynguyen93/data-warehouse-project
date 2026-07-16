# Data Catalog for Gold Layer
---

### 1. **gold.dim_customers**
- **Purpose:** Customer Information
- **Columns:**

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| customer_key     | INTEGER       | Surrogate key uniquely identifying each customer record in the dimension table                |
| customer_id      | INTEGER       | Unique numerical identifier assigned to each customer                                         |
| customer_number  | VARCHAR(50)   | Alphanumeric identifier representing the customer                                             |
| first_name       | VARCHAR(50)   | Customer's first name                                                                         |
| last_name        | VARCHAR(50)   | Customer's last name                                                                          |
| country          | VARCHAR(50)   | Country where the customer is from                                                            |
| marital_status   | VARCHAR(50)   | Customer's marital status ('Married', 'Single', 'Unknown').                                   |
| gender           | VARCHAR(50)   | Customer's gender ('Male', 'Female', 'Unknown').                                              |
| birthdate        | DATE          | Customer's birthdate formatted as YYYY-MM-DD                                                  |
| create_date      | DATE          | The date and time when the customer record was created in the system                          |

---

### 2. **gold.dim_products**
- **Purpose:** Product Information
- **Columns:**

| Column Name         | Data Type    | Description                                                                                   |
|---------------------|--------------|-----------------------------------------------------------------------------------------------|
| product_key         | INTEGER      | Surrogate key uniquely identifying each product record in the product dimension table         |
| product_id          | INTEGER      | A unique identifier assigned to the product                                                   |
| product_number      | VARCHAR(50)  | Alphanumeric code representing the product                                                    |
| product_name        | VARCHAR(50)  | Descriptive name of the product                                                               |
| category_id         | VARCHAR(50)  | Category ID                                                                                   |
| category            | VARCHAR(50)  | Broader classification of the product                                                         |
| subcategory         | VARCHAR(50)  | A more detailed classification of the product within the category                             |
| maintenance_required| VARCHAR(50)  | Indicates whether the product requires maintenance ('Yes', 'No').                             |
| cost                | INTEGER      | The cost of the product                                                                       |
| product_line        | VARCHAR(50)  | Product line                                                                                  |
| start_date          | DATE         | The date when the product became available                                                    |

---

### 3. **gold.fact_sales**
- **Purpose:** Order / Sales transactions
- **Columns:**

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| order_number    | VARCHAR(50)   | A unique alphanumeric identifier for each order                                               |
| product_key     | INT           | Surrogate key linking the order to the product dimension table.                               |
| customer_key    | INT           | Surrogate key linking the order to the customer dimension table.                              |
| order_date      | DATE          | Order date                                                                                    |
| shipping_date   | DATE          | Shipping date                                                                                 |
| due_date        | DATE          | Payment due date                                                                              |
| sales_amount    | INT           | Total sale amount                                                                             |
| quantity        | INT           | The number of units of the product                                                            |
| price           | INT           | The price per unit of the product                                                             |
