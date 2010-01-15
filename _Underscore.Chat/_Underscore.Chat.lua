--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.lua - Chat Frame modifications.                           *
  ****************************************************************************]]


local L = _UnderscoreLocalization.Chat;
local me = CreateFrame( "Frame" );
_Underscore.Chat = me;


me.ChatFrames = {};
me.AddMessageBackups = {};
local AddMessageFilters = {};

me.ScrollBindOverrides = {
	CAMERAZOOMIN = true;
	CAMERAZOOMOUT = true;
};

local IsCameraLookActive = false;
local IsMouseLookActive = false;
local IsScrollBound = false;




--[[****************************************************************************
  * Function: _Underscore.Chat.RegisterFilter                                  *
  ****************************************************************************]]
function me.RegisterFilter ( Filter )
	AddMessageFilters[ #AddMessageFilters + 1 ] = Filter;
end
--[[****************************************************************************
  * Function: _Underscore.Chat.AddMessage                                      *
  * Description: Hook to catch links in messages added by the UI and not by    *
	*   normal chat messages.                                                    *
  ****************************************************************************]]
do
	local type = type;
	local tostring = tostring;
	function me:AddMessage ( Text, ... )
		local Type = type( Text );
		if ( Type == "number" ) then
			Text, Type = tostring( Text ), "string";
		end
		if ( Type == "string" and Text ~= "" ) then
			for _, Filter in ipairs( AddMessageFilters ) do
				Text = Filter( Text ) or Text;
			end
		end
		me.AddMessageBackups[ self ]( self, Text, ... );
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.FilterTimestamp                                 *
  ****************************************************************************]]
do
	local date = date;
	function me.FilterTimestamp ( Text )
		if ( not Text:match( L.TIMESTAMP_PATTERN ) ) then
			-- Avoid putting a full time string into the Lua string table
			return L.TIMESTAMP_FORMAT:format( date( "%H" ), date( "%M" ), date( "%S" ), Text );
		end
	end
end




--[[****************************************************************************
  * Function: _Underscore.Chat:OnMouseWheel                                    *
  ****************************************************************************]]
function me:OnMouseWheel ( Delta )
	if ( IsModifiedClick( "_UNDERSCORE_CHAT_SCROLLPAGE" ) ) then
		if ( Delta > 0 ) then
			self:PageUp();
		else
			self:PageDown();
		end
	elseif ( IsModifiedClick( "_UNDERSCORE_CHAT_SCROLLALL" ) ) then
		if ( Delta > 0 ) then
			self:ScrollToTop();
		else
			self:ScrollToBottom();
		end
	elseif ( Delta > 0 ) then -- Only one line
		self:ScrollUp();
	else
		self:ScrollDown();
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.UpdateScrolling                                 *
  * Description: Enables/disables mouse wheel chat scrolling.                  *
  ****************************************************************************]]
function me.UpdateScrolling ()
	local Enable = not ( IsCameraLookActive or IsMouseLookActive or IsScrollBound );

	for _, ChatFrame in ipairs( me.ChatFrames ) do
		ChatFrame:EnableMouseWheel( Enable );
	end
end


--[[****************************************************************************
  * Function: _Underscore.Chat.CameraMoveStart                                 *
  ****************************************************************************]]
function me.CameraMoveStart ()
	IsCameraLookActive = true;
	me.UpdateScrolling();
end
--[[****************************************************************************
  * Function: _Underscore.Chat.CameraMoveStop                                  *
  ****************************************************************************]]
function me.CameraMoveStop ()
	IsCameraLookActive = false;
	me.UpdateScrolling();
end
--[[****************************************************************************
  * Function: _Underscore.Chat:OnUpdate                                        *
  ****************************************************************************]]
do
	local IsMouseLooking = IsMouselooking;
	function me:OnUpdate ()
		local NewValue = IsMouseLooking();
		if ( IsMouseLookActive ~= NewValue ) then
			IsMouseLookActive = NewValue;
			me.UpdateScrolling();
		end
	end
end


--[[****************************************************************************
  * Function: _Underscore.Chat:MODIFIER_STATE_CHANGED                          *
  * Description: Disables scrolling when the wheel is bound to something.      *
  ****************************************************************************]]
do
	local IsAltKeyDown = IsAltKeyDown;
	local IsControlKeyDown = IsControlKeyDown;
	local IsShiftKeyDown = IsShiftKeyDown;
	local concat = table.concat;
	local GetBindingByKey = GetBindingByKey;
	local wipe = wipe;
	local KeyParts = {};
	function me:MODIFIER_STATE_CHANGED ()
		if ( IsAltKeyDown() ) then
			KeyParts[ #KeyParts + 1 ] = "ALT";
		end
		if ( IsControlKeyDown() ) then
			KeyParts[ #KeyParts + 1 ] = "CTRL";
		end
		if ( IsShiftKeyDown() ) then
			KeyParts[ #KeyParts + 1 ] = "SHIFT";
		end

		local Bound = true;
		KeyParts[ #KeyParts + 1 ] = "MOUSEWHEELUP";
		local Binding = GetBindingByKey( concat( KeyParts, "-" ) );
		if ( not Binding or me.ScrollBindOverrides[ Binding ] ) then
			Bound = false; -- Scrolling allowed
		else
			KeyParts[ #KeyParts ] = "MOUSEWHEELDOWN";
			Binding = GetBindingByKey( concat( KeyParts, "-" ) );
			if ( not Binding or me.ScrollBindOverrides[ Binding ] ) then
				Bound = false; -- Scrolling allowed
			end
		end
		wipe( KeyParts );

		if ( IsScrollBound ~= Bound ) then
			IsScrollBound = Bound;

			me.UpdateScrolling();
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat:UPDATE_BINDINGS                                 *
  ****************************************************************************]]
me.UPDATE_BINDINGS = me.MODIFIER_STATE_CHANGED;
--[[****************************************************************************
  * Function: _Underscore.Chat:PLAYER_LOGIN                                    *
  * Description: Defaults chat to guild if you're in one after loading.        *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	me.PLAYER_LOGIN = nil;

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
	me:SetScript( "OnEvent", _Underscore.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "MODIFIER_STATE_CHANGED" );
	me:RegisterEvent( "PLAYER_LOGIN" );
	me:RegisterEvent( "UPDATE_BINDINGS" );


	hooksecurefunc( "CameraOrSelectOrMoveStart", me.CameraMoveStart );
	hooksecurefunc( "CameraOrSelectOrMoveStop", me.CameraMoveStop );


	for Index = 1, NUM_CHAT_WINDOWS do
		local ChatFrame = _G[ "ChatFrame"..Index ];

		me.ChatFrames[ Index ] = ChatFrame;
		ChatFrame:SetScript( "OnMouseWheel", me.OnMouseWheel );

		me.AddMessageBackups[ ChatFrame ] = ChatFrame.AddMessage;
		ChatFrame.AddMessage = me.AddMessage;
	end




	-- Add timestamps
	me.RegisterFilter( me.FilterTimestamp );

	-- Add new font sizes to menus for the tiny chat log
	local function AddFontHeight ( NewSize )
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
	AddFontHeight( 8 );
	AddFontHeight( 9 );
	AddFontHeight( 10 );

	-- Play sound every time a whisper is recieved
	CHAT_TELL_ALERT_TIME = 0;

	-- Make less common chat channels sticky
	ChatTypeInfo.CHANNEL.sticky = 1;
	ChatTypeInfo.YELL.sticky    = 1;
	ChatTypeInfo.OFFICER.sticky = 1;

	LoggingChat( true );
end
