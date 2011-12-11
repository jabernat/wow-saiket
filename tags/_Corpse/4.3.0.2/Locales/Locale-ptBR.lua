--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-ptBR.lua - Localized string constants (pt-BR/pt-PT).        *
  ****************************************************************************]]


if ( GetLocale() ~= "ptBR" and GetLocale() ~= "ptPT" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/ptBR/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^Cadáver de ([^%s%p%d%c]+)$",
	ENEMY_OFFLINE_PATTERN = "^Não foi possível encontrar o jogador '([^%s%p%d%c]+)'%.$",
	FRIEND_ADDED_PATTERN = "^Personagem ([^%s%p%d%c]+) adicionado à lista de amigos%.$",
	FRIEND_REMOVED_PATTERN = "^Personagem ([^%s%p%d%c]+) removido da lista de amigos%.$",
}, { __index = _Corpse.L; } );