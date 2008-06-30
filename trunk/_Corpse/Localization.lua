--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	_CorpseLocalization = setmetatable(
		{
			CORPSE_PATTERN = "^Corpse of ([^ ]+)$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP
			CORPSE_FORMAT = CORPSE_TOOLTIP;
			SERVER_DELIMITER = "-";

			LEVEL_CLASS_PATTERN = FRIENDS_LEVEL_TEMPLATE;
			ONLINE = GUILD_ONLINE_LABEL;
			OFFLINE = PLAYER_OFFLINE;

			FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) added to friends%.$"; -- Based on ERR_FRIEND_ADDED_S
			FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) removed from friends list%.$"; -- Based on ERR_FRIEND_REMOVED_S
			FRIEND_IS_ENEMY = ERR_FRIEND_WRONG_FACTION;

			ENEMY_ONLINE = ERR_PLAYER_WRONG_FACTION;
			ENEMY_OFFLINE_PATTERN = "^Cannot find player '([^%s%p%d%c]+)'%.$"; -- Based on ERR_BAD_PLAYER_NAME_S

			AFK = CHAT_FLAG_AFK;
			DND = CHAT_FLAG_DND;

			ERR_FRIENDS_MAX = NORMAL_FONT_COLOR_CODE.."_|cffCCCC88Corpse|r failed: Friends list full!";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );
end
