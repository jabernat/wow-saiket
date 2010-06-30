--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-frFR.lua - Localized string constants (fr-FR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "frFR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/frFR/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^Cadavre |2 ([^ ]+)$",
	ENEMY_OFFLINE_PATTERN = "^Impossible de trouver le personnage '([^%s%p%d%c]+)'%.$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) fait maintenant partie de vos amis%.$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) ne fait plus partie de vos amis%.$",
}, { __index = _Corpse.L; } );