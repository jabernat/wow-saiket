--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.General.lua - General or minor modifications to the UI.             *
  *                                                                            *
  * + Moves the default tooltip position to the top center of the screen.      *
  * + Moves the GM ticket frame.                                               *
  * + Moves the pet bar and posession bar.                                     *
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
  * Function: _Clean.General.PetBarManager                                     *
  * Description: Manages the pet bar's position.                               *
  ****************************************************************************]]
function me.PetBarManager ()
	if ( PetActionBarFrame:IsShown() ) then
		_Clean:RunProtectedFunction( function ()
			PetActionBarFrame:ClearAllPoints();
			PetActionBarFrame:SetPoint( "CENTER", UIParent );
			PetActionBarFrame:SetPoint( "BOTTOM", ChatFrame1, "TOP" );
		end, PetActionBarFrame:IsProtected() );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	PossessBarFrame:ClearAllPoints();
	PossessBarFrame:SetPoint( "BOTTOMLEFT", MultiBarBottomLeftButton1, "TOPLEFT" );

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
	Button:SetScript( "OnClick", ToggleHelpFrame );
	LoadMicroButtonTextures( Button, "Help" );
	Button.tooltipText = HELP_BUTTON;
	Button.newbieText = NEWBIE_TOOLTIP_HELP;

	UIPARENT_MANAGED_FRAME_POSITIONS[ "PossessBarFrame" ] = nil;
	_Clean:AddPositionManager( me.PetBarManager );
	hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.GameTooltipSetDefaultAnchor );
end
