--[[****************************************************************************
  * _Clean.Clock by Saiket                                                     *
  * _Clean.Clock.lua - Adds a clock to the top left of the viewport.           *
  ****************************************************************************]]


local L = _CleanLocalization.Clock;
local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, UIParent );
_Clean.Clock = me;

me.Text = me:CreateFontString( nil, "BACKGROUND", "NumberFontNormalSmall" )

me.UpdateRate = 0.2;




--[[****************************************************************************
  * Function: _Clean.Clock:OnUpdate                                            *
  ****************************************************************************]]
do
	local date = date;
	local NextUpdate = 0;
	function me:OnUpdate ( Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = me.UpdateRate;

			-- Avoid putting a full time string into the Lua string table
			me.Text:SetFormattedText( L.TIME_FORMAT, date( "%H" ), date( "%M" ), date( "%S" ) );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );

	me.Text:SetPoint( "TOPLEFT", WorldFrame );
	me.Text:SetAlpha( 0.5 );
	if ( IsAddOnLoaded( "_Clean.Font" ) ) then
		me.Text:SetFontObject( _Clean.Font.MonospaceNumber );
	end

	_Clean.RegisterAddOnInitializer( "_Dev", function ()
		_Dev.Stats:ClearAllPoints();
		_Dev.Stats:SetPoint( "TOPLEFT", me.Text, "TOPRIGHT" );
	end );
end
