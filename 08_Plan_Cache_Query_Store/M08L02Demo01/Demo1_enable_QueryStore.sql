SET NOCOUNT ON;

USE AdventureWorksPTO;
GO

-- To start with a clean slate, disable and purge the Query Store if it's running
ALTER DATABASE AdventureWorks2017 SET QUERY_STORE = OFF;
GO
ALTER DATABASE AdventureWorks2017 SET QUERY_STORE CLEAR;	
GO

-- Enable with settings better suited to a Demo than production!
ALTER DATABASE AdventureWorks2017
SET QUERY_STORE = ON ( 
	OPERATION_MODE = READ_WRITE,
	MAX_STORAGE_SIZE_MB = 512,			/* Demo value */
	INTERVAL_LENGTH_MINUTES = 5,		/* Demo value */	
	CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
	SIZE_BASED_CLEANUP_MODE = AUTO,
	QUERY_CAPTURE_MODE = ALL,			/* Demo value */
	DATA_FLUSH_INTERVAL_SECONDS = 900,	
	MAX_PLANS_PER_QUERY = 200,
	WAIT_STATS_CAPTURE_MODE = ON  
	);
GO	

-- Confirm that Query Store is enabled for the current database	
SELECT name, is_query_store_on
FROM sys.databases
WHERE database_id = DB_ID();
GO

-- Query the current Query Store configuration details (includes space usage)
SELECT CONCAT(desired_state_desc, ' / ', actual_state_desc) AS [ desired / actual state],
    readonly_reason, max_storage_size_mb AS max_storage_mb, current_storage_size_mb AS used_mb,
    query_capture_mode_desc AS capture_mode,
    capture_policy_stale_threshold_hours AS cstm_stale_hrs,
    capture_policy_execution_count AS cstm_exec_cnt,
    capture_policy_total_compile_cpu_time_ms AS cstm_compile_ms,
    capture_policy_total_execution_cpu_time_ms AS cstm_exec_ms,
    interval_length_minutes AS interval_min, flush_interval_seconds / 60 AS flush_min,
    stale_query_threshold_days AS retain_days, max_plans_per_query AS max_plans,
    size_based_cleanup_mode_desc AS size_based_cleanup, wait_stats_capture_mode_desc AS wait_stats
FROM sys.database_query_store_options;
GO

/*
	The desired and actual states will generally be the same.  If not, someone 
	has manually reset the mode or there's a problem - for example the allocated
	storage filled up but size-based cleanup is disabled.  You can deciper the
	readonly_reason codes here: 
	
		https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-query-store-options-transact-sql?f1url=https%3A%2F%2Fmsdn.microsoft.com%2Fquery%2Fdev15.query%3FappId%3DDev15IDEF1%26l%3DEN-US%26k%3Dk(database_query_store_options_TSQL);k(sql13.swb.tsqlresults.f1);k(sql13.swb.tsqlquery.f1);k(MiscellaneousFilesProject);k(DevLang-TSQL)%26rd%3Dtrue&view=sql-server-ver15

	A query_capture_mode_desc of AUTO or CUSTOM (2019 and later) is recommended
	to reduce overhead and avoid storing data about single-use and inexpensive 
	queries.

	The custom_XXX columns will only be populated if you're using the CUSTOM
	capture option.

	A collection interval of 5 is *not* appropriate for routine monitoring of 
	production databases.  Start with 60 min and know that smaller intervals
	increase both the load on the system and the amount of data that must be 
	stored.

	The remaining values are system default and should work well.

	---------------------------------------------------------------------------

	Now let's walk through how you can enable and configure Query Store using the 
	database properties windown.

	You may use the AdventureWorksPTO database, or create a separate database to 
	demonstrate initializing Query Store and modifying settings without impacting
	the demonstration.  

	CREATE DATABASE PTO_QueryStoreTemp;
	DROP DATABASE PTO_QueryStoreTemp;
*/





