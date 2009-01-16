--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.CastingBar.lua - Reposition the spell casting progress bar.         *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.CastingBar = me;




--[[****************************************************************************
  * Function: _Clean.CastingBar:HideArtwork                                    *
  * Description: Hides spark, flash, and border from casting bar.              *
  ****************************************************************************]]
function me:HideArtwork ()
	self.Border:Hide();
	self.Flash:Hide();
	self.Spark:Hide();
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
				Color = _Clean.Colors.Highlight;
			end
			if ( Color ) then
				self:SetStatusBarColor( Color.r, Color.g, Color.b, A );
			end

			Disabled = false;
		end
	end
end


--[[****************************************************************************
  * Function: _Clean.CastingBar:SkinCastingBar                                 *
  * Description: Skins a casting bar frame and positions it.                   *
  ****************************************************************************]]
function me:SkinCastingBar ()
	-- Position the bar between the left and right action bar grids
	self:ClearAllPoints();
	self:SetPoint( "TOPRIGHT", _Clean.ActionBar.BackdropBottomRight, "TOPLEFT", -10, -10 );
	self:SetPoint( "BOTTOMLEFT", _Clean.ActionBar.BackdropBottomLeft, "BOTTOMRIGHT", 10, 10 );

	local Text = _G[ self:GetName().."Text" ];
	Text:ClearAllPoints();
	Text:SetPoint( "CENTER", CastingBarFrame );
	Text:SetWidth( 0 ); -- Allow variable width
	Text:SetFontObject( GameFontHighlightLarge );

	local Background = _Clean.Colors.Background;
	for _, Region in ipairs( { self:GetRegions() } ) do
		if ( Region:GetObjectType() == "Texture" and Region:GetDrawLayer() == "BACKGROUND" and Region:GetTexture() == "Solid Texture" ) then
			Region:Hide();
			break;
		end
	end
	_Clean.Backdrop.Add( self );

	-- Change the bar texture
	self:SetStatusBarTexture( "Interface\\AddOns\\_Clean\\Skin\\Glaze" );

	-- Hooks
	self.Border = _G[ self:GetName().."Border" ];
	self.Flash = _G[ self:GetName().."Flash" ];
	self.Spark = _G[ self:GetName().."Spark" ];
	self:HookScript( "OnEvent", me.HideArtwork );
	self:HookScript( "OnUpdate", me.HideArtwork );
	hooksecurefunc( self, "SetStatusBarColor", me.SetStatusBarColor );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.SkinCastingBar( CastingBarFrame );
	me.SkinCastingBar( PetCastingBarFrame );

	UIPARENT_MANAGED_FRAME_POSITIONS[ "CastingBarFrame" ] = nil;
end
