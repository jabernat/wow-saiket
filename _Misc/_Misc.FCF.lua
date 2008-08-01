--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.FCF.lua - Floating Chat Frame modifications.                         *
  *                                                                            *
  * + Adds font sizes 8 through 10 to the chat frame's options dropdown.       *
  * + Recognizes URLs in chat frames and makes them clickable links.           *
  * + Enables the mousewheel for chat frames.                                  *
  *   + Support for keyboard speed modifiers. Use <Ctrl> to jump a full page   *
  *     up or down, and <Alt> to jump to the top or bottom.                    *
  *   + If the scrollwheel is bound to an action with a modifier - such as     *
  *     <Ctrl+MouseWheelDown>, that action will override scrolling.            *
  *   + While mouselooking, <MouseWheelUp/Down> bindings will always override  *
  *     scrolling to support the default zooming binds.                        *
  * + The yell, channel and officer chat modes stick between messages.         *
  * + If guilded when you log in, guild chat will be the default channel.      *
  * + Chat and combat logging will be enabled by default.                      *
  ****************************************************************************]]


local _Misc = _Misc;
local L = _MiscLocalization;
local me = CreateFrame( "Frame" );
_Misc.FCF = me;


local URLChatTypes = {
	[ "CHAT_MSG_AFK" ]            = true;
	[ "CHAT_MSG_BATTLEGROUND" ]   = true;
	[ "CHAT_MSG_BATTLEGROUND_LEADER" ] = true;
	[ "CHAT_MSG_CHANNEL" ]        = true;
	[ "CHAT_MSG_DND" ]            = true;
	[ "CHAT_MSG_EMOTE" ]          = true; -- Only for custom emotes
	[ "CHAT_MSG_GUILD" ]          = true;
	[ "CHAT_MSG_OFFICER" ]        = true;
	[ "CHAT_MSG_PARTY" ]          = true;
	[ "CHAT_MSG_RAID" ]           = true;
	[ "CHAT_MSG_RAID_LEADER" ]    = true;
	[ "CHAT_MSG_RAID_WARNING" ]   = true;
	[ "CHAT_MSG_SAY" ]            = true;
	[ "CHAT_MSG_WHISPER" ]        = true;
	[ "CHAT_MSG_WHISPER_INFORM" ] = true; -- For when you send a whisper
	[ "CHAT_MSG_YELL" ]           = true;
	[ "SYSMSG" ]                  = true;
	[ "CHAT_MSG_SYSTEM" ]         = true;
};
me.URLChatTypes = URLChatTypes;
local URLFormats = {
	' ([-_%w]+%.[-_%w]+%.[-_%w][^ <>"|]+) ?', -- Address with subdomain ("www")
	' ?"([-_%w]+%.[-_%w]+%.[-_%w][^<>"|]+)" ?',
	' ?<([-_%w]+%.[-_%w]+%.[-_%w][^<>"|]+)> ?',

	' (%a+://[^ <>"|]+) ?', -- Address with protocol
	' ?"(%a+://[^<>"|]+)" ?',
	' ?<(%a+://[^<>"|]+)> ?',

	' ([-_%w][-_%w%.]+[-_%w]@[-_%w][-_%w%.]+[-_%w]) ?', -- Email address
	' ?"([-_%w][-_%w%.]+[-_%w]@[-_%w][-_%w%.]+[-_%w])" ?',
	' ?<([-_%w][-_%w%.]+[-_%w]@[-_%w][-_%w%.]+[-_%w])> ?',

	' (%d+%.%d+%.%d+%.%d+:%d+) ?', -- IP address with port
	' (%d+%.%d+%.%d+%.%d+) ?' -- IP address
};
me.URLFormats = URLFormats;
local AddMessageMethods = {};
me.AddMessageMethods = AddMessageMethods;
me.MessageEventHandlerBackup = ChatFrame_MessageEventHandler;
me.SystemEventHandlerBackup = ChatFrame_SystemEventHandler;
me.IsCameraMoving = false;
me.IsMouseLooking = false;
me.IsShiftKeyDown = false;




--[[****************************************************************************
  * Function: _Misc.FCF.AddFontHeight                                          *
  * Description: Add a font size to the list in order if not already there.    *
  *   This won't work if Fonts.xml gets loaded a second time from a load on    *
  *   demand addon.                                                            *
  ****************************************************************************]]
function me.AddFontHeight ( NewSize )
	for Index, Size in ipairs( CHAT_FONT_HEIGHTS ) do
		if ( Size >= NewSize ) then
			if ( Size ~= NewSize ) then
				-- Add to the front of the list
				tinsert( CHAT_FONT_HEIGHTS, Index, NewSize );
			end
			break;
		end
	end
end


--[[****************************************************************************
  * Function: _Misc.FCF.ParseMessageURLs                                       *
  * Description: Replace links in a chat message with formated versions.       *
  ****************************************************************************]]
do
	local ipairs = ipairs;
	function me.ParseMessageURLs ( Text )
		-- Ensure that links at the start of the message are recognized
		Text = " "..Text;

		for _, Format in ipairs( URLFormats ) do
			if ( Text:find( Format ) ) then
				Text = Text:gsub( Format, L.FCF_URL_FORMAT );
			end
		end

		-- Remove that extra space we added earlier
		return Text:sub( 2 );
	end
end


--[[****************************************************************************
  * Function: _Misc.FCF.MessageEventHandler                                    *
  * Description: Catches chat events (hooks ChatFrame_MessageEventHandler).    *
  ****************************************************************************]]
do
	local ParseMessageURLs = me.ParseMessageURLs;
	function me.MessageEventHandler ( Event )
		if ( URLChatTypes[ Event ] ) then
			arg1 = ParseMessageURLs( arg1 );
		end

		me.MessageEventHandlerBackup( Event );
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF.SystemEventHandler                                     *
  * Description: Catches chat events (hooks ChatFrame_SystemEventHandler).     *
  ****************************************************************************]]
do
	local ParseMessageURLs = me.ParseMessageURLs;
	function me.SystemEventHandler ( Event )
		if ( URLChatTypes[ Event ] ) then
			arg1 = ParseMessageURLs( arg1 );
		end

		me.SystemEventHandlerBackup( Event );
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF.AddMessageSpellGsub                                    *
  * Description: Callback for gsub to add spell icons.                         *
  ****************************************************************************]]
do
	local GetSpellInfo = GetSpellInfo;
	local select = select;
	function me.AddMessageSpellGsub ( Match )
		local Texture = select( 3, GetSpellInfo( Match ) );
		return Texture and "|T"..Texture..":0|t|Hspell:"..Match;
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF.AddMessageItemGsub                                     *
  * Description: Callback for gsub to add item icons.                          *
  ****************************************************************************]]
do
	local GetItemIcon = GetItemIcon;
	function me.AddMessageItemGsub ( Match )
		local Texture = GetItemIcon( Match );
		return Texture and "|T"..Texture..":0|t|H"..Match.."|h[";
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF.AddMessage                                             *
  * Description: Hook to catch links in messages added by the UI and not by    *
	*   normal chat messages.                                                    *
  ****************************************************************************]]
do
	local AddMessageSpellGsub = me.AddMessageSpellGsub;
	local AddMessageItemGsub = me.AddMessageItemGsub;
	local ParseMessageURLs = me.ParseMessageURLs;
	local TimeIsKnown = _Misc.Time.IsKnown;
	local GetGameTimeString = _Misc.Time.GetGameTimeString;
	local select = select;
	function me:AddMessage ( Text, ... )
		if ( Text ) then
			if ( select( 4, ... ) == nil ) then -- Most likely a message added by another addon which won't be caught by the event handler
				Text = ParseMessageURLs( Text );
			end
			-- Add item and spell icons
			Text = Text:gsub( "|Hspell:(%d+)", AddMessageSpellGsub ):gsub( "|H(item:[^|]+)|h%[", AddMessageItemGsub );
			if ( not Text:find( L.FCF_TIMESTAMP_PATTERN ) and TimeIsKnown() ) then
				Text = L.FCF_TIMESTAMP_FORMAT:format( GetGameTimeString(), Text );
			end
			AddMessageMethods[ self ]( self, Text, ... );
		end
	end
end


--[[****************************************************************************
  * Function: _Misc.FCF.UpdateScrolling                                        *
  * Description: Enables/disables mouse wheel chat scrolling.                  *
  ****************************************************************************]]
function me.UpdateScrolling ()
	local Enable = not me.IsCameraMoving and not me.IsMouseLooking and not me.IsShiftKeyDown;
	for Index = 1, NUM_CHAT_WINDOWS do
		local ChatFrame = _G[ "ChatFrame"..Index ];
		
		ChatFrame:SetScript( "OnMouseWheel", Enable and me.OnMouseWheel or nil );
		_Misc.RunProtectedMethod( ChatFrame, "EnableMouseWheel", Enable );
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF:OnMouseWheel                                           *
  * Description: Scroll chat with the mouse wheel when appropriate.            *
  ****************************************************************************]]
function me:OnMouseWheel ( Delta )
	if ( IsControlKeyDown() ) then
		if ( Delta > 0 ) then
			self:PageUp();
		else
			self:PageDown();
		end
	elseif ( not IsAltKeyDown() ) then
		if ( Delta > 0 ) then
			self:ScrollUp();
		else
			self:ScrollDown();
		end
	elseif ( Delta > 0 ) then
		self:ScrollToTop();
	else
		self:ScrollToBottom();
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF:OnEvent                                                *
  * Description: Disables scrolling when shift is held.                        *
  ****************************************************************************]]
function me:OnEvent ( Event, Button, Pressed )
	if ( Event == "MODIFIER_STATE_CHANGED" and Button:sub( 2 ) == "SHIFT" ) then
		me.IsShiftKeyDown = Pressed == 1;
		me.UpdateScrolling();
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF:OnUpdate                                               *
  * Description: Disables scrolling when mouselooking is active.               *
  ****************************************************************************]]
do
	local IsMouselooking = IsMouselooking;
	function me:OnUpdate ( Elapsed )
		if ( me.IsCameraMoving ~= IsMouselooking() ) then
			me.IsCameraMoving = IsMouselooking();
			me.UpdateScrolling();
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.FCF.CameraMoveStart                                        *
  * Description: Disables scrolling when mouselooking is active.               *
  ****************************************************************************]]
function me.CameraMoveStart ()
	me.IsMouseLooking = true;
	me.UpdateScrolling();
end
--[[****************************************************************************
  * Function: _Misc.FCF.CameraMoveStop                                         *
  * Description: Disables scrolling when mouselooking is active.               *
  ****************************************************************************]]
function me.CameraMoveStop ()
	me.IsMouseLooking = false;
	me.UpdateScrolling();
end


--[[****************************************************************************
  * Function: _Misc.FCF.UpdateStickyType                                       *
  * Description: Defaults chat to guild if you're in one after loading.        *
  ****************************************************************************]]
function me.UpdateStickyType ()
	local EditBox = DEFAULT_CHAT_FRAME.editBox;
	if ( EditBox:GetAttribute( "stickyType" ) == "SAY" and IsInGuild() ) then
		EditBox:SetAttribute( "chatType", "GUILD" );
		EditBox:SetAttribute( "stickyType", "GUILD" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "MODIFIER_STATE_CHANGED" );
	hooksecurefunc( "CameraOrSelectOrMoveStart", me.CameraMoveStart );
	hooksecurefunc( "CameraOrSelectOrMoveStop", me.CameraMoveStop );


	for Index = 1, NUM_CHAT_WINDOWS do
		local ChatFrame = _G[ "ChatFrame"..Index ];

		AddMessageMethods[ ChatFrame ] = ChatFrame.AddMessage;
		ChatFrame.AddMessage = me.AddMessage;
	end
	me.UpdateScrolling();


	-- Link hooks
	ChatFrame_SystemEventHandler = me.SystemEventHandler;
	ChatFrame_MessageEventHandler = me.MessageEventHandler;

	-- This helps for using chat macros in general chat and so on
	ChatTypeInfo.CHANNEL.sticky = 1;
	ChatTypeInfo.YELL.sticky    = 1;
	ChatTypeInfo.OFFICER.sticky = 1;

	-- Add font sizes 8, 9 and 10 to menus for the tiny chat log
	me.AddFontHeight( 8 );
	me.AddFontHeight( 9 );
	me.AddFontHeight( 10 );

	-- Log chat
	LoggingChat( true );
	LoggingCombat( true );

	-- Play sound every time a whisper is recieved
	CHAT_TELL_ALERT_TIME = 0;
end
