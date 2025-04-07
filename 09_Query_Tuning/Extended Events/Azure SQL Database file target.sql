/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/
---- Transact-SQL code for Event File target on Azure SQL Database.

SET NOCOUNT ON;
GO
----  Step 1.  Establish one little table, and  ---------
----  insert one row of data.
DROP TABLE IF EXISTS Employee;

CREATE TABLE Employee
  (
     EmployeeGuid       UNIQUEIDENTIFIER NOT NULL DEFAULT Newid() PRIMARY KEY,
     EmployeeId         INT NOT NULL IDENTITY(1, 1),
     EmployeeKudosCount INT NOT NULL DEFAULT 0,
     EmployeeDescr      NVARCHAR(256) NULL
  );
GO 

INSERT INTO Employee ( EmployeeDescr )
    VALUES ( 'Jane Doe' );
GO

------  Step 2.  Create key, and  ------------
------  Create credential (your Azure Storage container must already exist).
IF NOT EXISTS (SELECT *
               FROM
                 sys.symmetric_keys
               WHERE  symmetric_key_id = 101)
  BEGIN
      CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DE5888D4-65BA-4F59-9D55-912BAE4BDBA3' -- Or any newid().
  END; 

GO 

IF EXISTS (SELECT *
           FROM
             sys.database_scoped_credentials
           WHERE  name = 'https://sqlsnacks.blob.core.windows.net/xeventssample')
  BEGIN
      DROP DATABASE SCOPED CREDENTIAL [https://sqlsnacks.blob.core.windows.net/xeventssample]
  END; 


GO 

-- use '.blob.',   and not '.queue.' or '.table.' etc.
-- NOTE: You will want to set the end date for the SAS token to be the end of your test engagement!
-- The reason I was having issues with reading the files directly from blob storage was that the SAS Token had
-- expired.
CREATE DATABASE SCOPED CREDENTIAL
	[https://sqlsnacks.blob.core.windows.net/xeventssample] WITH IDENTITY = 'SHARED ACCESS SIGNATURE', -- "SAS" token.
-- TODO: Paste in the long SasToken string here for Secret, 
-- but exclude any leading '?'.
	SECRET = 'sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2018-08-31T20:35:04Z&st=2018-07-13T12:35:04Z&spr=https&sig=LvakZJBJvypNGCGdLIyFZI25xVilTUqy%2FSaxrD9JrY8%3D';
GO 

------  Step 3.  Create (define) an event session.  --------
------  The event session has an event with an action,
------  and a has a target.
IF EXISTS (SELECT *
           FROM
             sys.database_event_sessions
           WHERE  name = 'ASDfiletargetsample')
  BEGIN
      DROP EVENT SESSION ASDfiletargetsample ON DATABASE;
  END
GO 

CREATE EVENT SESSION ASDfiletargetsample ON DATABASE
ADD EVENT sqlserver.sql_statement_starting(
    ACTION (sqlserver.sql_text)
    WHERE statement LIKE 'UPDATE Employee%')
ADD TARGET package0.event_file(SET filename =
            'https://sqlsnacks.blob.core.windows.net/xeventssample/ASDFileTargetSample.xel')
WITH
    (MAX_MEMORY = 10 MB,MAX_DISPATCH_LATENCY = 3 SECONDS)
;
GO
------  Step 4.  Start the event session.  ----------------
------  Issue the SQL Update statements that will be traced.
------  Then stop the session.

------  Note: If the target fails to attach,
------  the session must be stopped and restarted.

ALTER EVENT SESSION ASDfiletargetsample
ON DATABASE
STATE = START;
GO 

SELECT 'BEFORE_Updates',
       EmployeeKudosCount,
       *
FROM
  Employee;

UPDATE Employee
SET    EmployeeKudosCount = EmployeeKudosCount + 2
WHERE  EmployeeDescr = 'Jane Doe';

UPDATE Employee
SET    EmployeeKudosCount = EmployeeKudosCount + 13
WHERE  EmployeeDescr = 'Jane Doe';

SELECT 'AFTER__Updates',
       EmployeeKudosCount,
       *
FROM
  Employee;
GO 

ALTER EVENT SESSION ASDfiletargetsample
ON DATABASE
STATE = STOP;
GO

-------------- Step 5.  Select the results. ----------
SELECT
    *, 
    CAST(event_data AS XML) AS [event_data_XML]
FROM
    sys.fn_xe_file_target_read_file(
		'https://sqlsnacks.blob.core.windows.net/xeventssample/ASDFileTargetSample',null, null, null);
GO

-------------- Step 6.  Clean up. ----------
DROP EVENT SESSION ASDfiletargetsample
ON DATABASE;
GO

DROP DATABASE SCOPED CREDENTIAL [https://sqlsnacks.blob.core.windows.net/xeventssample];
GO

DROP TABLE Employee;
GO
