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
  * Function: _Clean.BlizzardBattlefieldMinimap:DropDownInitialize             *
  * Description: Disables obsolete buttons from dropdown menus.                *
  ****************************************************************************]]
function me:DropDownInitialize ()
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
  * Function: _Clean.BlizzardBattlefieldMinimap:SetPoint                       *
  * Description: Blocks unauthorized SetPoint calls.                           *
  ****************************************************************************]]
do
	local Disabled = false;
	function me:SetPoint ( ... )
		if ( not Disabled ) then -- Restore alpha
			Disabled = true;
			self:ClearAllPoints();
			self:SetPoint( "BOTTOMRIGHT", ChatFrame2Tab, "BOTTOMLEFT", 2, 0 );
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
	UIDropDownMenu_SetText( WorldMapZoneMinimapDropDown,
		WorldMapZoneMinimapDropDown_GetText( SHOW_BATTLEFIELD_MINIMAP ) );
end
--[[****************************************************************************
  * Function: _Clean.BlizzardBattlefieldMinimap.SetOpacity                     *
  * Description: Undoes custom alpha changes to the close button.              *
  ****************************************************************************]]
function me.SetOpacity ()
	BattlefieldMinimapCloseButton:SetAlpha( 0.5 );
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

		local function ShrinkTabBorder ( Texture )
			local Left, Top, _, _, Right = Texture:GetTexCoord();
			Texture:SetTexCoord( Left, Right, Top, 0.9 );
		end
		ShrinkTabBorder( BattlefieldMinimapTabLeft );
		ShrinkTabBorder( BattlefieldMinimapTabMiddle );
		ShrinkTabBorder( BattlefieldMinimapTabRight );

		BattlefieldMinimapCloseButton:ClearAllPoints();
		BattlefieldMinimapCloseButton:SetPoint( "RIGHT", BattlefieldMinimapTabText, "LEFT", 8, -2 );
		BattlefieldMinimapCloseButton:SetFrameStrata( "MEDIUM" ); -- Just higher than tab
		BattlefieldMinimapCloseButton:SetScale( 0.6 );
		_Clean.AddLockedButton( BattlefieldMinimapCloseButton );

		-- Disable movement
		BattlefieldMinimapTab:RegisterForDrag();
		BattlefieldMinimapTab:RegisterForClicks( "RightButtonUp" );
		_Clean.AddLockedButton( BattlefieldMinimapTab );
		hooksecurefunc( "BattlefieldMinimapDropDown_Initialize",
			me.DropDownInitialize );
		hooksecurefunc( BattlefieldMinimapTab, "SetPoint", me.SetPoint );

		-- Lock the tab's alpha
		DEFAULT_BATTLEFIELD_TAB_ALPHA = 0.5;
		BattlefieldMinimapTab:SetAlpha( DEFAULT_BATTLEFIELD_TAB_ALPHA );
		hooksecurefunc( BattlefieldMinimapTab, "SetAlpha", me.SetAlpha );
		hooksecurefunc( "BattlefieldMinimap_SetOpacity", me.SetOpacity );

		-- Lock show in battlegrounds setting
		me.DropDownUpdate();
		hooksecurefunc( "WorldMapZoneMinimapDropDown_Update", me.DropDownUpdate );
	end );
end
