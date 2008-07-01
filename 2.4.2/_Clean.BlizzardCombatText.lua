--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardCombatText.lua - Modifies the Blizzard_CombatText addon.    *
  *                                                                            *
  * + Changes the colors used to match the combat log.                         *
  * + Shrinks and compacts messages, as well as makes them transparent.        *
  * + Keeps messages on screen for a full 3 seconds.                           *
  * + Adds an outline to messages.                                             *
  * + Staggers crit messages, and increases the stagger range to 100 pixels.   *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.BlizzardCombatText = me;




--[[****************************************************************************
  * Function: _Clean.BlizzardCombatText.OnLoad                                 *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	local Colors = _Clean.Colors;
	local TypeInfo = {
		-- Misc warnings
		MANA_LOW   = Colors.Mana;
		HEALTH_LOW = Colors.Warning;
		HONOR_GAINED = Colors.Gain;
		FACTION      = Colors.Gain;
		ENTERING_COMBAT = Colors.System;
		LEAVING_COMBAT  = Colors.System;
		PROC_RESISTED   = Colors.Miss;
		ENCHANTMENT_ADDED   = Colors.Loot;
		ENCHANTMENT_REMOVED = Colors.Loot;

		-- Direct damage
		DAMAGE            = Colors.Hostile2;
		DAMAGE_CRIT       = Colors.Hostile2;
		SPELL_DAMAGE      = Colors.Hostile1;
		SPELL_DAMAGE_CRIT = Colors.Hostile1;
		DAMAGE_SHIELD     = Colors.Hostile2;
		EXTRA_ATTACKS     = Colors.Friendly1;

		-- Partial resists/blocks/absorbs
		SPLIT_DAMAGE = Colors.Hostile2;
		RESIST       = Colors.Miss;
		BLOCK        = Colors.Miss;
		ABSORB       = Colors.Miss;
		SPELL_RESIST = Colors.Miss;
		SPELL_BLOCK  = Colors.Miss;
		SPELL_ABSORB = Colors.Miss;

		-- Heals
		HEAL          = Colors.Friendly1;
		HEAL_CRIT     = Colors.Friendly1;
		PERIODIC_HEAL = Colors.Friendly1;

		-- Misses
		MISS    = Colors.Miss;
		DODGE   = Colors.Miss;
		PARRY   = Colors.Miss;
		EVADE   = Colors.Miss;
		IMMUNE  = Colors.Miss;
		DEFLECT = Colors.Miss;
		REFLECT = Colors.Miss;
		SPELL_MISS    = Colors.Miss;
		SPELL_DODGE   = Colors.Miss;
		SPELL_PARRY   = Colors.Miss;
		SPELL_EVADE   = Colors.Miss;
		SPELL_IMMUNE  = Colors.Miss;
		SPELL_DEFLECT = Colors.Miss;
		SPELL_REFLECT = Colors.Miss;

		-- Energy gains
		MANA   = Colors.Mana;
		RAGE   = Colors.Mana;
		FOCUS  = Colors.Mana;
		ENERGY = Colors.Mana;
		COMBO_POINTS = Colors.Mana;

		-- Auras
		SPELL_AURA_START         = Colors.Friendly2;
		SPELL_AURA_START_HARMFUL = Colors.Hostile2;
		SPELL_AURA_END         = Colors.Miss;
		SPELL_AURA_END_HARMFUL = Colors.Miss;
		SPELL_DISPELLED = Colors.Hostile1;
		DISPEL_FAILED   = Colors.Miss;

		-- Spell casts
		INTERRUPT        = Colors.Fail;
		SPELL_CAST       = Colors.Fail;
		SPELL_CAST_START = Colors.Fail;
		SPELL_ACTIVE     = Colors.System;
	};
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

	-- Merge TypeInfo with COMBAT_TEXT_TYPE_INFO
	for Type, Info in pairs( TypeInfo ) do
		local OrigInfo = COMBAT_TEXT_TYPE_INFO[ Type ];
		if ( OrigInfo ) then
			-- Merge color values with existing entry
			for Key, Value in pairs( Info ) do
				OrigInfo[ Key ] = Value;
			end
		else
			COMBAT_TEXT_TYPE_INFO[ Type ] = Info;
		end
	end

	-- Stagger crit messages
	for _, Type in ipairs( StaggeredInfo ) do
		COMBAT_TEXT_TYPE_INFO[ Type ].isStaggered = 1;
	end

	COMBAT_TEXT_HEIGHT = 16;
	COMBAT_TEXT_SCROLLSPEED = 3;
	COMBAT_TEXT_SPACING = 4;
	COMBAT_TEXT_STAGGER_RANGE = 100;

	local Font, Size = CombatTextFont:GetFont();
	CombatTextFont:SetFont( Font, Size, "OUTLINE" );
	CombatText:SetAlpha( 0.75 );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_CombatText", me.OnLoad );
end
