--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.Grid.lua - Modifies the Grid addon.                                 *
  *                                                                            *
  * + Adds support for unit popup menus to Grid frames.                        *
  ****************************************************************************]]


local _Units = _Units;
local me = {
	DropDown = nil;
};
_Units.Grid = me;




--[[****************************************************************************
  * Function: _Units.Grid.InitializeGenericMenu                                *
  * Description: Constructs the unit popup menu.                               *
  ****************************************************************************]]
function me.InitializeGenericMenu ()
	local UnitID = me.DropDown.unit or "player";
	local Which, Name, ID;

	if ( UnitIsUnit( UnitID, "player" ) ) then
		Which = "SELF";
	elseif ( UnitIsUnit( UnitID, "pet" ) ) then
		Which = "PET";
	elseif ( UnitIsPlayer( UnitID ) ) then
		ID = UnitInRaid( UnitID );
		if ( ID ) then
			Which = "RAID_PLAYER";
		elseif ( UnitInParty( UnitID ) ) then
			Which = "PARTY";
		else
			Which = "PLAYER";
		end
	else
		Which = "RAID_TARGET_ICON";
		Name = RAID_TARGET_ICON;
	end
	if ( Which ) then
		UnitPopup_ShowMenu( me.DropDown, Which, UnitID, Name, ID );
	end
end
--[[****************************************************************************
  * Function: _Units.Grid:ShowGenericMenu                                      *
  * Description: Adds a unit popup based on the unit.                          *
  ****************************************************************************]]
function me:ShowGenericMenu ( unit, button, anchor )
	HideDropDownMenu( 1 );

	me.DropDown.unit = unit or SecureButton_GetUnit( self );

	if ( me.DropDown.unit ) then
		ToggleDropDownMenu( 1, nil, me.DropDown, "cursor" );
	end
end
--[[****************************************************************************
  * Function: _Units.Grid:GridFrameInitialize                                  *
  * Description: Hook to modify new GridFrames.                                *
  ****************************************************************************]]
function me:GridFrameInitialize ()
	self.menu = me.ShowGenericMenu;
end


--[[****************************************************************************
  * Function: _Units.Grid.OnLoad                                               *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	-- Create dropdown menu
	me.DropDown = CreateFrame(
		"Frame", "_UnitsGridDropDown", UIParent, "UIDropDownMenuTemplate" );
	tinsert( UnitPopupFrames, me.DropDown:GetName() );
	UIDropDownMenu_Initialize( me.DropDown, me.InitializeGenericMenu, "MENU" );


	-- Hook Grid frames
	hooksecurefunc( GridFrame, "InitialConfigFunction", me.GridFrameInitialize );

	-- Add hook to all existing frames
	GridFrame:WithAllFrames(
		function ( self ) me.GridFrameInitialize( self.frame ); end );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Units.RegisterAddOnInitializer( "Grid", me.OnLoad );
end
