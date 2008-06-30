--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * _Arena.lua - Common functions.                                             *
NOTE(ToDo:
	1: Add secure action button to use zoom.
	2: Add player name tracking.
	*: Add new buffs for mousing over players.
)
  ****************************************************************************]]


_ArenaOptions = {};


local L = _ArenaLocalization;
local me = CreateFrame( "Frame", "_ArenaFrame" );
_Arena = me;

me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormal" );




--[[****************************************************************************
  * Function: _Arena.Toggle                                                    *
  * Description: Enables or disables scanning units.                           *
  ****************************************************************************]]
function me.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not me:IsShown();
	end

	if ( Enable ) then
		me:Show();
	else
		me:Hide();
	end
end
--[[****************************************************************************
  * Function: _Arena.ToggleSlashCommand                                        *
  * Description: Slash command that toggles the _Arena window.                 *
  ****************************************************************************]]
function me.ToggleSlashCommand ()
	me.Toggle();
end




--[[****************************************************************************
  * Function: _Arena:UPDATE_MOUSEOVER_UNIT                                     *
  ****************************************************************************]]
function me:UPDATE_MOUSEOVER_UNIT ()
	if ( me.Scan.ScanUnit( "mouseover" ) ) then
		me.List.Update();
	end
end
--[[****************************************************************************
  * Function: _Arena:PLAYER_ENTERING_WORLD                                     *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	me.Scan.ResetResults();

	if ( select( 2, IsInInstance() ) == "arena" ) then -- In arena map
		if ( me:IsShown() ) then -- Already shown, just update
			me.List.Update();
		end
		me:RegisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );
		me:Show();
		me.Camera.Enable();
	else
		me:UnregisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );
		me:Hide();
	end
end
--[[****************************************************************************
  * Function: _Arena:CHAT_MSG_BG_SYSTEM_NEUTRAL                                *
  ****************************************************************************]]
function me:CHAT_MSG_BG_SYSTEM_NEUTRAL ( _, Message )
	if ( Message == L.ARENA_WARNING_15SEC ) then
		me.Camera.Disable();
	end
end

--[[****************************************************************************
  * Function: _Arena:OnEvent                                                   *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( self[ Event ] ) == "function" ) then
			self[ Event ]( self, Event, ... );
		end
	end
end


--[[****************************************************************************
  * Function: _Arena:OnShow                                                    *
  * Description: Enables tooltip scanning.                                     *
  ****************************************************************************]]
function me:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
	if ( UnitExists( "mouseover" ) ) then
		me.Scan.ScanUnit( "mouseover" ); -- Scan existing unit
	end
	me.List.Update();
	me:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" );
end
--[[****************************************************************************
  * Function: _Arena:OnHide                                                    *
  * Description: Disables tooltip scanning.                                    *
  ****************************************************************************]]
function me:OnHide ()
	PlaySound( "igCharacterInfoClose" );
	me:UnregisterEvent( "UPDATE_MOUSEOVER_UNIT" );
	me:UnregisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );

	me.Camera.Disable();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScale( 0.6 );
	me:SetWidth( 128 );
	me:SetHeight( 64 );
	me:SetPoint( "CENTER" );
	me:SetFrameStrata( "DIALOG" );
	me:EnableMouse( true );
	me:SetToplevel( true );
	me:SetBackdrop( {
		bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
		edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder";
		tile = true; tileSize = 32; edgeSize = 32;
		insets = { left = 7; right = 5; top = 3; bottom = 6; };
	} );
	-- Make dragable
	me:SetMovable( true );
	me:SetUserPlaced( true );
	me:SetClampedToScreen( true );
	me:CreateTitleRegion():SetAllPoints();
	-- Close button
	CreateFrame( "Button", nil, me, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 4, 4 );
	-- Title
	me.Title:SetText( L.WINDOW_TITLE );
	me.Title:SetPoint( "TOPRIGHT", -36, -4 );


	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );

	me:SetScript( "OnShow", me.OnShow );
	me:SetScript( "OnHide", me.OnHide );


	SlashCmdList[ "ARENASCAN" ] = me.ToggleSlashCommand;
end
