SET NOCOUNT ON;

USE	AdventureWorksPTO;

/*
	Let's start by sampling what's visible in each of the catalog views...
*/

-- Unique SQL statements
SELECT TOP (5) * FROM sys.query_store_query_text; 
/* 
	You can search this view to find a query you're interested in analyzing or
	troubleshooting
*/

-- Unique sets of context settings
SELECT TOP (5) * FROM sys.query_context_settings; 
/*
	There will be one row for each unique set of contexts (things like ANSI 
	settings) queries are executed under.  There's not a simple way to decipher 
	the meanings of the bitmap values.
*/

-- One row for each unique combination of SQL text + context
SELECT TOP (5) * FROM sys.query_store_query; 
/*
	Much Query Store functionality is driven by the query_id value.  A query_id
	identifies a unique combination of query text + context.

	You can use object_id to locate data for a specific stored proc.  There will
	be separate query_ids for each statement in a stored proc.

	We can also see a lot of interesting compilation stats here
*/

-- The query plan(s) associated with each query_id
SELECT TOP (5) * FROM sys.query_store_plan;
/*
	Interesting values include the engine_version, compatibility level and, of
	course, the query plan - which you'll need to cast as XML to be view in 
	another query window.

	Here we can also see if a plan is being forced (and if forcing has failed
	why that is).
*/

-- Data collection interval endpoints
SELECT TOP (5) * FROM sys.query_store_runtime_stats_interval;
/*
	Note that these are UTC times
*/


-- Runtime metrics aggregated by stats interval
SELECT TOP (5) * FROM sys.query_store_runtime_stats; 
/*
	*Lots* of data about execution costs - aggregated by data collection interval.
*/

SELECT TOP (5) * FROM sys.query_store_wait_stats;
/*
	Information on what your queries are waiting on grouped by category and
	aggregated by the same data collection intervals as used for the runtime
	stats.

	Waits are grouped into categories.  Tracking every native wait type would 
	be cost prohibitive.  You can see which wait types fall into which cate-
	gories here:

	https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-wait-stats-transact-sql?view=sql-server-ver15#wait-categories-mapping-table
*/

/*****************************************************************************/

-- Now lets track our demo proc through the Query Store views

-- Text
SELECT t.*
FROM sys.query_store_query_text t
     INNER JOIN sys.query_store_query q ON q.query_text_id = t.query_text_id
WHERE q.object_id = OBJECT_ID('Demo.getProductInfo');
/*
	We get two rows, one for each statement in the stored proc.  
	The focus in Query Store is on individual statements, not objects
*/

-- Query
SELECT *
FROM sys.query_store_query
WHERE object_id = OBJECT_ID('demo.getProductInfo');
/*
	Again, 2 rows - one for each statement in the proc.  If we were to execute
	the proc in a different context, for example...

		SET ANSI_DEFAULTS OFF;
		EXECUTE demo.getProductInfo 777;

	An additional pair of rows would be returned with differing context_ids.
*/

-- Plans
SELECT p.*, CAST(p.query_plan AS XML) AS xml_query_plan
FROM sys.query_store_plan p
     INNER JOIN sys.query_store_query q ON q.query_id = p.query_id
WHERE q.object_id = OBJECT_ID('demo.getProductInfo');
/*
	This returns all the different plans that have been executed for the statements 
	in our stored proc.

	The query plan is returned as nvarchar(max).  We can cast it as XML so we can
	click on it and view it as a graphical plan.

	This is where we can find which plans are being forced and whether any forced
	plans have failed.
*/

-- Runtime Stats (for just one plan for easier interpretation)
SELECT i.start_time, r.*
FROM sys.query_store_runtime_stats r INNER JOIN sys.query_store_runtime_stats_interval i ON i.runtime_stats_interval_id = r.runtime_stats_interval_id
WHERE r.plan_id = ( SELECT TOP ( 1 ) p.plan_id
                    FROM sys.query_store_plan p
                         INNER JOIN sys.query_store_query q ON q.query_id = p.query_id
                    WHERE q.object_id = OBJECT_ID('demo.getProductInfo'));
/*
	For each data collection interval in which a plan was executed there will 
	be one row of aggregate metrics.  All times are UTC.


*/

-- Wait Stats (for just one plan to keep it simple)
SELECT i.start_time, w.*
FROM sys.query_store_wait_stats w
     INNER JOIN sys.query_store_runtime_stats_interval i ON i.runtime_stats_interval_id = w.runtime_stats_interval_id
WHERE w.plan_id = ( SELECT TOP ( 1 ) p.plan_id
                    FROM sys.query_store_plan p
                         INNER JOIN sys.query_store_query q ON q.query_id = p.query_id
                    WHERE q.object_id = OBJECT_ID('demo.getProductInfo'));
/*
	Here we see the wait time we accrued by category per plan and data collection 
	interval.
*/


