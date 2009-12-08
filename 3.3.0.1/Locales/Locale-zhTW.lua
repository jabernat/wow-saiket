--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhTW.lua - Localized string constants (zhTW) by Sparanoid.  *
  ****************************************************************************]]


if ( GetLocale() == "zhTW" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)的屍體$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+)已被加入好友名單$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+)已被從好友名單中刪除$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^無法找到「([^%s%p%d%c]+)」$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
