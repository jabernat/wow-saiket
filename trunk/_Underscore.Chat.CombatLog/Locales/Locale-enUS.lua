--[[****************************************************************************
  * _Underscore.Chat.CombatLog by Saiket                                       *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local Meta = getmetatable( _UnderscoreLocalization );
_UnderscoreLocalization.Chat.CombatLog = setmetatable( {
	TRUNCATE_SUFFIX = "-";

	-- Args are: Source, Spell, Action, Destination, Value, Result(i.e. blocked), School, PowerType, Amount(i.e. block value), ExtraAmount
	FORMAT = "%1$s %2$s %4$s %3$s %5$s %6$s";
	FORMAT_ENVIRONMENTAL = "%4$s %2$s %3$s %5$s %6$s"; -- No source
	FORMAT_MISS = "%1$s %2$s %4$s %5$s %6$s"; -- Don't duplicate miss type
	FORMAT_ENCHANT = "%4$s %2$s %5$s %3$s %6$s"; -- Use player as source and item as destination

	Actions = setmetatable( {
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
	Results = setmetatable( {
		ABSORB = "|cffffff9a(|cffaaaaaaAbs:%d|cffffff9a)|r";
		BLOCK  = "|cffffff9a(|cffaaaaaaBlock:%d|cffffff9a)|r";
		CRITICAL = "|cffffff9a(|cffaaaaaaCrit|cffffff9a)|r";
		CRITICAL_SPELL = "|cffffff9a(|cffaaaaaaCrit|cffffff9a)|r";
		CRUSHING = "|cffffff9a(|cffaaaaaaCrush|cffffff9a)|r";
		GLANCING = "|cffffff9a(|cffaaaaaaGlance|cffffff9a)|r";
		REFLECT  = "|cffffff9a(|cffaaaaaaReflect|cffffff9a)|r";
		RESIST = "|cffffff9a(|cffaaaaaaResist:%d|cffffff9a)|r";
		VULNERABILITY = "|cffffff9a(|cffaaaaaaVuln:%d|cffffff9a)|r";
		OVERHEALING = "|cff33aa33{%d}|r";
		OVERKILLING = "|cffff1111{%d}|r";
	}, Meta );
}, Meta );


TEXT_MODE_A_STRING_TIMESTAMP = "|cff808080[%s]|r %s";
TEXT_MODE_A_TIMESTAMP = "%02d:%02d:%02d";

TEXT_MODE_A_STRING_ACTION = "|cffffffff%2$s"; -- Non-clickable, does not end color codes

-- Unit names
TEXT_MODE_A_STRING_BRACE_UNIT = "|cffaaaaaa[%2$s|cffaaaaaa]|r";
TEXT_MODE_A_STRING_POSSESSIVE = "%s";
UNIT_YOU_DEST_POSSESSIVE   = UNIT_YOU_DEST; -- "You" instead of "Your"
UNIT_YOU_SOURCE_POSSESSIVE = UNIT_YOU_SOURCE;

-- Spell/item links
TEXT_MODE_A_STRING_ITEM        = "|cffaaaaaa|Hitem:%s|h%s|h|r";
TEXT_MODE_A_STRING_SPELL       = "|cffaaaaaa|Hspell:%s:%s|h%s|h|r";
TEXT_MODE_A_STRING_SPELL_EXTRA = "|cffaaaaaa|Hspell:%s:%s|h%s|h|r";
-- Optional inner-link braces
TEXT_MODE_A_STRING_BRACE_ITEM  = "|cffaaaaaa[%2$s|cffaaaaaa]";
TEXT_MODE_A_STRING_BRACE_SPELL = "|cffaaaaaa[%2$s|cffaaaaaa]";

TEXT_MODE_A_STRING_VALUE_TYPE   = "%s |cff808080%s|r";
TEXT_MODE_A_STRING_VALUE_SCHOOL = "%s|cff808080%s|r";