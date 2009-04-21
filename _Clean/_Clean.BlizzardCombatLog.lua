--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardCombatLog.lua - Modifies the Blizzard_CombatLog addon.      *
  ****************************************************************************]]


local _Clean = _Clean;
local L = _CleanLocalization.BLIZZARD_COMBATLOG;
local me = {
	MaxFieldLength = 16;
};
_Clean.BlizzardCombatLog = me;




--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.FCFDockUpdate                           *
  * Description: Repositions the combat log and its bars.                      *
  ****************************************************************************]]
function me.FCFDockUpdate ()
	_G[ COMBATLOG:GetName().."Background" ]:SetPoint( "TOPLEFT", -2, 3 );
end
--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.Truncate                                *
  * Description: Truncates text to a given length.                             *
  ****************************************************************************]]
do
	local max = max;
	function me.Truncate ( MaxLength, Text )
		if ( #Text > MaxLength ) then
			return Text:sub( 1, max( 0, MaxLength - 1 ) )..L.TRUNCATESUFFIX;
		else
			return Text;
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.FilterEvent                             *
  * Description: Truncates event arguments.                                    *
  ****************************************************************************]]
do
	local Truncate = me.Truncate;
	function me.FilterEvent ( Timestamp, EventType, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags, SpellID, SpellName, ... )
		if ( SpellName and ( EventType:find( "^SPELL_" ) or EventType:find( "^RANGE_" ) ) ) then
			SpellName = Truncate( me.MaxFieldLength, SpellName );
		end

		return Timestamp, EventType, SourceGUID,
			SourceName and Truncate( me.MaxFieldLength, SourceName ) or nil,
			SourceFlags, DestGUID,
			DestName and Truncate( me.MaxFieldLength, DestName ) or nil,
			DestFlags, SpellID, SpellName, ...;
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.CombatLogAddEvent                       *
  * Description: Truncates long strings from the combat log.                   *
  ****************************************************************************]]
do
	local FilterEvent = me.FilterEvent;
	function me.CombatLogAddEvent ( ... )
		Blizzard_CombatLog_RefreshGlobalLinks();
		COMBATLOG:AddMessage( CombatLog_OnEvent( Blizzard_CombatLog_CurrentSettings, FilterEvent( ... ) ) );
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.CombatLogRefilterUpdate                 *
  * Description: Truncates long strings from the combat log.                   *
  ****************************************************************************]]
do
	local CombatLogGetCurrentEntry = CombatLogGetCurrentEntry;
	local CombatLogAdvanceEntry = CombatLogAdvanceEntry;
	local Valid, Total, Text, R, G, B;
	function me.CombatLogRefilterUpdate ()
		Valid = CombatLogGetCurrentEntry();
		Total = 0;
		Blizzard_CombatLog_RefreshGlobalLinks();
		while ( Valid and Total < COMBATLOG_LIMIT_PER_FRAME ) do
			Text, R, G, B = CombatLog_OnEvent( Blizzard_CombatLog_CurrentSettings, me.FilterEvent( CombatLogGetCurrentEntry() ) );
			COMBATLOG:AddMessage( Text, R, G, B, 1, true ); -- Add to top of frame

			Valid = CombatLogAdvanceEntry( -1 );
			Total = Total + 1;
		end
		CombatLogQuickButtonFrame_CustomProgressBar:SetValue( CombatLogQuickButtonFrame_CustomProgressBar:GetValue() + Total );

		if ( not Valid or ( CombatLogQuickButtonFrame_CustomProgressBar:GetValue() >= COMBATLOG_MESSAGE_LIMIT ) ) then
			CombatLogUpdateFrame.refiltering = false;
			CombatLogUpdateFrame:SetScript( "OnUpdate", nil );
			CombatLogQuickButtonFrame_CustomProgressBar:Hide();
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_CombatLog", function ()
		local FilterButton = CombatLogQuickButtonFrame_CustomAdditionalFilterButton;
		FilterButton:ClearAllPoints();
		FilterButton:SetPoint( "LEFT", COMBATLOG:GetName().."TabText", "RIGHT", -2, -2 );
		FilterButton:SetScale( 0.8 );
		FilterButton:GetNormalTexture():SetAlpha( 0.75 );
		FilterButton:SetAlpha( 0.5 );
		FilterButton:SetParent( _G[ COMBATLOG:GetName().."Tab" ] );
		_Clean.AddLockedButton( CombatLogQuickButtonFrame_CustomAdditionalFilterButton );
		FilterButton:RegisterForClicks( "RightButtonUp" );
		FilterButton:SetScript( "OnEnter", nil );
		FilterButton:SetScript( "OnHide", nil );
		FilterButton:SetHighlightTexture( "Interface\\Buttons\\UI-Common-MouseHilight", "ADD" );

		-- Disable use of quick buttons
		local function DisableQuickButton ( Filter )
			Filter.hasQuickButton = false;
			Filter.quickButtonDisplay.solo = false;
			Filter.quickButtonDisplay.party = false;
			Filter.quickButtonDisplay.raid = false;
		end
		DisableQuickButton( DEFAULT_COMBATLOG_FILTER_TEMPLATE );
		for _, Filter in ipairs( Blizzard_CombatLog_Filters.filters ) do
			DisableQuickButton( Filter );
		end

		Blizzard_CombatLog_Update_QuickButtons();
		BlizzardOptionsPanel_CheckButton_Disable( CombatConfigSettingsShowQuickButton );
		Blizzard_CombatLog_RefreshGlobalLinks();

		local ProgressBar = CombatLogQuickButtonFrame_CustomProgressBar;
		local Background = _G[ COMBATLOG:GetName().."Background" ];
		ProgressBar:SetParent( ChatFrame2 );
		ProgressBar:ClearAllPoints();
		ProgressBar:SetPoint( "TOPRIGHT", Background );
		ProgressBar:SetPoint( "BOTTOM", Background );
		ProgressBar:SetWidth( 8 );
		ProgressBar:SetOrientation( "VERTICAL" );
		local Normal = _Clean.Colors.Normal;
		ProgressBar:SetStatusBarColor( Normal.r, Normal.g, Normal.b );

		local Frame = CombatLogQuickButtonFrame_Custom;
		hooksecurefunc( "FCF_DockUpdate", me.FCFDockUpdate );
		Frame:Hide();
		Frame.Show = _Clean.NilFunction;
		Frame.Hide = _Clean.NilFunction;

		CombatLog_AddEvent = me.CombatLogAddEvent;
		Blizzard_CombatLog_RefilterUpdate = me.CombatLogRefilterUpdate;
		COMBATLOG_LIMIT_PER_FRAME = 10;
		COMBATLOG_MESSAGE_LIMIT = 1000;




		-- Formatting
		local _G = _G;
		local Prefixes = {
			"SWING",
			"RANGE",
			"SPELL",
			"SPELL_PERIODIC",
			"SPELL_BUILDING",
			"ENVIRONMENTAL",
		};
		local Suffixes = {
			"_DAMAGE",
			"_MISSED",
			"_HEAL",
			"_ENERGIZE",
			"_DRAIN",
			"_LEECH",
			"_INTERRUPT",
			"_DISPEL",
			"_DISPEL_FAILED",
			"_STOLEN",
			"_EXTRA_ATTACKS",
			"_AURA_APPLIED",
			"_AURA_REMOVED",
			"_AURA_APPLIED_DOSE",
			"_AURA_REMOVED_DOSE",
			"_AURA_REFRESH",
			"_AURA_BROKEN",
			"_AURA_BROKEN_SPELL",
			"_CAST_START",
			"_CAST_SUCCESS",
			"_CAST_FAILED",
			"_INSTAKILL",
			"_DURABILITY_DAMAGE",
			"_DURABILITY_DAMAGE_ALL",
			"_CREATE", -- Object
			"_SUMMON", -- NPC
			"_RESURRECT",
		};

		-- Add format overrides for events with odd parameters
		TEXT_MODE_A_STRING_1 = L.FORMAT;
		wipe( EVENT_TEMPLATE_FORMATS );
		for _, Prefix in ipairs( Prefixes ) do
			EVENT_TEMPLATE_FORMATS[ Prefix.."_MISSED" ] = L.FORMAT_MISS;
		end
		for _, Suffix in ipairs( Suffixes ) do
			EVENT_TEMPLATE_FORMATS[ "ENVIRONMENTAL"..Suffix ] = L.FORMAT_ENVIRONMENTAL;
		end


		-- Add action labels for events (i.e. hurt/heal/cast)
		local SuffixLabels = {
			_DAMAGE = "HURT";
			_HEAL = "HEAL";

			_ENERGIZE = "ENERGY";
			_LEECH = "DRAIN";
			_DRAIN = "DRAIN";

			_MISSED = "MISS";

			_AURA_REMOVED = "LOSE";
			_AURA_REMOVED_DOSE = "LOSE";
			_AURA_BROKEN = "LOSE";
			_AURA_BROKEN_SPELL = "LOSE";
			_AURA_APPLIED = "GAIN";
			_AURA_APPLIED_DOSE = "GAIN";
			_AURA_REFRESH = "REFRESH";
			_DISPEL = "DISPELL";
			_AURA_STOLEN = "STOLE";

			_CAST_SUCCESS = "CAST";
			_CAST_START = "CAST_START";
			_INTERRUPT = "INTERRUPT";
			_CAST_FAILED = "FAIL";
			_DISPEL_FAILED = "FAIL";

			_INSTAKILL = "KILL";
			_CREATE = "SUMMON";
			_SUMMON = "SUMMON";

			_DURABILITY_DAMAGE = "DURABILITY";
			_DURABILITY_DAMAGE_ALL = "DURABILITY";

			_EXTRA_ATTACKS = "EXTRA_ATTACK";

			_RESURRECT = "RESURRECT";
		};
		local AuraSuffixes = {
			_AURA_REMOVED = true;
			_AURA_REMOVED_DOSE = true;
			_AURA_BROKEN = true;
			_AURA_BROKEN_SPELL = true;
			_AURA_APPLIED = true;
			_AURA_APPLIED_DOSE = true;
			_AURA_REFRESH = true;
			_DISPEL = true;
			_AURA_STOLEN = true;
		};
		for _, Prefix in ipairs( Prefixes ) do
			for _, Suffix in ipairs( Suffixes ) do
				local Action = "ACTION_"..Prefix..Suffix;
				local Label = L.ACTIONS[ SuffixLabels[ Suffix ] ];
				if ( AuraSuffixes[ Suffix ] ) then
					_G[ Action.."_BUFF" ] = Label;
					_G[ Action.."_DEBUFF" ] = Label;
				else
					_G[ Action ] = Label;
				end
			end
		end
		local SpecialLabels = { -- Special events
			DAMAGE_SHIELD = "HURT";
			DAMAGE_SPLIT = "HURT";
			DAMAGE_SHIELD_MISSED = "MISS";
			ENCHANT_REMOVED = "LOSE";
			ENCHANT_APPLIED = "GAIN";
			PARTY_KILL = "KILL";
			UNIT_DIED = "DIE";
			UNIT_DESTROYED = "DIE";
		};
		for Event, Key in pairs( SpecialLabels ) do
			_G[ "ACTION_"..Event ] = L.ACTIONS[ Key ];
		end


		-- Labels for all miss types
		local MissTypes = {
			_ABSORB = "MISS_ABSORB";
			_BLOCK = "MISS_BLOCK";
			_DEFLECT = "MISS_DEFLECT";
			_DODGE = "MISS_DODGE";
			_EVADE = "MISS_EVADE";
			_IMMUNE = "MISS_IMMUNE";
			_MISS = "MISS_MISS";
			_PARRY = "MISS_PARRY";
			_REFLECT = "MISS_REFLECT";
			_RESIST = "MISS_RESIST";
		};
		local function AddMissTypes ( Event )
			for Type, Key in pairs( MissTypes ) do
				_G[ "ACTION_"..Event..Type ] = L.ACTIONS[ Key ];
			end
		end
		for _, Prefix in ipairs( Prefixes ) do
			AddMissTypes( Prefix.."_MISSED" );
		end
		AddMissTypes( "DAMAGE_SHIELD_MISSED" );


		-- Labels for all environment types
		local EnvironmentTypes = {
			_DROWNING = "DROWN";
			_FALLING = "FALL";
			_FATIGUE = "FATIGUE";
			_FIRE = "FIRE";
			_LAVA = "LAVA";
			_SLIME = "SLIME";
		};
		for _, Suffix in ipairs( Suffixes ) do
			for Type, Key in pairs( EnvironmentTypes ) do
		 		_G[ "ACTION_ENVIRONMENTAL"..Suffix..Type ] = L.ACTIONS[ Key ];
			end
		end


		-- Result labels (i.e. crit/partial block/crush)
		for Type, Label in pairs( L.RESULTS ) do
			_G[ "TEXT_MODE_A_STRING_RESULT_"..Type ] = Label;
		end
	end );
end
