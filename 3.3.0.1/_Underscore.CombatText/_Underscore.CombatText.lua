--[[****************************************************************************
  * _Underscore.CombatText by Saiket                                           *
  * _Underscore.CombatText.lua - Modifies the Blizzard_CombatText addon.       *
  ****************************************************************************]]


local L = _UnderscoreLocalization.CombatText;
local me = {};
_Underscore.CombatText = me;

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

local OnEventBackup = CombatText:GetScript( "OnEvent" );




--[[****************************************************************************
  * Function: _Underscore.CombatText.AddHealMessage                            *
  * Description: Adds a scrolling message for heal events.                     *
  ****************************************************************************]]
function me.AddHealMessage ( Target, Caster, Amount, Overhealing, Critical )
	Caster = COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" and Caster or "";

	local Message;
	if ( Overhealing == 0 ) then
		Message = L.HEAL_FORMAT:format( Caster, Amount, Target or "", Overhealing );
	else
		Message = L.OVERHEAL_FORMAT:format( Caster, Amount - Overhealing, Target or "", Overhealing );
	end

	local Info = COMBAT_TEXT_TYPE_INFO[ Critical and "HEAL_CRIT" or "HEAL" ];
	CombatText_AddMessage( Message, COMBAT_TEXT_SCROLL_FUNCTION,
		Info.r, Info.g, Info.b,
		Critical and "crit" or nil, Info.isStaggered );
end


--[[****************************************************************************
  * Function: _Underscore.CombatText:COMBAT_LOG_EVENT_UNFILTERED               *
  ****************************************************************************]]
do
	local MeFlag = COMBATLOG_OBJECT_AFFILIATION_MINE;
	local band = bit.band;
	local ByMe, OnMe;
	function me:COMBAT_LOG_EVENT_UNFILTERED ( Event, _, Type, _, Caster, CasterFlags, _, Target, TargetFlags, SpellID, _, _, Amount, Overhealing, _, Critical )
		if ( Type:match( "_HEAL$" ) and not ( Type:match( "^ENVIRONMENTAL" ) or me.IgnoredHealSpells[ SpellID ] ) ) then
			OnMe = band( TargetFlags, MeFlag ) ~= 0;
			ByMe = band( CasterFlags, MeFlag ) ~= 0;
			if ( OnMe or ByMe ) then
				me.AddHealMessage( not OnMe and Target, not ByMe and Caster, Amount, Overhealing, Critical );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.CombatText:COMBAT_TEXT_UPDATE                        *
  ****************************************************************************]]
function me:COMBAT_TEXT_UPDATE ( Event, Type, ... )
	-- Hide default healing messages
	if ( not Type:find( "HEAL", 1, true ) ) then
		OnEventBackup( self, Event, Type, ... );
	end
end
--[[****************************************************************************
  * Function: _Underscore.CombatText:OnEvent                                   *
  * Description: Enables overhealing and watching heals you cast on others.    *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( self, Event, ... );
		else
			OnEventBackup( self, Event, ... );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Hook to enable healing messages
	CombatText:SetScript( "OnEvent", me.OnEvent );
	CombatText:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );


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
end
