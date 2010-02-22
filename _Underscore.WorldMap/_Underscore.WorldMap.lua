--[[****************************************************************************
  * _Underscore.WorldMap by Saiket                                             *
  * _Underscore.WorldMap.lua - Adds coordinates to the World Map frame.        *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local L = _UnderscoreLocalization.WorldMap;
local me = CreateFrame( "Frame", nil, WorldMapButton );
_Underscore.WorldMap = me;

me.Text = me:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );


me.Scale = 1;
me.OffsetX, me.OffsetY = -8, -16;




--[[****************************************************************************
  * Function: _Underscore.WorldMap.UpdateUnit                                  *
  * Description: Adds class color to player blips on the map.                  *
  ****************************************************************************]]
do
	local Colors = _Underscore.Colors.class;
	local InactiveColor = { 0.5, 0.2, 0.8 };
	local Top, Bottom, Left, Right = 0.25, 0.5, 7 / 8, 1; -- Row 2, column 8: White template blip
	function me:UpdateUnit ()
		local UnitID = self.unit or self.name;
		local Icon = self.icon;

		local Color;
		if ( UnitID and UnitIsPlayer( UnitID ) ) then -- Class colored icon
			if ( PlayerIsPVPInactive( UnitID ) ) then
				Color = InactiveColor;
			else
				local _, Class = UnitClass( UnitID );
				Color = Colors[ Class ];
			end
		end

		if ( Color ) then
			Icon:SetTexture( [[Interface\Minimap\PartyRaidBlips]] );
			Icon:SetVertexColor( unpack( Color ) );
			if ( UnitPlayerOrPetInParty( UnitID ) ) then
				Icon:SetTexCoord( Left, Right, Top, Bottom );
			else -- Bottom half contains raid member blips
				Icon:SetTexCoord( Left, Right, Top + 0.5, Bottom + 0.5 );
			end
		else -- Generic blip icon
			Icon:SetTexture( [[Interface\WorldMap\WorldMapPartyIcon]] );
			Icon:SetVertexColor( 1, 1, 1 );
			Icon:SetTexCoord( 0, 1, 0, 1 );
		end
	end
end


--[[****************************************************************************
  * Function: _Underscore.WorldMap.DisableBlackout                             *
  * Description: Keeps the black background behind the map hidden.             *
  ****************************************************************************]]
function me.DisableBlackout ()
	WorldMapFrame:EnableMouse( false );
	--WorldMapFrame:EnableKeyboard( false ); -- Breaks escape keybind
	BlackoutWorld:Hide();
end


--[[****************************************************************************
  * Function: _Underscore.WorldMap:OnUpdate                                    *
  * Description: Updates the coordinate tooltip.                               *
  ****************************************************************************]]
do
	local GetCursorPosition = GetCursorPosition;
	function me:OnUpdate ()
		if ( self:IsMouseOver() ) then
			local CursorX, CursorY = GetCursorPosition();
			local MapScale = self:GetEffectiveScale();
			local Left, Bottom, Width, Height = self:GetRect();
			Left, Bottom = CursorX / MapScale - Left, CursorY / MapScale - Bottom;

			me.Text:SetFormattedText( L.COORD_FORMAT,
				100 * Left / Width,
				100 * ( 1 - Bottom / Height ) );

			local Scale = me.Scale * UIParent:GetEffectiveScale();
			me:SetScale( Scale / MapScale ); -- Standard scale no matter scale of parent
			me:SetPoint( "TOPRIGHT", self, "BOTTOMLEFT",
				( Left * MapScale + me.OffsetX ) / Scale,
				( Bottom * MapScale + me.OffsetY ) / Scale );

			me:SetSize( me.Text:GetStringWidth(), me.Text:GetStringHeight() );
			me:Show();
		else
			me:Hide();
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetFrameStrata( "TOOLTIP" );
	me:SetClampedToScreen( true );
	_Underscore.Backdrop.Create( me ):SetAlpha( 0.5 );

	local Color = NORMAL_FONT_COLOR;
	me.Text:SetTextColor( Color.r, Color.g, Color.b, 0.7 );
	me.Text:SetAllPoints();

	WorldMapButton:HookScript( "OnUpdate", me.OnUpdate );

	WorldMapUnit_Update = me.UpdateUnit;


	hooksecurefunc( "WorldMap_ToggleSizeUp", me.DisableBlackout );
	me.DisableBlackout();
end
