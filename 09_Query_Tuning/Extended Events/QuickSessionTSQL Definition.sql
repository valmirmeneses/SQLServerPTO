CREATE EVENT SESSION [QuickSessionTSQL] ON SERVER -- NOTE: in Azure SQL database 
ADD EVENT sqlserver.existing_connection(          -- this must be ON DATABASE
    ACTION(package0.event_sequence,sqlserver.client_hostname,sqlserver.session_id)), -- capture for existing connections
ADD EVENT sqlserver.login(SET collect_options_text=(1)
    ACTION(package0.event_sequence,sqlserver.client_hostname,sqlserver.session_id)), -- capture login and logout info
ADD EVENT sqlserver.logout(
    ACTION(package0.event_sequence,sqlserver.session_id)),
ADD EVENT sqlserver.rpc_starting(                                                    -- rpc starting useful for batches from client
    ACTION(package0.event_sequence,sqlserver.database_name,sqlserver.session_id)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),                -- filter out systems sessions
ADD EVENT sqlserver.sql_batch_starting(                                              -- sql statements, could add stored procedure etc.
    ACTION(package0.event_sequence,sqlserver.database_name,sqlserver.session_id)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0))))                 -- filter out systems sessions
WITH (MAX_MEMORY=8192 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,               -- configuration items.
	MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,
	TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


