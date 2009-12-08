--[[****************************************************************************
  * _Clean.HUD by Saiket                                                       *
  * _Clean.HUD.Crosshairs.lua - Adds crosshairs to the viewport.               *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, WorldFrame );
_Clean.HUD.Crosshairs = me;




--[[****************************************************************************
  * Function: _Clean.HUD.Crosshairs.Screenshot                                 *
  * Description: Hide the crosshairs just before screenshots are taken.        *
  ****************************************************************************]]
do
	local Backup = Screenshot;
	function me.Screenshot ( ... )
		me:Hide();
		return Backup( ... );
	end
end

--[[****************************************************************************
  * Function: _Clean.HUD.Crosshairs:OnEvent                                    *
  * Description: Reshows the crosshairs after a screenshot is taken.           *
  ****************************************************************************]]
function me:OnEvent ( Event )
	-- SCREENSHOT_SUCCEEDED / SCREENSHOT_FAILED
	self:Show();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	Screenshot = me.Screenshot;
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "SCREENSHOT_FAILED" );
	me:RegisterEvent( "SCREENSHOT_SUCCEEDED" );

	me:SetFrameStrata( "BACKGROUND" );
	me:SetWidth( 32 );
	me:SetHeight( 32 );
	me:SetAlpha( 0.75 );
	me:SetPoint( "CENTER" );

	local Texture = me:CreateTexture( nil, "ARTWORK" );
	Texture:SetAllPoints();
	Texture:SetTexture( [[Interface\AddOns\_Clean.HUD\Skin\Crosshairs]] );
	Texture:SetTexCoord( 1, 0, 1, 0 ); -- Note: For some reason, flipping it makes it sharper
	Texture:SetVertexColor( unpack( _Clean.Colors.Highlight ) );
end
