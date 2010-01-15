--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	_UnderscoreLocalization.Chat = setmetatable( {
		TIMESTAMP_FORMAT = GRAY_FONT_COLOR_CODE.."[%02d:%02d:%02d]|r %s"; -- Hour, Minute, Second, Message
		TIMESTAMP_PATTERN = "^"..GRAY_FONT_COLOR_CODE.."%[%d%d:%d%d:%d%d%]|r ";

		URL_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%s|h<%1$s>|h|r ";
		URLPATH_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%s%s|h<%1$s%2$s>|h|r "; -- Domain, Path

		RAIDWARNING_FORMAT = "[|cff%02X%02X%02X%s|r]: %s"; -- R, G, B, Author, Message
	}, getmetatable( _UnderscoreLocalization ) );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Chat message formats
	CHAT_BATTLEGROUND_GET        = "|Hchannel:Battleground|h[B]|h %s: ";
	CHAT_BATTLEGROUND_LEADER_GET = [[|Hchannel:Battleground|h[B|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]];
	CHAT_GUILD_GET   = "|Hchannel:Guild|h[G]|h %s: ";
	CHAT_OFFICER_GET = "|Hchannel:Officer|h[O]|h %s: ";
	CHAT_PARTY_GET        = "|Hchannel:Party|h[P]|h %s: ";
	CHAT_PARTY_LEADER_GET = [[|Hchannel:Party|h[P|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]];
	CHAT_RAID_GET         = "|Hchannel:Raid|h[R]|h %s: ";
	CHAT_RAID_LEADER_GET  = [[|Hchannel:Raid|h[R|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]];
	CHAT_RAID_WARNING_GET = "|Hchannel:RaidWarning|h[R-WARN]|h %s: ";
	CHAT_SAY_GET = "|Hchannel:Say|h[S]|h %s: ";
	CHAT_WHISPER_GET = "[W] %s: ";
	CHAT_WHISPER_INFORM_GET = "[W]\194\187%s: ";
	CHAT_YELL_GET = "|Hchannel:Yell|h[Y]|h %s: ";

	CHAT_MONSTER_PARTY_GET   = CHAT_PARTY_GET;
	CHAT_MONSTER_SAY_GET     = CHAT_SAY_GET;
	CHAT_MONSTER_WHISPER_GET = CHAT_WHISPER_GET;
	CHAT_MONSTER_YELL_GET    = CHAT_YELL_GET;


	-- Player name chat links
	JOINED_PARTY = "|Hplayer:%1$s|h[%1$s]|h joins the party.";
	ERR_JOINED_GROUP_S = JOINED_PARTY;
	LEFT_PARTY = "|Hplayer:%1$s|h[%1$s]|h leaves the party.";
	ERR_LEFT_GROUP_S = LEFT_PARTY;
end
