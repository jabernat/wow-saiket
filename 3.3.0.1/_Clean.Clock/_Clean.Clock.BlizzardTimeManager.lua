--[[****************************************************************************
  * _Clean.Clock by Saiket                                                     *
  * _Clean.Clock.BlizzardTimeManager.lua - Hides the Blizzard_TimeManager mod. *
  ****************************************************************************]]




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
		-- Move time button on top of time text
		TimeManagerClockButton:SetAlpha( 0 );
		TimeManagerClockButton:SetAllPoints( _Clean.Clock.Text );
		TimeManagerClockButton:SetScript( "OnEnter", nil );
		TimeManagerClockButton:SetScript( "OnLeave", nil );

		_Clean.AddLockedButton( TimeManagerClockButton );
	end );
end
