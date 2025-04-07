-- IMPORTANT
-- 1. In this demo, always show the execution plan and review the messages tab to see logical reads stats
-- 2. The logical reads and query costs can be slightly different from the notes in the script, but it
--    does not affect the demo
--------------------------------------------------------------------------------------------------------

/* ===============================================================================
	Prepare Demo environment 
   =============================================================================== */

USE [AdventureWorks]
GO
DROP TABLE IF EXISTS Person.PersonDemo
GO
select * 
into Person.PersonDemo
from Person.Person
GO
update [Sales].[SalesOrderHeader]
set [ShipDate] = null, [Status] = 3
where TerritoryID = 1 and SalesPersonID = 281
GO
DROP INDEX [IX_SalesOrderHeader_CustomerID] ON [Sales].[SalesOrderHeader]
GO

/* ===============================================================================
	Demo 1. Exploring basic operators:
		* Table Scan
		* Clustered Index Scan
		* Clustered Index Seek
		* Index Scan
		* Index Seek
   =============================================================================== */

USE [AdventureWorks]
GO

set statistics io on

-- IMPORTANT: Click on Include Actual Execution Plan or press Ctrl+M

select * from Person.PersonDemo

-- Go to the execution plan and show the plan uses a table scan
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 3809
-- Review the cost: 2.84599

-- Check the indexes on the table. There is no index 
sp_helpindex 'Person.PersonDemo'

-- Create a Clustered PK on the natural key for the table
ALTER TABLE Person.PersonDemo
ADD CONSTRAINT PK_PersonDemo_BusinessEntityID PRIMARY KEY CLUSTERED (BusinessEntityID  );  
GO  

-- Execute the same query
select * from Person.PersonDemo

-- Go to the execution plan and show the plan now uses a Clustered index Scan. 
-- Is it a better plan? it is using an index after all
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 3820
-- Review the cost: 2.84673
-- Actually, it does more logical reads and the cost is higher. Why?

-- Execute the query
select * from Person.PersonDemo
where BusinessEntityID = 20774

-- Go to the execution plan and show the plan uses a Clustered index Seek. 
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 3
-- Review the cost: 0.0032831

-- Execute the query
select * from Person.PersonDemo
where FirstName = 'Omar'

-- Go to the execution plan and show the plan uses a Clustered index Scan. 
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 3820
-- Review the cost: 2.84673
-- How can the Clustered index Scan be avoided and the cost reduced?

-- Lets index the column used in the where clause
CREATE NONCLUSTERED INDEX [ix_PersonDemo_FirstName] 
ON [Person].[PersonDemo] ([FirstName] ASC )

-- Execute the query
select * from Person.PersonDemo
where FirstName = 'Omar'

-- Go to the execution plan and show the plan now uses a Index Seek. 
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo'. , logical reads 134
-- Review the cost: 0.04472
-- good improvemt

-- Execute the query
select * from Person.PersonDemo
where FirstName = 'Omar' 
	and LastName = 'Jai' 

-- Go to the execution plan and show the plan uses a Index Seek. 
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 134
-- Review the cost: 0.04472
-- Can the cost and IO be reduced? 

-- Option 1 -- Also index LastName
	   	  
CREATE NONCLUSTERED INDEX [ix_PersonDemo_LastName] 
ON [Person].[PersonDemo] ([LastName] ASC )

--Execute the query again
select * from Person.PersonDemo
where FirstName = 'Omar' 
	and LastName = 'Jai' 

-- Go to the execution plan and show the plan now uses two Index Seeks and looks more complex than before
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 7
-- Review the cost: 0.01590
-- Good improvement, but can the cost and IO be reduced even more? 

-- Option 2. Index FirstName and LastName in a single index

CREATE NONCLUSTERED INDEX [ix_PersonDemo_FirstName_LastName] 
ON [Person].[PersonDemo] ([FirstName] ASC, [LastName] ASC )

--Execute the query again
select * from Person.PersonDemo
where FirstName = 'Omar' 
	and LastName = 'Jai' 

-- Go to the execution plan and show the plan now uses one Seeks and looks 
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 5
-- Review the cost: 0.00658
-- Good. We were able to reduce it even more!!!!

-- As the combined index in better, lets delete the index by LastName
-- This is for demo only. There could be other queries that would benefit from an index on LastName
DROP INDEX [ix_PersonDemo_LastName] ON [Person].[PersonDemo]

-- But now we have redundant indexes
sp_helpindex 'Person.PersonDemo'

-- Drop the index by FirtName as the one by FistName,LastName does the same and more
DROP INDEX [ix_PersonDemo_FirstName] ON [Person].[PersonDemo]
GO

sp_helpindex 'Person.PersonDemo'

-- Execute the query
select * from Person.PersonDemo
where FirstName = 'Omar' 
	  OR
	  LastName = 'Jai'

-- Go to the execution plan and show the plan uses an Index Scan
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 631
-- Review the cost: 0.488754
-- Scanning the nonclusterd index is not as bad as scanning the whole table, but.. 
-- Why is it scaning the index instead of doing a Seek as the condition filter by both columns on the index?
-- What can we do to improve the query?

-- Index LastName again
CREATE NONCLUSTERED INDEX [ix_PersonDemo_LastName] 
ON [Person].[PersonDemo] ([LastName] ASC )
GO

-- Execute the query again
select * from Person.PersonDemo
where FirstName = 'Omar' 
	  OR
	  LastName = 'Jai'

-- Go to the execution plan and show the plan uses two Index Seeks: 
-- one to get the people named Omar, other to get people with last name Jai
-- and then join the results and does a sort to delete common rows
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo'. , logical reads 533
-- Review the cost: 0.449231
-- Good. We have improved the query!

/* ===============================================================================
	Demo 2. Exploring basic operators:
		* RID Lookup
		* Key Lookup
   =============================================================================== */

-- Execute the query 
select *
from Person.PersonDemo
where FirstName = 'Omar'

-- Go to the execution plan and show that there is a Key Lookup operator 
-- that represents 93% of the total query cost
-- Review the cost of the query: 0.04472
-- Put the mouse over the Key Lookup operator and explain the Output List
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 134
-- Is there anything we can do about it? Can we reduce the cost of the Key Lookup?
-- Not really, because of the select *

-- Execute the query
select FirstName, LastName
from Person.PersonDemo
where FirstName = 'Omar' 

-- Go to the execution plan and show that there is no Key Lookup operator. Why?
-- Because the index ix_PersonDemo_FirstName has all the column we need in the query (covering index)
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 2

-- Execute the query
select BusinessEntityID, FirstName, LastName
from Person.PersonDemo
where FirstName = 'Omar' 

-- Go to the execution plan and show that there is no Key Lookup operator. 
-- Why there is no Key Lookup if the index is only on FirstName and LastName?
-- Because all non clustered indexes included automatically the keys for the clustered index

-- Execute the query 
select BusinessEntityID, PersonType, Suffix, FirstName, LastName
from Person.PersonDemo
where FirstName = 'Omar' 

-- Go to the execution plan and show that there is a Key Lookup operator 
-- that represents 93% of the total query cost
-- Review the cost of the query: 0.04472
-- Put the mouse over the Key Lookup operator and explain the Output List
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo'  logical reads 134
-- Is there anything we can do about it? Can we reduce the cost of the Key Lookup and IO?
-- Yes!!! create a covering index

-- Modify the existing index to include Suffix and PersonType
-- Can we create another index with the included columns? Yes, but then you would have a redundant index
CREATE NONCLUSTERED INDEX [ix_PersonDemo_FirstName_LastName] ON [Person].[PersonDemo]
(	[FirstName] ASC,
	[LastName] ASC
)
INCLUDE ( 	[Suffix], [PersonType]) 
with (DROP_EXISTING=ON)

-- Execute the query again
select BusinessEntityID, PersonType, Suffix, FirstName, LastName
from Person.PersonDemo
where FirstName = 'Omar'

-- Go to the execution plan and show that there is no Key Lookup operator 
-- Review the cost of the query: 0.00329
-- Go to the Messages tab and review how many logical reads occurred -> Table 'PersonDemo' logical reads 2
-- Good. We have reduced the cost for the query and the required IO

/* ===============================================================================
	Demo 3. Exploring basic operators:
		* Hash Match Join
   =============================================================================== */

--Execute the query:
select *
from [Sales].[Customer] C
INNER JOIN  [Sales].[SalesOrderHeader] H 
ON C.CustomerID = H.CustomerID
where c.TerritoryID = 1 and C.storeid = 840

-- Go to the execution plan and show that there is a Hash Match operator, and 2 Clustered Index Scan 
-- Review the cost of the query: 0.8479
-- Go to the Messages tab and review how many logical reads occurred 
-- ->Table 'SalesOrderHeader' logical reads 689
-- ->Table 'Customer' logical reads 123

-- Explain why the plan uses a Hash Match
-- Notice that the Plan is recommending an index
-- CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
-- ON [Sales].[Customer] ([StoreID],[TerritoryID])

-- Is that a good option, why not creating the index using a different order 
-- ON [Sales].[Customer] ([TerritoryID],[StoreID])

-- Lets see how many different values are for StoreId and how many rows are for the StoreId that repeats the most
select StoreID, COUNT (*) 
from [Sales].[Customer] 
group by StoreID
order by 2 desc

-- Lets see how many different values are for TerritoryID and how many rows are for the StoreId that repeats the most
select TerritoryID, COUNT (*) 
from [Sales].[Customer] 
group by TerritoryID
order by 2 desc

-- Show that there are more different values for StoreID than TerritoryID
-- so creating the index
-- ON [Sales].[Customer] ([StoreID],[TerritoryID])
-- will help to obtain better estimates. 


CREATE NONCLUSTERED INDEX [ix_Customer_StoreID_TerritoryID]
ON [Sales].[Customer] ([StoreID],[TerritoryID])

--Execute the query again:
select *
from [Sales].[Customer] C
INNER JOIN  [Sales].[SalesOrderHeader] H 
ON C.CustomerID = H.CustomerID
where c.TerritoryID = 1 and C.storeid = 840

-- Go to the execution plan and show that there is still a Hash Match operator, and 1 Clustered Index Scan 
-- Review the cost of the query: 0.7209
-- Go to the Messages tab and review how many logical reads occurred 
-- ->Table 'SalesOrderHeader' logical reads 689
-- ->Table 'Customer' logical reads 6
-- We have reduced the cost of the query and the IO on Customer, but can we improve the query even more?

-- In the plan there is an index recommendation
-- CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
-- ON [Sales].[SalesOrderHeader] ([CustomerID])
-- INCLUDE ([RevisionNumber],[OrderDate],[DueDate],[ShipDate],[Status],
--          [OnlineOrderFlag],[SalesOrderNumber],[PurchaseOrderNumber],
--			[AccountNumber],[SalesPersonID],[TerritoryID],[BillToAddressID],
--			[ShipToAddressID],[ShipMethodID],[CreditCardID],[CreditCardApprovalCode],
--			[CurrencyRateID],[SubTotal],[TaxAmt],[Freight],[TotalDue],[Comment],[rowguid],[ModifiedDate])

-- Explain why it is not a good idea to create this index
-- All columns are included, son you are basically duplicating the table on a non clustered index

-- To improve the query, create an index on the join column of SalesOrderHeader
CREATE NONCLUSTERED INDEX [ix_SalesOrderHeader_CustomerID]
ON [Sales].[SalesOrderHeader](CustomerID)

--Execute the query again:
select *
from [Sales].[Customer] C
INNER JOIN  [Sales].[SalesOrderHeader] H 
ON C.CustomerID = H.CustomerID
where c.TerritoryID = 1 and C.storeid = 840

-- Go to the execution plan and show that it now uses Nested Loop operators , 
-- Review the cost of the query: 0.02093
-- Go to the Messages tab and review how many logical reads occurred 
-- ->Table 'SalesOrderHeader' logical reads 10
-- ->Table 'Customer' logical reads 6
-- Good. We have improved the performance of the query significantly.

/* ===============================================================================
	Demo 3. The Tipping Point
	=============================================================================== */

-- Execute the query 
select * 
from Person.PersonDemo
where PersonType = 'SC'

-- Go to the execution plan and show the plan uses an Index Scan on a index that contains the column PersonType
-- Review the cost: 2.5940
-- Review how many logical reads occurred -> Table 'PersonDemo' logical reads 2428
-- What can we do to improve the query?

CREATE NONCLUSTERED INDEX [ix_PersonDemo_PersonType] 
ON [Person].[PersonDemo] ([PersonType] ASC )

-- Execute the query again 
select * 
from Person.PersonDemo
where PersonType = 'SC'

-- Go to the execution plan and show the plan uses an Index Seek
-- Review the cost: 2.2594
-- Review how many logical reads occurred -> Table 'PersonDemo' logical reads 2320
-- the query performance sligthly improved improved

-- Execute the same query but filtering by other value
select * 
from Person.PersonDemo
where PersonType = 'VC'

-- Go to the execution plan and show the plan also uses an Index Seek.. nice!

-- Execute the same query but filtering by two values
select * 
from Person.PersonDemo
where PersonType = 'SC' OR PersonType = 'VC'

-- Go to the execution plan and show the plan also uses an Index Seek.. 
-- nice! SQL Server is the best!!!!

-- Execute the same query but filtering by other value
select * 
from Person.PersonDemo
where PersonType = 'IN'

-- Go to the execution plan and show the plan uses now a Clustered Index Scan
-- Review how many logical reads occurred -> Table 'PersonDemo' logical reads 3820
-- Review the cost: 2.8467
-- Has SQL Server gone crazy?? Why is it not using the index on PersonType?
-- Why does the plan suddenly change and uses a Clustered Index Scan instead of an Index Seek?

-- Lets see how many rows there are for each value of PersonType
select PersonType, count(*) 
from Person.PersonDemo
group by PersonType
order by 2 desc

-- There are so many rows for IN that the QO prefers to use a Clustered Index Scan instead of an Index Seek
-- The Tipping Point is the point where the number of rows returned is no longer selective 
-- enough to justify the I/O being done and SQL Server chooses not to use the non-clustered 
-- index to look up the corresponding data rows and instead performs a Table Scan 

 -- How SQL Server knows that?? the statistics
DBCC SHOW_STATISTICS ('Person.PersonDemo',ix_PersonDemo_PersonType)

-- The QO prefers to use a Clustered Index Scan instead of an Index Seek 
-- because it is chepaer to scan the index that do several seeks
-- Don't you believe me?
-- Let's force the index seek and see the cost of the plan

-- Execute both queries at the same time to compare the plans
select * 
from Person.PersonDemo
where PersonType = 'IN'

select * 
from Person.PersonDemo WITH (FORCESEEK)
where PersonType = 'IN'

-- Go to the execution plan tab and show the cost for each plan
-- The plan that uses the Index Seek has a higher cost (14.8597) 
-- than the plan that uses the Clustered Index Scan (2.8467)
-- Compare the IO of each query. The plan that uses the Index Seek did 3820 logical reads and
-- the plan that uses the Clustered Index Scan did 56651 logical reads.
-- The QO did the right choice by scanning the Clustered Index
-- SQL Server rocks!!!

-- Restore database closet to its original state
USE [AdventureWorks]
GO
DROP TABLE IF EXISTS Person.PersonDemo
GO
DROP INDEX [ix_Customer_StoreID_TerritoryID] ON [Sales].[Customer]
GO



