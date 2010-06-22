--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-ruRU.lua - Localized string constants (ru-RU).              *
  ****************************************************************************]]


if ( GetLocale() ~= "ruRU" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/ruRU/
_CorpseLocalization = setmetatable( {
	CORPSE_PATTERN = "^Труп |3%-1%(([^ ]+)%)$", -- Needs review
	ENEMY_OFFLINE_PATTERN = "^Игрок с именем \"([^%s%p%d%c]+)\" не найден%.$", -- Needs review
	FRIEND_ADDED_PATTERN = "^Вы добавили |3%-3%(([^%s%p%d%c]+)%) в список друзей%.$", -- Needs review
	FRIEND_REMOVED_PATTERN = "^Вы удалили |3%-3%(([^%s%p%d%c]+)%) из списка друзей%.$", -- Needs review
}, { __index = _CorpseLocalization; } );