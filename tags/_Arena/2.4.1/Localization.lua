--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	_ArenaLocalization = setmetatable(
		{
			WINDOW_TITLE = "_|cffCCCC88Arena|r";

			UNKNOWNOBJECT = UNKNOWNOBJECT;
			ARENA_WARNING_15SEC = "Fifteen seconds until the Arena battle begins!";
			LONGSIGHT = "Longsight"; -- Name of spell:12883

			-- List
			LIST_CLASS_PATTERN = "%s%d"
				..GRAY_FONT_COLOR_CODE.."\195\151"..FONT_COLOR_CODE_CLOSE.."%s"; -- CountColor Count x Class
			LIST_SPEC_SEPARATOR = ",\n";
			LIST_SPEC_PATTERN = "(%s)";
			LIST_COUNT_PATTERN = "[%d]";

			-- Scan
			SCAN_CREATURETYPE_DEMON = "Demon";
			SCAN_CREATUREFAMILY_FELGUARD = "Felguard";
			SCAN_CREATURETYPE_BEAST = "Beast";
			SCAN_TOTEM_PATTERN1 = " Totem ?[IVX]*$"; -- Catches totem names with ranks
			SCAN_TOTEM_PATTERN2 = "^Totem ";

			-- Classes
			DRUID   = "Druid";
			HUNTER  = "Hunter";
			MAGE    = "Mage";
			PALADIN = "Paladin";
			PRIEST  = "Priest";
			ROGUE   = "Rogue";
			SHAMAN  = "Shaman";
			WARLOCK = "Warlock";
			WARRIOR = "Warrior";

			-- Buttons
			BUTTON_RESET = "R";
			BUTTON_RESET_TITLE = "Reset scan data";
			BUTTON_CAMERA_TITLE = "Toggle floating camera";
			-- Well names
			WELL_TITLE_FORMAT = "%s "..GRAY_FONT_COLOR_CODE.."(|cff%02x%02x%02x%s"..GRAY_FONT_COLOR_CODE..")"; -- Title [rgb](Class)
			WELL_REFRESHMENT_TABLE = "Refreshment Table";
			WELL_SOULWELL = "Soulwell";

			-- Specs
			BALANCE = "Balance";
			FERAL = "Feral";
			RESTORATION = "Restoration";
			BEASTMASTERY = "Beast Mastery";
			MARKSMANSHIP = "Marksmanship";
			SURVIVAL = "Survival";
			ARCANE = "Arcane";
			FIRE = "Fire";
			FROST = "Frost";
			HOLY = "Holy";
			PROTECTION = "Protection";
			RETRIBUTION = "Retribution";
			SHADOW = "Shadow";
			DISCIPLINE = "Discipline";
			ASSASSINATION = "Assassination";
			COMBAT = "Combat";
			SUBTLETY = "Subtlety";
			ELEMENTAL = "Elemental";
			ENHANCEMENT = "Enhancement";
			AFFLICTION = "Affliction";
			DEMONOLOGY = "Demonology";
			DESTRUCTION = "Destruction";
			ARMS = "Arms";
			FURY = "Fury";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	BINDING_HEADER__ARENA = "_|cffCCCC88Arena|r";
	BINDING_NAME__ARENA_TOGGLE= "Toggle unit scanning";
	BINDING_NAME__ARENA_CAMERA_TOGGLE = "Toggle free camera movement";

	SLASH_ARENASCAN1 = "/arenascan";
end
