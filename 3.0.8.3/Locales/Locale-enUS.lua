--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	_CleanLocalization = setmetatable( {
		BLIZZARDCOMBATLOG_TRUNCATESUFFIX = "-";
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Combat log
	TEXT_MODE_A_STRING_1 = "%1$s %2$s %4$s %3$s %5$s %6$s";
	TEXT_MODE_A_STRING_2 = "%1$s %2$s %4$s %3$s %5$s %6$s";

	-- Action type
	TEXT_MODE_A_STRING_ACTION = HIGHLIGHT_FONT_COLOR_CODE.."%2$s"; -- Non-clickable, does not end color codes


	-- Damage amounts
	local LightGray = "|cffaaaaaa";
	TEXT_MODE_A_STRING_RESULT_ABSORB = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Abs:%d"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_BLOCK  = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Block:%d"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_CRITICAL = LIGHTYELLOW_FONT_COLOR_CODE.."("..NORMAL_FONT_COLOR_CODE.."Crit"..LIGHTYELLOW_FONT_COLOR_CODE..")|r"; -- Slightly darker
	TEXT_MODE_A_STRING_RESULT_CRITICAL_SPELL = TEXT_MODE_A_STRING_RESULT_CRITICAL; -- Spell crit
	TEXT_MODE_A_STRING_RESULT_CRUSHING = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Crush"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_GLANCING = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Glance"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_REFLECT  = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Reflect"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_RESIST = LIGHTYELLOW_FONT_COLOR_CODE.."("..LightGray.."Resist:%d"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_VULNERABILITY = LIGHTYELLOW_FONT_COLOR_CODE.."("..NORMAL_FONT_COLOR_CODE.."Vuln:%d"..LIGHTYELLOW_FONT_COLOR_CODE..")|r";
	TEXT_MODE_A_STRING_RESULT_OVERHEALING = "|cff33aa33{%d}|r";

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

	-- Timestamps
	TEXT_MODE_A_STRING_TIMESTAMP = GRAY_FONT_COLOR_CODE.."[%s]|r %s";
	TEXT_MODE_A_TIMESTAMP = "%02d:%02d:%02d";


	-- Action types
	do
		local Hurt, Heal = "hurt|cffcc7f7f", "heal|cff66ff66";
		local Drain, Energy = "drain|cffcc7f7f", "energy|cff66ff66";
		local Miss = "|cff7f7f7fmiss";
		local Lose, Gain, Dispell, Stole = "|cff555555lose", "|cff7f7f7fgain", "|cff555555dispell", "|cff555555stole";
		local Fail, Begin, Cast, Interrupt = "|cff555555fail", "|cff7f7f7fbegin", "|cffffff11cast", "|cff555555interrupt";
		local Kill, Die = "|cffffff11kill", "|cffffff11die";
		local Summon, Durability, ExtraAttack = "|cff006633summon", "|cffffff11durability", "|cffffff11extra attack";

		ACTION_DAMAGE_SHIELD         = Hurt;
		ACTION_ENVIRONMENTAL_DAMAGE  = Hurt; --
		ACTION_RANGE_DAMAGE          = Hurt;
		ACTION_SPELL_DAMAGE          = Hurt;
		ACTION_SPELL_PERIODIC_DAMAGE = Hurt;
		ACTION_SWING_DAMAGE          = Hurt;
		ACTION_DAMAGE_SPLIT          = Hurt;
		ACTION_SPELL_HEAL          = Heal;
		ACTION_SPELL_PERIODIC_HEAL = Heal;

		ACTION_SPELL_ENERGIZE          = Energy;
		ACTION_SPELL_PERIODIC_ENERGIZE = Energy;
		ACTION_SPELL_LEECH          = Drain;
		ACTION_SPELL_DRAIN          = Drain;
		ACTION_SPELL_PERIODIC_DRAIN = Drain;
		ACTION_SPELL_PERIODIC_LEECH = Drain;

		ACTION_DAMAGE_SHIELD_MISSED  = Miss;
		ACTION_RANGE_MISSED          = Miss;
		ACTION_SPELL_MISSED          = Miss;
		ACTION_SPELL_PERIODIC_MISSED = Miss;
		ACTION_SWING_MISSED          = Miss;

		ACTION_ENCHANT_REMOVED                = Lose;
		ACTION_SPELL_AURA_REMOVED             = Lose;
		ACTION_SPELL_AURA_REMOVED_BUFF        = Lose;
		ACTION_SPELL_AURA_REMOVED_DEBUFF      = Lose; --
		ACTION_SPELL_AURA_REMOVED_DOSE        = Lose;
		ACTION_SPELL_AURA_REMOVED_DOSE_BUFF   = Lose;
		ACTION_SPELL_AURA_REMOVED_DOSE_DEBUFF = Lose;
		ACTION_ENCHANT_APPLIED                = Gain;
		ACTION_SPELL_AURA_APPLIED             = Gain;
		ACTION_SPELL_AURA_APPLIED_BUFF        = Gain;
		ACTION_SPELL_AURA_APPLIED_DEBUFF      = Gain; --
		ACTION_SPELL_AURA_APPLIED_DOSE        = Gain;
		ACTION_SPELL_AURA_APPLIED_DOSE_BUFF   = Gain; --
		ACTION_SPELL_AURA_APPLIED_DOSE_DEBUFF = Gain;
		ACTION_SPELL_AURA_DISPELLED        = Dispell;
		ACTION_SPELL_AURA_DISPELLED_BUFF   = Dispell;
		ACTION_SPELL_AURA_DISPELLED_DEBUFF = Dispell;
		ACTION_SPELL_AURA_STOLEN        = Stole;
		ACTION_SPELL_AURA_STOLEN_BUFF   = Stole;
		ACTION_SPELL_AURA_STOLEN_DEBUFF = Stole;

		ACTION_SPELL_CAST_FAILED   = Fail;
		ACTION_SPELL_DISPEL_FAILED = Fail.." dispel";
		ACTION_SPELL_CAST_START   = Begin;
		ACTION_SPELL_CAST_SUCCESS = Cast;
		ACTION_SPELL_INTERRUPT = Interrupt;

		ACTION_PARTY_KILL      = Kill;
		ACTION_SPELL_INSTAKILL = Kill;
		ACTION_UNIT_DESTROYED = Die;
		ACTION_UNIT_DIED      = Die;

		ACTION_SPELL_CREATE = Summon; -- Created a trap, a soul well, etc.
		ACTION_SPELL_SUMMON = Summon;
		ACTION_SPELL_DURABILITY_DAMAGE     = Durability;
		ACTION_SPELL_DURABILITY_DAMAGE_ALL = Durability.." full";
		ACTION_SPELL_EXTRA_ATTACKS = ExtraAttack;
	end


	-- The following aren't really actions
	ACTION_ENVIRONMENTAL_DAMAGE_DROWNING = "Drown";   --
	ACTION_ENVIRONMENTAL_DAMAGE_FALLING  = "Fall";    --
	ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE  = "Fatigue"; --
	ACTION_ENVIRONMENTAL_DAMAGE_FIRE     = "Fire";    --
	ACTION_ENVIRONMENTAL_DAMAGE_LAVA     = "Lava";    --
	ACTION_ENVIRONMENTAL_DAMAGE_SLIME    = "Slime";   --

	ACTION_DAMAGE_SHIELD_MISSED_BLOCK   = "Block";
	ACTION_DAMAGE_SHIELD_MISSED_DEFLECT = "Deflect";
	ACTION_DAMAGE_SHIELD_MISSED_DODGE   = "Dodge";
	ACTION_DAMAGE_SHIELD_MISSED_EVADED  = "Evade";
	ACTION_DAMAGE_SHIELD_MISSED_IMMUNE  = "Immune";
	ACTION_DAMAGE_SHIELD_MISSED_MISS    = "Miss";
	ACTION_DAMAGE_SHIELD_MISSED_PARRY   = "Parry";
	ACTION_DAMAGE_SHIELD_MISSED_RESIST  = "Resist";

	ACTION_RANGE_MISSED_ABSORB  = "Absorb";
	ACTION_RANGE_MISSED_BLOCK   = "Block";
	ACTION_RANGE_MISSED_DEFLECT = "Deflect";
	ACTION_RANGE_MISSED_DODGE   = "Dodge";
	ACTION_RANGE_MISSED_EVADE   = "Evade";
	ACTION_RANGE_MISSED_IMMUNE  = "Immune";
	ACTION_RANGE_MISSED_MISS    = "Miss";
	ACTION_RANGE_MISSED_PARRY   = "Parry";
	ACTION_RANGE_MISSED_RESIST  = "Resist";

	ACTION_SWING_MISSED_ABSORB  = "Absorb";
	ACTION_SWING_MISSED_BLOCK   = "Block";
	ACTION_SWING_MISSED_DEFLECT = "Deflect";
	ACTION_SWING_MISSED_DODGE   = "Dodge";
	ACTION_SWING_MISSED_EVADE   = "Evade";
	ACTION_SWING_MISSED_IMMUNE  = "Immune";
	ACTION_SWING_MISSED_MISS    = "Miss";
	ACTION_SWING_MISSED_PARRY   = "Parry";
	ACTION_SWING_MISSED_RESIST  = "Resist";

	ACTION_SPELL_MISSED_ABSORB  = "Absorb";
	ACTION_SPELL_MISSED_BLOCK   = "Block";
	ACTION_SPELL_MISSED_DEFLECT = "Deflect";
	ACTION_SPELL_MISSED_DODGE   = "Dodge";
	ACTION_SPELL_MISSED_EVADE   = "Evade";
	ACTION_SPELL_MISSED_IMMUNE  = "Immune";
	ACTION_SPELL_MISSED_MISS    = "Miss";
	ACTION_SPELL_MISSED_PARRY   = "Parry";
	ACTION_SPELL_MISSED_REFLECT = "Reflect";
	ACTION_SPELL_MISSED_RESIST  = "Resist";

	ACTION_SPELL_PERIODIC_MISSED_ABSORB    = "Tick Absorb";
	ACTION_SPELL_PERIODIC_MISSED_BLOCK     = "Tick Block";
	ACTION_SPELL_PERIODIC_MISSED_DEFLECTED = "Tick Deflect";
	ACTION_SPELL_PERIODIC_MISSED_DODGE     = "Tick Dodge";
	ACTION_SPELL_PERIODIC_MISSED_EVADED    = "Tick Evade";
	ACTION_SPELL_PERIODIC_MISSED_IMMUNE    = "Tick Immune";
	ACTION_SPELL_PERIODIC_MISSED_MISS      = "Tick Miss";
	ACTION_SPELL_PERIODIC_MISSED_PARRY     = "Tick Parry";
	ACTION_SPELL_PERIODIC_MISSED_RESIST    = "Tick Resist";




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
end
