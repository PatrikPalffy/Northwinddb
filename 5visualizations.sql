--the number of customers per country
SELECT 
    Country AS country,
    COUNT(*) AS appearance
FROM 
    customers_staging
GROUP BY 
    Country
ORDER BY 
    appearance DESC;

--Total Quantity Ordered per Product    
SELECT 
    ProductID AS product_id,
    SUM(Quantity) AS total_quantity
FROM 
    order_details_staging
GROUP BY 
    ProductID
ORDER BY 
    ProductID;

--Top 10 Shippers by Number of Orders    
SELECT 
    s.CompanyName AS shipper_name,
    COUNT(o.OrderID) AS total_orders
FROM 
    orders_staging o
JOIN 
    suppliers_staging s ON o.ShipVia = s.SupplierID
GROUP BY 
    s.CompanyName
ORDER BY 
    total_orders DESC;


 --Number of Orders Shipped by Country
SELECT 
    o.ShipCountry AS country,
    COUNT(o.OrderID) AS total_orders_shipped
FROM 
    orders_staging o
GROUP BY 
    o.ShipCountry
ORDER BY 
    total_orders_shipped DESC;

--Average Order Value by Customer
SELECT 
    c.CompanyName AS customer_name,
    AVG(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS avg_order_value
FROM 
    order_details_staging od
JOIN 
    orders_staging o ON od.OrderID = o.OrderID
JOIN 
    customers_staging c ON o.CustomerID = c.CustomerID
GROUP BY 
    c.CompanyName
ORDER BY 
    avg_order_value DESC;