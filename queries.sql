-- QuickBite TAE-2 Advanced SQL
USE quickbite_db;

-- =========================================================
-- 1. INNER JOIN: Order details with customer and restaurant
-- =========================================================
SELECT
    o.OrderID,
    c.CustomerName,
    r.RestaurantName,
    o.OrderDate,
    o.TotalAmount,
    o.OrderStatus
FROM Orders o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Restaurant r ON o.RestaurantID = r.RestaurantID
ORDER BY o.OrderDate DESC;

-- =========================================================
-- 2. MULTI-TABLE JOIN: Detailed delivered-order report
-- =========================================================
SELECT
    o.OrderID,
    c.CustomerName,
    r.RestaurantName,
    dp.PartnerName,
    p.PaymentMethod,
    p.PaymentStatus,
    d.DeliveryStatus,
    o.TotalAmount
FROM Orders o
JOIN Customer c ON o.CustomerID = c.CustomerID
JOIN Restaurant r ON o.RestaurantID = r.RestaurantID
JOIN Payment p ON o.OrderID = p.OrderID
JOIN Delivery d ON o.OrderID = d.OrderID
JOIN DeliveryPartner dp ON d.PartnerID = dp.PartnerID
WHERE o.OrderStatus = 'Delivered'
ORDER BY o.TotalAmount DESC;

-- =========================================================
-- 3. LEFT OUTER JOIN: Customers with or without orders
-- =========================================================
SELECT
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalOrders DESC;

-- =========================================================
-- 4. SELF JOIN: Restaurants offering the same cuisine
-- =========================================================
SELECT
    r1.RestaurantName AS Restaurant1,
    r2.RestaurantName AS Restaurant2,
    r1.Cuisine
FROM Restaurant r1
JOIN Restaurant r2
    ON r1.Cuisine = r2.Cuisine
   AND r1.RestaurantID < r2.RestaurantID
ORDER BY r1.Cuisine, r1.RestaurantName;

-- =========================================================
-- 5. AGGREGATE + GROUP BY + HAVING
-- Restaurants with at least 5 orders
-- =========================================================
SELECT
    r.RestaurantID,
    r.RestaurantName,
    COUNT(o.OrderID) AS TotalOrders,
    ROUND(AVG(o.TotalAmount), 2) AS AverageOrderValue,
    ROUND(SUM(o.TotalAmount), 2) AS Revenue
FROM Restaurant r
JOIN Orders o ON r.RestaurantID = o.RestaurantID
GROUP BY r.RestaurantID, r.RestaurantName
HAVING COUNT(o.OrderID) >= 5
ORDER BY Revenue DESC;

-- =========================================================
-- 6. CORRELATED SUBQUERY
-- Customers whose spending is above their own average order value
-- =========================================================
SELECT
    o.OrderID,
    o.CustomerID,
    o.TotalAmount,
    o.OrderDate
FROM Orders o
WHERE o.TotalAmount > (
    SELECT AVG(o2.TotalAmount)
    FROM Orders o2
    WHERE o2.CustomerID = o.CustomerID
)
ORDER BY o.CustomerID, o.TotalAmount DESC;

-- =========================================================
-- 7. CORRELATED SUBQUERY
-- Restaurants whose average rating is above the overall average
-- =========================================================
SELECT
    r.RestaurantID,
    r.RestaurantName,
    (
        SELECT ROUND(AVG(rv.Rating), 2)
        FROM Review rv
        WHERE rv.RestaurantID = r.RestaurantID
    ) AS RestaurantAverageRating
FROM Restaurant r
WHERE (
    SELECT AVG(rv.Rating)
    FROM Review rv
    WHERE rv.RestaurantID = r.RestaurantID
) > (
    SELECT AVG(Rating)
    FROM Review
)
ORDER BY RestaurantAverageRating DESC;

-- =========================================================
-- 8. BUSINESS REPORTING VIEW: Restaurant performance
-- =========================================================
CREATE OR REPLACE VIEW vw_RestaurantPerformance AS
SELECT
    r.RestaurantID,
    r.RestaurantName,
    r.Cuisine,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ROUND(COALESCE(SUM(o.TotalAmount), 0), 2) AS TotalRevenue,
    ROUND(AVG(rv.Rating), 2) AS AverageRating
FROM Restaurant r
LEFT JOIN Orders o ON r.RestaurantID = o.RestaurantID
LEFT JOIN Review rv ON r.RestaurantID = rv.RestaurantID
GROUP BY r.RestaurantID, r.RestaurantName, r.Cuisine;

SELECT * FROM vw_RestaurantPerformance
ORDER BY TotalRevenue DESC;

-- =========================================================
-- 9. BUSINESS REPORTING VIEW: Customer order summary
-- =========================================================
CREATE OR REPLACE VIEW vw_CustomerOrderSummary AS
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Email,
    COUNT(o.OrderID) AS TotalOrders,
    ROUND(COALESCE(SUM(o.TotalAmount), 0), 2) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Email;

SELECT * FROM vw_CustomerOrderSummary
ORDER BY TotalSpent DESC;

-- =========================================================
-- 10. PARAMETERIZED STORED PROCEDURE
-- Places one order for one menu item.
-- =========================================================
DROP PROCEDURE IF EXISTS sp_PlaceOrder;

DELIMITER $$

CREATE PROCEDURE sp_PlaceOrder(
    IN p_CustomerID INT,
    IN p_RestaurantID INT,
    IN p_MenuItemID INT,
    IN p_Quantity INT,
    IN p_PaymentMethod VARCHAR(30)
)
BEGIN
    DECLARE v_Price DECIMAL(10,2);
    DECLARE v_Total DECIMAL(10,2);
    DECLARE v_OrderID INT;
    DECLARE v_MenuRestaurantID INT;
    DECLARE v_Availability BOOLEAN;

    IF p_Quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;

    SELECT RestaurantID, Price, Availability
    INTO v_MenuRestaurantID, v_Price, v_Availability
    FROM MenuItem
    WHERE MenuItemID = p_MenuItemID;

    IF v_MenuRestaurantID IS NULL OR v_MenuRestaurantID <> p_RestaurantID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Menu item does not belong to the selected restaurant';
    END IF;

    IF v_Availability = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Menu item is currently unavailable';
    END IF;

    SET v_Total = v_Price * p_Quantity;

    START TRANSACTION;

    INSERT INTO Orders
        (CustomerID, RestaurantID, OrderDate, TotalAmount, OrderStatus)
    VALUES
        (p_CustomerID, p_RestaurantID, NOW(), v_Total, 'Placed');

    SET v_OrderID = LAST_INSERT_ID();

    INSERT INTO OrderItem
        (OrderID, MenuItemID, Quantity, UnitPrice)
    VALUES
        (v_OrderID, p_MenuItemID, p_Quantity, v_Price);

    INSERT INTO Payment
        (OrderID, PaymentMethod, PaymentStatus)
    VALUES
        (v_OrderID, p_PaymentMethod, 'Pending');

    COMMIT;

    SELECT
        v_OrderID AS NewOrderID,
        v_Total AS TotalAmount,
        'Order placed successfully' AS Message;
END$$

DELIMITER ;

-- Example:
-- CALL sp_PlaceOrder(1, 1, 1, 2, 'UPI');

-- =========================================================
-- 11. TRIGGER
-- When payment becomes Paid, automatically accept a Placed order.
-- =========================================================
DROP TRIGGER IF EXISTS trg_PaymentPaid_AcceptOrder;

DELIMITER $$

CREATE TRIGGER trg_PaymentPaid_AcceptOrder
AFTER UPDATE ON Payment
FOR EACH ROW
BEGIN
    IF NEW.PaymentStatus = 'Paid'
       AND OLD.PaymentStatus <> 'Paid' THEN
        UPDATE Orders
        SET OrderStatus = 'Accepted'
        WHERE OrderID = NEW.OrderID
          AND OrderStatus = 'Placed';
    END IF;
END$$

DELIMITER ;

-- Trigger test:
-- UPDATE Payment
-- SET PaymentStatus = 'Paid'
-- WHERE PaymentID = 1;
--
-- SELECT OrderID, OrderStatus
-- FROM Orders
-- WHERE OrderID = 1;

-- =========================================================
-- 12. Additional business query
-- Top delivery partners by completed deliveries
-- =========================================================
SELECT
    dp.PartnerID,
    dp.PartnerName,
    COUNT(d.DeliveryID) AS CompletedDeliveries
FROM DeliveryPartner dp
JOIN Delivery d ON dp.PartnerID = d.PartnerID
WHERE d.DeliveryStatus = 'Delivered'
GROUP BY dp.PartnerID, dp.PartnerName
HAVING COUNT(d.DeliveryID) >= 2
ORDER BY CompletedDeliveries DESC;
