-- QuickBite TAE-2: MySQL DDL
DROP DATABASE IF EXISTS quickbite_db;
CREATE DATABASE quickbite_db;
USE quickbite_db;

CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    Email VARCHAR(150) NOT NULL UNIQUE,
    CHECK (Phone REGEXP '^[0-9]{10,15}$'),
    CHECK (Email LIKE '%@%.%')
);

CREATE TABLE Address (
    AddressID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    Address VARCHAR(255) NOT NULL,
    CONSTRAINT fk_address_customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Restaurant (
    RestaurantID INT AUTO_INCREMENT PRIMARY KEY,
    RestaurantName VARCHAR(150) NOT NULL,
    Cuisine VARCHAR(80) NOT NULL,
    ApprovalStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CHECK (ApprovalStatus IN ('Pending','Approved','Rejected'))
);

CREATE TABLE MenuItem (
    MenuItemID INT AUTO_INCREMENT PRIMARY KEY,
    RestaurantID INT NOT NULL,
    ItemName VARCHAR(150) NOT NULL,
    Category VARCHAR(80) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Availability BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (RestaurantID)
        REFERENCES Restaurant(RestaurantID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (Price > 0)
);

CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    RestaurantID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10,2) NOT NULL,
    OrderStatus VARCHAR(30) NOT NULL DEFAULT 'Placed',
    CONSTRAINT fk_orders_customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (RestaurantID)
        REFERENCES Restaurant(RestaurantID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (TotalAmount > 0),
    CHECK (OrderStatus IN ('Placed','Accepted','Preparing','Ready','Out for Delivery','Delivered','Cancelled'))
);

CREATE TABLE OrderItem (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    MenuItemID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_orderitem_order FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_orderitem_menu FOREIGN KEY (MenuItemID)
        REFERENCES MenuItem(MenuItemID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (Quantity > 0),
    CHECK (UnitPrice > 0)
);

CREATE TABLE Payment (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    PaymentMethod VARCHAR(30) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_payment_order FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (PaymentMethod IN ('UPI','Credit Card','Debit Card','Cash on Delivery','Wallet','Net Banking')),
    CHECK (PaymentStatus IN ('Pending','Paid','Failed','Refunded'))
);

CREATE TABLE DeliveryPartner (
    PartnerID INT AUTO_INCREMENT PRIMARY KEY,
    PartnerName VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    CHECK (Phone REGEXP '^[0-9]{10,15}$')
);

CREATE TABLE Delivery (
    DeliveryID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    PartnerID INT NOT NULL,
    DeliveryStatus VARCHAR(30) NOT NULL DEFAULT 'Assigned',
    CONSTRAINT fk_delivery_order FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_delivery_partner FOREIGN KEY (PartnerID)
        REFERENCES DeliveryPartner(PartnerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (DeliveryStatus IN ('Assigned','Picked Up','Out for Delivery','Delivered','Cancelled'))
);

CREATE TABLE Review (
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    RestaurantID INT NOT NULL,
    Rating INT NOT NULL,
    ReviewText TEXT,
    CONSTRAINT fk_review_customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_review_restaurant FOREIGN KEY (RestaurantID)
        REFERENCES Restaurant(RestaurantID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (Rating BETWEEN 1 AND 5)
);

CREATE TABLE Administrator (
    AdminID INT AUTO_INCREMENT PRIMARY KEY,
    AdminName VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    CHECK (Email LIKE '%@%.%')
);

SHOW TABLES;
