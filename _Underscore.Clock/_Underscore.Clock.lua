--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * _Underscore.Clock.lua - Adds a clock to the top left of the viewport.      *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.Clock = me;

local UPDATE_INTERVAL = 0.2;

me.Text = UIParent:CreateFontString( nil, "BACKGROUND", "NumberFontNormalSmall" );
local Updater = me.Text:CreateAnimationGroup();




do
	local date = date;
	--- Updates the clock text.
	function Updater:OnLoop ()
		-- Avoid putting a full time string into the Lua string table
		me.Text:SetFormattedText( me.L.TIME_FORMAT, date( "%H" ), date( "%M" ), date( "%S" ) );
	end
end




Updater:CreateAnimation( "Animation" ):SetDuration( UPDATE_INTERVAL );
Updater:SetLooping( "REPEAT" );
Updater:SetScript( "OnLoop", Updater.OnLoop );
Updater:OnLoop();
Updater:Play();

me.Text:SetPoint( "TOPLEFT", WorldFrame );
me.Text:SetAlpha( 0.5 );
if ( IsAddOnLoaded( "_Underscore.Font" ) ) then
	me.Text:SetFontObject( _Underscore.Font.MonospaceNumber );
end

_Underscore.RegisterAddOnInitializer( "_Dev", function ()
	_Dev.Stats:ClearAllPoints();
	_Dev.Stats:SetPoint( "TOPLEFT", me.Text, "TOPRIGHT" );
end );