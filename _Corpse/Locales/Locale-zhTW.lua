--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhTW.lua - Localized string constants (zhTW) by Sparanoid.  *
  ****************************************************************************]]


if ( GetLocale() == "zhTW" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)的屍體$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP
		CORPSE_FORMAT = CORPSE_TOOLTIP;
		SERVER_DELIMITER = "-";

		LEVEL_CLASS_PATTERN = FRIENDS_LEVEL_TEMPLATE;
		ONLINE = GUILD_ONLINE_LABEL;
		OFFLINE = PLAYER_OFFLINE;

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) 已被添加至好友名單%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) 已從好友名單中移除%.$"; -- Based on ERR_FRIEND_REMOVED_S
		FRIEND_IS_ENEMY = ERR_FRIEND_WRONG_FACTION;

		ENEMY_ONLINE = ERR_PLAYER_WRONG_FACTION;
		ENEMY_OFFLINE_PATTERN = "^找不到名為 '([^%s%p%d%c]+)' 的玩家%.$"; -- Based on ERR_BAD_PLAYER_NAME_S

		AFK = CHAT_FLAG_AFK;
		DND = CHAT_FLAG_DND;
	}, { __index = _CorpseLocalization; } );
end
