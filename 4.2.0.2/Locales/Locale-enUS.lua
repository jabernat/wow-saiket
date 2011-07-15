--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


-- See http://wow.curseforge.com/addons/corpse/localization/enUS/
select( 2, ... ).L = setmetatable( {
	CORPSE_PATTERN = "^Corpse of ([^%s%p%d%c]+)$",
	ENEMY_OFFLINE_PATTERN = "^Cannot find player '([^%s%p%d%c]+)'%.$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+) added to friends%.$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+) removed from friends list%.$",

	-- Phrases localized by default UI
	ENEMY_ONLINE = ERR_PLAYER_WRONG_FACTION;
	FRIEND_IS_ENEMY = ERR_FRIEND_WRONG_FACTION;
	LEVEL_CLASS_PATTERN = FRIENDS_LEVEL_TEMPLATE;
	OFFLINE = PLAYER_OFFLINE;
	ONLINE = GUILD_ONLINE_LABEL;
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );