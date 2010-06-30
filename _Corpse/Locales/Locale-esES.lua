--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-esES.lua - Localized string constants (es-ES/es-MX).        *
  ****************************************************************************]]


if ( GetLocale() ~= "esES" and GetLocale() ~= "esMX" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/esES/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^Cadáver de ([^ ]+)$",
	ENEMY_OFFLINE_PATTERN = "^No se encuentra al jugador '([^%s%p%d%c]+)'%.$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) añadido como amigo%.$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) eliminado de la lista de amigos%.$",
}, { __index = _Corpse.L; } );