--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Crosshairs.lua - Adds crosshairs to the viewport.          *
  ****************************************************************************]]


local me = CreateFrame( "Frame", nil, WorldFrame );
select( 2, ... ).Crosshairs = me;




do
	local Backup = Screenshot;
	--- Hide the crosshairs just before screenshots are taken.
	function me.Screenshot ( ... )
		me:Hide();
		return Backup( ... );
	end
end

--- Reshows the crosshairs after a screenshot is taken.
function me:OnEvent ()
	-- SCREENSHOT_SUCCEEDED / SCREENSHOT_FAILED
	self:Show();
end




Screenshot = me.Screenshot;
me:SetScript( "OnEvent", me.OnEvent );
me:RegisterEvent( "SCREENSHOT_FAILED" );
me:RegisterEvent( "SCREENSHOT_SUCCEEDED" );

me:SetFrameStrata( "BACKGROUND" );
me:SetPoint( "CENTER" );
me:SetSize( 32, 32 );
me:SetAlpha( 0.75 );

local Texture = me:CreateTexture( nil, "ARTWORK" );
Texture:SetAllPoints();
Texture:SetTexture( [[Interface\AddOns\]]..( ... )..[[\Skin\Crosshairs]] );
Texture:SetTexCoord( 1, 0, 1, 0 ); -- Note: For some reason, flipping it makes it sharper
Texture:SetVertexColor( unpack( _Underscore.Colors.Highlight ) );