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
  * Function: _Clean.Crosshairs:SCREENSHOT_FAILED                              *
  ****************************************************************************]]
function me:SCREENSHOT_FAILED ()
	self:Show();
end
--[[****************************************************************************
  * Function: _Clean.Crosshairs:SCREENSHOT_SUCCEEDED                           *
  ****************************************************************************]]
function me:SCREENSHOT_SUCCEEDED ()
	self:Show();
end
--[[****************************************************************************
  * Function: _Clean.Crosshairs:OnEvent                                        *
  * Description: Keeps track of whether voice is transmitting or not.          *
  ****************************************************************************]]
function me:OnEvent ( Event )
	if ( type( me[ Event ] ) == "function" ) then
		me[ Event ]( self );
	end
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

	Screenshot = me.Screenshot;
end
