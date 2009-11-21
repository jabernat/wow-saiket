--[[****************************************************************************
  * _Clean.Chat by Saiket                                                      *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Meta = getmetatable( _CleanLocalization );
	local LightGray = "|cffaaaaaa";
	local ResultFormat = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."%s"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";

	_CleanLocalization.Chat = setmetatable( {
		TIMESTAMP_FORMAT = GRAY_FONT_COLOR_CODE.."[%02d:%02d:%02d]|r %s"; -- Hour, Minute, Second, Message
		TIMESTAMP_PATTERN = "^"..GRAY_FONT_COLOR_CODE.."%[%d%d:%d%d:%d%d%]|r ";

		URL_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%s|h<%1$s>|h|r ";
		URLPATH_FORMAT = " "..LIGHTYELLOW_FONT_COLOR_CODE.."|Hurl:%s%s|h<%1$s%2$s>|h|r "; -- Domain, Path

		RAIDWARNING_FORMAT = "[|cff%02X%02X%02X%s|r]: %s"; -- R, G, B, Author, Message


		-- Combat log
		LOG_TRUNCATE_SUFFIX = "-";

		-- Args are: Source, Spell, Action, Destination, Value, Result(i.e. blocked), School, PowerType, Amount(i.e. block value), ExtraAmount
		LOG_FORMAT = "%1$s %2$s %4$s %3$s %5$s %6$s";
		LOG_FORMAT_ENVIRONMENTAL = "%4$s %2$s %3$s %5$s %6$s"; -- No source
		LOG_FORMAT_MISS = "%1$s %2$s %4$s %5$s %6$s"; -- Don't duplicate miss type
		LOG_FORMAT_ENCHANT = "%4$s %2$s %5$s %3$s %6$s"; -- Use player as source and item as destination

		LogActions = setmetatable( {
			HURT = "Hurt|cffcc7f7f";
			HEAL = "Heal|cff66ff66";
			DRAIN = "Drain|cffcc7f7f";
			ENERGY = "Energy|cff66ff66";

			MISS = "|cff7f7f7fMiss|r";
			-- Subtypes of MISS
			MISS_ABSORB  = "|cff7f7f7fAbsorb|r";
			MISS_BLOCK   = "|cff7f7f7fBlock|r";
			MISS_DEFLECT = "|cff7f7f7fDeflect|r";
			MISS_DODGE   = "|cff7f7f7fDodge|r";
			MISS_EVADE   = "|cff7f7f7fEvade|r";
			MISS_IMMUNE  = "|cff7f7f7fImmune|r";
			MISS_MISS    = "|cff7f7f7fMiss|r";
			MISS_PARRY   = "|cff7f7f7fParry|r";
			MISS_REFLECT = "|cff7f7f7fReflect|r";
			MISS_RESIST  = "|cff7f7f7fResist|r";

			LOSE = "|cff555555Lose";
			GAIN = "|cff7f7f7fGain";
			REFRESH = "|cff7f7f7fRefresh";
			DISPELL = "|cff555555Dispell";
			STOLE = "|cff555555Stole";

			CAST = "|cffffff11Cast";
			CAST_START = "|cff7f7f7fBegin";
			FAIL = "|cff555555Fail";
			INTERRUPT = "|cff555555Interrupt";
			RESURRECT = "|cffffff11Revive";

			KILL = "|cffffff11Kill";
			DIE = "|cffffff11Die";

			SUMMON = "|cff006633Summon";
			DURABILITY = "|cffffff11Durability";
			EXTRA_ATTACK = "|cffffff11Extra attack";

			-- Environment types
			DROWN   = "Drown";
			FALL    = "Fall";
			FATIGUE = "Fatigue";
			FIRE    = "Fire";
			LAVA    = "Lava";
			SLIME   = "Slime";
		}, Meta );
		LogResults = setmetatable( {
			ABSORB = ResultFormat:format( "Abs:%d" );
			BLOCK  = ResultFormat:format( "Block:%d" );
			CRITICAL = ResultFormat:format( "Crit" ); -- Slightly darker
			CRITICAL_SPELL = ResultFormat:format( "Crit" ); -- Spell crit
			CRUSHING = ResultFormat:format( "Crush" );
			GLANCING = ResultFormat:format( "Glance" );
			REFLECT  = ResultFormat:format( "Reflect" );
			RESIST = ResultFormat:format( "Resist:%d" );
			VULNERABILITY = ResultFormat:format( "Vuln:%d" );
			OVERHEALING = "|cff33aa33{%d}|r";
			OVERKILLING = "|cffff1111{%d}|r";
		}, Meta );
	}, Meta );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Blizzard Combat Log
	TEXT_MODE_A_STRING_TIMESTAMP = GRAY_FONT_COLOR_CODE.."[%s]|r %s";
	TEXT_MODE_A_TIMESTAMP = "%02d:%02d:%02d";

	TEXT_MODE_A_STRING_ACTION = HIGHLIGHT_FONT_COLOR_CODE.."%2$s"; -- Non-clickable, does not end color codes

	-- Unit names
	TEXT_MODE_A_STRING_BRACE_UNIT = LightGray.."[%2$s"..LightGray.."]|r";
	TEXT_MODE_A_STRING_POSSESSIVE = "%s";
	UNIT_YOU_DEST_POSSESSIVE   = UNIT_YOU_DEST; -- "You" instead of "Your"
	UNIT_YOU_SOURCE_POSSESSIVE = UNIT_YOU_SOURCE;

	-- Spell/item links
	TEXT_MODE_A_STRING_ITEM        = LightGray.."|Hitem:%s|h%s|h|r";
	TEXT_MODE_A_STRING_SPELL       = LightGray.."|Hspell:%s:%s|h%s|h|r";
	TEXT_MODE_A_STRING_SPELL_EXTRA = LightGray.."|Hspell:%s:%s|h%s|h|r";
	-- Optional inner-link braces
	TEXT_MODE_A_STRING_BRACE_ITEM  = LightGray.."[%2$s"..LightGray.."]";
	TEXT_MODE_A_STRING_BRACE_SPELL = LightGray.."[%2$s"..LightGray.."]";

	TEXT_MODE_A_STRING_VALUE_TYPE   = "%s "..GRAY_FONT_COLOR_CODE.."%s|r";
	TEXT_MODE_A_STRING_VALUE_SCHOOL = "%s"..GRAY_FONT_COLOR_CODE.."%s|r";
	STRING_SCHOOL_PHYSICAL = "";
	STRING_SCHOOL_UNKNOWN  = "";
	STRING_SCHOOL_HOLY   = "H";
	STRING_SCHOOL_FIRE   = "F";
	STRING_SCHOOL_NATURE = "N";
	STRING_SCHOOL_FROST  = "Fr";
	STRING_SCHOOL_SHADOW = "S";
	STRING_SCHOOL_ARCANE = "A";
	-- Physical and a Magical
	STRING_SCHOOL_FLAMESTRIKE = "F";
	STRING_SCHOOL_FROSTSTRIKE = "Fr";
	STRING_SCHOOL_SPELLSTRIKE = "A";
	STRING_SCHOOL_STORMSTRIKE = "N";
	STRING_SCHOOL_SHADOWSTRIKE = "S";
	STRING_SCHOOL_HOLYSTRIKE = "H";
	-- Two Magical Schools
	STRING_SCHOOL_FROSTFIRE = "F+Fr";
	STRING_SCHOOL_SPELLFIRE = "F+A";
	STRING_SCHOOL_FIRESTORM = "F+N";
	STRING_SCHOOL_SHADOWFLAME = "F+S";
	STRING_SCHOOL_HOLYFIRE = "F+H";
	STRING_SCHOOL_SPELLFROST = "Fr+A";
	STRING_SCHOOL_FROSTSTORM = "Fr+N";
	STRING_SCHOOL_SHADOWFROST = "Fr+S";
	STRING_SCHOOL_HOLYFROST = "Fr+H";
	STRING_SCHOOL_SPELLSTORM = "A+N";
	STRING_SCHOOL_SPELLSHADOW = "A+S";
	STRING_SCHOOL_DIVINE = "A+H";
	STRING_SCHOOL_SHADOWSTORM = "N+S";
	STRING_SCHOOL_HOLYSTORM = "N+H";
	STRING_SCHOOL_SHADOWLIGHT = "S+H";
	-- Three or more schools
	STRING_SCHOOL_ELEMENTAL = "Ele";
	STRING_SCHOOL_CHROMATIC = "Chrom";
	STRING_SCHOOL_MAGIC = "Mag";
	STRING_SCHOOL_CHAOS = "Chaos";




	-- Chat message formats
	CHAT_BATTLEGROUND_GET        = "|Hchannel:Battleground|h[B]|h %s: ";
	CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:Battleground|h[B|TInterface\\GroupFrame\\UI-Group-LeaderIcon:0|t]|h %s: ";
	CHAT_GUILD_GET   = "|Hchannel:Guild|h[G]|h %s: ";
	CHAT_OFFICER_GET = "|Hchannel:Officer|h[O]|h %s: ";
	CHAT_PARTY_GET        = "|Hchannel:Party|h[P]|h %s: ";
	CHAT_RAID_GET         = "|Hchannel:Raid|h[R]|h %s: ";
	CHAT_RAID_LEADER_GET  = "|Hchannel:Raid|h[R|TInterface\\GroupFrame\\UI-Group-LeaderIcon:0|t]|h %s: ";
	CHAT_RAID_WARNING_GET = "|Hchannel:RaidWarning|h[R-WARN]|h %s: ";
	CHAT_SAY_GET = "|Hchannel:Say|h[S]|h %s: ";
	CHAT_WHISPER_GET = "[W] %s: ";
	CHAT_WHISPER_INFORM_GET = "[W]\194\187%s: ";
	CHAT_YELL_GET = "|Hchannel:Yell|h[Y]|h %s: ";

	CHAT_MONSTER_PARTY_GET   = CHAT_PARTY_GET;
	CHAT_MONSTER_SAY_GET     = CHAT_SAY_GET;
	CHAT_MONSTER_WHISPER_GET = CHAT_WHISPER_GET;
	CHAT_MONSTER_YELL_GET    = CHAT_YELL_GET;


	-- Player name chat links
	JOINED_PARTY = "|Hplayer:%1$s|h[%1$s]|h joins the party.";
	ERR_JOINED_GROUP_S = JOINED_PARTY;
	LEFT_PARTY = "|Hplayer:%1$s|h[%1$s]|h leaves the party.";
	ERR_LEFT_GROUP_S = LEFT_PARTY;
end
