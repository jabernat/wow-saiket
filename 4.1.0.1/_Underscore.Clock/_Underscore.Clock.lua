--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * _Underscore.Clock.lua - Adds a clock to the top left of the viewport.      *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.Clock = me;

me.Frame = CreateFrame( "Frame", nil, UIParent );
me.Text = me.Frame:CreateFontString( nil, "BACKGROUND", "NumberFontNormalSmall" )

me.UpdateRate = 0.2;




do
	local date = date;
	local NextUpdate = 0;
	--- Updates the clock text.
	function me.Frame:OnUpdate ( Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = me.UpdateRate;

			-- Avoid putting a full time string into the Lua string table
			me.Text:SetFormattedText( me.L.TIME_FORMAT, date( "%H" ), date( "%M" ), date( "%S" ) );
		end
	end
end




me.Frame:SetScript( "OnUpdate", me.Frame.OnUpdate );

me.Text:SetPoint( "TOPLEFT", WorldFrame );
me.Text:SetAlpha( 0.5 );
if ( IsAddOnLoaded( "_Underscore.Font" ) ) then
	me.Text:SetFontObject( _Underscore.Font.MonospaceNumber );
end

_Underscore.RegisterAddOnInitializer( "_Dev", function ()
	_Dev.Stats:ClearAllPoints();
	_Dev.Stats:SetPoint( "TOPLEFT", me.Text, "TOPRIGHT" );
end );