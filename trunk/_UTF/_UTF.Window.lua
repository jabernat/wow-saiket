--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Browse.lua - Frame for finding individual characters by ID or by      *
  *   automatically scanning for ones that exist in the current font.          *
  *                                                                            *
  * + Using the mouse wheel over the frame will initiate a scan in the given   *
  *   direction that will stop when the next character is found in the font.   *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame", "_UTFBrowse", UIParent );
_UTF.Browse = me;

me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );




--[[****************************************************************************
  * Function: _UTF.Browse.Toggle                                               *
  * Description: Toggles the _UTF browse window.                               *
  ****************************************************************************]]
function me.Toggle ( Show )
	if ( Show == nil ) then
		Show = not me:IsVisible();
	end
	if ( Show ) then
		me:Show();
	else
		me:Hide();
	end
end
--[[****************************************************************************
  * Function: _UTF.Browse.ToggleSlashCommand                                   *
  * Description: Slash command that toggles the _UTF window.                   *
  ****************************************************************************]]
function me.ToggleSlashCommand ()
	me.Toggle();
end




--[[****************************************************************************
  * Function: _UTF.Browse:OnHide                                               *
  * Description: Plays a closing sound when the _UTF window is closed.         *
  ****************************************************************************]]
function me:OnHide ()
	PlaySound( "igCharacterInfoClose" );
end
--[[****************************************************************************
  * Function: _UTF.Browse:OnShow                                               *
  * Description: Plays an opening sound when the _UTF window is opened.        *
  ****************************************************************************]]
function me:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetWidth( 200 );
	me:SetHeight( 192 );
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
	me.Title:SetPoint( "TOPLEFT", me, 11, -6 );

	me:SetScript( "OnHide", me.OnHide );
	me:SetScript( "OnShow", me.OnShow );

	SlashCmdList[ "UTFTOGGLE" ] = me.ToggleSlashCommand;
end
