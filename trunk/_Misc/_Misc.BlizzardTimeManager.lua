--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.BlizzardTimeManager.lua - Modifies the Blizzard_TimeManager addon.   *
  *                                                                            *
  * + Moves the small time plate from the minimap.                             *
  ****************************************************************************]]




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
		-- Move time button on top of time text
		TimeManagerClockButton:SetAlpha( 0 );
		TimeManagerClockButton:SetAllPoints( _Misc.Time.Text );
		TimeManagerClockButton:SetScript( "OnEnter", nil );
		TimeManagerClockButton:SetScript( "OnLeave", nil );
	end );
end
