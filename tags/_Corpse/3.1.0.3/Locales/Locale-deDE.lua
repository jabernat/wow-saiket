--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-deDE.lua - Localized string constants (de-DE).              *
  ****************************************************************************]]


if ( GetLocale() == "deDE" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^Leichnam von ([^ ]+)$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) zu Freundesliste hinzugefügt%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) von Freundesliste entfernt%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^Spieler '([^%s%p%d%c]+)' ist nicht auffindbar%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
