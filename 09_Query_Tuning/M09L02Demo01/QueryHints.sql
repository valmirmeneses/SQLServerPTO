------------------------------------------------------------------------------------------
-- Demo 2.1 - Query Hints
------------------------------------------------------------------------------------------

-- Check SSMS option "Actual Execution Plan"

SET NOCOUNT ON;
GO

-- Begin setup

CREATE INDEX IX_SOH_OrderDate
ON Sales.SalesOrderHeader(OrderDate, CustomerID, TotalDue);

-- End setup

/* 
Execute the query below and show the execution plan, click on "SELECT" operation and review 
the subtree query cost, it will be 0.023, also show the Merge Join (Union) operation.
*/

SELECT *  
FROM HumanResources.Employee AS e1  
UNION  
SELECT *  
FROM HumanResources.Employee AS e2 

/*
Then execute the query including "OPTION (HASH UNION)" query hint, and show  the subtree query cost, 
it will be a litte bit lower 0.021. Also show the Hash Match (Union) operation.
*/

SELECT *  
FROM HumanResources.Employee AS e1  
UNION  
SELECT *  
FROM HumanResources.Employee AS e2  
OPTION (HASH UNION);  
GO  

/* 
Now execute the query below and show the execution plan, click on "Clustered Index Scan" operation 
and review its properties, expand "Actual Number of Rows" showing the number of threads used
by the optimizer. Note: thread number 0 is not taken into consideration, you can see 0 rows
were processed. Review MaxDOP configuration and the total of logical CPU's.
*/

SELECT *
FROM Sales.SalesOrderDetail
ORDER BY ProductID
GO

/* 
Then execute it again including "OPTION (MAXDOP 2)", show the execution plan, click on "Clustered Index 
Scan" operation and review its properties, expand "Actual Number of Rows" showing the number of threads 
used by the optimizer. The number of threads must be the same compared to the number specified by 
the MAXDOP hint.
*/

SELECT *
FROM Sales.SalesOrderDetail
ORDER BY ProductID
OPTION (MAXDOP 2);    
GO

/* 
Finally execute it again specifying "OPTION (MAXDOP 1)", show the execution plan, click on "Clustered 
Index Scan" operation and review its properties and "Actual Number of Rows". The execution plan
is not using parallelism as MAXDOP = 1 means the processing will be serialized. If you show the subtree
cost, you will notice this will be the costliest option.
*/

SELECT *
FROM Sales.SalesOrderDetail
ORDER BY ProductID
OPTION (MAXDOP 1);    
GO


-- Execute next 3 statement in a bunddle. 

DECLARE @start_date DATETIME = '20050101', @end_date DATETIME = '20190101';

SELECT SalesOrderID, OrderDate, CustomerID, TotalDue, OnlineOrderFlag
FROM Sales.SalesOrderHeader WITH (FORCESCAN)
WHERE OrderDate >= @start_date
AND OrderDate < @end_date;

SELECT SalesOrderID, OrderDate, CustomerID, TotalDue, OnlineOrderFlag
FROM Sales.SalesOrderHeader WITH (FORCESEEK)
WHERE OrderDate >= @start_date
AND OrderDate < @end_date;

/* 
Show the 2 execution plans, which one has the highest subtree cost? Is it always better to use an Index 
Seek over a Scan operation?
*/


-- Clean up

DROP INDEX [IX_SOH_OrderDate] ON [Sales].[SalesOrderHeader]
GO