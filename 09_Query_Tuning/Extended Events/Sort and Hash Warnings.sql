CREATE EVENT SESSION [Sort and Hash Warnings] ON SERVER 
ADD EVENT sqlserver.hash_spill_details(
    ACTION(sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text)),
ADD EVENT sqlserver.hash_warning(
    ACTION(sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text)
    WHERE ([hash_warning_type]=(1))),
ADD EVENT sqlserver.sort_warning(
    ACTION(sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text)
    WHERE ([sort_warning_type]=(2)))
GO


