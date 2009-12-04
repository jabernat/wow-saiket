--[[****************************************************************************
  * _Clean.Chat.CombatLog by Saiket                                            *
  * _Clean.Chat.CombatLog.lua - Modifies the Blizzard_CombatLog addon.         *
  ****************************************************************************]]


-- NOTE(The normal chat module needs to look right when this is disabled.)
local L = _CleanLocalization.Chat.CombatLog;
local _Clean = _Clean;
local me = {};
_Clean.Chat.CombatLog = me;

local MaxFieldLength = 16;

local SpellEvents = {};




--[[****************************************************************************
  * Function: _Clean.Chat.CombatLog.FCFDockUpdate                              *
  * Description: Repositions the combat log and its bars.                      *
  ****************************************************************************]]
function me.FCFDockUpdate ()
	_G[ COMBATLOG:GetName().."Background" ]:SetPoint( "TOPLEFT", -2, 3 );
end
--[[****************************************************************************
  * Function: _Clean.Chat.CombatLog.Truncate                                   *
  * Description: Truncates text to a given length.                             *
  ****************************************************************************]]
do
	local max = max;
	function me.Truncate ( Text )
		if ( #Text > MaxFieldLength ) then
			return Text:sub( 1, max( 0, MaxFieldLength - 1 ) )..L.TRUNCATE_SUFFIX;
		else
			return Text;
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Chat.CombatLog.FilterEvent                                *
  * Description: Truncates event arguments.                                    *
  ****************************************************************************]]
do
	local Truncate = me.Truncate;
	local select = select;
	local SpellID, SpellName, ItemID, ItemName;
	function me.FilterEvent ( Timestamp, Event, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags, ... )
		if ( SourceName ) then
			SourceName = Truncate( SourceName );
		end
		if ( DestName ) then
			DestName = Truncate( DestName );
		end

		if ( SpellEvents[ Event ] ) then
			SpellID, SpellName = ...;
			return Timestamp, Event, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags,
				SpellID, SpellName and Truncate( SpellName ), select( 3, ... );
		elseif ( Event == "ENCHANT_APPLIED" or Event == "ENCHANT_REMOVED" ) then
			SpellName, ItemID, ItemName = ...;
			return Timestamp, Event, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags,
				SpellName, ItemID, ItemName and Truncate( ItemName ), select( 4, ... );
		end

		return Timestamp, Event, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags, ...;
	end
end
--[[****************************************************************************
  * Function: _Clean.Chat.CombatLog.AddEvent                                   *
  * Description: Truncates long strings from new combat log messages.          *
  ****************************************************************************]]
function me.AddEvent ( ... )
	Blizzard_CombatLog_RefreshGlobalLinks();
	COMBATLOG:AddMessage( CombatLog_OnEvent( Blizzard_CombatLog_CurrentSettings, me.FilterEvent( ... ) ) );
end
--[[****************************************************************************
  * Function: _Clean.Chat.CombatLog.RefilterUpdate                             *
  * Description: Truncates long strings as the combat log refills.             *
  ****************************************************************************]]
do
	local CombatLogGetCurrentEntry = CombatLogGetCurrentEntry;
	local CombatLogAdvanceEntry = CombatLogAdvanceEntry;
	function me.RefilterUpdate ()
		local Total, Valid = 0, CombatLogGetCurrentEntry();
		Blizzard_CombatLog_RefreshGlobalLinks();
		while ( Valid and Total < COMBATLOG_LIMIT_PER_FRAME ) do
			local Text, R, G, B = CombatLog_OnEvent( Blizzard_CombatLog_CurrentSettings, me.FilterEvent( CombatLogGetCurrentEntry() ) );
			COMBATLOG:AddMessage( Text, R, G, B, nil, true ); -- Add to top of frame

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
	FilterButton:SetHighlightTexture( [[Interface\Buttons\UI-Common-MouseHilight]], "ADD" );

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
	ProgressBar:SetParent( COMBATLOG );
	ProgressBar:ClearAllPoints();
	ProgressBar:SetPoint( "TOPRIGHT", Background );
	ProgressBar:SetPoint( "BOTTOM", Background );
	ProgressBar:SetWidth( 8 );
	ProgressBar:SetOrientation( "VERTICAL" );
	ProgressBar:SetStatusBarColor( unpack( _Clean.Colors.Normal ) );

	local Frame = CombatLogQuickButtonFrame_Custom;
	hooksecurefunc( "FCF_DockUpdate", me.FCFDockUpdate );
	Frame:Hide();
	Frame.Show = _Clean.NilFunction;

	CombatLog_AddEvent = me.AddEvent;
	Blizzard_CombatLog_RefilterUpdate = me.RefilterUpdate;
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
	SpellEvents[ "DAMAGE_SHIELD" ] = true;
	SpellEvents[ "DAMAGE_SPLIT" ] = true;
	SpellEvents[ "DAMAGE_SHIELD_MISSED" ] = true;
	for _, Prefix in ipairs( Prefixes ) do
		if ( Prefix == "RANGE" or Prefix:match( "^SPELL" ) ) then
			for _, Suffix in ipairs( Suffixes ) do
				SpellEvents[ Prefix..Suffix ] = true;
			end
		end
	end

	-- Add format overrides for events with odd parameters
	TEXT_MODE_A_STRING_1 = L.FORMAT;
	wipe( EVENT_TEMPLATE_FORMATS );
	EVENT_TEMPLATE_FORMATS[ "ENCHANT_APPLIED" ] = L.FORMAT_ENCHANT;
	EVENT_TEMPLATE_FORMATS[ "ENCHANT_REMOVED" ] = L.FORMAT_ENCHANT;
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
			local Label = L.Actions[ SuffixLabels[ Suffix ] ];
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
		_G[ "ACTION_"..Event ] = L.Actions[ Key ];
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
			_G[ "ACTION_"..Event..Type ] = L.Actions[ Key ];
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
	 		_G[ "ACTION_ENVIRONMENTAL"..Suffix..Type ] = L.Actions[ Key ];
		end
	end


	-- Result labels (i.e. crit/partial block/crush)
	for Type, Label in pairs( L.Results ) do
		_G[ "TEXT_MODE_A_STRING_RESULT_"..Type ] = Label;
	end




	-- Update log with new format
	Blizzard_CombatLog_Refilter();
end
