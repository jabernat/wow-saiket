--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.Grid.lua - Modifies the Grid addon.                                 *
  *                                                                            *
  * + Adds support for unit popup menus to Grid frames.                        *
  ****************************************************************************]]


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


--[[****************************************************************************
  * Function: _Units.Grid.OnLoad                                               *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	-- Hook Grid frames
	hooksecurefunc( GridFrame, "InitialConfigFunction", me.GridFrameInitialize );

	-- Add hook to all existing frames
	GridFrame:WithAllFrames( function ( self ) me.GridFrameInitialize( self.frame ); end );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Units.RegisterAddOnInitializer( "Grid", me.OnLoad );
end
