--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.Grid.lua - Modifies the Grid addon.                                 *
  *                                                                            *
  * + Adds support for unit popup menus to Grid frames.                        *
  ****************************************************************************]]


local L = _UnitsLocalization;
local _Units = _Units;
local me = {};
_Units.Grid = me;




--[[****************************************************************************
  * Function: _Units.Grid:GridFrameInitialize                                  *
  * Description: Hook to modify new GridFrames.                                *
  ****************************************************************************]]
function me:GridFrameInitialize ()
	self.menu = _Units.ShowGenericMenu;
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Units.RegisterAddOnInitializer( "Grid", function ()
		-- Hook Grid frame creation
		hooksecurefunc( GridFrame, "InitialConfigFunction", me.GridFrameInitialize );

		-- Add hook to all existing frames
		GridFrame:WithAllFrames( function ( self ) me.GridFrameInitialize( self.frame ); end );

		-- Add better layouts that include pets from all classes
		GridLayout:AddLayout( L.GRID_LAYOUT_CLASS, {
			{
				--groupFilter = "WARLOCK,HUNTER",
				isPetGroup = true,
				filterOnPet = true,
			},
			{ groupFilter = "WARRIOR"; },
			{ groupFilter = "PRIEST"; },
			{ groupFilter = "DRUID"; },
			{ groupFilter = "PALADIN"; },
			{ groupFilter = "SHAMAN"; },
			{ groupFilter = "MAGE"; },
			{ groupFilter = "WARLOCK"; },
			{ groupFilter = "HUNTER"; },
			{ groupFilter = "ROGUE"; },
			{ groupFilter = "DEATHKNIGHT"; },
		} );
		GridLayout:AddLayout( L.GRID_LAYOUT_GROUP, {
			{
				--groupFilter = "WARLOCK,HUNTER",
				isPetGroup = true,
				filterOnPet = true,
			},
			{ groupFilter = "1"; },
			{ groupFilter = "2"; },
			{ groupFilter = "3"; },
			{ groupFilter = "4"; },
			{ groupFilter = "5"; },
			{ groupFilter = "6"; },
			{ groupFilter = "7"; },
			{ groupFilter = "8"; },
		} );
	end );
end
