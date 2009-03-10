--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.PitBull.lua - Modifies the PitBull addon.                           *
  *                                                                            *
  * + Adds support for unit popup menus to miscellaneous PitBull frames.       *
  ****************************************************************************]]


if ( select( 6, GetAddOnInfo( "PitBull" ) ) == "MISSING" ) then
	return;
end
local _Units = _Units;
local me = {};
_Units.PitBull = me;




--[[****************************************************************************
  * Function: _Units.PitBull.CreateUnitFrame                                   *
  * Description: Hook to modify new PitBull frames.                            *
  ****************************************************************************]]
do
	local function VarArg ( Frame, ... )
		Frame.menu = _Units.ShowGenericMenu;
		return Frame, ...;
	end
	function me.CreateUnitFrame ( ... )
		return VarArg( me.CreateUnitFrameBackup( ... ) );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Units.RegisterAddOnInitializer( "PitBull", function ()
		-- Hook PitBull frame creation
		me.CreateUnitFrameBackup = PitBull.CreateUnitFrame;
		PitBull.CreateUnitFrame = me.CreateUnitFrame;

		-- Add hook to all existing frames
		local Index = 1;
		local Frame = PitBullUnitFrame1;
		while ( Frame ) do
			Frame.menu = _Units.ShowGenericMenu;
	
			Index = Index + 1;
			Frame = _G[ "PitBullUnitFrame"..Index ];
		end
	end );
end
