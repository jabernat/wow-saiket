--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BlizzardTimeManager.lua - Modifies the Blizzard_TimeManager addon.  *
  *                                                                            *
  * + Removes the small time plate from the minimap.                           *
  ****************************************************************************]]




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
		TimeManagerClockButton:Hide();
		TimeManagerClockButton_Show = _Clean.NilFunction;
	end );
end
