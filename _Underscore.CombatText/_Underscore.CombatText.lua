--[[****************************************************************************
  * _Underscore.CombatText by Saiket                                           *
  * _Underscore.CombatText.lua - Modifies the Blizzard_CombatText addon.       *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.CombatText = me;

me.Frame = CreateFrame( "Frame" );

me.IgnoredHealSpells = {
	[ 20267 ] = true; -- Judgement of Light
	--[ 20167 ] = true; -- Seal of Light
	[ 54968 ] = true; -- Glyph of Holy Light
	[ 15290 ] = true; -- Vampiric Embrace

	[ 52041 ] = true; -- Healing Stream Totem I
	[ 52042 ] = true; -- Healing Stream Totem (Rank unknown)
	[ 52046 ] = true; -- Healing Stream Totem II
	[ 52047 ] = true; -- Healing Stream Totem III
	[ 52048 ] = true; -- Healing Stream Totem IV
	[ 52049 ] = true; -- Healing Stream Totem V
	[ 52050 ] = true; -- Healing Stream Totem VI
	[ 58759 ] = true; -- Healing Stream Totem VII
	[ 58760 ] = true; -- Healing Stream Totem VIII
	[ 58761 ] = true; -- Healing Stream Totem IX
};

local NumLines = 40; -- Max number of visible messages

local ShowCasterNames;




--- Turns heal messages on when default UI settings allow them.
function me.Synchronize ()
	if ( GetCVarBool( "enableCombatText" ) and GetCVarBool( "CombatHealing" ) ) then
		ShowCasterNames = GetCVarBool( "fctFriendlyHealers" );
		me.Frame:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
	else
		me.Frame:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
	end
end


do
	--- Adds a scrolling message for heal events.
	-- @param Target  Optional target name.
	-- @param Caster  Optional caster name.
	-- @param ...  Extra args for *_HEAL combat events.
	local function AddHealMessage ( Target, Caster, SpellID, _, _, Amount, Overhealing, _, Critical )
		if ( not me.IgnoredHealSpells[ SpellID ] ) then
			local Format = me.L[ Overhealing == 0 and "HEAL_FORMAT" or "OVERHEAL_FORMAT" ];
			local Info = COMBAT_TEXT_TYPE_INFO[ Critical and "HEAL_CRIT" or "HEAL" ];

			return CombatText_AddMessage( Format:format( Caster or "", Amount - Overhealing, Target or "", Overhealing ),
				COMBAT_TEXT_SCROLL_FUNCTION,
				Info.r, Info.g, Info.b,
				Critical and "crit" or nil, Info.isStaggered );
		end
	end

	local Mine = COMBATLOG_OBJECT_AFFILIATION_MINE;
	local band = bit.band;
	--- Catches heals by or on the player and adds detailed combat text for them.
	function me.Frame:COMBAT_LOG_EVENT_UNFILTERED ( _, _, Type, _, Caster, CasterFlags, _, Target, TargetFlags, ... )
		if ( Type:match( "_HEAL$" ) and not Type:match( "^ENVIRONMENTAL" ) ) then
			-- Use flags to include pets'/vehicles' heals
			local OnMe, ByMe = band( TargetFlags, Mine ) ~= 0, band( CasterFlags, Mine ) ~= 0;
			if ( OnMe or ByMe ) then
				return AddHealMessage( not OnMe and Target, ( ShowCasterNames and not ByMe ) and Caster, ... );
			end
		end
	end
end
--- Synchs settings when default UI combat text settings change.
function me.Frame:CVAR_UPDATE ( _, Var )
	if ( Var == "SHOW_COMBAT_TEXT_TEXT"
		or Var == "SHOW_COMBAT_HEALING"
		or Var == "COMBAT_TEXT_SHOW_FRIENDLY_NAMES_TEXT"
	) then
		return me.Synchronize();
	end
end
--- Synchs settings when CVar data is loaded.
me.Frame.VARIABLES_LOADED = me.Synchronize;


do
	local OnEventBackup = CombatText:GetScript( "OnEvent" );
	--- Filters out default healing messages from the combat text frame.
	function me:CombatTextOnEvent ( Event, Type, ... )
		if ( Event ~= "COMBAT_TEXT_UPDATE" or not Type:find( "HEAL", 1, true ) ) then
			return OnEventBackup( self, Event, Type, ... );
		end
	end
end




CombatText:SetScript( "OnEvent", me.CombatTextOnEvent );

me.Frame:SetScript( "OnEvent", _Underscore.OnEvent );
me.Frame:RegisterEvent( "CVAR_UPDATE" );
me.Frame:RegisterEvent( "VARIABLES_LOADED" );

me.Synchronize(); -- In case VARIABLES_LOADED already fired


-- Modify overall font appearance
COMBAT_TEXT_HEIGHT = 16;
COMBAT_TEXT_SCROLLSPEED = 3;
COMBAT_TEXT_SPACING = 4;
COMBAT_TEXT_STAGGER_RANGE = 100;

local Font, Size = CombatTextFont:GetFont();
CombatTextFont:SetFont( Font, Size, "OUTLINE" );
CombatText:SetAlpha( 0.75 );

-- Increase max number of messages
for Index = NUM_COMBAT_TEXT_LINES + 1, NumLines do
	CombatText:CreateFontString( "CombatText"..Index, "BACKGROUND", "CombatTextTemplate" );
end
NUM_COMBAT_TEXT_LINES = max( NumLines, NUM_COMBAT_TEXT_LINES );


-- Format individual message types
local Colors = {
	Hostile  = { 0.8, 0.5, 0.5 }; -- Brighter
	HostileDim  = { 0.8, 1/3, 1/3 };
	Friendly = { 0.4, 1.0, 0.4 }; -- Brighter
	FriendlyDim = { 0.2, 0.6, 0.2 };

	Miss = { 0.5, 0.5, 0.5 }; -- Miss, dodge, evade, etc.
	Fail = { 1/3, 1/3, 1/3 }; -- Couldn't cast
	Mana = { 0.2, 0.2, 1.0 };

	Loot    = { 0.0, 0.4, 0.2 }; -- Money, loot, tradeskills
	System  = { 1.0, 1.0, 0.0 };
	Gain    = { 0.4, 2/3, 1.0 }; -- Rep., faction, XP, skills
	Warning = { 1.0, 0.1, 0.0 };
};
local TypeInfo = {
	-- Misc warnings
	MANA_LOW   = "Mana";
	HEALTH_LOW = "Warning";
	HONOR_GAINED = "Gain";
	FACTION      = "Gain";
	ENTERING_COMBAT = "System";
	LEAVING_COMBAT  = "System";
	PROC_RESISTED   = "Miss";
	ENCHANTMENT_ADDED   = "Loot";
	ENCHANTMENT_REMOVED = "Loot";

	-- Direct damage
	DAMAGE            = "HostileDim";
	DAMAGE_CRIT       = "HostileDim";
	SPELL_DAMAGE      = "Hostile";
	SPELL_DAMAGE_CRIT = "Hostile";
	DAMAGE_SHIELD     = "HostileDim";
	EXTRA_ATTACKS     = "Friendly";

	-- Partial resists/blocks/absorbs
	SPLIT_DAMAGE = "HostileDim";
	RESIST       = "Miss";
	BLOCK        = "Miss";
	ABSORB       = "Miss";
	SPELL_RESIST = "Miss";
	SPELL_BLOCK  = "Miss";
	SPELL_ABSORB = "Miss";

	-- Heals
	HEAL          = "Friendly";
	HEAL_CRIT     = "Friendly";
	PERIODIC_HEAL = "Friendly";

	-- Misses
	MISS    = "Miss";
	DODGE   = "Miss";
	PARRY   = "Miss";
	EVADE   = "Miss";
	IMMUNE  = "Miss";
	DEFLECT = "Miss";
	REFLECT = "Miss";
	SPELL_MISS    = "Miss";
	SPELL_DODGE   = "Miss";
	SPELL_PARRY   = "Miss";
	SPELL_EVADE   = "Miss";
	SPELL_IMMUNE  = "Miss";
	SPELL_DEFLECT = "Miss";
	SPELL_REFLECT = "Miss";

	-- Energy gains
	MANA   = "Mana";
	RAGE   = "Mana";
	FOCUS  = "Mana";
	ENERGY = "Mana";
	COMBO_POINTS = "Mana";

	-- Auras
	SPELL_AURA_START         = "FriendlyDim";
	SPELL_AURA_START_HARMFUL = "HostileDim";
	SPELL_AURA_END         = "Miss";
	SPELL_AURA_END_HARMFUL = "Miss";
	SPELL_DISPELLED = "Hostile";
	DISPEL_FAILED   = "Miss";

	-- Spell casts
	INTERRUPT        = "Fail";
	SPELL_CAST       = "Fail";
	SPELL_CAST_START = "Fail";
	SPELL_ACTIVE     = "System";
};
-- Merge TypeInfo with COMBAT_TEXT_TYPE_INFO
for Type, Color in pairs( TypeInfo ) do
	local Info = COMBAT_TEXT_TYPE_INFO[ Type ];
	if ( Info ) then
		-- Merge color values with existing entry
		Info.r, Info.g, Info.b = unpack( Colors[ Color ] );
	end
end

-- Stagger spammy messages
local StaggeredInfo = {
	"DAMAGE_CRIT",
	"SPELL_DAMAGE",
	"SPELL_DAMAGE_CRIT",
	"SPELL_MISS",
	"SPELL_DODGE",
	"SPELL_PARRY",
	"SPELL_EVADE",
	"SPELL_IMMUNE",
	"SPELL_DEFLECT",
	"SPELL_REFLECT",
	"SPELL_RESIST",
	"SPELL_BLOCK",
	"SPELL_ABSORB",
	"PERIODIC_HEAL",
	"HEAL_CRIT",

	"IMMUNE",
	"DEFLECT",
	"REFLECT",
	"RESIST",
	"BLOCK",
	"ABSORB",
};
for _, Type in ipairs( StaggeredInfo ) do
	COMBAT_TEXT_TYPE_INFO[ Type ].isStaggered = 1;
end