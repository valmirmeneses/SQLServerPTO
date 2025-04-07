SET NOCOUNT ON;

USE AdventureWorksPTO;

/* 
	After completing the demonstrations for Module 8 Lesson 2 delete the database
	objects created for the demo.

	This cleanup code is also found at the end of of Mod8_Lesson2_Demo2_create_a_workload.sql


	Stop the execution of the code used to generate a workload in 
	Mod8_Lesson2_Demo2_create_a_workload.sql if it's still executing
*/

-- Run this script to identify and delete any leftover Demo indexes
SELECT N'DROP INDEX ' + OBJECT_SCHEMA_NAME(object_id) + N'.' + OBJECT_NAME(object_id) + N'.' + name + ';'
FROM sys.indexes
WHERE object_id = OBJECT_ID('sales.salesorderdetail') AND name LIKE N'Demo%';
GO

-- Drop the stored proc
DROP PROCEDURE Demo.getProductInfo;
GO

-- Drop the schema
DROP SCHEMA Demo;
GO
