------------------------------------------------------------------------------------------
-- Demo 3.1 - QueryTroubleshooting (Plan Cache)
------------------------------------------------------------------------------------------


-- what information is available in this DMV?
SELECT TOP 1 *
FROM   sys.dm_exec_cached_plans;


-- what information is available in this DMV?
SELECT TOP 1 *
FROM   sys.dm_exec_query_stats;


-- this query returns the text and plan for queries
-- point out each coumn type
SELECT objtype,
       refcounts,
       usecounts,
       text,
       query_plan
FROM   sys.dm_exec_cached_plans AS a
       INNER JOIN
       sys.dm_exec_query_stats AS b
       ON a.plan_handle = b.plan_handle CROSS APPLY sys.dm_exec_sql_text (b.sql_handle) 
   CROSS APPLY sys.dm_exec_query_plan (b.plan_handle);


--The query below returns the Top 20 Cumulative CPU within last 1hours
SELECT   last_execution_time,
         total_worker_time AS [Total CPU Time],
         execution_count,
         total_worker_time / execution_count AS [Avg CPU Time],
         text,
         qp.query_plan
FROM     sys.dm_exec_query_stats AS qs 
         CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS st 
 CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) AS qp
WHERE    DATEDIFF(hour, last_execution_time, getdate()) < 1
ORDER BY total_worker_time DESC;


--Example Top 10 statements by I/O
SELECT   TOP 10 (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count AS [Avg IO],
                substring(qt.text, qs.statement_start_offset / 2, 
(CASE WHEN qs.statement_end_offset = -1 THEN len(CONVERT (NVARCHAR (MAX), qt.text)) * 2 
      ELSE qs.statement_end_offset 
  END - qs.statement_start_offset) / 2) AS query_text,
                qt.dbid,
                qt.objectid
FROM     sys.dm_exec_query_stats AS qs CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS qt
ORDER BY [Avg IO] DESC;


-- The query below can be used to find query plans that may run in parallel
SELECT p.*,
       q.*,
       cp.plan_handle
FROM   sys.dm_exec_cached_plans AS cp CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) AS p CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) AS q
WHERE  cp.cacheobjtype = 'Compiled Plan'
       AND p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
        max(//p:RelOp/@Parallel)', 'float') > 0;


-- Sys.dm_exec_query_stats Example
--This example returns information about the top five queries by average CLR Time
SELECT   TOP 5 creation_time,
               last_execution_time,
               total_worker_time,
               total_worker_time / execution_count AS [Avg CPU Time],
               last_worker_time,
               execution_count,
               (SELECT SUBSTRING(text, statement_start_offset / 2, (CASE WHEN statement_end_offset = -1 THEN LEN(CONVERT (NVARCHAR (MAX), text)) * 2 ELSE statement_end_offset END - statement_start_offset) / 2)
                FROM   sys.dm_exec_sql_text (sql_handle)) AS query_text
FROM     sys.dm_exec_query_stats
ORDER BY [total_worker_time] DESC
