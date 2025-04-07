-- Step 1: Only show requests with active queries except for this one
SELECT er.session_id, er.command, er.status, er.wait_type, er.cpu_time, er.logical_reads, eqsx.query_plan, t.text
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_query_statistics_xml(er.session_id) eqsx
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) t
WHERE er.session_id <> @@SPID
GO
 
-- Step 2: What does the plan profile look like for the active query

-- Run the next query several time and see the progression of the row_count for
-- the Nested Loops and Table Spool operators

SELECT session_id, physical_operator_name, node_id, thread_id, row_count, estimate_row_count
FROM sys.dm_exec_query_profiles
WHERE session_id <> @@SPID
ORDER BY session_id, node_id DESC
GO

/*	
	Notice the huge estimate_row_count for the Nested Loops and Table Spool operators. 
	Notice the row_count (number of rows currently processed) is not even close to the estiamte.
	
	Is the estimate inaccurate? It is a possibility but, if it is right, this query is
	far from completing. 
*/

/* When lightweight query profiling is on by default in SQL Server 2019,
	row_count is the only statistics captured. Capturing statistics for CPU and I/O 
	can e expensive but you can sill can capture them with standard profiling.*/

-- Step 3: Go back and look at the plan and query text for a clue
SELECT er.session_id, er.command, er.status, er.wait_type, er.cpu_time, er.logical_reads, eqsx.query_plan, t.text
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_query_statistics_xml(er.session_id) eqsx
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) t
WHERE er.session_id <> @@SPID
GO

/* 
	Click on the XML plan. A new window will open and show the Plan in a Graphical way. 
	Get the value for the text column. This is the query being executed. Rewie the query 

	Notice the join clause
	INNER JOIN Sales.InvoiceLines sil
	ON si.InvoiceID = si.InvoiceID

	It is a self join. So the cause of the problem can be a simple typo
	and the query msut be modified to use the follwoing JOIN clause

	INNER JOIN Sales.InvoiceLines sil
	ON si.InvoiceID = sil.InvoiceID

 	
	The query take foreer to complete so it can be killed and fixed

	Kill the session for the mysmartquery.sql
*/