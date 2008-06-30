--[[****************************************************************************
  * _Immunize by Saiket                                                        *
  * _Immunize.lua - Immunizes the client to the "|3" crash.                    *
  ****************************************************************************]]


local L = _ImmunizeLocalization;
local me = CreateFrame( "Frame", "_Immunize" );

me.Enabled = false; -- True when danger is present

local EventIntercept = {
	Handlers = {}; -- Key is event, value is handler
	Frames = {}; -- Both a hash table and indexed array
	Ignore = false; -- Flag to turn off hooks
};
me.EventIntercept = EventIntercept;
local EventInterceptHandlers = EventIntercept.Handlers;
local EventInterceptFrames = EventIntercept.Frames;

me.ReloadUIBackup = ReloadUI;
me.GetGuildRosterMOTDBackup = GetGuildRosterMOTD;




--[[****************************************************************************
  * Function: _Immunize.FilterGsub                                             *
  * Description: Callback used to replace harmful escape sequences.            *
  ****************************************************************************]]
do
	local band = bit.band;
	function me.FilterGsub ( Match )
		local Count = #Match;
		if ( band( Count, 1 ) == 1 ) then -- Odd number of pipe characters
			return ( "|" ):rep( Count - 1 ).."|cffff1111||3|r";
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.Filter                                                 *
  * Description: Replaces harmful escape sequences.                            *
  ****************************************************************************]]
function me.Filter ( Message )
	return ( Message:gsub( "(|+)3", me.FilterGsub ) );
end




--[[****************************************************************************
  * Function: _Immunize.ReloadUI                                               *
  * Description: Disables normal ReloadUI commands when a bad GMotD is set.    *
  *   Reloading UI with a bad GMotD will lock up the client at the load bar.   *
  ****************************************************************************]]
function me.ReloadUI  ()
	if ( me.Enabled ) then
		( IsResting() and Logout or ForceQuit )();
	else
		me.ReloadUIBackup();
	end
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildRosterMOTD                                     *
  * Description: Replaces all escape sequences.                                *
  ****************************************************************************]]
function me.GetGuildRosterMOTD ()
	local Message = me.GetGuildRosterMOTDBackup();
	if ( Message ) then
		return me.Filter( Message );
	end
end




--[[****************************************************************************
  * Function: _Immunize:GUILD_MOTD                                             *
  ****************************************************************************]]
function me:GUILD_MOTD ( _, Message )
	-- Enable lockdown if harmful GMotD is found
	me.Enabled = Message ~= me.Filter( Message );
end
--[[****************************************************************************
  * Function: _Immunize:OnEvent                                                *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( me, Event, ... );
		end
		if ( EventInterceptHandlers[ Event ] ) then
			EventIntercept.Handler( Event, EventInterceptHandlers[ Event ]( ... ) );
		end
	end
end




--[[****************************************************************************
  * Function: _Immunize.EventIntercept:RegisterEvent                           *
  * Description: Disallows registering of intercepted events.                  *
  ****************************************************************************]]
do
	local tinsert = tinsert;
	function EventIntercept:RegisterEvent ( Event )
		if ( not EventIntercept.Ignore ) then
			local Frames = EventInterceptFrames[ Event:upper() ];
			if ( Frames ) then
				EventIntercept.Ignore = true;
				self:UnregisterEvent( Event );
				EventIntercept.Ignore = false;

				-- Add to list of registered frames
				if ( not Frames[ self ] ) then
					tinsert( Frames, self );
					Frames[ self ] = #Frames;
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.EventIntercept:UnregisterEvent                         *
  * Description: Removes false registered frame.                               *
  ****************************************************************************]]
do
	local tremove = tremove;
	function EventIntercept:UnregisterEvent ( Event )
		if ( not EventIntercept.Ignore ) then
			local Frames = EventInterceptFrames[ Event:upper() ];
			if ( Frames and Frames[ self ] ) then
				tremove( Frames, Frames[ self ] );
				Frames[ self ] = nil;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.EventIntercept:RegisterAllEvents                       *
  * Description: Disallows registering of intercepted events.                  *
  ****************************************************************************]]
function EventIntercept:RegisterAllEvents ()
	if ( not EventIntercept.Ignore ) then
		for Event, Frames in pairs( EventInterceptFrames ) do
			EventIntercept.RegisterEvent( self, Event );
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.EventIntercept:UnregisterAllEvents                     *
  * Description: Removes false registered frame.                               *
  ****************************************************************************]]
function EventIntercept:UnregisterAllEvents ()
	if ( not EventIntercept.Ignore ) then
		for Event, Frames in pairs( EventInterceptFrames ) do
			EventIntercept.UnregisterEvent( self, Event );
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.EventIntercept.Add                                     *
  * Description: Adds an intercepted frame.                                    *
  ****************************************************************************]]
function EventIntercept.Add ( Event, Handler, ... )
	if ( not EventInterceptHandlers[ Event ] ) then
		EventInterceptHandlers[ Event ] = Handler;
		EventInterceptFrames[ Event ] = {};

		-- Add previously registered frames to new intercept list
		for Index = 1, select( "#", ... ) do
			select( Index, ... ):RegisterEvent( Event );
		end

		EventIntercept.Ignore = true;
		me:RegisterEvent( Event );
		EventIntercept.Ignore = false;
	end
end
--[[****************************************************************************
  * Function: _Immunize.EventIntercept.Handler                                 *
  * Description: Calls fake events for all registered frames.  Arguments must  *
  *   already be modified before call.                                         *
  ****************************************************************************]]
function EventIntercept.Handler ( Event, ... )
	local Script;
	for _, Frame in ipairs( EventInterceptFrames[ Event ] ) do
		Script = Frame:GetScript( "OnEvent" );
		if ( Script ) then
			this = Frame;
			Script( Frame, Event, ... );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );

	-- Hook all register/unregister event methods
	local function HookRegisterEvent ( self )
		local MetaIndex = getmetatable( type( self ) == "string" and CreateFrame( self ) or self ).__index;
		hooksecurefunc( MetaIndex, "RegisterEvent", EventIntercept.RegisterEvent );
		hooksecurefunc( MetaIndex, "UnregisterEvent", EventIntercept.UnregisterEvent );
		hooksecurefunc( MetaIndex, "RegisterAllEvents", EventIntercept.RegisterAllEvents );
		hooksecurefunc( MetaIndex, "UnregisterAllEvents", EventIntercept.UnregisterAllEvents );
	end
	HookRegisterEvent( me ); -- Frame
	HookRegisterEvent( "Cooldown" );
	HookRegisterEvent( ChatFrameEditBox ); -- EditBox
	HookRegisterEvent( GameTooltip ); -- GameTooltip
	HookRegisterEvent( UIErrorsFrame ); -- MessageFrame
	HookRegisterEvent( MiniMapPing ); -- Model
	HookRegisterEvent( WorldStateScoreScrollFrame ); -- ScrollFrame
	HookRegisterEvent( GuildEventMessageFrame ); -- ScrollingMessageFrame
	HookRegisterEvent( ItemTextPageText ); -- SimpleHTML
	HookRegisterEvent( CharacterModelFrame ); -- PlayerModel
	HookRegisterEvent( DressUpModel ); -- DressUpModel
	HookRegisterEvent( TabardModel ); -- TabardModel
	HookRegisterEvent( "Button" );
	HookRegisterEvent( TutorialFrameCheckButton ); -- CheckButton
	HookRegisterEvent( ColorPickerFrame ); -- ColorSelect
	HookRegisterEvent( Minimap ); -- Minimap
	HookRegisterEvent( OpacitySliderFrame ); -- Slider
	HookRegisterEvent( CastingBarFrame ); -- StatusBar

	local function GUILD_MOTD ( Message, ... )
		Message = me.Filter( Message );
		arg1 = Message;
		return Message, ...;
	end
	EventIntercept.Add( "GUILD_MOTD", GUILD_MOTD, GetFramesRegisteredForEvent( "GUILD_MOTD" ) );


	ReloadUI = me.ReloadUI;
	GetGuildRosterMOTD = me.GetGuildRosterMOTD;
end
