--[[****************************************************************************
  * _Immunize by Saiket                                                        *
  * _Immunize.lua - Immunizes the client to the "|3" crash.                    *
  ****************************************************************************]]


local L = _ImmunizeLocalization;
local me = CreateFrame( "Frame", "_Immunize" );

me.IsPrivateServer = false; -- Set to true for extra protection on private servers

me.Enabled = false; -- True when danger is present

local EventIntercept = {
	Handlers = {}; -- Key is event, value is handler
	Frames = {}; -- Both a hash table and indexed array
	Ignore = false; -- Flag to turn off hooks
};
me.EventIntercept = EventIntercept;
local EventInterceptHandlers = EventIntercept.Handlers;
local EventInterceptFrames = EventIntercept.Frames;




--[[****************************************************************************
  * Function: _Immunize.FilterGsub                                             *
  * Description: Callback used to replace harmful escape sequences.            *
  ****************************************************************************]]
do
	local band = bit.band;
	function me.FilterGsub ( Match )
		local Count = #Match;
		if ( band( Count, 1 ) == 1 ) then -- Odd number of pipe characters
			return Match:sub( 1, -2 ).."|cffff1111||3|r";
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
  * Function: _Immunize.FilterRemoveGsub                                       *
  * Description: Callback used to remove harmful escape sequences.             *
  ****************************************************************************]]
do
	local band = bit.band;
	function me.FilterRemoveGsub ( Match )
		local Count = #Match;
		if ( band( Count, 1 ) == 1 ) then -- Odd number of pipe characters
			return Match:sub( 1, -2 ); -- Remove last pipe
		end
	end
end
--[[****************************************************************************
  * Function: _Immunize.FilterRemove                                           *
  * Description: Removes harmful escape sequences.                             *
  ****************************************************************************]]
function me.FilterRemove ( Message )
	return ( Message:gsub( "(|+)3", me.FilterRemoveGsub ) );
end




--[[****************************************************************************
  * Function: _Immunize.ReloadUI                                               *
  * Description: Disables normal ReloadUI commands when a bad GMotD is set.    *
  *   Reloading UI with a bad GMotD will lock up the client at the load bar.   *
  ****************************************************************************]]
function me.ReloadUI  ( ... )
	if ( me.Enabled ) then
		( IsResting() and Logout or ForceQuit )();
	else
		me.ReloadUIBackup( ... );
	end
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildRosterMOTDVararg                               *
  ****************************************************************************]]
function me.GetGuildRosterMOTDVararg ( Message, ... )
	if ( Message ) then
		Message = me.Filter( Message );
	end
	return Message, ...;
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildRosterMOTD                                     *
  * Description: Replaces all harmful escape sequences.                        *
  ****************************************************************************]]
function me.GetGuildRosterMOTD ( ... )
	return me.GetGuildRosterMOTDVararg( me.GetGuildRosterMOTDBackup( ... ) );
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildRosterInfoVararg                               *
  ****************************************************************************]]
function me.GetGuildRosterInfoVararg ( Name, Rank, RankIndex, Level, Class, Zone, Note, OfficerNote, ... )
	if ( Rank ) then
		Rank = me.Filter( Rank );
	end
	if ( Note ) then
		Note = me.Filter( Note );
	end
	if ( OfficerNote ) then
		OfficerNote = me.Filter( OfficerNote );
	end
	return Name, Rank, RankIndex, Level, Class, Zone, Note, OfficerNote, ...;
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildRosterInfo                                     *
  * Description: Replaces all harmful escape sequences from ranks and notes.   *
  ****************************************************************************]]
function me.GetGuildRosterInfo ( Index, ... )
	return me.GetGuildRosterInfoVararg( me.GetGuildRosterInfoBackup( Index, ... ) );
end
--[[****************************************************************************
  * Function: _Immunize.GuildControlGetRankNameVararg                          *
  ****************************************************************************]]
function me.GuildControlGetRankNameVararg ( Rank, ... )
	return me.Filter( Rank ), ...;
end
--[[****************************************************************************
  * Function: _Immunize.GuildControlGetRankName                                *
  * Description: Replaces all harmful escape sequences.                        *
  ****************************************************************************]]
function me.GuildControlGetRankName ( Index, ... )
	return me.GuildControlGetRankNameVararg( me.GuildControlGetRankNameBackup( Index, ... ) );
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildInfoVararg                                     *
  ****************************************************************************]]
function me.GetGuildInfoVararg ( Guild, Rank, RankID, ... )
	if ( Rank ) then
		Rank = me.Filter( Rank );
	end
	return Guild, Rank, RankID, ...;
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildInfo                                           *
  * Description: Replaces all harmful escape sequences in rank name.           *
  ****************************************************************************]]
function me.GetGuildInfo ( UnitID, ... )
	return me.GetGuildInfoVararg( me.GetGuildInfoBackup( UnitID, ... ) );
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildInfoTextVararg                                 *
  ****************************************************************************]]
function me.GetGuildInfoTextVararg ( Info, ... )
	if ( Info ) then
		Info = me.Filter( Info );
	end
	return Info, ...;
end
--[[****************************************************************************
  * Function: _Immunize.GetGuildInfoText                                       *
  * Description: Replaces all harmful escape sequences in guild info.          *
  ****************************************************************************]]
function me.GetGuildInfoText ( ... )
	return me.GetGuildInfoTextVararg( me.GetGuildInfoTextBackup( ... ) );
end




--[[****************************************************************************
  * Function: _Immunize:PLAYER_LOGIN                                           *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	-- Disable chat bubbles
	SetCVar( "ChatBubbles", "0" );
	SetCVar( "ChatBubblesParty", "0" );
	hooksecurefunc( "SetCVar", function ( CVar, Value )
		Value = tonumber( Value );
		if ( Value ~= 0 ) then
			CVar = CVar:upper();
			if ( CVar == "CHATBUBBLES" ) then
				SetCVar( "ChatBubbles", "0" );
			elseif ( CVar == "CHATBUBBLESPARTY" ) then
				SetCVar( "ChatBubblesParty", "0" );
			end
		end
	end );
end
--[[****************************************************************************
  * Function: _Immunize:GUILD_MOTD                                             *
  ****************************************************************************]]
function me:GUILD_MOTD ( _, Message )
	-- Enable lockdown if harmful GMotD is found
	me.Enabled = Message ~= me.Filter( Message );
end
--[[****************************************************************************
  * Function: _Immunize:GUILD_ROSTER_UPDATE                                    *
  ****************************************************************************]]
function me:GUILD_ROSTER_UPDATE ()
	-- Scan for harmful player notes
	local Rank, Note, OfficerNote, _;
	for Index = 1, GetNumGuildMembers( GetGuildRosterShowOffline() ) do
		_, Rank, _, _, _, _, Note, OfficerNote = me.GetGuildRosterInfoBackup( Index );
		if ( ( Rank ~= me.Filter( Rank ) )
		  or ( Note ~= me.Filter( Note ) )
		  or ( OfficerNote ~= me.Filter( OfficerNote ) )
		) then
			me.Enabled = true;
			return;
		end
	end

	-- Scan ranks
	for Index = 1, GuildControlGetNumRanks() do
		Rank = me.GuildControlGetRankNameBackup( Index );
		if ( Rank ~= me.Filter( Rank ) ) then
			me.Enabled = true;
			return;
		end
	end

	me.Enabled = false; -- Nothing found
end
--[[****************************************************************************
  * Function: _Immunize:PLAYER_GUILD_UPDATE                                    *
  ****************************************************************************]]
me.PLAYER_GUILD_UPDATE = me.GUILD_ROSTER_UPDATE; -- Check when entering/leaving guild
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
	do
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
	end

	do
		local FilterRemove = me.FilterRemove;
		local function CHAT_MSG_ADDON ( Prefix, Message, ... )
			Prefix = FilterRemove( Prefix );
			arg1 = Prefix;
			Message = FilterRemove( Message );
			arg2 = Message;
			return Prefix, Message, ...;
		end
		EventIntercept.Add( "CHAT_MSG_ADDON", CHAT_MSG_ADDON, GetFramesRegisteredForEvent( "CHAT_MSG_ADDON" ) );
	end

	if ( me.IsPrivateServer ) then
		local Filter = me.Filter;
		local function CHAT_MSG ( Message, ... )
			if ( Message ) then
				Message = Filter( Message );
				arg1 = Message;
			end
			return Message, ...;
		end

		me:RegisterEvent( "PLAYER_LOGIN" );
		me:RegisterEvent( "PLAYER_GUILD_UPDATE" );
		me:RegisterEvent( "GUILD_ROSTER_UPDATE" );

		EventIntercept.Add( "GUILD_MOTD", CHAT_MSG, GetFramesRegisteredForEvent( "GUILD_MOTD" ) );
		EventIntercept.Add( "SYSMSG", CHAT_MSG, GetFramesRegisteredForEvent( "SYSMSG" ) );

		EventIntercept.Add( "CHAT_MSG_AFK", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_AFK" ) );
		EventIntercept.Add( "CHAT_MSG_BATTLEGROUND", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_BATTLEGROUND" ) );
		EventIntercept.Add( "CHAT_MSG_BATTLEGROUND_LEADER", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_BATTLEGROUND_LEADER" ) );
		EventIntercept.Add( "CHAT_MSG_CHANNEL", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_CHANNEL" ) );
		EventIntercept.Add( "CHAT_MSG_DND", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_DND" ) );
		EventIntercept.Add( "CHAT_MSG_EMOTE", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_EMOTE" ) );
		EventIntercept.Add( "CHAT_MSG_GUILD", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_GUILD" ) );
		EventIntercept.Add( "CHAT_MSG_OFFICER", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_OFFICER" ) );
		EventIntercept.Add( "CHAT_MSG_PARTY", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_PARTY" ) );
		EventIntercept.Add( "CHAT_MSG_RAID", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_RAID" ) );
		EventIntercept.Add( "CHAT_MSG_RAID_LEADER", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_RAID_LEADER" ) );
		EventIntercept.Add( "CHAT_MSG_RAID_WARNING", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_RAID_WARNING" ) );
		EventIntercept.Add( "CHAT_MSG_SAY", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_SAY" ) );
		EventIntercept.Add( "CHAT_MSG_SYSTEM", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_SYSTEM" ) );
		EventIntercept.Add( "CHAT_MSG_WHISPER", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_WHISPER" ) );
		EventIntercept.Add( "CHAT_MSG_WHISPER_INFORM", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_WHISPER_INFORM" ) );
		EventIntercept.Add( "CHAT_MSG_YELL", CHAT_MSG, GetFramesRegisteredForEvent( "CHAT_MSG_YELL" ) );


		me.ReloadUIBackup = ReloadUI;
		me.GetGuildRosterMOTDBackup = GetGuildRosterMOTD;
		me.GetGuildRosterInfoBackup = GetGuildRosterInfo;
		me.GuildControlGetRankNameBackup = GuildControlGetRankName;
		me.GetGuildInfoBackup = GetGuildInfo;
		me.GetGuildInfoTextBackup = GetGuildInfoText;

		ReloadUI = me.ReloadUI;
		GetGuildRosterMOTD = me.GetGuildRosterMOTD;
		GetGuildRosterInfo = me.GetGuildRosterInfo;
		GuildControlGetRankName = me.GuildControlGetRankName;
		GetGuildInfo = me.GetGuildInfo;
		GetGuildInfoText = me.GetGuildInfoText;
	end
end
