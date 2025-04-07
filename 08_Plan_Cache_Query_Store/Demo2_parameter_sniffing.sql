SET NOCOUNT ON;

-- Disable the "optimize for ad hoc workload" server configuration option
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Optimize for ad hoc workload', 0;
RECONFIGURE;
GO

-- NEWER syntax:
ALTER DATABASE SCOPED CONFIGURATION SET OPTIMIZE_FOR_AD_HOC_WORKLOADS = OFF;


/*
	Optimize for ad hoc workload prevents caching of plans the first time a
	query is executed.  It applies to *all* statements, not just ad hoc SQL.

	It's generally recommended that it be enabled on your servers to prevent
	bloating of the plan cache by single-use ad hoc queries, but it	complicates 
	demonstrations (as you have to execute all your queries at least twice to 
	get them into the cache) so we're disabling it here.
*/

/*****************************************************************************/

USE AdventureWorks;
GO

-- Create a simple stored procedure 
CREATE OR ALTER PROC dbo.GetPersonInfo (@last_name_partial NVARCHAR(50))
AS
BEGIN
	SELECT CONCAT_WS(' ', Title, FirstName, MiddleName, LastName) AS NameWithTitle
	FROM Person.Person
	WHERE LastName LIKE  @last_name_partial + N'%';
END
GO

/*
	Turn on the option to include "Include Actual Execution Plans" (Ctrl+M) and
	turn on an option that let's us see the logical I/O costs of our queries.

*/

SET STATISTICS IO ON;

/*
	Now execute the stored procedure twice - first with a parameter that returns 
	a very small record set then with a parameter than returns a lot more rows.
*/

EXEC dbo.GetPersonInfo @last_name_partial = N'Q'; 
GO
EXEC dbo.GetPersonInfo @last_name_partial = N'M'; 
GO	

/*
	The first query returns only 2 rows.  The second returns 1550 rows.

	The two query plans are identical.  Note the use of Nested Loops joins - 
	a good choice when an outer input - the index on (LastName, FirstName, 
	MiddleName) in our example - returns a smaller number of rows.

	The cached plan was optimized for the "Q" parameter (which we executed
	first), so a plan optimized for low row counts makes sense.

	Looking at the I/O statistics on the Messages tab we see that the cost of
	the "Q" execution was low - 9 logical reads (that's the number of pages 
	read from the buffer pool).  The cost of the the "M" execution was *much*
	higher at 4662 logical reads.  More I/O = slower performance.
	
		Table 'Person'. Scan count 1, logical reads 8
		Table 'Person'. Scan count 1, logical reads 4662

	Is that high I/O cost just due to the fact that we're retrieving more rows
	or is the choice of query plan a factor?

	Let's do another experiment...

	We'll mark the proc for a recompile (at its next execution) using sp_recompile
	then execute the proc with the same two parameters but in reverse order.
*/

EXEC sp_recompile 'dbo.GetPersonInfo';

EXEC dbo.GetPersonInfo @last_name_partial = N'M'; 
GO	
EXEC dbo.GetPersonInfo @last_name_partial = N'Q'; 
GO

/*
	First, check out the query plans.  Again, they're both the same, but this 
	time clustered index scans are used to retrieve the data.  This is because 
	the cached plan was optimized for "M" which returns a lot of rows.  

	{ Note the missing index recommendation.  A covering index would be very 
	  helpful here, but that's a topic for another lesson. }

	Scanning all the pages in an index once can be cheaper than than performing 
	many individual index seeks.  The proof is in the I/O statistics:

		Table 'Person'. Scan count 1, logical reads 3819
		Table 'Person'. Scan count 1, logical reads 3819

	The cost for the "M" execution was 3819 logical reads - still high, but 
	better than the 4662 logical reads incurred using Nested Lookups.  

	The cost for the "Q" execution, on the other hand, is *much* higher than it
	was before - 3819 vs 8 logical reads.  Clearly, this is a less cost-effective 
	query plan for the low row count "Q" parameter.

	There lies your problem...

	If most of the time your query returns low row counts, perhaps you opt to 
	use the Nested Loops join plan all the time and occasionally tolerate slower
	performance when result sets are high.  
	
	If high row counts are typically high, you might be better off caching and
	reusing the clustered index scan plan.

	But, if you can afford the CPU overhead, you *could* use a recompile hint
	to generate a plan that's always based on the current parameter values .
*/


-- Alter our proc to include a recompile hint then repeat the test queries
CREATE OR ALTER PROC dbo.GetPersonInfo (@last_name_partial NVARCHAR(50))
AS
BEGIN
	SELECT CONCAT_WS(' ', Title, FirstName, MiddleName, LastName) AS NameWithTitle
	FROM Person.Person
	WHERE LastName LIKE  @last_name_partial + N'%'
	OPTION (RECOMPILE);		/* use the hint only for statements where parameter sniffing is problematic */
END
GO

-- Execute the test queries - in any order you'd like
EXEC dbo.GetPersonInfo @last_name_partial = N'M'; 
GO	
EXEC dbo.GetPersonInfo @last_name_partial = N'Q'; 
GO
EXEC dbo.GetPersonInfo @last_name_partial = N'M'; 
GO	

/*
	This gets us an appropriate plan every time, but at the cost of having to 
	compile a plan for the SELECT with each execution of the proc.  This might
	not be possible in all situations.  CPU costs can soar if procs with recom-
	pile hints are executed at high rates.
*/

/*****************************************************************************/

-- Clean up
DROP PROC dbo.GetPersonInfo;

-- Reenable this option
EXEC sp_configure 'Optimize for ad hoc workload', 1;
RECONFIGURE;
GO


