------------------------------------------------------------------------------------------
-- Demo 1.1 - SARGability
------------------------------------------------------------------------------------------

-- Check SSMS option "Actual Execution Plan"

SET NOCOUNT ON;
GO
SET STATISTICS IO, TIME ON;
GO

USE AdventureWorksPTO
GO

-- Clear the cache
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

-- Create appropriate NCIX
IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'NCOrderDate_AccountNr' AND object_id = OBJECT_ID (N'Sales.SalesOrderHeader'))
DROP INDEX NCOrderDate_AccountNr ON Sales.SalesOrderHeader
GO
CREATE INDEX NCOrderDate_AccountNr ON Sales.SalesOrderHeader (OrderDate, AccountNumber);
GO

-- Run all 2 GO delimited statements below.
-- Which one will do the Seek?
SELECT SalesOrderID, OrderDate FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2019 AND MONTH(OrderDate) = 7
GO
DECLARE @start DATETIME = '07/01/2019', @end DATETIME = '07/31/2019'
SELECT SalesOrderID, OrderDate FROM Sales.SalesOrderHeader
WHERE OrderDate BETWEEN @start AND @end
GO

-- Run all 2 GO delimited statements below.
-- Which one will do the Seek?
DECLARE @date int = DATEDIFF(dd, '2019-01-21 00:00:00.000', GETDATE())
SELECT SalesOrderID FROM Sales.SalesOrderHeader
WHERE DATEDIFF(d, OrderDate, GETDATE()) = @date
GO
DECLARE @date int = DATEDIFF(dd, '2019-01-21 00:00:00.000', GETDATE())
SELECT SalesOrderID FROM Sales.SalesOrderHeader
WHERE OrderDate = CONVERT(VARCHAR(10), DATEADD(d, -@date, GETDATE()), 101)
GO


-- Run all 2 GO delimited statements below.
-- Which one will do the Seek?
SELECT SalesOrderID FROM Sales.SalesOrderHeader
WHERE LEFT(AccountNumber, 11) = '10-4030-014'
GO
SELECT SalesOrderID FROM Sales.SalesOrderHeader
WHERE AccountNumber LIKE '10-4030-014%'
GO



-- Cleanup
IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'NCAccountNr' AND object_id = OBJECT_ID (N'Sales.SalesOrderHeader'))
DROP INDEX NCAccountNr ON Sales.SalesOrderHeader
GO
IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'NCOrderDate_AccountNr' AND object_id = OBJECT_ID (N'Sales.SalesOrderHeader'))
DROP INDEX NCOrderDate_AccountNr ON Sales.SalesOrderHeader
GO


------------------------------------------------------------------------------------------
-- Demo 1.2 - Declarative Referential Integrity (DRI) and Constraints
------------------------------------------------------------------------------------------

-- Check SSMS option "Actual Execution Plan"

SET NOCOUNT ON;
GO

USE AdventureWorksPTO 
GO

-- Will both tables be accessed?
SELECT sod.SalesOrderID, sod.UnitPrice, sod.OrderQty
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID;
GO

--No, because there is a Check Constraint between 2 tables, so there is no need to query both tables

-- Will both tables be accessed?
SELECT sod.SalesOrderID, sod.UnitPrice, sod.OrderQty
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.SalesOrderID = 43659;
GO

-- Yes, because there is a predicate on the joined table, so it has to be accessed


-- Will both tables be accessed? 
SELECT sod.SalesOrderID, sod.UnitPrice, sod.OrderQty
FROM Sales.SalesOrderDetail AS sod
WHERE sod.LineTotal > 1000
	AND EXISTS (SELECT * FROM Sales.SalesOrderHeader AS soh WHERE sod.SalesOrderID = soh.SalesOrderID);
GO

/*
Again no, because a trusted constraint exists between the joined tables on the pseudo-join key
The sub-query is correlated so the trusted constraint is used for the same purpose
*/

-- What if we un-trust the constraint?
ALTER TABLE Sales.SalesOrderDetail NOCHECK CONSTRAINT FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID;
GO

 -- Try again... Will both tables be accessed? Why?
SELECT sod.SalesOrderID, sod.UnitPrice, sod.OrderQty
FROM Sales.SalesOrderDetail AS sod
WHERE sod.LineTotal > 1000
	AND EXISTS (SELECT * FROM Sales.SalesOrderHeader AS soh WHERE sod.SalesOrderID = soh.SalesOrderID);
GO

--Trust the constraint again
ALTER TABLE Sales.SalesOrderDetail
	WITH CHECK --—> this clause will make your FK trustworthy again
	CHECK CONSTRAINT FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID
GO

-- Why aren't any tables accessing this query?
SELECT sod.SalesOrderID, sod.UnitPrice, sod.OrderQty
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE sod.UnitPrice = -5;
GO


/*
There's a constraint that mandates UnitPrice is above 0, therefore there is no need to access 
any table because the predicate is inexistent by its very definition.
*/



------------------------------------------------------------------------------------------
-- Demo 1.3 - Computed Column (Aggregation Example)
------------------------------------------------------------------------------------------
SET NOCOUNT ON;
GO

USE AdventureWorksPTO
GO

-- Begin setup

-- Create demo table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTest]') AND type in (N'U'))
DROP TABLE [dbo].[ProductTest];
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTest]') AND type in (N'U'))
CREATE TABLE [dbo].[ProductTest]
(
    [StockQty] smallint NOT NULL,
    [ProductID] int NOT NULL,
    [UnitPrice] money NOT NULL,
    [UnitPriceDiscount] money NOT NULL,
    [StockDate] DATETIME NOT NULL
);
GO

-- Populate table
INSERT INTO [dbo].[ProductTest]
SELECT [OrderQty], [ProductID], [UnitPrice], [UnitPriceDiscount], [ModifiedDate]
FROM [Sales].[SalesOrderDetail];
GO

--just updating data.  Not a query to demo.
UPDATE dbo.[ProductTest]
SET UnitPriceDiscount = ROUND((UnitPrice * ProductID % 8), 1),
	StockDate = CAST (((2013 - ProductID % 5) * 10000 + ((ProductID % 11) + 1) * 100 + ((ProductID) % 27) + 1) AS CHAR(8));
GO

-- Look at the base table and see a sample population
SELECT TOP 10 *
FROM  dbo.[ProductTest];
GO

-- End setup

-- Check SSMS option "Actual Execution Plan"

SET STATISTICS IO ON
GO

-- The query we want to look at:
-- "Find all products where total stock after discount is greater than $10000"
-- Also check the I/O stats
SELECT [StockQty], [ProductID], [UnitPrice], [UnitPriceDiscount], [StockDate], 
	(isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [StockQty], (0.0)))
FROM dbo.[ProductTest]
WHERE (isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [StockQty], (0.0))) > 10000;
GO


-- Add a computed column and create index on this computed column
ALTER TABLE [ProductTest]
ADD stockValue AS (isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [StockQty], (0.0))) PERSISTED;
GO
CREATE INDEX IX_StockValue ON dbo.[ProductTest](stockValue);
GO

-- Try the original query
-- Will SQL Server be able to pick up the index?
-- Also check the I/O stats
SELECT [StockQty], [ProductID], [UnitPrice], [UnitPriceDiscount], [StockDate], 
	(isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [StockQty], (0.0)))
FROM dbo.[ProductTest]
WHERE (isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [StockQty], (0.0))) > 10000;
GO


-- Or a bit easier to read now...
SELECT *
FROM dbo.[ProductTest]
WHERE stockValue > 10000;
GO

SET STATISTICS IO OFF
GO

-- Clean up
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTest]') AND type in (N'U'))
DROP TABLE [dbo].[ProductTest];
GO
