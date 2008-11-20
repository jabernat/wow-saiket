--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	_MiscLocalization = setmetatable(
		{
			RAIDWARNING_FORMAT = "[%s]: %s";

			UNDRESS_LABEL = "Undress";


			-- Time
			TIME_FORMAT = "%02d:%02d:%s";
			TIMETEXT_FORMAT = "T%s";
			TIME_VALUE_FORMAT = "%02d";
			TIME_VALUE_UNKNOWN = "??";


			-- Blizzard_CombatText
			BLIZZARDCOMBATTEXT_HEAL_FORMAT = "%s +%d %s";
			BLIZZARDCOMBATTEXT_OVERHEAL_FORMAT = "%s +%d %s {%d}";


			-- FCF
			FCF_TIMESTAMP_FORMAT = GRAY_FONT_COLOR_CODE.."[%s]|r %s"; -- TimeString, Message
			FCF_TIMESTAMP_PATTERN = "^"..GRAY_FONT_COLOR_CODE.."%[[%d?][%d?]:[%d?][%d?]:[%d?][%d?]%]|r ";
			FCF_URL_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%1|h<%1>|h|r "; -- URL


			-- QuestLog
			QUESTLOG_TITLETEXT_FORMAT = "[%d%s] %s"; -- Level, QuestTag, Title
			QUESTLOG_QUESTTAGS = {
				[ ELITE ]   = "+";
				[ LFG_TYPE_DUNGEON ] = "d"; -- Dungeon
				[ GROUP  ]  = "g";
				[ RAID  ]   = "r";
				[ PVP ]     = "p";
				[ DUNGEON_DIFFICULTY2 ] = "h"; -- Heroic
			};
			QUESTLOG_DAILY_PATTERN = "^Daily (.*)$"; -- DAILY_QUEST_TAG_TEMPLATE
			QUESTLOG_DAILY_FORMAT = "%s|cff71d5ff\226\151\138|r";
			QUESTLOG_ISCOMPLETETAGS = {
				[ -1 ] = RED_FONT_COLOR_CODE.."("..FAILED..")";
				[ 1 ] = GREEN_FONT_COLOR_CODE.."("..COMPLETE..")";
			};


			-- GameTooltip
			GAMETOOLTIP_GUILD_FORMAT = "<%s>"; -- GuildName


			-- CastingBar
			CASTINGBAR_TIMETEXT_FORMAT = "(%.1fs)"; -- Seconds


			-- WorldMapFrame
			WORLDMAPFRAME_COORDS_FORMAT = "%.2f, %.2f"; -- X, Y
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Camera
	BINDING_HEADER__MISC_CAMERA = "_|cffCCCC88Misc|r Camera";
	BINDING_NAME__MISC_CAMERA_UP     = "Pitch Up";
	BINDING_NAME__MISC_CAMERA_DOWN   = "Pitch Down";
	BINDING_NAME__MISC_CAMERA_LEFT   = "Turn Left";
	BINDING_NAME__MISC_CAMERA_RIGHT  = "Turn Right";
	BINDING_NAME__MISC_CAMERA_IN     = BINDING_NAME_CAMERAZOOMIN;
	BINDING_NAME__MISC_CAMERA_OUT    = BINDING_NAME_CAMERAZOOMOUT;
	BINDING_NAME__MISC_CAMERA_FLIP   = BINDING_NAME_FLIPCAMERAYAW;


	-- Macro
	SLASH_PRINT1 = "/print";
	SLASH_ALERT1 = "/alert";
	SLASH_ERR1 = "/err";
	SLASH_MOUNT1 = "/mount";
end
