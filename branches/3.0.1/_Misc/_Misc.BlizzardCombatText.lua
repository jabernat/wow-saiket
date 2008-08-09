--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.BlizzardCombatText.lua - Modifies the Blizzard_CombatText addon.     *
  *                                                                            *
  * + Allows up to 40 messages at once.                                        *
  * + Adds overhealing to heal messages.                                       *
  * + Displays messages for your heals on others.                              *
  ****************************************************************************]]


local L = _MiscLocalization;
local _Misc = _Misc;
local me = {
	MessageMax = 40;
	CombatTextOnEventBackup;
};
_Misc.BlizzardCombatText = me;




--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText.AddHealMessage                          *
  * Description: Adds a scrolling message for heal events.                     *
  ****************************************************************************]]
do
	local UnitExists = UnitExists;
	local UnitHealth = UnitHealth;
	local UnitHealthMax = UnitHealthMax;
	local tonumber = tonumber;
	function me.AddHealMessage ( Type, Amount, Target, Caster )
		local UnitID = Target or "player";
		local Overhealed = UnitExists( UnitID )
			and max( 0, tonumber( Amount ) - ( UnitHealthMax( UnitID ) - UnitHealth( UnitID ) ) ) or 0;
		Caster = COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" and Caster or "";

		local Message = Overhealed == 0
			and L.BLIZZARDCOMBATTEXT_HEAL_FORMAT:format( Caster, Amount, Target or "" )
			or L.BLIZZARDCOMBATTEXT_OVERHEAL_FORMAT:format( Caster, Amount - Overhealed, Target or "", Overhealed );

		local Info = COMBAT_TEXT_TYPE_INFO[ Type ];
		CombatText_AddMessage( Message, COMBAT_TEXT_SCROLL_FUNCTION,
			Info.r, Info.g, Info.b,
			Type == "HEAL_CRIT" and "crit" or nil, Info.isStaggered );
	end
end


--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText:COMBAT_LOG_EVENT_UNFILTERED             *
  ****************************************************************************]]
do
	local MeFlag = COMBATLOG_OBJECT_AFFILIATION_MINE;
	local band = bit.band;
	function me:COMBAT_LOG_EVENT_UNFILTERED ( Event, _, Type, _, _, CasterFlags, _, Target, TargetFlags, _, _, _, Amount, Critical )
		if ( Type == "SPELL_HEAL" and band( CasterFlags, MeFlag ) == 1 and band( TargetFlags, MeFlag ) == 0 ) then
			-- Heal cast by player onto someone else
			me.AddHealMessage( Critical and "HEAL_CRIT" or "HEAL", Amount, Target, false );
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText:COMBAT_TEXT_UPDATE                      *
  ****************************************************************************]]
function me:COMBAT_TEXT_UPDATE ( Event, Type, Caster, Amount, ... )
	if ( Type:find( "HEAL", 1, true ) ) then
		me.AddHealMessage( Type, Amount, false, Caster ~= UnitName( "player" ) and Caster );
	else
		me.CombatTextOnEventBackup( self, Event, Type, Caster, Amount, ... );
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText.CombatTextOnEvent                       *
  * Description: Enables overhealing and watching heals you cast on others.    *
  ****************************************************************************]]
do
	local type = type;
	local UnitName = UnitName;
	function me:CombatTextOnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( self, Event, ... );
		else
			me.CombatTextOnEventBackup( self, Event, ... );
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText.OnLoad                                  *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	-- Allow a max of 40 messages
	for Index = NUM_COMBAT_TEXT_LINES + 1, me.MessageMax do
		CombatText:CreateFontString( "CombatText"..Index, "BACKGROUND", "CombatTextTemplate" );
	end
	NUM_COMBAT_TEXT_LINES = max( me.MessageMax, NUM_COMBAT_TEXT_LINES );

	me.CombatTextOnEventBackup = CombatText:GetScript( "OnEvent" );
	CombatText:SetScript( "OnEvent", me.CombatTextOnEvent );
	CombatText:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "Blizzard_CombatText", me.OnLoad );
end
