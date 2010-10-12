--[[****************************************************************************
  * _Underscore.Quest by Saiket                                                *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local Meta = getmetatable( _Underscore.L );
select( 2, ... ).L = setmetatable( {
	TITLE_FORMAT = "[%d%s] %s"; -- Level, QuestTag, Title

	DAILY_PATTERN = "^Daily (.*)$"; -- DAILY_QUEST_TAG_TEMPLATE
	DAILY_FORMAT = "%s|cff71d5ff◊|r";

	Types = setmetatable( {
		[ ELITE ] = "+";
		[ LFG_TYPE_DUNGEON ] = "d"; -- Dungeon
		[ GROUP ] = "g";
		[ RAID ] = "r";
		[ RAID.." (10)" ] = "r10";
		[ RAID.." (25)" ] = "r25";
		[ PVP ] = "p";
		[ ITEM_HEROIC ] = "h"; -- Heroic
	}, Meta );
	Completed = {
		[ -1 ] = "|cffff2020(Failed)|r";
		[ 1 ] = "|cff20ff20(Complete)|r";
	};
}, Meta );