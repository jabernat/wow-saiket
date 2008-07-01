--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardCombatLog.lua - Modifies the Blizzard_CombatLog addon.      *
  *                                                                            *
  * + Repositions the custom bar and progress bar.                             *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.BlizzardCombatLog = me;




--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.FCFDockUpdate                           *
  * Description: Repositions the combat log and its bars.                      *
  ****************************************************************************]]
do
	local SetPoint = _Clean.SetPoint;
	function me.FCFDockUpdate ()
		SetPoint( _G[ COMBATLOG:GetName().."Background" ], "TOPLEFT", -2, 3 );
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.Truncate                                *
  * Description: Truncates text to a given length.                             *
  ****************************************************************************]]
do
	local max = max;
	function me.Truncate ( MaxLength, Text )
		if ( #Text > MaxLength ) then
			return Text:sub( 1, max( 0, MaxLength - 1 ) ).."-";
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
			SpellName = Truncate( 16, SpellName );
		end

		return Timestamp, EventType, SourceGUID,
			SourceName and Truncate( 16, SourceName ) or nil,
			SourceFlags, DestGUID,
			DestName and Truncate( 16, DestName ) or nil,
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
function me.CombatLogRefilterUpdate ()
	local Valid = CombatLogGetCurrentEntry();
	local Total = 0;
	Blizzard_CombatLog_RefreshGlobalLinks();
	local Text, R, G, B;
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


--[[****************************************************************************
  * Function: _Clean.BlizzardCombatLog.OnLoad                                  *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	local FilterButton = CombatLogQuickButtonFrame_CustomAdditionalFilterButton;
	_Clean.ClearAllPoints( FilterButton );
	_Clean.SetPoint( FilterButton, "LEFT", COMBATLOG:GetName().."TabText", "RIGHT", -2, -2 );
	_Clean.RunProtectedMethod( FilterButton, "SetScale", 0.8 );
	FilterButton:GetNormalTexture():SetAlpha( 0.75 );
	FilterButton:SetAlpha( 0.5 );
	_Clean.RunProtectedMethod( FilterButton, "SetParent", _G[ COMBATLOG:GetName().."Tab" ] );
	_Clean.AddLockedButton( CombatLogQuickButtonFrame_CustomAdditionalFilterButton );
	_Clean.RunProtectedMethod( FilterButton, "RegisterForClicks", "RightButtonUp" );
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
	OptionsFrame_DisableCheckBox( CombatConfigSettingsShowQuickButton );
	Blizzard_CombatLog_RefreshGlobalLinks();

	local ProgressBar = CombatLogQuickButtonFrame_CustomProgressBar;
	local Background = _G[ COMBATLOG:GetName().."Background" ];
	_Clean.RunProtectedMethod( ProgressBar, "SetParent", ChatFrame2 );
	_Clean.ClearAllPoints( ProgressBar );
	_Clean.SetPoint( ProgressBar, "TOPRIGHT", Background );
	_Clean.SetPoint( ProgressBar, "BOTTOM", Background );
	_Clean.RunProtectedMethod( ProgressBar, "SetWidth", 8 );
	ProgressBar:SetOrientation( "VERTICAL" );
	ProgressBar:SetStatusBarColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );

	local Frame = CombatLogQuickButtonFrame_Custom;
	hooksecurefunc( "FCF_DockUpdate", me.FCFDockUpdate );
	_Clean.RunProtectedMethod( Frame, "Hide" );
	Frame.Show = _Clean.NilFunction;
	Frame.Hide = _Clean.NilFunction;

	CombatLog_AddEvent = me.CombatLogAddEvent;
	Blizzard_CombatLog_RefilterUpdate = me.CombatLogRefilterUpdate;
	COMBATLOG_LIMIT_PER_FRAME = 10;
	COMBATLOG_MESSAGE_LIMIT = 1000;
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_CombatLog", me.OnLoad );
end
