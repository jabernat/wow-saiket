--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * _Underscore.Clock.BlizzardTimeManager.lua - Hides Blizzard_TimeManager.    *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.RegisterAddOnInitializer( "Blizzard_TimeManager", function ()
	-- Move time button on top of time text
	local Button = TimeManagerClockButton;
	Button:SetAlpha( 0 );
	Button:SetAllPoints( me.Text );
	Button:SetScript( "OnEnter", nil );
	Button:SetScript( "OnLeave", nil );

	_Underscore.AddLockedButton( Button );
end );