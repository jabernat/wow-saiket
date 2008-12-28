--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Crosshairs.lua - Adds crosshairs to the viewport.                   *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, WorldFrame );
_Clean.Crosshairs = me;

me.ScreenshotBackup = Screenshot;
me.Texture = me:CreateTexture( nil, "ARTWORK" );




--[[****************************************************************************
  * Function: _Clean.Crosshairs.Screenshot                                     *
  * Description: Hide the crosshairs just before screenshots are taken.        *
  ****************************************************************************]]
function me.Screenshot ()
	me:Hide();
	me.ScreenshotBackup();
end

--[[****************************************************************************
  * Function: _Clean.Crosshairs:OnEvent                                        *
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
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "SCREENSHOT_FAILED" );
	me:RegisterEvent( "SCREENSHOT_SUCCEEDED" );

	me:SetFrameStrata( "BACKGROUND" );
	me:SetWidth( 32 );
	me:SetHeight( 32 );
	me:SetAlpha( 0.75 );
	me:SetPoint( "CENTER" );
	me.Texture:SetTexture( "Interface\\AddOns\\_Clean\\Skin\\CrossHairs" );
	-- For some reason, drawing the texture flipped like this makes it sharper
	me.Texture:SetPoint( "TOPLEFT", me, "BOTTOMRIGHT" );
	me.Texture:SetPoint( "BOTTOMRIGHT", me, "TOPLEFT" );

	local Highlight = _Clean.Colors.Highlight;
	me.Texture:SetVertexColor( Highlight.r, Highlight.g, Highlight.b, Highlight.a );

	Screenshot = me.Screenshot;
end
