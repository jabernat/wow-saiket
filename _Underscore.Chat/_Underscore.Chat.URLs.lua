--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.URLs.lua - Makes chat URLs into clickable links.          *
  ****************************************************************************]]


local L = _UnderscoreLocalization.Chat;
local me = {};
_Underscore.Chat.URLs = me;


me.Formats = {
	-- Address with domain name
	[[ (%a[-_%w.]*%.%a%a+)(/[^][ <>"{}|\^~]*) ?]],
	[[ ?"(%a[-_%w.]*%.%a%a+)(/[^][ <>"{}|\^~]*)" ?]],
	[[ ?<(%a[-_%w.]*%.%a%a+)(/[^][ <>"{}|\^~]*)> ?]],
	[[ (%a[-_%w]*%.%a[-_%w]*%.%a%a+) ?]], -- Require a subdomain if path ommited
	[[ ?"(%a[-_%w]*%.%a[-_%w]*%.%a%a+)" ?]],
	[[ ?<(%a[-_%w]*%.%a[-_%w]*%.%a%a+)> ?]],

	-- Address with protocol
	[[ (%a+://)([^][ <>"{}|\^~]+) ?]],
	[[ ?"(%a+://)([^][ <>"{}|\^~]+)" ?]],
	[[ ?<(%a+://)([^][ <>"{}|\^~]+)> ?]],

	-- Email address
	[[ (%a[-_%w.]*@%a[-_%w.]*%.%a%a+) ?]],
	[[ ?"(%a[-_%w.]*@%a[-_%w.]*%.%a%a+)" ?]],
	[[ ?<(%a[-_%w.]*@%a[-_%w.]*%.%a%a+)> ?]],

	-- IP address with optional port
	[[ (%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:?%d*)(/[^][ <>"{}|\^~]*) ?]], -- Path
	[[ ?<(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:?%d*)(/[^][ <>"{}|\^~]*)> ?]],
	[[ (%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:?%d*) ?]], -- No path
	[[ ?<(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:?%d*)> ?]]
};




--[[****************************************************************************
  * Function: _Underscore.Chat.URLs.Filter                                     *
  * Description: Replace links in a chat message with formated versions.       *
  ****************************************************************************]]
do
	local ipairs = ipairs;
	local function GsubReplace ( Domain, Path )
		-- Note: Prevent elipses from matching the subdomain patterns
		if ( not Domain:find( "..", 1, true ) ) then
			if ( Path ) then
				return L.URLPATH_FORMAT:format( Domain, Path );
			else
				return L.URL_FORMAT:format( Domain );
			end
		end
	end
	function me.Filter ( Text )
		-- Ensure that links at the start of the message are recognized
		Text = " "..Text;

		for _, Format in ipairs( me.Formats ) do
			if ( Text:match( Format ) ) then
				Text = Text:gsub( Format, GsubReplace );
			end
		end

		return Text:sub( 2 ); -- Remove the added space
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.URLs:MessageEventHandler                        *
  * Description: Catches chat events to replace URLs.                          *
  ****************************************************************************]]
function me:MessageEventHandler ( Event, Message, ... )
	local NewMessage = me.Filter( Message );
	if ( NewMessage ~= Message ) then
		return nil, NewMessage, ...;
	end
end


--[[****************************************************************************
  * Function: _Underscore.Chat.URLs.SetItemRef                                 *
  * Description: Allows the UI to recognize "|Hurl:" as a hyperlink.           *
  ****************************************************************************]]
do
	local Backup = SetItemRef;
	function me.SetItemRef ( Link, Text, ... )
		if ( Link:sub( 1, 4 ) == "url:" ) then
			if ( IsModifiedClick( "CHATLINK" ) ) then
				Link = Link:sub( 5 );
				local EditBox = DEFAULT_CHAT_FRAME.editBox;
				if ( EditBox:IsShown() ) then
					EditBox:Insert( Link );
				else
					ChatFrame_OpenChat( Link );
				end
			end
		else
			return Backup( Link, Text, ... );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	local ChatTypes = {
		"CHAT_MSG_AFK",
		"CHAT_MSG_BATTLEGROUND",
		"CHAT_MSG_BATTLEGROUND_LEADER",
		"CHAT_MSG_CHANNEL",
		"CHAT_MSG_DND",
		"CHAT_MSG_EMOTE", -- Only for custom emotes
		"CHAT_MSG_GUILD",
		"CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY",
		"CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_RAID_WARNING",
		"CHAT_MSG_SAY",
		"CHAT_MSG_WHISPER",
		"CHAT_MSG_WHISPER_INFORM", -- For when you send a whisper
		"CHAT_MSG_YELL",
		"SYSMSG",
		"CHAT_MSG_SYSTEM",
	};

	for _, Event in ipairs( ChatTypes ) do
		ChatFrame_AddMessageEventFilter( Event, me.MessageEventHandler );
	end
	SetItemRef = me.SetItemRef;
end
