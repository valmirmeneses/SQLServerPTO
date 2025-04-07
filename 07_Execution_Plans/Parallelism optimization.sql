/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/

SET NOCOUNT ON;

USE AdventureWorksPTO;
GO

-- IMPORTANT:  Enable the option to "Include Actual Execution Plan" (Ctrl+M) 

-- We're using the MERGE join hint to bump up the query cost thereby forcing a parallel plan.  
SELECT sod.SalesOrderID, sod.OrderQty, p.ProductID, p.Name
FROM Production.Product p
     INNER MERGE JOIN Sales.SalesOrderDetail sod ON sod.ProductID = p.ProductID;
GO

/*	Hold your cursor over the SELECT operator in the graphical plan to see 
	the estimated subtree cost of the query and the Degree of parallelism

	Show the parallelism operator and the little orange circle with to arrows that 
	indicates parallelism

*/

-- Show the actual configuration for the Max Degree of Parallelism and
-- cost threshold for parallelism of the instance
select name, value_in_use 
from sys.configurations 
where name IN ('max degree of parallelism', 'cost threshold for parallelism')


-- Limit execution to a serial plan by using the MAXDOP=1 hint
SELECT sod.SalesOrderID, sod.OrderQty, p.ProductID, p.Name
FROM Production.Product p
     INNER MERGE JOIN Sales.SalesOrderDetail sod ON sod.ProductID = p.ProductID
OPTION ( MAXDOP 1 );

/*	Hold your cursor over the SELECT operator in the graphical plan to see 
	the estimated subtree cost of the query
	StatementSubTreeCost="10.7556"

	The high estimated subtree cost of this plan (10.7556) would normally trigger
	the search for a parallel query plan, but we've prevented that with our 
	MAXDOP hint.
*/

-- Change the cost threshold for parallelism to a high value
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50'
GO
RECONFIGURE WITH OVERRIDE
GO


-- Execute the query again 
SELECT sod.SalesOrderID, sod.OrderQty, p.ProductID, p.Name
FROM Production.Product p
     INNER MERGE JOIN Sales.SalesOrderDetail sod ON sod.ProductID = p.ProductID;
GO

/*	Hold your cursor over the SELECT operator in the graphical plan to see 
	the estimated subtree cost of the query
	StatementSubTreeCost="10.7556"

	This time it does not use parallelism because the cost in under the new threshold
*/

-- Change the cost threshold for parallelism to the default value
EXEC sys.sp_configure N'cost threshold for parallelism', N'5'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Change the max degree of parallelism to 1 
EXEC sys.sp_configure N'max degree of parallelism', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Execute the query again 
SELECT sod.SalesOrderID, sod.OrderQty, p.ProductID, p.Name
FROM Production.Product p
     INNER MERGE JOIN Sales.SalesOrderDetail sod ON sod.ProductID = p.ProductID;
GO

/*	Hold your cursor over the SELECT operator in the graphical plan to see 
	the estimated subtree cost of the query
	StatementSubTreeCost="10.7556"

	This time it does not use parallelism because we disabled parallelism
	by setting max degree of parallelism to 1
*/

-- Change the max degree of parallelism to the default (not recommended value)
EXEC sys.sp_configure N'max degree of parallelism', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO