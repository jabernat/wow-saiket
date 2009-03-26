--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhCN.lua - Localized string constants (zhCN) by Sparanoid.  *
  ****************************************************************************]]


if ( GetLocale() == "zhCN" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)的尸体$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP
		CORPSE_FORMAT = CORPSE_TOOLTIP;
		SERVER_DELIMITER = "-";

		LEVEL_CLASS_PATTERN = FRIENDS_LEVEL_TEMPLATE;
		ONLINE = GUILD_ONLINE_LABEL;
		OFFLINE = PLAYER_OFFLINE;

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) 已被添加到好友名单%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) 已从好友名单中移除%.$"; -- Based on ERR_FRIEND_REMOVED_S
		FRIEND_IS_ENEMY = ERR_FRIEND_WRONG_FACTION;

		ENEMY_ONLINE = ERR_PLAYER_WRONG_FACTION;
		ENEMY_OFFLINE_PATTERN = "^找不到名为 '([^%s%p%d%c]+)' 的玩家%.$"; -- Based on ERR_BAD_PLAYER_NAME_S

		AFK = CHAT_FLAG_AFK;
		DND = CHAT_FLAG_DND;
	}, { __index = _CorpseLocalization; } );
end
