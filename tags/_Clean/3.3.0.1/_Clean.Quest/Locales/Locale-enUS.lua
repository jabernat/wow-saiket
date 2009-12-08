--[[****************************************************************************
  * _Clean.Quest by Saiket                                                     *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Meta = getmetatable( _CleanLocalization );
	_CleanLocalization.Quest = setmetatable( {
		TITLE_FORMAT = "[%d%s] %s"; -- Level, QuestTag, Title

		DAILY_PATTERN = "^Daily (.*)$"; -- DAILY_QUEST_TAG_TEMPLATE
		DAILY_FORMAT = "%s|cff71d5ff\226\151\138|r";

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
			[ -1 ] = RED_FONT_COLOR_CODE.."("..FAILED..")|r";
			[ 1 ] = GREEN_FONT_COLOR_CODE.."("..COMPLETE..")|r";
		};
	}, Meta );
end
