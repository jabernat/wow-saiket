--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Crosshairs.lua - Adds crosshairs to the viewport.          *
  ****************************************************************************]]


local NS = CreateFrame( "Frame", nil, WorldFrame );
select( 2, ... ).Crosshairs = NS;




do
	local Backup = Screenshot;
	--- Hide the crosshairs just before screenshots are taken.
	function NS.Screenshot ( ... )
		NS:Hide();
		return Backup( ... );
	end
end

--- Reshows the crosshairs after a screenshot is taken.
function NS:OnEvent ()
	-- SCREENSHOT_SUCCEEDED / SCREENSHOT_FAILED
	self:Show();
end




Screenshot = NS.Screenshot;
NS:SetScript( "OnEvent", NS.OnEvent );
NS:RegisterEvent( "SCREENSHOT_FAILED" );
NS:RegisterEvent( "SCREENSHOT_SUCCEEDED" );

NS:SetFrameStrata( "BACKGROUND" );
NS:SetPoint( "CENTER" );
NS:SetSize( 32, 32 );
NS:SetAlpha( 0.75 );

local Texture = NS:CreateTexture( nil, "ARTWORK" );
Texture:SetAllPoints();
Texture:SetTexture( [[Interface\AddOns\]]..( ... )..[[\Skin\Crosshairs]] );
Texture:SetTexCoord( 1, 0, 1, 0 ); -- Note: For some reason, flipping it makes it sharper
Texture:SetVertexColor( unpack( _Underscore.Colors.Highlight ) );