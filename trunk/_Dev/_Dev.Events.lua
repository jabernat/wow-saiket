--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Events.lua - Tools to view API events.                                *
  *                                                                            *
  * + Adds option to all all chat windows for showing addon chat messages.     *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local me = {
	AddOnChat = {
		ChatFrames = {};
		ListenerCount = 0; -- Number of chat types registered across all chat frames
	}; -- End _Dev.Events.AddOnChat
}; -- End _Dev.Events
_Dev.Events = me;
local AddOnChat = me.AddOnChat;
local ChatFrames = AddOnChat.ChatFrames;




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
				_Dev:RegisterEvent( "CHAT_MSG_ADDON" );
			end
			AddOnChat.ListenerCount = Count + 1;
			TypeList[ Type ] = true;
			TypeList.n = TypeCount + 1;
		end

	elseif ( TypeList[ Type ] ) then
		if ( Count == 1 ) then
			_Dev:UnregisterEvent( "CHAT_MSG_ADDON" );
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
	local Print = _Dev.Print;
	function AddOnChat.AddMessage ( Prefix, Message, Type, Sender )
		local Color = ChatTypeInfo[ Type ];
		local Message = L.ADDONCHAT_MSG_FORMAT:format( L.ADDONCHAT_TYPES[ Type ],
			Sender, Sender, EscapeString( Prefix ), EscapeString( Message ) );
	
		for ChatFrame, TypeList in pairs( ChatFrames ) do
			if ( TypeList[ Type ] ) then
				Print( Message, ChatFrame, Color );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Dev:CHAT_MSG_ADDON                                              *
  ****************************************************************************]]
do
	local AddMessage = AddOnChat.AddMessage;
	function _Dev:CHAT_MSG_ADDON ( Event, ... )
		AddMessage( ... );
	end
end


--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.DropDownButtonHandler                      *
  * Description: Enables or disables chat types when clicked in the drop down. *
  ****************************************************************************]]
function AddOnChat.DropDownButtonHandler ()
	AddOnChat.EnableChatType( FCF_GetCurrentChatFrame(), this.value, not not this.checked );
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.DropDownAddChatType                        *
  * Description: Hooks setup routines for chat frame drop down menus to add    *
  *   addon chat message options.                                              *
  ****************************************************************************]]
function AddOnChat.DropDownAddChatType ( Type )
	local Info = UIDropDownMenu_CreateInfo(); -- Common blank table
	local Color = ChatTypeInfo[ Type ];
	local TypeList = ChatFrames[ FCF_GetCurrentChatFrame() ];

	Info.func = AddOnChat.DropDownButtonHandler;
	Info.keepShownOnClick = 1;
	Info.text = L.ADDONCHAT_TYPES[ Type ];
	Info.value = Type;
	Info.checked = ( TypeList and TypeList[ Type ] ) and 1 or nil;
	Info.textR = Color.r;
	Info.textG = Color.g;
	Info.textB = Color.b;
	UIDropDownMenu_AddButton( Info, UIDROPDOWNMENU_MENU_LEVEL );
end
--[[****************************************************************************
  * Function: _Dev.Events.AddOnChat.DropDownInitialize                         *
  * Description: Hooks setup routines for chat frame drop down menus to add    *
  *   addon chat message options.                                              *
  ****************************************************************************]]
do
	local DropDownAddChatType = AddOnChat.DropDownAddChatType;
	function AddOnChat.DropDownInitialize ()
		if ( UIDROPDOWNMENU_MENU_LEVEL == 1 ) then
			local Info = UIDropDownMenu_CreateInfo(); -- Common blank table
			-- Spacer
			Info.disabled = 1;
			UIDropDownMenu_AddButton( Info );
	
			Info.text = L.ADDONCHAT_MESSAGES;
			Info.hasArrow = 1;
			Info.notCheckable = 1;
			Info.disabled = nil;
			UIDropDownMenu_AddButton( Info );
		elseif ( UIDROPDOWNMENU_MENU_LEVEL == 2
			and UIDROPDOWNMENU_MENU_VALUE == L.ADDONCHAT_MESSAGES
		) then -- Addon Chat sub-menu
			DropDownAddChatType( "GUILD" );
			DropDownAddChatType( "RAID" );
			DropDownAddChatType( "PARTY" );
			DropDownAddChatType( "BATTLEGROUND" );
			DropDownAddChatType( "WHISPER" );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( "FCFOptionsDropDown_Initialize", AddOnChat.DropDownInitialize );

	-- Hook chat windows if not hooked already
	for Index = 1, NUM_CHAT_WINDOWS do
		hooksecurefunc( _G[ "ChatFrame"..Index.."TabDropDown" ], "initialize",
			AddOnChat.DropDownInitialize );
	end
end
