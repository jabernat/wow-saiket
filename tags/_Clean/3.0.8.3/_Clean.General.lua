--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.General.lua - General or minor modifications to the UI.             *
  ****************************************************************************]]


local _Clean = _Clean;
local L = _CleanLocalization;
local me = {};
_Clean.General = me;




--[[****************************************************************************
  * Function: _Clean.General.GameTooltipSetDefaultAnchor                       *
  * Description: Moves the default tooltip position to the top center.         *
  ****************************************************************************]]
function me:GameTooltipSetDefaultAnchor ( Parent )
	self:ClearAllPoints();
	self:SetPoint( "TOP", UIParent, 0, -2 );
end


--[[****************************************************************************
  * Function: _Clean.General.UpdateDurabilityFrame                             *
  * Description: Moves the durability frame to the center of the bottom pane.  *
  ****************************************************************************]]
function me.UpdateDurabilityFrame ()
	DurabilityFrame:ClearAllPoints();
	DurabilityFrame:SetPoint( "CENTER", _Clean.BottomPane );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Fix the small number font to use antialiasing
	local Path, Height, Flags = NumberFontNormalSmall:GetFont();
	Flags = Flags:gsub( ", ([A-Z]+)", { [ "MONOCHROME" ] = ""; [ "THICKOUTLINE" ] = ""; } );
	NumberFontNormalSmall:SetFont( Path, Height, Flags );

	-- Move and shrink the GM ticket frame
	TicketStatusFrame:ClearAllPoints();
	TicketStatusFrame:SetPoint( "TOPRIGHT", Minimap, "TOPLEFT", -8, 0 );
	TicketStatusFrame:SetScale( 0.85 );
	TicketStatusFrame:SetAlpha( 0.75 );

	-- Add a button to open the help window to the main menu
	local Button = CreateFrame( "Button", "_CleanHelpButton", GameMenuFrame, "MainMenuBarMicroButton" );
	Button:SetPoint( "TOPRIGHT", GameMenuFrame, -50, 28 );
	Button:SetScale( 0.7 );
	Button:SetFrameLevel( Button:GetFrameLevel() + 1 ); -- Raise above other buttons in the menu
	Button:SetScript( "OnClick", ToggleHelpFrame );
	LoadMicroButtonTextures( Button, "Help" );
	Button.tooltipText = HELP_BUTTON;
	Button.newbieText = NEWBIE_TOOLTIP_HELP;

	-- Move the durability frame to the middle
	hooksecurefunc( "UIParent_ManageFramePositions", me.UpdateDurabilityFrame );
	me.UpdateDurabilityFrame();

	hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.GameTooltipSetDefaultAnchor );

	-- Pad class icons
	local IconPadding = 0.08 / 4; -- Icons are in a 4x4 grid
	for _, Coords in pairs( CLASS_BUTTONS ) do
		Coords[ 1 ] = Coords[ 1 ] + IconPadding;
		Coords[ 2 ] = Coords[ 2 ] - IconPadding;
		Coords[ 3 ] = Coords[ 3 ] + IconPadding;
		Coords[ 4 ] = Coords[ 4 ] - IconPadding;
	end
end
