CREATE DATABASE IF NOT EXISTS FINCH_NW_DB;
USE DATABASE FINCH_NW_DB;

CREATE SCHEMA IF NOT EXISTS FINCh_NW_DB.STAGING;
USE SCHEMA FINCH_NW_DB.STAGING;

CREATE OR REPLACE STAGE FICNH_NW_STAGE




CREATE OR REPLACE TABLE customers_staging (
    CustomerID   VARCHAR,
    CompanyName  VARCHAR,
    ContactName  VARCHAR,
    ContactTitle VARCHAR,
    City         VARCHAR,
    Region       VARCHAR,
    PosCode      VARCHAR,
    Country      VARCHAR,
    Phone        VARCHAR,
    Fax          VARCHAR
);
ALTER TABLE customers_staging
DROP COLUMN Address;



CREATE OR REPLACE TABLE employees_staging (
    EmployeeID       NUMBER,
    LastName         VARCHAR,
    FirstName        VARCHAR,
    Title            VARCHAR,
    TitleOfCourtesy  VARCHAR,
    BirthDate        DATE,  
    HireDate         DATE,  
    Address          VARCHAR,
    City             VARCHAR,
    Region           VARCHAR,
    PostalCode       VARCHAR,
    Country          VARCHAR,
    HomePhone        VARCHAR,
    Extension        VARCHAR,
    Photo            VARCHAR,
    Notes            VARCHAR,
    ReportsTo        NUMBER,
    PhotoPath        VARCHAR
);


CREATE OR REPLACE TABLE order_details_staging (
    OrderID   NUMBER,
    ProductID NUMBER,
    UnitPrice NUMBER,
    Quantity  NUMBER,
    Discount  NUMBER
);


CREATE OR REPLACE TABLE orders_staging (
    OrderID        NUMBER,
    CustomerID     VARCHAR,
    EmployeeID     NUMBER,
    OrderDate      DATE,
    RequiredDate   DATE,
    ShippedDate    DATE,
    ShipVia        NUMBER,
    Freight        NUMBER,
    ShipName       VARCHAR,
    ShipCity       VARCHAR,
    ShipRegion     VARCHAR,
    ShipPostalCode VARCHAR,
    ShipCountry    VARCHAR
);



CREATE OR REPLACE TABLE products_staging (
    ProductID      NUMBER,
    ProductName    VARCHAR,
    SupplierID     NUMBER,
    CategoryID     NUMBER,
    QuantityPerUnit VARCHAR,
    UnitPrice      NUMBER,
    UnitsInStock   NUMBER,
    UnitsOnOrder   NUMBER,
    ReorderLevel   NUMBER,
    Discontinued   NUMBER
);




CREATE OR REPLACE TABLE suppliers_staging (
    SupplierID   NUMBER,
    CompanyName  VARCHAR,
    ContactName  VARCHAR,
    ContactTitle VARCHAR,
    Address      VARCHAR,
    City         VARCHAR,
    Region       VARCHAR,
    PostalCode   VARCHAR,
    Country      VARCHAR,
    Phone        VARCHAR,
    Fax          VARCHAR,
    HomePage     VARCHAR
);





COPY INTO customers_staging
FROM @FICNH_NW_STAGE/customers.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);

COPY INTO employees_staging
FROM @FICNH_NW_STAGE/employees.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);

COPY INTO order_details_staging
FROM @FICNH_NW_STAGE/orders_details.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);


COPY INTO orders_staging
FROM @FICNH_NW_STAGE/orders.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

COPY INTO products_staging
FROM @FICNH_NW_STAGE/products.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);

COPY INTO suppliers_staging
FROM @FICNH_NW_STAGE/suppliers.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);


CREATE OR REPLACE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    month INT,
    day_of_month INT,
    day_name VARCHAR(45),
    month_name VARCHAR(45)
);

CREATE OR REPLACE TABLE dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id INT NOT NULL,
    company_name VARCHAR(45),
    contact_name VARCHAR(45),
    contact_title VARCHAR(45),
    address VARCHAR(45),
    city VARCHAR(45),
    region VARCHAR(45),
    postal_code VARCHAR(45),
    country VARCHAR(45),
    phone VARCHAR(45)
);

CREATE OR REPLACE TABLE dim_employee (
    employee_key INT PRIMARY KEY,
    employee_id INT NOT NULL,
    last_name VARCHAR(45),
    first_name VARCHAR(45),
    title VARCHAR(45),
    city VARCHAR(45),
    country VARCHAR(45)
);

CREATE OR REPLACE TABLE dim_shipper (
    shipper_key INT PRIMARY KEY,
    shipper_id INT NOT NULL,
    company_name VARCHAR(45),
    phone VARCHAR(45)
);

CREATE OR REPLACE TABLE dim_product (
    product_key INT PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(45),
    category_name VARCHAR(45),
    supplier_name VARCHAR(45),
    standard_price FLOAT,
    discontinued TINYINT
);


CREATE OR REPLACE TABLE fact_order_details (
    fact_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT,
    quantity FLOAT,
    unit_price FLOAT,
    discount FLOAT,
    extended_price FLOAT,
    order_date_key INT,
    shipped_date_key INT,
    customer_key INT,
    employee_key INT,
    shipper_key INT,
    product_key INT
);