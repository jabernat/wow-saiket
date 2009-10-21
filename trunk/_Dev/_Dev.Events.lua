--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Events.lua - Tools to view API events.                                *
  *                                                                            *
  * + Adds ability to pulse frames as they receive events.                     *
  * + Adds option to all all chat windows for showing addon chat messages.     *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local me = {};
_Dev.Events = me;

local Pulse = CreateFrame( "Frame", nil, _Dev );
me.Pulse = Pulse;
local ListenersFree = {};
Pulse.ListenersFree = ListenersFree;
local ListenersUsed = {};
Pulse.ListenersUsed = ListenersUsed;
Pulse.ColorIndex = 0;
Pulse.Rate = 1 / 3; -- Seconds to keep pulse visible

local AddOnChat = CreateFrame( "Frame", nil, _Dev );
me.AddOnChat = AddOnChat;
AddOnChat.ListenerCount = 0; -- Number of chat types registered across all chat frames
local ChatFrames = {};
AddOnChat.ChatFrames = ChatFrames;




--------------------------------------------------------------------------------
-- _Dev.Events.Pulse
--------------------

--[[****************************************************************************
  * Function: _Dev.Events.Pulse.RemoveAll                                      *
  * Description: Removes all listeners and returns the number removed.         *
  ****************************************************************************]]
function Pulse.RemoveAll ()
	local Count = 0;
	for Event in pairs( ListenersUsed ) do
		Pulse.Remove( Event );
		Count = Count + 1;
	end
	return Count;
end
--[[****************************************************************************
  * Function: _Dev.Events.Pulse.Remove                                         *
  * Description: Attempts to remove a listener and returns true if successful. *
  ****************************************************************************]]
function Pulse.Remove ( Event )
	local ListenerFrame = ListenersUsed[ Event ];
	if ( ListenerFrame ) then
		ListenerFrame:UnregisterEvent( Event );
		ListenerFrame:Hide();
		_Dev.Outline.RemoveAll( ListenerFrame );
		ListenersUsed[ Event ] = nil;
		ListenersFree[ ListenerFrame ] = true;

		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Events.Pulse.Add                                            *
  * Description: Adds a listener for a given event if none already exists, and *
  *   returns true if successful.                                              *
  ****************************************************************************]]
function Pulse.Add ( Event )
	if ( not ListenersUsed[ Event ] ) then
		local NewListener = next( ListenersFree );
		if ( NewListener ) then
			ListenersFree[ NewListener ] = nil;
		else
			NewListener = CreateFrame( "Frame", nil, Pulse );
			NewListener:SetScript( "OnEvent", Pulse.ListenerOnEvent );
			NewListener:SetScript( "OnUpdate", Pulse.ListenerOnUpdate );
	
			-- Implement outline structures
			NewListener.TemplateName = "_DevEventsPulseTemplate";
			NewListener.UnusedOutlines = {};
			NewListener.Targets = {};

			Pulse.ColorIndex = mod( Pulse.ColorIndex, #_Dev.Outline.Colors ) + 1;
			NewListener.Color = _Dev.Outline.Colors[ Pulse.ColorIndex ];
		end

		Pulse.ListenersUsed[ Event ] = NewListener;
		NewListener:RegisterEvent( Event );

		return true;
	end
end

--[[****************************************************************************
  * Function: _Dev.Events.Pulse.GetListener                                    *
  * Description: Either gets a free listener frame or creates a new one.       *
  ****************************************************************************]]
function Pulse.GetListener ( Event )
	local NewListener = next( ListenersFree );
	if ( NewListener ) then
		ListenersFree[ NewListener ] = nil;
	else
		NewListener = CreateFrame( "Frame", nil, Pulse );
		NewListener:SetScript( "OnEvent", Pulse.ListenerOnEvent );
		NewListener:SetScript( "OnUpdate", Pulse.ListenerOnUpdate );

		-- Implement outline structures
		NewListener.TemplateName = "_DevBorderTemplate";
		NewListener.UnusedOutlines = {};
		NewListener.Targets = {};

		Pulse.ColorIndex = mod( Pulse.ColorIndex, #_Dev.Outline.Colors ) + 1;
		NewListener.Color = _Dev.Outline.Colors[ Pulse.ColorIndex ];
	end

	Pulse.ListenersUsed[ Event ] = NewListener;
	return NewListener;
end

--[[****************************************************************************
  * Function: _Dev.Events.Pulse:ListenerOutlineFrames                          *
  * Description: Outlines frames from vararg argument.                         *
  ****************************************************************************]]
do
	local select = select;
	local Frame;
	function Pulse:ListenerOutlineFrames ( ... )
		for Index = 1, select( "#", ... ) do
			Frame = select( Index, ... );
			if ( Frame:IsVisible() and Frame:GetWidth() ~= 0 and Frame:GetHeight() ~= 0 and Frame:GetLeft() and Frame:GetBottom() ) then
				_Dev.Outline.Add( self, Frame );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Events.Pulse:ListenerOnEvent                                *
  * Description: Pulses all outlines for the listener.                         *
  ****************************************************************************]]
function Pulse:ListenerOnEvent ( Event )
	_Dev.Outline.RemoveAll( self );
	Pulse.ListenerOutlineFrames( self, GetFramesRegisteredForEvent( Event ) );
	self:SetAlpha( 1 );
	self:Show();
end
--[[****************************************************************************
  * Function: _Dev.Events.Pulse:ListenerOnUpdate                               *
  * Description: Fades out the listener and eventually hides it.               *
  ****************************************************************************]]
function Pulse:ListenerOnUpdate ( Elapsed )
	local Alpha = self:GetAlpha() - Elapsed / Pulse.Rate;
	if ( Alpha <= 0 ) then
		self:Hide();
	else
		self:SetAlpha( Alpha );
	end
end
--[[****************************************************************************
  * Function: _Dev.Events.Pulse:OutlineOnLoad                                  *
  * Description: Sets the correct colors of an outline pulse.                  *
  ****************************************************************************]]
do
	local select = select;
	local function ColorRegions ( Color, ... )
		for Index = 1, select( "#", ... ) do
			select( Index, ... ):SetVertexColor( Color.r, Color.g, Color.b );
		end
	end
	function Pulse:OutlineOnLoad ()
		ColorRegions( self:GetParent().Color, self:GetRegions() );
	end
end




--------------------------------------------------------------------------------
-- _Dev.Events.AddOnChat
------------------------

--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.EnableChatType                             *
  * Description: Enables or disables a chat type for the given chat window.    *
  ****************************************************************************]]
function AddOnChat.EnableChatType ( ChatFrame, Type, Enable )
	if ( not ChatFrames[ ChatFrame ] ) then
		if ( not Enable ) then
			return;
		end
		ChatFrames[ ChatFrame ] = { n = 0 };
	end
	local TypeList = ChatFrames[ ChatFrame ];
	local TypeCount = TypeList.n;

	local Count = AddOnChat.ListenerCount;
	if ( Enable ) then
		if ( not TypeList[ Type ] ) then
			if ( Count == 0 ) then
				AddOnChat:RegisterEvent( "CHAT_MSG_ADDON" );
			end
			AddOnChat.ListenerCount = Count + 1;
			TypeList[ Type ] = true;
			TypeList.n = TypeCount + 1;
		end

	elseif ( TypeList[ Type ] ) then
		if ( Count == 1 ) then
			AddOnChat:UnregisterEvent( "CHAT_MSG_ADDON" );
		end
		AddOnChat.ListenerCount = Count - 1;
		TypeList[ Type ] = nil;
		if ( TypeCount == 1 ) then -- About to remove last chat type
			ChatFrames[ ChatFrame ] = nil;
		else
			TypeList.n = TypeCount - 1;
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.AddMessage                                 *
  * Description: Adds an addon chat message to all registered frames.          *
  ****************************************************************************]]
do
	local EscapeString = _Dev.Dump.EscapeString;
	local Print, tostring = _Dev.Print, tostring;
	function AddOnChat.AddMessage ( Prefix, Message, Type, Sender )
		local Color = ChatTypeInfo[ Type ];
		local Message = L.ADDONCHAT_MSG_FORMAT:format( L.ADDONCHAT_TYPES[ Type ],
			Type == "WHISPER_INFORM" and L.ADDONCHAT_OUTBOUND or "",
			Sender, EscapeString( tostring( Prefix ) ), EscapeString( tostring( Message ) ) );
		if ( Type == "WHISPER_INFORM" ) then
			Type = "WHISPER";
		end
	
		for ChatFrame, TypeList in pairs( ChatFrames ) do
			if ( TypeList[ Type ] ) then
				Print( Message, ChatFrame, Color );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat:OnEvent                                    *
  ****************************************************************************]]
do
	local AddMessage = AddOnChat.AddMessage;
	function AddOnChat:OnEvent ( Event, ... )
		AddMessage( ... );
	end
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.SendAddonMessage                           *
  ****************************************************************************]]
do
	local AddMessage = AddOnChat.AddMessage;
	local strupper = strupper;
	function AddOnChat.SendAddonMessage ( Prefix, Message, Type, Target )
		if ( Type:upper() == "WHISPER" and AddOnChat:IsEventRegistered( "CHAT_MSG_ADDON" ) ) then
			AddMessage( Prefix, Message, "WHISPER_INFORM", Target:lower():gsub( "^%a", strupper ) );
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat:DropDownOnSelect                           *
  * Description: Enables or disables chat types when clicked in the drop down. *
  ****************************************************************************]]
function AddOnChat:DropDownOnSelect ( Type, _, Checked )
	AddOnChat.EnableChatType( FCF_GetCurrentChatFrame(), Type, not not Checked );
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.DropDownAddChatType                        *
  * Description: Hooks setup routines for chat frame drop down menus to add    *
  *   addon chat message options.                                              *
  ****************************************************************************]]
function AddOnChat.DropDownAddChatType ( Type, Level )
	local Info = UIDropDownMenu_CreateInfo(); -- Common blank table
	local Color = ChatTypeInfo[ Type ];
	local TypeList = ChatFrames[ FCF_GetCurrentChatFrame() ];

	Info.func = AddOnChat.DropDownOnSelect;
	Info.keepShownOnClick = 1;
	Info.text = ( "|cff%02x%02x%02x" ):format( Color.r * 255 + 0.5, Color.g * 255 + 0.5, Color.b * 255 + 0.5 )..L.ADDONCHAT_TYPES[ Type ];
	Info.arg1 = Type;
	Info.checked = ( TypeList and TypeList[ Type ] ) and 1 or nil;
	UIDropDownMenu_AddButton( Info, Level );
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat:DropDownInitialize                         *
  * Description: Hooks setup routines for chat frame drop down menus to add    *
  *   addon chat message options.                                              *
  ****************************************************************************]]
do
	local DropDownAddChatType = AddOnChat.DropDownAddChatType;
	function AddOnChat:DropDownInitialize ( Level )
		if ( Level == 1 ) then
			local Info = UIDropDownMenu_CreateInfo(); -- Common blank table
			-- Spacer
			Info.disabled = 1;
			UIDropDownMenu_AddButton( Info );
	
			Info.text = L.ADDONCHAT_MESSAGES;
			Info.hasArrow = 1;
			Info.notCheckable = 1;
			Info.disabled = nil;
			UIDropDownMenu_AddButton( Info );
		elseif ( Level == 2 and UIDROPDOWNMENU_MENU_VALUE == L.ADDONCHAT_MESSAGES ) then -- Addon Chat sub-menu
			DropDownAddChatType( "GUILD", Level );
			DropDownAddChatType( "RAID", Level );
			DropDownAddChatType( "PARTY", Level );
			DropDownAddChatType( "BATTLEGROUND", Level );
			DropDownAddChatType( "WHISPER", Level );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	AddOnChat:SetScript( "OnEvent", AddOnChat.OnEvent );
	hooksecurefunc( "SendAddonMessage", AddOnChat.SendAddonMessage );

	hooksecurefunc( "FCFOptionsDropDown_Initialize", AddOnChat.DropDownInitialize );

	-- Hook chat windows if not hooked already
	for Index = 1, NUM_CHAT_WINDOWS do
		hooksecurefunc( _G[ "ChatFrame"..Index.."TabDropDown" ], "initialize",
			AddOnChat.DropDownInitialize );
	end
end
