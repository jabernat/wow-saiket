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




--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.DropDownInitialize             *
  * Description: Disables obsolete buttons from dropdown menus.                *
  ****************************************************************************]]
function me.DropDownInitialize ()
	for ButtonIndex = 1, DropDownList1.numButtons do
		local Button = _G[ "DropDownList1Button"..ButtonIndex ];
		if ( Button.value == LOCK_BATTLEFIELDMINIMAP ) then
			Button:Disable();
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap:SetAlpha                       *
  * Description: Blocks unauthorized SetAlpha calls.                           *
  ****************************************************************************]]
do
	local Disabled = false;
	function me:SetAlpha ( Alpha )
		if ( not Disabled ) then -- Restore alpha
			Disabled = true;
			self:SetAlpha( DEFAULT_BATTLEFIELD_TAB_ALPHA );
			Disabled = false;
		end
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
	BattlefieldMinimapTab:ClearAllPoints();
	BattlefieldMinimapTab:SetPoint( "RIGHT", ChatFrame2Tab, "LEFT", 2, 0 );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	UIDropDownMenu_DisableDropDown( WorldMapZoneMinimapDropDown );

	_Clean.RegisterAddOnInitializer( "Blizzard_BattlefieldMinimap", function ()
		BattlefieldMinimap:DisableDrawLayer( "BORDER" );
		BattlefieldMinimap:DisableDrawLayer( "OVERLAY" );
		BattlefieldMinimap:SetAlpha( 0.5 );

		-- Set up the tab and close buttons
		BattlefieldMinimap:ClearAllPoints();
		BattlefieldMinimap:SetPoint( "BOTTOMRIGHT", ChatFrame2, "TOPRIGHT", 6, -1 );

		_Clean:AddPositionManager( me.TabManager );
		me.TabManager();
		BattlefieldMinimap:UnregisterEvent( "ADDON_LOADED" );
		BattlefieldMinimapTab:SetUserPlaced( true );

		BattlefieldMinimapCloseButton:ClearAllPoints();
		BattlefieldMinimapCloseButton:SetPoint( "RIGHT", BattlefieldMinimapTabText, "LEFT", 8, 0 );
		BattlefieldMinimapCloseButton:SetFrameStrata( "MEDIUM" ); -- Just higher than tab
		BattlefieldMinimapCloseButton:SetScale( 0.6 );
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
	end );
end
