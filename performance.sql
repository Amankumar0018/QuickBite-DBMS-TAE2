-- QuickBite TAE-2 Performance Testing
USE quickbite_db;

-- =========================================================
-- QUERY 1: Customer order filtering
-- BEFORE INDEX
-- =========================================================
EXPLAIN
SELECT
    CustomerID,
    OrderID,
    OrderDate,
    TotalAmount,
    OrderStatus
FROM Orders
WHERE CustomerID = 50
  AND OrderStatus = 'Delivered'
ORDER BY OrderDate DESC;

-- =========================================================
-- Create composite index
-- =========================================================
CREATE INDEX idx_orders_customer_status_date
ON Orders (CustomerID, OrderStatus, OrderDate);

-- AFTER INDEX
EXPLAIN
SELECT
    CustomerID,
    OrderID,
    OrderDate,
    TotalAmount,
    OrderStatus
FROM Orders
WHERE CustomerID = 50
  AND OrderStatus = 'Delivered'
ORDER BY OrderDate DESC;

-- =========================================================
-- QUERY 2: Restaurant order reporting
-- BEFORE INDEX
-- =========================================================
EXPLAIN
SELECT
    RestaurantID,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE RestaurantID = 25
  AND OrderDate >= '2026-04-01'
GROUP BY RestaurantID;

-- =========================================================
-- Create composite index
-- =========================================================
CREATE INDEX idx_orders_restaurant_date
ON Orders (RestaurantID, OrderDate);

-- AFTER INDEX
EXPLAIN
SELECT
    RestaurantID,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE RestaurantID = 25
  AND OrderDate >= '2026-04-01'
GROUP BY RestaurantID;

-- =========================================================
-- Optional: show created indexes
-- =========================================================
SHOW INDEX FROM Orders;
