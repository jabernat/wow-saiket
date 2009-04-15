--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-ruRU.lua - Localized string constants (ru-RU).              *
  ****************************************************************************]]


if ( GetLocale() == "ruRU" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^Труп |3%-1%(([^ ]+)%)$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^Вы добавили |3%-3%(([^%s%p%d%c]+)%) в список друзей%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^Вы удалили |3%-3%(([^%s%p%d%c]+)%) из списка друзей%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^Игрок с именем \"([^%s%p%d%c]+)\" не найден%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
