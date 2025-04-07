SET NOCOUNT ON;
GO
USE AdventureWorks;
GO
DBCC FREEPROCCACHE
GO
SET STATISTICS TIME ON;
SET STATISTICS IO ON
GO
SELECT p.Title + ' ' + p.FirstName + ' ' + p.LastName AS FullName, c.AccountNumber, s.Name
FROM Person.Person AS p 
INNER JOIN Sales.Customer AS c ON c.PersonID = p.BusinessEntityID 
INNER JOIN Sales.Store AS s ON s.BusinessEntityID = c.StoreID
WHERE p.LastName = 'Koski'
