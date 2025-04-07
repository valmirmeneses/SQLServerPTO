SET NOCOUNT ON;

USE AdventureWorksPTO;
GO

/* 
	Check whether any Demo indexes already exist - drop them if they do

		SELECT N'DROP INDEX ' + OBJECT_SCHEMA_NAME(object_id) + N'.' + OBJECT_NAME(object_id) + N'.' + name + ';'
		FROM sys.indexes
		WHERE object_id = OBJECT_ID('sales.salesorderdetail') AND name LIKE N'Demo%';
*/

CREATE SCHEMA Demo;
GO

-- Create a stored proc
CREATE OR ALTER PROCEDURE Demo.getProductInfo
    @ProductID INT
AS
    SET NOCOUNT ON;
    SELECT   ProductID, OrderQty, UnitPrice
    FROM     Sales.SalesOrderDetail
    WHERE    ProductID = @ProductID;

	SELECT ProductID, Name, ProductNumber
	FROM Production.Product
	WHERE ProductID = @ProductID;
GO

/*
	To reduce the cost of executing the test proc over and over and over, we'll
	enable an option (for this query window only) to skip displaying the result 
	sets after code is executed:

		Right-click in window
		Select "Query Options..."
		Click on "Results" in the lefthand panel
		Enable the option to "Discard results after execution"
*/

/*****************************************************************************/

-- Kick off a looping workload to generate some data to collect in the Query Store

DECLARE @counter INT = 1, @subcounter INT = 1;
WHILE (@counter <= 100)
BEGIN

	-- Execute the proc multiple times with a different, random ProductId each 
	-- time
	DECLARE @product_id INT, @counter2 INT = 1;
	WHILE (@counter2 <= 250)
	BEGIN

		-- Periodically recompile the proc in hopes of occasionally generating a plan
		-- not well suited to our random paramter values
		IF @counter % 50 = 0
		BEGIN
			EXEC sp_recompile 'Demo.getProductInfo';
		END
        
		SET @product_id = ROUND((RAND() * 1000),0);
		
		EXEC Demo.getProductInfo @product_id;
		
		SET @counter2 += 1;
		
		WAITFOR DELAY '00:00:02';

	END
	
	-- Every so often, change up the indexes so different plans are generated
	IF @counter % 100 = 0
	BEGIN
		IF @subcounter = 1
			-- Create a non-covering index
			CREATE NONCLUSTERED INDEX Demo_ProductID__UnitPrice ON Sales.SalesOrderDetail ( ProductID ) INCLUDE (UnitPrice);

		IF @subcounter = 2
			-- Create a covering index
			CREATE NONCLUSTERED INDEX Demo_ProductID__UnitPrice_OrderQty ON Sales.SalesOrderDetail ( ProductID ) INCLUDE ( UnitPrice, OrderQty );

		IF @subcounter = 3
			-- Drop the covering index 
			DROP INDEX IF EXISTS Demo_ProductID__UnitPrice_OrderQty ON Sales.SalesOrderDetail;

		IF @subcounter = 4
			-- Drop the non-covering index 
			DROP INDEX IF EXISTS Demo_ProductID__UnitPrice ON Sales.SalesOrderDetail;

		IF @subcounter < 4
			SET @subcounter += 1;
		ELSE 
			SET @subcounter = 1;
	END

	SET @counter += 1;

	WAITFOR DELAY '00:00:02';
	    
END
GO

/*****************************************************************************/

-- Clean up (in a comment block so it's not accidentally run too early)

/*
	-- Stop this script if it's still executing

	-- In another query window, run the script below to check again for any 
	-- leftover Demo indexes - delete any that are still there
	SELECT N'DROP INDEX ' + OBJECT_SCHEMA_NAME(object_id) + N'.' + OBJECT_NAME(object_id) + N'.' + name + ';'
	FROM sys.indexes
	WHERE object_id = OBJECT_ID('sales.salesorderdetail') AND name LIKE N'Demo%';
	GO

	DROP PROCEDURE Demo.getProductInfo;
	GO

	DROP SCHEMA Demo;
	GO
*/
