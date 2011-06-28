--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.AddOnChat.lua - Adds hidden addon communication to chat windows.      *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local me = CreateFrame( "Frame", nil, _Dev );
_Dev.AddOnChat = me;

me.ListenerCount = 0; -- Number of chat types registered across all chat frames
local ChatFrames = {};
me.ChatFrames = ChatFrames;




--[[****************************************************************************
  * Function: _Dev.AddOnChat.EnableChatType                                    *
  * Description: Enables or disables a chat type for the given chat window.    *
  ****************************************************************************]]
function me.EnableChatType ( ChatFrame, Type, Enable )
	if ( not ChatFrames[ ChatFrame ] ) then
		if ( not Enable ) then
			return;
		end
		ChatFrames[ ChatFrame ] = { n = 0 };
	end
	local TypeList = ChatFrames[ ChatFrame ];
	local TypeCount = TypeList.n;

	local Count = me.ListenerCount;
	if ( Enable ) then
		if ( not TypeList[ Type ] ) then
			if ( Count == 0 ) then
				me:RegisterEvent( "CHAT_MSG_ADDON" );
			end
			me.ListenerCount = Count + 1;
			TypeList[ Type ] = true;
			TypeList.n = TypeCount + 1;
		end

	elseif ( TypeList[ Type ] ) then
		if ( Count == 1 ) then
			me:UnregisterEvent( "CHAT_MSG_ADDON" );
		end
		me.ListenerCount = Count - 1;
		TypeList[ Type ] = nil;
		if ( TypeCount == 1 ) then -- About to remove last chat type
			ChatFrames[ ChatFrame ] = nil;
		else
			TypeList.n = TypeCount - 1;
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.AddOnChat.AddMessage                                        *
  * Description: Adds an addon chat message to all registered frames.          *
  ****************************************************************************]]
do
	local EscapeString = _Dev.Dump.EscapeString;
	local Print, tostring = _Dev.Print, tostring;
	function me.AddMessage ( Prefix, Message, Type, Sender )
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
  * Function: _Dev.AddOnChat:OnEvent                                           *
  ****************************************************************************]]
function me:OnEvent ( Event, ... )
	me.AddMessage( ... );
end
--[[****************************************************************************
  * Function: _Dev.AddOnChat.SendAddonMessage                                  *
  ****************************************************************************]]
do
	local strupper = strupper;
	function me.SendAddonMessage ( Prefix, Message, Type, Target )
		if ( me:IsEventRegistered( "CHAT_MSG_ADDON" ) and Type:upper() == "WHISPER" ) then
			me.AddMessage( Prefix, Message, "WHISPER_INFORM", Target:lower():gsub( "^%a", strupper ) );
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.AddOnChat:DropDownOnSelect                                  *
  * Description: Enables or disables chat types when clicked in the drop down. *
  ****************************************************************************]]
function me:DropDownOnSelect ( Type, _, Checked )
	me.EnableChatType( FCF_GetCurrentChatFrame(), Type, not not Checked );
end
--[[****************************************************************************
  * Function: _Dev.AddOnChat:DropDownInitialize                                *
  * Description: Hooks setup routines for chat frame drop down menus to add    *
  *   addon chat message options.                                              *
  ****************************************************************************]]
do
	local function AddChatTypeButton ( Info, Type )
		local Color = ChatTypeInfo[ Type ];
		local TypeList = ChatFrames[ FCF_GetCurrentChatFrame() ];

		Info.colorCode = ( "|cff%02x%02x%02x" ):format( Color.r * 255 + 0.5, Color.g * 255 + 0.5, Color.b * 255 + 0.5 );
		Info.text = L.ADDONCHAT_TYPES[ Type ];
		Info.arg1 = Type;
		Info.checked = ( TypeList and TypeList[ Type ] ) and 1 or nil;
		UIDropDownMenu_AddButton( Info, 2 );
	end
	function me:DropDownInitialize ( Level )
		local Info = UIDropDownMenu_CreateInfo();
		if ( Level == 1 ) then
			-- Spacer
			Info.disabled = true;
			Info.notCheckable = true;
			UIDropDownMenu_AddButton( Info );

			Info.text = L.ADDONCHAT_MESSAGES;
			Info.hasArrow = true;
			Info.disabled = nil;
			UIDropDownMenu_AddButton( Info );
		elseif ( Level == 2 and UIDROPDOWNMENU_MENU_VALUE == L.ADDONCHAT_MESSAGES ) then -- Addon Chat sub-menu
			Info.func = me.DropDownOnSelect;
			Info.isNotRadio = true;
			Info.keepShownOnClick = true;

			AddChatTypeButton( Info, "GUILD" );
			AddChatTypeButton( Info, "OFFICER" );
			AddChatTypeButton( Info, "RAID" );
			AddChatTypeButton( Info, "PARTY" );
			AddChatTypeButton( Info, "BATTLEGROUND" );
			AddChatTypeButton( Info, "WHISPER" );
		end
	end
end




me:SetScript( "OnEvent", me.OnEvent );
hooksecurefunc( "SendAddonMessage", me.SendAddonMessage );

hooksecurefunc( "FCFOptionsDropDown_Initialize", me.DropDownInitialize );

-- Hook chat windows if not hooked already
for Index = 1, NUM_CHAT_WINDOWS do
	hooksecurefunc( _G[ "ChatFrame"..Index.."TabDropDown" ], "initialize", me.DropDownInitialize );
end