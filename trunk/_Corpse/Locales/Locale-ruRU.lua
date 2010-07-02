--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-ruRU.lua - Localized string constants (ru-RU).              *
  ****************************************************************************]]


if ( GetLocale() ~= "ruRU" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/ruRU/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^Труп ([^%s%p%d%c]+)$",
	ENEMY_OFFLINE_PATTERN = "^Игрок с именем \"([^%s%p%d%c]+)\" не найден%.$",
	FRIEND_ADDED_PATTERN = "^Вы добавили |3%-3%(([^%s%p%d%c]+)%) в список друзей%.$",
	FRIEND_REMOVED_PATTERN = "^Вы удалили |3%-3%(([^%s%p%d%c]+)%) из списка друзей%.$",
}, { __index = _Corpse.L; } );