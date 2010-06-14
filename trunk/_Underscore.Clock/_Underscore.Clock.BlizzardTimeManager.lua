--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * _Underscore.Clock.BlizzardTimeManager.lua - Hides Blizzard_TimeManager.    *
  ****************************************************************************]]


_Underscore.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
	-- Move time button on top of time text
	TimeManagerClockButton:SetAlpha( 0 );
	TimeManagerClockButton:SetAllPoints( _Underscore.Clock.Text );
	TimeManagerClockButton:SetScript( "OnEnter", nil );
	TimeManagerClockButton:SetScript( "OnLeave", nil );

	_Underscore.AddLockedButton( TimeManagerClockButton );
end );