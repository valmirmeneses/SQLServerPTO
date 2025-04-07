SELECT DISTINCT( s.NAME )
FROM
  sys.database_event_session_events se
  JOIN sys.database_event_sessions s
    ON s.event_session_id = se.event_session_id
GO

select * from sys.database_event_session_events
select * from sys.database_event_sessions


SELECT
        o.object_type,
        p.name         AS [package_name],
        o.name         AS [db_object_name],
        o.description  AS [db_obj_description]
    FROM
                   sys.dm_xe_objects  AS o
        INNER JOIN sys.dm_xe_packages AS p  ON p.guid = o.package_guid
    WHERE
        o.object_type in
            (
            'action',  'event',  'target'
            )
    ORDER BY
        o.object_type,
        p.name,
        o.name;