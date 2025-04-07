----------------------------------------
-- *** Interleaved Execution Demo *** --
----------------------------------------

-- Change compatibility level to show previous behavior 

USE [master]
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 130;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

USE [WideWorldImportersDW];
GO

-- IMPORTANT:  Enable the option to "Include Actual Execution Plan" (Ctrl+M) 

-- Our "before" state 

SELECT  [fo].[Order Key], [fo].[Description], [fo].[Package],
		[fo].[Quantity], [foo].[OutlierEventQuantity]
FROM    [Fact].[Order] AS [fo]
INNER JOIN [Fact].[WhatIfOutlierEventQuantity]('Mild Recession',
                            '1-01-2013',
                            '10-15-2014') AS [foo] ON [fo].[Order Key] = [foo].[Order Key]
                            AND [fo].[City Key] = [foo].[City Key]
                            AND [fo].[Customer Key] = [foo].[Customer Key]
                            AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
                            AND [fo].[Order Date Key] = [foo].[Order Date Key]
                            AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
                            AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
                            AND [fo].[Picker Key] = [foo].[Picker Key]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE   [si].[Lead Time Days] > 0
		AND [fo].[Quantity] > 50;


-- Show the execution plan:
--		Notice the estimated number of rows for the Table Valued Function operator
--		Notice the cost of the query by placing the mouse pointer on the SELECT operator
--		Notice the spills 



-- IMPORTANT:  Execute following query on another windows to compare plan shapes 

-- Change compatibility level to show new behavior 

USE [master];
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

USE [WideWorldImportersDW];
GO

-- IMPORTANT:  In the new window, enable the option to "Include Actual Execution Plan" (Ctrl+M) 

-- Our "after" state (with Interleaved execution) 

SELECT  [fo].[Order Key], [fo].[Description], [fo].[Package],
		[fo].[Quantity], [foo].[OutlierEventQuantity]
FROM    [Fact].[Order] AS [fo]
INNER JOIN [Fact].[WhatIfOutlierEventQuantity]('Mild Recession',
                            '1-01-2013',
                            '10-15-2014') AS [foo] ON [fo].[Order Key] = [foo].[Order Key]
                            AND [fo].[City Key] = [foo].[City Key]
                            AND [fo].[Customer Key] = [foo].[Customer Key]
                            AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
                            AND [fo].[Order Date Key] = [foo].[Order Date Key]
                            AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
                            AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
                            AND [fo].[Picker Key] = [foo].[Picker Key]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE   [si].[Lead Time Days] > 0
		AND [fo].[Quantity] > 50;

-- Show the execution plan:
--		Notice the estimated number of rows (did it change?) for the Table Valued Function operator
--		Notice the cost of the query by placing the mouse pointer on the SELECT operator
--		Any spills?
go	