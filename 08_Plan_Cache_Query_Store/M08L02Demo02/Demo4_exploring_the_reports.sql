

/*
	Introduction to the Query Store Reports


	In Object Explorer, drill down from 
		the Server to 
			Databases to 
				AdventureWorksPTO to 
					the QueryStore folder
					

	Double-click on Overall Resource Consumption
	
	This is a useful report for looking at overall resource consumption over time.
	Metrics are displayed for:

		Duration 
		Execution Count
		CPU Time
		Logical Reads

	Click on the Configure button.  Here you can select a different set of metrics, 
	a different time interval (the default is the 1 month), a different aggregation
	value (how much time each bar represents) and whether you want to use local (the
	default) or UTC time.

	Double-click on one of the bars to...

	******************************************************************************

	...open the Top Resouce Consuming Queries report.

	Most of the reports are laid out like this one.  

	The histogram at the upper left represents individual queries (each bar is for
	a unique query_id).  The height of the bars indicates resource usage for whatever
	metric is currently selected.  The topmost consumers (25 by default) are found
	at the left.  

	Choose a different metric and notice how the display changes.  

	Hold your cursor over a few bars and notice what information is displayed.


	The chart at the upper right displays information about query plans associated 
	with the currently highlighted bar in the histogram.  If multiple plans have
	been used to execute the query there will be dots of multiple colors.  
	
	A single dot may represent data aggregated across multiple data collection 
	intervals depending on the size of your data collection interval and the number
	of hours or days of data displayed in the chart.

	Hold your cursor over several different dots noticing what information is
	displayed.

	Click on Configure (in the upper right corner) and note what you can modify 
	to change the data displays.


	The query plan displayed at the bottom in the bottom window is that associated
	with the currently selected dot in the plan summary window.

	If you select the Duration metric the bars in the histogram should be for the
	statements in our test stored proc, and one of them should have multiple plans 
	associated with it.  Click on the differently colored dots to see how the 
	displayed query plan changes.

	Highlight the bar associated with multiple plans then click on the icon in the 
	toolbar above the histogram that looks like what you might see through a siting
	scope on a rifle - circle with cross-hairs containing a red zig zag line to
	drill down to...

	******************************************************************************

	...the Tracked Queries Report

	You can use this view to get a historic perspective on a single query.

	******************************************************************************

	Close any open reports and take a look at the remaining reports...

	The Regressed Queries report targets queries that are currently performing less
	well as compared to an earlier time window.  

	Click on one of the plan dots then click on Force to force use of that specific
	query plan for the associated statement going forward.  A check mark will be
	displayed over the dots associated with the forced plan.

	******************************************************************************

	Now open the Queries With Forced Plans report.  The query for which you forced
	a plan will be displayed at the left.  Unforce the query plan by clicking on 
	the dot associated with the fored plan then clicking the Unforce Plan button.

	******************************************************************************

	Open the Queries With High Variation report to see which queries have widely
	varying resouce consumption over time.  

*/