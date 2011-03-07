--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.lua - Chat Frame modifications.                           *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.Chat = me;

me.Frame = CreateFrame( "Frame" );
me.MaxLines = 1024;

local PreserveMaxLines = IsShiftKeyDown();




do
	local Filters = {};
	--- @param Filter  Callback that receives a chat message and optionally returns a replacement.
	function me.RegisterFilter ( Filter )
		Filters[ #Filters + 1 ] = Filter;
	end
	local type, ipairs = type, ipairs;
	local AddMessageBackups = {};
	--- Hook to apply filters to all messages printed to chat.
	local function AddMessage ( self, Text, ... )
		if ( type( Text ) == "string" and Text ~= "" ) then
			for _, Filter in ipairs( Filters ) do
				Text = Filter( Text ) or Text;
			end
		end
		return AddMessageBackups[ self ]( self, Text, ... );
	end
	--- Shows the bottom button when not scrolled to the bottom.
	local function OnMessageScrollChanged ( self )
		local Bottom = self.buttonFrame.bottomButton;
		if ( self:AtBottom() ) then
			Bottom:Hide();
		else
			Bottom:Show();
		end
	end
	--- Scrolls to the bottom of the chat frame.
	local function BottomOnClick ( self )
		PlaySound( "igChatScrollDown" );
		return self:GetParent():ScrollToBottom();
	end
	--- Hides the bottom button if at the bottom already.
	local function BottomOnUpdate ( self )
		if ( self:GetParent():AtBottom() ) then
			self:Hide();
		end
	end
	--- Modifies this chat frame.
	function me.RegisterFrame ( Frame )
		Frame:SetClampRectInsets( 0, 0, 0, 0 );
		Frame:SetMaxResize( 0, 0 ); -- No limit
		Frame:SetMinResize( 200, 120 );
		Frame:SetFading( false );
		Frame:SetScript( "OnMessageScrollChanged", OnMessageScrollChanged );
		if ( not PreserveMaxLines ) then -- Keep early messages in window if shift is held
			Frame:SetMaxLines( me.MaxLines );
		end
		if ( GetCVarBool( "chatMouseScroll" ) ) then
			Frame:SetScript( "OnMouseWheel", FloatingChatFrame_OnMouseScroll );
		end
		_G[ Frame:GetName().."Tab" ]:SetHitRectInsets( 4, 4, 12, 0 );

		Frame.buttonFrame:Hide();
		Frame.buttonFrame:SetScript( "OnShow", Frame.buttonFrame.Hide );
		-- Scroll-to-bottom button
		local Bottom = Frame.buttonFrame.bottomButton;
		Bottom:SetParent( Frame );
		Bottom:Hide();
		Bottom:SetPoint( "TOPLEFT", Frame, "BOTTOMLEFT", -2, 2 );
		Bottom:SetPoint( "RIGHT", 2, 0 );
		Bottom:SetHeight( 8 );
		Bottom:SetScript( "OnClick", BottomOnClick );
		Bottom:SetScript( "OnUpdate", BottomOnUpdate );
		Bottom:SetNormalTexture( nil );
		Bottom:SetPushedTexture( nil );
		Bottom:SetDisabledTexture( nil );
		Bottom:GetHighlightTexture():SetAlpha( 0.5 );
		local Texture = Bottom:CreateTexture( nil, "BACKGROUND" );
		Texture:SetAllPoints();
		local R, G, B = unpack( _Underscore.Colors.Foreground );
		Texture:SetTexture( R, G, B, 0.25 );
		Texture:SetGradientAlpha( "VERTICAL", 1, 1, 1, 1, 1, 1, 1, 0 );
		Texture:SetBlendMode( "ADD" );
		local Flash = _G[ Bottom:GetName().."Flash" ];
		Flash:SetTexture( R, G, B, 0.25 );
		Flash:SetGradientAlpha( "VERTICAL", 1, 1, 1, 1, 1, 1, 1, 0 );

		AddMessageBackups[ Frame ] = Frame.AddMessage;
		Frame.AddMessage = AddMessage;
	end
end


do
	local IsCameraLookActive, IsMouseLookActive = false, false;
	--- Synchronizes chat scrolling with camera controls.
	local function UpdateScrolling ()
		if ( GetCVarBool( "chatMouseScroll" ) ) then
			local Enable = not ( IsCameraLookActive or IsMouseLookActive );
			for _, Name in ipairs( CHAT_FRAMES ) do
				_G[ Name ]:EnableMouseWheel( Enable );
			end
		end
	end
	--- Disables scrolling chat while moving the camera.
	function me.CameraMoveStart ()
		IsCameraLookActive = true;
		UpdateScrolling();
	end
	--- Re-enables scrolling chat after moving the camera.
	function me.CameraMoveStop ()
		IsCameraLookActive = false;
		UpdateScrolling();
	end
	local IsMouselooking = IsMouselooking;
	--- Disables scrolling chat while mouselooking.
	function me.Frame:OnUpdate ()
		local NewValue = IsMouselooking();
		if ( IsMouseLookActive ~= NewValue ) then
			IsMouseLookActive = NewValue;
			UpdateScrolling();
		end
	end
	me.Frame.VARIABLES_LOADED = UpdateScrolling;
end
--- Allows modifiers to scroll by page or to top/bottom.
function me:OnMouseWheel ( Delta )
	local Up = Delta > 0;
	if ( IsModifiedClick( "_UNDERSCORE_CHAT_SCROLLPAGE" ) ) then
		return self[ Up and "PageUp" or "PageDown" ]( self );
	elseif ( IsModifiedClick( "_UNDERSCORE_CHAT_SCROLLALL" ) ) then
		return self[ Up and "ScrollToTop" or "ScrollToBottom" ]( self );
	else
		return self[ Up and "ScrollUp" or "ScrollDown" ]( self );
	end
end


do
	local date = date;
	--- Adds a timestamp to Text if it doesn't already have one.
	function me.FilterTimestamp ( Text )
		if ( not Text:match( me.L.TIMESTAMP_PATTERN ) ) then
			-- Avoid putting a full time string into the Lua string table
			return me.L.TIMESTAMP_FORMAT:format( date( "%H" ), date( "%M" ), date( "%S" ), Text );
		end
	end
end




me.RegisterFilter( me.FilterTimestamp );
for _, Name in ipairs( CHAT_FRAMES ) do
	me.RegisterFrame( _G[ Name ] );
end
--- Hooks newly created temporary chat frames.
setmetatable( CHAT_FRAMES, { __newindex = function ( self, Index, Name )
	if ( Name ) then
		return me.RegisterFrame( _G[ Name ] );
	end
end; } );
if ( PreserveMaxLines ) then
	local Color = RED_FONT_COLOR;
	DEFAULT_CHAT_FRAME:AddMessage( me.L.MAXLINES_PRESERVED, Color.r, Color.g, Color.b );
end

FriendsMicroButton:Hide();
FriendsMicroButton:SetScript( "OnShow", FriendsMicroButton.Hide );
ChatFrameMenuButton:Hide();
ChatFrameMenuButton:SetScript( "OnShow", ChatFrameMenuButton.Hide );

me.Frame:SetScript( "OnUpdate", me.Frame.OnUpdate );
me.Frame:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
me.Frame:RegisterEvent( "VARIABLES_LOADED" );
hooksecurefunc( "CameraOrSelectOrMoveStart", me.CameraMoveStart );
hooksecurefunc( "CameraOrSelectOrMoveStop", me.CameraMoveStop );
FloatingChatFrame_OnMouseScroll = me.OnMouseWheel;


--- Adds NewSize to font size menus.
local function AddFontHeight ( NewSize )
	for Index, Size in ipairs( CHAT_FONT_HEIGHTS ) do
		if ( Size >= NewSize ) then
			if ( Size ~= NewSize ) then
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