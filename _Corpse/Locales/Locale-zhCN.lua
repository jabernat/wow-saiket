--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhCN.lua - Localized string constants (zhCN) by Sparanoid.  *
  ****************************************************************************]]


if ( GetLocale() == "zhCN" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)的尸体$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) 已被添加到好友名单%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) 已从好友名单中移除%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^找不到名为 '([^%s%p%d%c]+)' 的玩家%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
