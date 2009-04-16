--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-esES.lua - Localized string constants (es-ES/es-MX).        *
  ****************************************************************************]]


if ( GetLocale() == "esES" or GetLocale() == "esMX" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^Cadáver de ([^ ]+)$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) añadido como amigo%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) eliminado de la lista de amigos%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^No se encuentra al jugador '([^%s%p%d%c]+)'%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
