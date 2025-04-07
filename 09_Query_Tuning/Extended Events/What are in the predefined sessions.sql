-- What are the predefined sessions? Note: this only shows enabled sessions.
-- When we enable the QuickStartStandard or QuickStartSQL they will then show up in 
-- this query.
SELECT DISTINCT( NAME ), session_source as [Source]
FROM
  sys.dm_xe_session_events se
  JOIN sys.dm_xe_sessions s
    ON s.address = se.event_session_address

GO
-- Let's see what event are contained in this session
-- Captures important events such as deadlock graph automatically!
SELECT event_name                   AS Event,
       Cast(event_predicate AS XML) AS [predicate],
       [name]                       AS [Session Name]
FROM
  sys.dm_xe_session_events se
  JOIN sys.dm_xe_sessions s
    ON s.address = se.event_session_address
WHERE  NAME = 'system_health'; 

GO
-- Let's see what event are contained in this session
-- If you opted in to sending telemetry during setup (or Azure SQL DB)
SELECT event_name                   AS Event,
       Cast(event_predicate AS XML) AS [predicate],
       [name]                       AS [Session Name]
FROM
  sys.dm_xe_session_events se
  JOIN sys.dm_xe_sessions s
    ON s.address = se.event_session_address
WHERE  NAME = 'telemetry_xevents';

GO
-- Let's see what event are contained in this session
-- sp_server_diagnostics system stored procedure results
-- leveraged by clustering and AO
SELECT event_name                   AS Event,
       Cast(event_predicate AS XML) AS [predicate],
       [name]                       AS [Session Name]
FROM
  sys.dm_xe_session_events se
  JOIN sys.dm_xe_sessions s
    ON s.address = se.event_session_address
WHERE  NAME = 'sp_server_diagnostics session';

GO 
-- Let's see what event are contained in this session
-- In-memory OLTP (formerly code named Hekaton hence the hk)
SELECT event_name                   AS Event,
       Cast(event_predicate AS XML) AS [predicate],
       [name]                       AS [Session Name]
FROM
  sys.dm_xe_session_events se
  JOIN sys.dm_xe_sessions s
    ON s.address = se.event_session_address
WHERE  NAME = 'hkenginexesession';

GO 

