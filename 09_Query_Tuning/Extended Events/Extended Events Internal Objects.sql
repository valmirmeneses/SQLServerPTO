-- which packages are registered to provide XEvents
-- currently there are 16 packages some however may be
-- implemented in multiple versions due to changes by
-- SQL Server version - note three sqlserver packages
SELECT [name],
       [description],
       capabilities,
       capabilities_desc
FROM
  sys.dm_xe_packages
ORDER  BY
  [name]; 


-- To see what modules implement the package
SELECT sys.dm_xe_packages.[name],
       sys.dm_xe_packages.[description],
       sys.dm_os_loaded_modules.[name]
FROM
  sys.dm_os_loaded_modules
  JOIN sys.dm_xe_packages
    ON sys.dm_os_loaded_modules.base_address = sys.dm_xe_packages.module_address
ORDER  BY
  sys.dm_xe_packages.[name]; 


-- What objects are there in the Extended Event sub-system?
SELECT DISTINCT object_type
FROM
  sys.dm_xe_objects;

--type			The data types represented by XEvents
--event			The instrumented points in the engine code
--target		The destinations to which we can persist event data
--pred_compare	The type of comparison - similiar to types but more specific
--pred_source	The items on which we can filter our event
--action		The things we can do when an enabled event is fired
--map			The internal map of values to texts
--message		The internal messages that XEvents may write to Error Log, event log etc.

-- This will vary by version of SQL Server
SELECT object_type,
       Count(object_type) [Object Count]
FROM
  sys.dm_xe_objects
GROUP  BY
  object_type;
GO
-- By substituting the various object types in this query you can see the 
-- variety of information contained in XEvents

SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'type';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'event';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'target';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'pred_compare';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'pred_source';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'map';
GO
SELECT *
FROM
  sys.dm_xe_objects
WHERE  object_type = 'message';
GO 

 