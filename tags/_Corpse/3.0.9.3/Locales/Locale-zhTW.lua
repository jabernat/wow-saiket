--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhTW.lua - Localized string constants (zhTW) by Sparanoid.  *
  ****************************************************************************]]


if ( GetLocale() == "zhTW" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)的屍體$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) 已被添加至好友名單%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) 已從好友名單中移除%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^找不到名為 '([^%s%p%d%c]+)' 的玩家%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
