--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.MainMenuBar.lua - Remove some unnecessary elements and reposition   *
  *   the experience and reputation bars.                                      *
  *                                                                            *
  * + Lines the bottom of the screen with the experience and reputation watch  *
  *   bars, and pushes the rest of the interface up when they're visible.      *
  * + Removes lots of unnecessary artwork from the main menu bar and allows    *
  *   mouseclicks to pass through it.                                          *
  * + Removes the latency graphic.                                             *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {
	StatusBarHeight = 10;
};
_Clean.MainMenuBar = me;




--[[****************************************************************************
  * Function: _Clean.MainMenuBar.PositionBarTextures                           *
  * Description: Positions four textures along a status bar so that they will  *
  *   stretch correctly when the bar is resized.                               *
  ****************************************************************************]]
function me.PositionBarTextures ( Bar, ... )
	local Left = Bar:CreateTexture();
	local Right = Bar:CreateTexture();
	Left:SetPoint( "TOPLEFT", Bar );
	Left:SetPoint( "BOTTOMRIGHT", Bar, "BOTTOM" );
	Right:SetPoint( "TOPRIGHT", Bar );
	Right:SetPoint( "BOTTOMLEFT", Bar, "BOTTOM" );

	for Index = 1, select( "#", ... ) do
		local Texture = select( Index, ...);
		local Parent = Index > 2 and Right or Left;
		local Even = mod( Index - 1, 2 ) == 0;

		Texture:ClearAllPoints();
		Texture:SetPoint( "TOPLEFT", Parent, not Even and "TOP" );
		Texture:SetPoint( "BOTTOMRIGHT", Parent, Even and "BOTTOM" );
		Texture:SetBlendMode( "ADD" );
		Texture:SetVertexColor( 1, 1, 1, 0.25 );
	end
end


--[[****************************************************************************
  * Function: _Clean.MainMenuBar.ReputationWatchBarUpdate                      *
  * Description: Repositions the reputation and experience bars. (Hooks        *
  *   ReputationWatchBar_Update.)                                              *
  ****************************************************************************]]
function me.ReputationWatchBarUpdate ( NewLevel )
	if ( ReputationWatchBar:IsShown() ) then
		_Clean.ClearAllPoints( ReputationWatchBar );
		_Clean.SetPoint( ReputationWatchBar, "BOTTOMLEFT", MainMenuExpBar,
			MainMenuExpBar:IsShown() and "TOPLEFT" or "BOTTOMLEFT" );
		_Clean.SetPoint( ReputationWatchBar, "RIGHT", MainMenuExpBar );
	end

	for Index = 0, 3 do
		_Clean.RunProtectedMethod( _G[ "ReputationWatchBarTexture"..Index ], "Show" );
		_Clean.RunProtectedMethod( _G[ "ReputationXPBarTexture"..Index ], "Hide" );
	end
	_Clean.RunProtectedMethod( ReputationWatchStatusBarText, "Show" ); -- Keeps it visible even when the exp bar is shown
end


--[[****************************************************************************
  * Function: _Clean.MainMenuBar.ExhaustionTickUpdate                          *
  * Description: Repositions the exhaustion fill bar. (Hooks                   *
  *   ExhaustionTick_Update.)                                                  *
  ****************************************************************************]]
function me.ExhaustionTickUpdate ()
	if ( this:IsShown() ) then
		_Clean.SetPoint( ExhaustionLevelFillBar, "RIGHT", this );
	end
end


--[[****************************************************************************
  * Function: _Clean.MainMenuBar.MenuBarManager                                *
  * Description: Manages the menu bar's position.                              *
  ****************************************************************************]]
function me.MenuBarManager ()
	-- Move the whole UI up to accomodate reputation and experience bars
	local Offset = ( ReputationWatchBar:IsShown() and me.StatusBarHeight or 0 )
		+ ( MainMenuExpBar:IsShown() and me.StatusBarHeight or 0 );
	_Clean.ClearAllPoints( ActionButton1 );
	_Clean.SetPoint( ActionButton1, "BOTTOMLEFT", UIParent, 0, Offset );

	_Clean.ClearAllPoints( MainMenuBarBackpackButton );
	_Clean.SetPoint( MainMenuBarBackpackButton, "BOTTOM", ActionButton1 );
	_Clean.SetPoint( MainMenuBarBackpackButton, "RIGHT", UIParent, 1, 0 );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	MainMenuBar:EnableMouse( false );

	-- Bags
	local LastButton = MainMenuBarBackpackButton;
	MainMenuBarBackpackButtonIconTexture:SetTexCoord( 0.08, 0.92, 0.08, 0.92 );
	MainMenuBarBackpackButtonNormalTexture:SetTexture();
	for Index = 0, 3 do
		local Button = _G[ "CharacterBag"..Index.."Slot" ];
		Button:SetPoint( "RIGHT", LastButton, "LEFT", 1, 0 );
		_G[ "CharacterBag"..Index.."SlotIconTexture" ]:SetTexCoord( 0.08, 0.92, 0.08, 0.92 );
		_G[ "CharacterBag"..Index.."SlotNormalTexture" ]:SetTexture();
		LastButton = Button;
	end
	-- Keyring
	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint( "LEFT", CharacterBag3Slot );
	KeyRingButton:SetParent( CharacterBag3Slot );
	KeyRingButton:SetWidth( 12 );
	KeyRingButton:GetNormalTexture():SetTexCoord( 0.15, 0.45, 0.1, 0.52 );

	-- Lag-o-meter
	MainMenuBarPerformanceBar:Hide();
	MainMenuBarPerformanceBarFrameButton:Hide();

	-- Experience and Reputation Bars
	MainMenuExpBar:EnableMouse( false );
	MainMenuExpBar:ClearAllPoints();
	MainMenuExpBar:SetPoint( "BOTTOMLEFT", UIParent );
	MainMenuExpBar:SetPoint( "RIGHT", UIParent );
	MainMenuExpBar:SetWidth( 0 );
	MainMenuExpBar:SetHeight( _Clean.MainMenuBar.StatusBarHeight );
	MainMenuBarExpText:SetFontObject( NumberFontNormalSmall );

	ReputationWatchBar:EnableMouse( false );
	ReputationWatchBar:SetHeight( _Clean.MainMenuBar.StatusBarHeight );
	ReputationWatchStatusBar:SetAllPoints( ReputationWatchBar );
	ReputationWatchStatusBarText:SetFontObject( NumberFontNormalSmallGray );

	ExhaustionTick:EnableMouse( false );
	MainMenuBarMaxLevelBar:EnableMouse( false );

	-- Move the grid lines on the progress bars to match the new size
	me.PositionBarTextures( MainMenuExpBar,
		MainMenuXPBarTexture0,
		MainMenuXPBarTexture1,
		MainMenuXPBarTexture2,
		MainMenuXPBarTexture3 );
	me.PositionBarTextures( ReputationWatchStatusBar,
		ReputationWatchBarTexture0,
		ReputationWatchBarTexture1,
		ReputationWatchBarTexture2,
		ReputationWatchBarTexture3 );

	-- Remove artwork
	for Index = 0, 3 do
		local Texture = _G[ "MainMenuBarTexture"..Index ];
		Texture:SetTexture();
		Texture:Hide();
		Texture = _G[ "MainMenuMaxLevelBar"..Index ];
		Texture:SetTexture();
		Texture:Hide();
		_G[ "ReputationXPBarTexture"..Index ]:SetTexture();
	end
	-- Gryphons
	MainMenuBarLeftEndCap:Hide();
	MainMenuBarRightEndCap:Hide();


	-- Hide the action bar set-changing arrow buttons and number
	ActionBarUpButton:Hide();
	ActionBarDownButton:Hide();
	MainMenuBarPageNumber:Hide();
	-- Hide the cluster of UI panel buttons
	CharacterMicroButton:ClearAllPoints();
	CharacterMicroButton:SetPoint( "TOP", UIParent, "BOTTOM" );

	-- Add the help frame's button to the main game menu, just to the right of its title
	HelpMicroButton:SetParent( GameMenuFrame );
	HelpMicroButton:ClearAllPoints();
	HelpMicroButton:SetPoint( "TOPLEFT", GameMenuFrameHeader, "TOPRIGHT", -GameMenuFrameHeader:GetWidth() / 4, 19 );
	HelpMicroButton:SetAlpha( 1.0 );


	-- Hooks
	_Clean.AddPositionManager( me.MenuBarManager );
	hooksecurefunc( "ExhaustionTick_Update", me.ExhaustionTickUpdate );
	hooksecurefunc( "ReputationWatchBar_Update", me.ReputationWatchBarUpdate );
end
