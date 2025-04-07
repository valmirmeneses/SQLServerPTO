-- Step 1: Warm the buffer pool cache to make it a fair comparison
USE [WideWorldImportersDW]
GO
SELECT COUNT(*) FROM Fact.OrderHistoryExtended
GO

-- Step 2: Clear the procedure cache and change dbcompat to 130 to show previous behavior
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE
GO
ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 130
GO

-- Step 3: Run the query
-- IMPORTANT:  Enable the option to "Include Actual Execution Plan" (Ctrl+M) 

SET STATISTICS PROFILE ON
GO
SELECT [Tax Rate], [Lineage Key], [Salesperson Key], SUM(Quantity) AS SUM_QTY, 
SUM([Unit Price]) AS SUM_BASE_PRICE, COUNT(*) AS COUNT_ORDER
FROM Fact.OrderHistoryExtended
WHERE [Order Date Key]<=DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate], [Lineage Key], [Salesperson Key]
ORDER BY [Tax Rate], [Lineage Key], [Salesperson Key]
GO
SET STATISTICS PROFILE OFF
GO

-- Note the execution time: around 16 seconds
-- See the execution plan:
--		Notice the Actual Execution Mode for the Table Scan Operator on the OrderHistoryExtended table = Row
--		Notice the cost of the query 755.858

-- Step 4: Clear the procedure cache and change dbcompat to 150 to enable batch mode
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE
GO
ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 150
GO

-- Step 5: Now let's run it again 
SET STATISTICS PROFILE ON
GO
SELECT [Tax Rate], [Lineage Key], [Salesperson Key], SUM(Quantity) AS SUM_QTY, 
SUM([Unit Price]) AS SUM_BASE_PRICE, COUNT(*) AS COUNT_ORDER
FROM Fact.OrderHistoryExtended
WHERE [Order Date Key]<=DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate], [Lineage Key], [Salesperson Key]
ORDER BY [Tax Rate], [Lineage Key], [Salesperson Key]
GO
SET STATISTICS PROFILE OFF
GO
-- Note the execution time: around 2 seconds. It is much faster
-- See the execution plan:
--		Notice the Actual Execution Mode for the Table Scan Operator on the OrderHistoryExtended table = Batch
--		Notice the cost of the query 681.05
