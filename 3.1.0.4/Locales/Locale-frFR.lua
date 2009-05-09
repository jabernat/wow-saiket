--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-frFR.lua - Localized string constants (fr-FR).              *
  ****************************************************************************]]


if ( GetLocale() == "frFR" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^Cadavre |2 ([^ ]+)$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) fait maintenant partie de vos amis%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) ne fait plus partie de vos amis%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^Impossible de trouver le personnage '([^%s%p%d%c]+)'%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
