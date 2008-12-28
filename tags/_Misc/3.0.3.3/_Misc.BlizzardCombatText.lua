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
	function me.AddHealMessage ( Target, Caster, Amount, Overhealing, Critical )
		Caster = COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" and Caster or "";

		local Message;
		if ( Overhealing == 0 ) then
			Message = L.BLIZZARDCOMBATTEXT_HEAL_FORMAT:format( Caster, Amount, Target or "", Overhealing );
		else
			Message = L.BLIZZARDCOMBATTEXT_OVERHEAL_FORMAT:format( Caster, Amount - Overhealing, Target or "", Overhealing );
		end

		local Info = COMBAT_TEXT_TYPE_INFO[ Critical and "HEAL_CRIT" or "HEAL" ];
		CombatText_AddMessage( Message, COMBAT_TEXT_SCROLL_FUNCTION,
			Info.r, Info.g, Info.b,
			Critical and "crit" or nil, Info.isStaggered );
	end
end


--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText:COMBAT_LOG_EVENT_UNFILTERED             *
  ****************************************************************************]]
do
	local MeFlag = COMBATLOG_OBJECT_AFFILIATION_MINE;
	local band = bit.band;
	local ByMe, OnMe;
	function me:COMBAT_LOG_EVENT_UNFILTERED ( Event, _, Type, _, Caster, CasterFlags, _, Target, TargetFlags, _, _, _, Amount, Overhealing, Critical )
		if ( Type:match( "_HEAL$" ) ) then
			OnMe = band( TargetFlags, MeFlag ) ~= 0;
			ByMe = band( CasterFlags, MeFlag ) ~= 0;
			if ( OnMe or ByMe ) then
				me.AddHealMessage( not OnMe and Target, not ByMe and Caster, Amount, Overhealing, Critical );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardCombatText:COMBAT_TEXT_UPDATE                      *
  ****************************************************************************]]
function me:COMBAT_TEXT_UPDATE ( Event, Type, Caster, Amount, ... )
	if ( not Type:find( "HEAL", 1, true ) ) then
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "Blizzard_CombatText", function ()
		-- Allow a max of 40 messages
		for Index = NUM_COMBAT_TEXT_LINES + 1, me.MessageMax do
			CombatText:CreateFontString( "CombatText"..Index, "BACKGROUND", "CombatTextTemplate" );
		end
		NUM_COMBAT_TEXT_LINES = max( me.MessageMax, NUM_COMBAT_TEXT_LINES );
	
		me.CombatTextOnEventBackup = CombatText:GetScript( "OnEvent" );
		CombatText:SetScript( "OnEvent", me.CombatTextOnEvent );
		CombatText:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
	end );
end
