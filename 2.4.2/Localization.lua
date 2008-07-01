--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	_MiscLocalization = setmetatable(
		{
			RAIDWARNING_FORMAT = "[%s]: %s";

			FACTION_CHANGE_PATTERNS = {
				-- Complements of the following formats:
				"^Reputation with (.+) increased by %d+%.$", -- FACTION_STANDING_INCREASED
				"^Reputation with (.+) decreased by %d+%.$", -- FACTION_STANDING_DECREASED
				"^You are now .+ with (.+)%.$" -- FACTION_STANDING_CHANGED
			};

			UNDRESS_LABEL = "Undress";


			-- Time
			TIME_FORMAT = "%02d:%02d:%s";
			TIMETEXT_FORMAT = "T%s";
			TIME_VALUE_FORMAT = "%02d";
			TIME_VALUE_UNKNOWN = "??";


			-- AfkDndStatus
			AFKDNDSTATUS_AFK_PATTERN = "^You are now AFK: .*$"; -- MARKED_AFK_MESSAGE
			AFKDNDSTATUS_DND_PATTERN = "^You are now DND: .*%.$"; -- MARKED_DND


			-- Blizzard_CombatText
			BLIZZARDCOMBATTEXT_HEAL_FORMAT = "%s +%d %s";
			BLIZZARDCOMBATTEXT_OVERHEAL_FORMAT = "%s +%d %s {%d}";


			-- FCF
			FCF_TIMESTAMP_FORMAT = GRAY_FONT_COLOR_CODE.."[%s] "
				..FONT_COLOR_CODE_CLOSE.."%s"; -- TimeString, Message
			FCF_TIMESTAMP_PATTERN = "^"..GRAY_FONT_COLOR_CODE.."%[[%d?][%d?]:[%d?][%d?]:[%d?][%d?]%] "..FONT_COLOR_CODE_CLOSE;
			FCF_URL_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%1|h<%1>|h"
				..FONT_COLOR_CODE_CLOSE.." "; -- URL


			-- QuestLog
			QUESTLOG_TITLETEXT_FORMAT = "[%d%s] %s"; -- Level, QuestTag, Title
			QUESTLOG_QUESTTAGS = {
				[ ELITE ]   = "+";
				[ LFG_TYPE_DUNGEON ] = "d";
				[ GROUP  ]  = "g";
				[ RAID  ]   = "r";
				[ PVP ]     = "p";
				[ DUNGEON_DIFFICULTY2 ] = "h"; -- Heroic
			};
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
end
