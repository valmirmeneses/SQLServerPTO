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

-------------------------------------------------------------------------
-- Exploring Join Order
-- You will realize that doesn't matter the query join order. 
-- SQl Server optimizer could internally use another join order 
-- considering only the cost.
-------------------------------------------------------------------------

-- Clear the plan cache to to ensure a new query execution plan is generated
DBCC FREEPROCCACHE;

USE AdventureWorks;
GO

-- IMPORTANT:  Enable the option to "Include Actual Execution Plan" (Ctrl+M) 

-- From tables with a small number of rows first
SELECT bc.BusinessEntityID, c.Name, p.PersonType, p.NameStyle, e.NationalIDNumber
FROM Person.ContactType c --20 rows
     INNER JOIN Person.BusinessEntityContact bc --909 rows
    ON bc.ContactTypeID = c.ContactTypeID
     INNER JOIN HumanResources.Employee e --290 rows
    ON e.BusinessEntityID = bc.BusinessEntityID
     INNER JOIN Person.Person p --19972 rows
    ON p.BusinessEntityID = bc.BusinessEntityID;

/*
	Compare the join order in the plan with the order in which the tables are 
	listed in the FROM clause.

	Query Order				Plan Order
		ContactType				Employee
		BusinessEntityContact	BusinessEntityContact
		Employee				Person
		Person					ContactType
	
	By joining Employee and BusinessEntityContact first, the result set is reduced 
	to an estimated row count of 1 (output of the Hash Match) early in query exe-
	cution.  This then reduces the cost of those subsequent Clustered Index Seeks.
*/

-- Clear the plan cache again
DBCC FREEPROCCACHE;

-- And reorder the tables in your FROM clause
SELECT bc.BusinessEntityID, c.Name, p.PersonType, p.NameStyle, e.NationalIDNumber
FROM Person.BusinessEntityContact bc --909 rows
     INNER JOIN Person.Person p --19972 rows
    ON p.BusinessEntityID = bc.BusinessEntityID
     INNER JOIN HumanResources.Employee e --290 rows
    ON e.BusinessEntityID = bc.BusinessEntityID
     INNER JOIN Person.ContactType c --20 rows
    ON bc.ContactTypeID = c.ContactTypeID;
/*
	Compare the join order in the plan with the order in which the tables are 
	listed in the FROM clause.

	An identical execution plan is generated.

	Query Order				Plan Order
		BusinessEntityContact	Employee
		Person					BusinessEntityContact
		Employee				Person
		ContactType				ContactType
*/


-- Clear the plan cache again
DBCC FREEPROCCACHE;

-- Consider that this is different for outer joins
-- Execute the following queries together

SELECT bc.BusinessEntityID, c.Name, p.PersonType, p.NameStyle, e.NationalIDNumber
FROM Person.ContactType c --20 rows
     LEFT JOIN Person.BusinessEntityContact bc --909 rows
    ON bc.ContactTypeID = c.ContactTypeID
     LEFT JOIN HumanResources.Employee e --290 rows
    ON e.BusinessEntityID = bc.BusinessEntityID
     LEFT JOIN Person.Person p --19972 rows
    ON p.BusinessEntityID = bc.BusinessEntityID;

SELECT bc.BusinessEntityID, c.Name, p.PersonType, p.NameStyle, e.NationalIDNumber
FROM Person.BusinessEntityContact bc --909 rows
     LEFT JOIN Person.Person p --19972 rows
    ON p.BusinessEntityID = bc.BusinessEntityID
     LEFT JOIN HumanResources.Employee e --290 rows
    ON e.BusinessEntityID = bc.BusinessEntityID
     LEFT JOIN Person.ContactType c --20 rows
    ON bc.ContactTypeID = c.ContactTypeID;

-- Note that this itme SQL Server did not change the join order as it is necessary
-- to execute the query as stated to return the information as requested.