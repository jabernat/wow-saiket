--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * _Underscore.Clock.BlizzardTimeManager.lua - Hides Blizzard_TimeManager.    *
  ****************************************************************************]]


local NS = select( 2, ... );
_Underscore.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
	-- Move time button on top of time text
	local Button = TimeManagerClockButton;
	Button:SetAlpha( 0 );
	Button:SetAllPoints( NS.Text );
	Button:SetScript( "OnEnter", nil );
	Button:SetScript( "OnLeave", nil );

	_Underscore.AddLockedButton( Button );
end );