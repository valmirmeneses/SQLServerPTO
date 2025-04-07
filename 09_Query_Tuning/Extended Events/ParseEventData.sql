-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		boB Taylor
-- Create date: 6/21/2018
-- Description:	Simplify the parsing of XEvent Data payloads
-- =============================================
CREATE PROCEDURE ParseEventData 
	-- Add the parameters for the stored procedure here
	@TargetType varchar(128) = '', 
	@SessionName varchar(128) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF @TargetType NOT IN (SELECT [name]
		FROM
			sys.dm_xe_objects
		WHERE  object_type = 'target'
			AND (capabilities_desc NOT LIKE 'private%' OR capabilities_desc IS NULL))
		RAISERROR (N'Invalid target type',16,1)

	IF @SessionName NOT IN (SELECT name from sys.dm_xe_sessions)
		RAISERROR (N'Must be an active session',16,1)

	SELECT Cast(t.target_data AS XML) AS EventDataXml
	   FROM
		 sys.dm_xe_session_targets AS t
		 JOIN sys.dm_xe_sessions AS s
		   ON s.address = t.event_session_address
	   -- find the session that we are interested in. Must specify the type and the name
	   WHERE  t.target_name = @TargetType AND s.name = @SessionName
END
GO
