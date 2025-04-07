USE AdventureWorksPTO
GO
DBCC FREEPROCCACHE
GO

-- IMPORTANT:  Enable the option to "Include Actual Execution Plan" (Ctrl+M) 

------------------------------------------------------------------------------------------
-- Demo 1 - See StatementOptmLevel
------------------------------------------------------------------------------------------

-- Note that StatementOptmLevel in the plan properties only displays 
-- TRIVIAL or FULL - not the Phase reached.

-- 1. Execute query and look for StatementOptmLevel in properties of the SELECT operator:
select top 10 * from  person.person

-- 2. Execute query and look for StatementOptmLevel in properties of the SELECT operator:
select	  p.title
		, p.firstname
		, p.middlename
		, p.lastname
		, a.addressline1
		, a.addressline2
		, a.city
		, a.postalcode
from person.person as p 
inner join person.businessentityaddress as b
on p.businessentityid = b.businessentityid
inner join person.address as a on b.addressid = a.addressid
go


------------------------------------------------------------------------------------------
-- Demo 2 - Statement Optimization phases and SHOWPLAN info
------------------------------------------------------------------------------------------

-- Direct trace flag output to the console (Messages tab)
DBCC TRACEON(3604);
GO

/*
	Using trace flag 8675 we can see details on which Stage and Phase of optimization 
	was used.  This is an undocumented trace flag and not appropriate for use in your
	production databases.  Trace flag output will appear on the Messages tab.

	The "end search(x)" values indicate which Phase of query optimization was reached
		0 = Transaction Processing
		1 = Quick Plan
		2 = Full Optimization 

	Note that StatementOptmLevel in the plan properties only displays TRIVIAL or 
	FULL - not the Phase reached.

	As we execute the queries below we'll also check for StatementOptmEarlyAbortReason
	and StatementOptmLevel values in the graphical and XML plans.
*/

-- Example 1
SELECT p.Name AS ProductName, ( OrderQty * UnitPrice ) AS NonDiscountSales,
    (( OrderQty * UnitPrice ) * UnitPriceDiscount ) AS Discounts
FROM Production.Product p
     INNER JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
ORDER BY ProductName DESC
OPTION ( RECOMPILE, QUERYTRACEON 8675 );
GO
/*
	In the graphical query plan hold your cursor over the SELECT operator to see 
	the estimated subtree cost of the query (7.7386).  

	The complexity of the query qualified it for Phase 1 optimization.  At the end
	of Phase 1 optimization the best plan found had a cost exceeding the current 
	"cost threshold for  parallelism" (default of 5), so parallel plans were evaluated.

	This evaluation also occurs in Phase 1 (this is why there are 2 search(1) lines 
	in the trace flag output).  The plan having the lower cost after Phase 1 (serial 
	or parallel) is passed to Phase 2.  In our case the plan was immediately returned
	without going through Full Optimization.  We know this because we don't see a
	search(2) entry in the Messages tab.

	In the Messages tab look for these rows

	end search(1),  cost: 11.1705 tasks: 282 time: 0 net: 0 total: 0 net: 0.009	  (Evaluation of serial plans)
	end search(1),  cost: 3.0331 tasks: 385 time: 0 net: 0 total: 0 net: 0.01	  (Evaluation of parallel plans)
*/

-- Example 2
SELECT I.CustomerID, C.FirstName, C.LastName, A.AddressLine1, A.City, SP.Name AS [State],
    CR.Name AS CountryRegion
FROM Person.Person AS C
     INNER JOIN Sales.SalesPerson AS CA ON CA.BusinessEntityID = C.BusinessEntityID
     INNER JOIN Sales.SalesOrderHeader AS I ON CA.BusinessEntityID = I.SalesPersonID
     INNER JOIN Person.Address AS A ON A.AddressID = I.BillToAddressID
     INNER JOIN Person.StateProvince SP ON SP.StateProvinceID = A.StateProvinceID
     INNER JOIN Person.CountryRegion CR ON CR.CountryRegionCode = SP.CountryRegionCode
ORDER BY I.CustomerID
OPTION ( RECOMPILE, QUERYTRACEON 8675 );
GO
/*
	This query qualified for Phase 0 optimization, but that didn't return a good
	enough plan, so the Optimizer moved onto Phase 1 which found a lower cost plan,
	but perhaps not the best plan since optimization timed out before it was complete.
	
	The timeout warning is visible in the properties of the SELECT operator and 
	in the XML view of the plan.

	end search(0),  cost: 3.28159 tasks: 786 time: 0 net: 0 total: 0 net: 0.021
	end search(1),  cost: 1.38219 tasks: 3540 time: 0 net: 0 total: 0 net: 0.06
	*** Optimizer time out abort at task 3540 ***
*/

-- Example 3
SELECT P.ProductNumber, P.ProductID, M.Name, PS.Name, SUM(I.Quantity) AS TotalQty
FROM Production.Product AS P
     LEFT OUTER JOIN Production.ProductModel AS M ON M.ProductModelID = P.ProductModelID
     INNER JOIN Production.ProductInventory AS I ON I.ProductID = P.ProductID
     LEFT OUTER JOIN Production.ProductSubcategory AS PS ON PS.ProductSubcategoryID = P.ProductSubcategoryID
WHERE P.ProductNumber LIKE N'R%'
GROUP BY P.ProductID, P.ProductNumber, M.Name, PS.Name
OPTION ( RECOMPILE, QUERYTRACEON 8675 );
GO
/*
	This simpler query took less effort to optimize.

	End of simplification, time: 0.003 net: 0.002 total: 0 net: 0.002
	end search(0),  cost: 0.115044 tasks: 352 time: 0 net: 0 total: 0 net: 0.014
*/

-- Example 4
SELECT 1 AS Column1 INTO #MyTempTable
OPTION ( QUERYTRACEON 8675 );
GO
/*
	SELECT INTO properties shows an Optimization Level of TRIVIAL

	End of simplification, time: 0 net: 0 total: 0 net: 0
	End of post optimization rewrite, time: 0 net: 0 total: 0 net: 0
	End of query plan compilation, time: 0 net: 0 total: 0 net: 0
*/

-- Example 5
SELECT * FROM Person.Person OPTION ( RECOMPILE, QUERYTRACEON 8675 );	/* Trivial */
SELECT * FROM Person.Person WHERE LastName = N'Baker' OPTION ( RECOMPILE, QUERYTRACEON 8675 );	/* Full */
/*
	The only practical way to execute the first query is with a Clustered Index 
	Scan, so the Optimizer doesn't need to perform cost-based optimization.

	The second query has 2 execution options.  For low row counts an Index Seek
	coupled with Key Lookups into the base table is an efficient choice.  But at
	higher row counts it will be cheaper (less IO) to perform a Clustered Index 
	Scan.  
*/

SELECT LastName, FirstName FROM Person.Person WHERE LastName = N'Baker' OPTION ( RECOMPILE, QUERYTRACEON 8675 );	/* Trivial */
SELECT Title, LastName, FirstName FROM Person.Person WHERE LastName = N'Baker' OPTION ( RECOMPILE, QUERYTRACEON 8675 );	/* Full */
/*
	For this pair, the first query is covered by an index, so an Index Seek will
	be the best - and obvious - choice.

	In the second query we need to retrieve Title from the base table.  For low
	row count queries, this can be done efficiently by combining an Index Seek 
	with a Key Lookup, but at higer rowcounts it will be cheaper to perform a
	Clustered Index Scan.
*/

-- DMV with cumulative optimization info
SELECT counter, occurrence
FROM sys.dm_exec_query_optimizer_info
WHERE counter IN (N'optimizations', N'trivial plan', N'search 0', N'search 1', N'search 2',
    N'timeout');
/*
	counter			-	occurrence - 
	optimizations		79420
	trivial plan		16131
	search 0			6253
	search 1			56449
	search 2			451
	timeout				785

*/
