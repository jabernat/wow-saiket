--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardBattlefieldMinimap.lua - Modifies the                       *
  *   Blizzard_BattlefieldMinimap addon.                                       *
  *                                                                            *
  * + Removes the border and close button from the map.                        *
  * + Anchors map near chat frame and lowers overall opacity.                  *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.BlizzardBattlefieldMinimap = me;

me.EnableSetAlpha = false;




--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.DropDownInitialize             *
  * Description: Disables obsolete buttons from dropdown menus.                *
  ****************************************************************************]]
function me.DropDownInitialize ()
	for ButtonIndex = 1, DropDownList1.numButtons do
		local Button = _G[ "DropDownList1Button"..ButtonIndex ];
		if ( Button.value == LOCK_BATTLEFIELDMINIMAP ) then
			_Clean.RunProtectedMethod( Button, "Disable" );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap:SetAlpha                       *
  * Description: Blocks unauthorized SetAlpha calls.                           *
  ****************************************************************************]]
function me:SetAlpha ( Alpha )
	if ( not me.EnableSetAlpha ) then -- Restore alpha
		me.EnableSetAlpha = true;
		self:SetAlpha( DEFAULT_BATTLEFIELD_TAB_ALPHA );
		me.EnableSetAlpha = false;
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.DropDownUpdate                 *
  * Description: Hooks zone map view selection to only allow in battlegrounds. *
  ****************************************************************************]]
function me.DropDownUpdate ()
	SHOW_BATTLEFIELD_MINIMAP = "1"; -- Show in battlegrounds

	UIDropDownMenu_SetSelectedValue( WorldMapZoneMinimapDropDown,
		SHOW_BATTLEFIELD_MINIMAP );
	UIDropDownMenu_SetText(
		WorldMapZoneMinimapDropDown_GetText( SHOW_BATTLEFIELD_MINIMAP ),
		WorldMapZoneMinimapDropDown );
end

--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.TabManager                     *
  * Description: Repositions the battlefield minimap tab.                      *
  ****************************************************************************]]
function me.TabManager ()
	_Clean.ClearAllPoints( BattlefieldMinimapTab );
	_Clean.SetPoint( BattlefieldMinimapTab,
		"RIGHT", ChatFrame2Tab, "LEFT", 2, 0 );
end


--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.OnLoad                         *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	BattlefieldMinimap:DisableDrawLayer( "BORDER" );
	BattlefieldMinimap:DisableDrawLayer( "OVERLAY" );
	BattlefieldMinimap:SetAlpha( 0.5 );

	-- Set up the tab and close buttons
	_Clean.ClearAllPoints( BattlefieldMinimap );
	_Clean.SetPoint( BattlefieldMinimap,
		"BOTTOMRIGHT", ChatFrame2, "TOPRIGHT", 6, -1 );

	_Clean.AddPositionManager( me.TabManager );
	me.TabManager();
	BattlefieldMinimap:UnregisterEvent( "ADDON_LOADED" );
	BattlefieldMinimapTab:SetUserPlaced( true );

	_Clean.ClearAllPoints( BattlefieldMinimapCloseButton );
	_Clean.SetPoint( BattlefieldMinimapCloseButton,
		"RIGHT", BattlefieldMinimapTabText, "LEFT", 8, 0 );
	_Clean.RunProtectedMethod( BattlefieldMinimapCloseButton,
		"SetFrameStrata", "MEDIUM" ); -- Just higher than tab
	_Clean.RunProtectedMethod( BattlefieldMinimapCloseButton, "SetScale", 0.6 );
	_Clean.AddLockedButton( BattlefieldMinimapCloseButton );

	-- Disable movement
	BattlefieldMinimapTab:RegisterForDrag();
	BattlefieldMinimapTab:RegisterForClicks( "RightButtonUp" );
	_Clean.AddLockedButton( BattlefieldMinimapTab );
	hooksecurefunc( "BattlefieldMinimapDropDown_Initialize",
		me.DropDownInitialize );

	-- Lock the tab's alpha
	DEFAULT_BATTLEFIELD_TAB_ALPHA = 0.5;
	BattlefieldMinimapTab:SetAlpha( DEFAULT_BATTLEFIELD_TAB_ALPHA );
	hooksecurefunc( BattlefieldMinimapTab, "SetAlpha", me.SetAlpha );

	-- Lock show in battlegrounds setting
	me.DropDownUpdate();
	hooksecurefunc( "WorldMapZoneMinimapDropDown_Update", me.DropDownUpdate );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_BattlefieldMinimap", me.OnLoad );

	UIDropDownMenu_DisableDropDown( WorldMapZoneMinimapDropDown );
end
