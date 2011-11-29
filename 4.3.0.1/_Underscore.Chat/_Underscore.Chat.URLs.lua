--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.URLs.lua - Makes chat URLs into clickable links.          *
  ****************************************************************************]]


local Chat = select( 2, ... );
local NS = {};
Chat.URLs = NS;
local L = Chat.L;


NS.Formats = {
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
	[[ ?<(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:?%d*)> ?]],
};




do
	--- @return Found URL formatted as a hyperlink for gsub.
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
	local ipairs = ipairs;
	--- @return Text with all URLs converted to hyperlinks.
	function NS.Filter ( Text )
		Text = " "..Text; -- Allows links at the start to be recognized
		for _, Format in ipairs( NS.Formats ) do
			if ( Text:match( Format ) ) then
				Text = Text:gsub( Format, GsubReplace );
			end
		end
		return Text:sub( 2 ); -- Remove the added space
	end
end
--- Formats URLs as links in standard chat events.
function NS:MessageEventHandler ( Event, Message, ... )
	local NewMessage = NS.Filter( Message );
	if ( NewMessage ~= Message ) then
		return nil, NewMessage, ...;
	end
end


do
	local Backup = SetItemRef;
	--- Handles clicking and re-linking URL hyperlinks.
	function NS.SetItemRef ( Link, Text, ... )
		if ( Link:sub( 1, 4 ) ~= "url:" ) then
			return Backup( Link, Text, ... );
		end
		if ( IsModifiedClick( "CHATLINK" ) ) then
			ChatEdit_InsertLink( Link:sub( 5 ) );
		end
	end
end




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
	ChatFrame_AddMessageEventFilter( Event, NS.MessageEventHandler );
end
SetItemRef = NS.SetItemRef;