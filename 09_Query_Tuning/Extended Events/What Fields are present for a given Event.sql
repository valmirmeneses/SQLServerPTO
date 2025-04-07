SELECT p.NAME        AS package_name,
       o.NAME        AS event_name,
       c.NAME        AS event_field,
       c.type_name   AS field_type,
       c.column_type AS column_type
FROM
  sys.dm_xe_objects o
  JOIN sys.dm_xe_packages p
    ON o.package_guid = p.guid
  JOIN sys.dm_xe_object_columns c
    ON o.NAME = c.object_name
WHERE  o.object_type = 'event'
       --AND o.NAME = 'sql_statement_completed'
ORDER  BY
  package_name,
  event_name; 
