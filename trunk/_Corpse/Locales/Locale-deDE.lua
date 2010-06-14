--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-deDE.lua - Localized string constants (de-DE).              *
  ****************************************************************************]]


if ( GetLocale() ~= "deDE" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/deDE/
_CorpseLocalization = setmetatable( {
	CORPSE_PATTERN = "^Leichnam von ([^ ]+)$",
	ENEMY_OFFLINE_PATTERN = "^Spieler '([^%s%p%d%c]+)' ist nicht auffindbar%.$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) zu Freundesliste hinzugefügt%.$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) von Freundesliste entfernt%.$",
}, { __index = _CorpseLocalization; } );