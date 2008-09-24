--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.CastingBar.lua - Reposition the spell casting progress bar.         *
  *                                                                            *
  * + Removes the casting bar's border and unnecessary highlights and flashes. *
  * + Spans the bar between the left and right action button grids.            *
  * + Allows spell names of any width to be shown in the bar's label.          *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.CastingBar = me;

me.Overlay = CastingBarFrame:CreateTexture( nil, "OVERLAY" );




--[[****************************************************************************
  * Function: _Clean.CastingBar.HideArtwork                                    *
  * Description: This version does not have a border, has no progress spark,   *
  *   and does not flash when done casting.                                    *
  ****************************************************************************]]
local Border = CastingBarFrameBorder;
local Flash = CastingBarFrameFlash;
local Spark = CastingBarFrameSpark;
function me.HideArtwork ()
	Border:Hide();
	Flash:Hide();
	Spark:Hide();
end
--[[****************************************************************************
  * Function: _Clean.CastingBar:SetStatusBarColor                              *
  * Description: Replaces the standard status colors.                          *
  ****************************************************************************]]
do
	local Disabled = false;
	function me:SetStatusBarColor ( R, G, B, A )
		if ( not Disabled ) then -- Restore color
			Disabled = true;

			local Color;
			if ( R == 0.0 and G == 1.0 and B == 0.0 ) then
				Color = _Clean.Colors.Friendly2;
			elseif ( R == 1.0 and G == 0.0 and B == 0.0 ) then
				Color = _Clean.Colors.Hostile2;
			elseif ( R == 1.0 and G == 0.7 and B == 0.0 ) then
				Color = _Clean.Colors.Mana;
			end
			if ( Color ) then
				self:SetStatusBarColor( Color.r, Color.g, Color.b, A );
			end

			Disabled = false;
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Position the bar between the left and right action bar grids
	CastingBarFrame:ClearAllPoints();
	CastingBarFrame:SetPoint( "TOPRIGHT", MultiBarBottomRight,
		"TOPLEFT", -10, -10 );
	CastingBarFrame:SetPoint( "BOTTOMLEFT", ActionButton12,
		"BOTTOMRIGHT", 10, 10 );

	CastingBarFrameText:ClearAllPoints();
	CastingBarFrameText:SetPoint( "CENTER", CastingBarFrame );
	CastingBarFrameText:SetWidth( 0 ); -- Allow variable width
	CastingBarFrameText:SetFontObject( GameFontHighlightLarge );

	local Background = _Clean.Colors.Background;
	for _, Region in ipairs( { CastingBarFrame:GetRegions() } ) do
		if ( Region:GetObjectType() == "Texture" and Region:GetDrawLayer() == "BACKGROUND" and Region:GetTexture() == "Solid Texture" ) then
			Region:SetTexture( _Clean.Backdrop.bgFile );
			Region:SetVertexColor( Background.r, Background.g, Background.b, Background.a );
			break;
		end
	end

	-- Add glossy overlay
	me.Overlay:SetAllPoints( CastingBarFrame );
	me.Overlay:SetTexture( "Interface\\TokenFrame\\UI-TokenFrame-CategoryButton" );
	me.Overlay:SetBlendMode( "ADD" );
	me.Overlay:SetTexCoord( 0.1, 0.9, 0, 0.28125 );
	local Color = _Clean.Colors.Normal;
	me.Overlay:SetVertexColor( Color.r, Color.g, Color.b, 0.5 );

	-- Hooks
	UIPARENT_MANAGED_FRAME_POSITIONS[ "CastingBarFrame" ] = nil;
	CastingBarFrame:HookScript( "OnEvent", me.HideArtwork );
	CastingBarFrame:HookScript( "OnUpdate", me.HideArtwork );
	hooksecurefunc( CastingBarFrame, "SetStatusBarColor", me.SetStatusBarColor );
end
