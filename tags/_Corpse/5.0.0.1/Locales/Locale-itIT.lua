--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-itIT.lua - Localized string constants (it-IT).              *
  ****************************************************************************]]


if ( GetLocale() ~= "itIT" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/itIT/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^Corpo di ([^%s%p%d%c]+)$", -- Needs review
	ENEMY_OFFLINE_PATTERN = "^Impossibile trovare il giocatore '([^%s%p%d%c]+)'%.$", -- Needs review
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) è stato aggiunto agli amici%.$", -- Needs review
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) è state rimosso dagli amici%.$", -- Needs review
}, { __index = _Corpse.L; } );