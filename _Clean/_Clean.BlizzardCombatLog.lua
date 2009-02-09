--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardCombatLog.lua - Modifies the Blizzard_CombatLog addon.      *
  ****************************************************************************]]


local _Clean = _Clean;
local L = _CleanLocalization;
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
			return Text:sub( 1, max( 0, MaxLength - 1 ) )..L.BLIZZARDCOMBATLOG_TRUNCATESUFFIX;
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
	end );
end
