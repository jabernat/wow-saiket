--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-zhTW.lua - Localized string constants (zhTW).               *
  ****************************************************************************]]


if ( GetLocale() ~= "zhTW" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/zhTW/
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^([^%s%p%d%c]+)的屍體$",
	ENEMY_OFFLINE_PATTERN = "^無法找到「([^%s%p%d%c]+)」$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+)已被加入好友名單$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+)已從好友名單中移除。$",
}, { __index = _Corpse.L; } );