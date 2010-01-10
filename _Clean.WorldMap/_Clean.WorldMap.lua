--[[****************************************************************************
  * _Clean.WorldMap by Saiket                                                  *
  * _Clean.WorldMap.lua - Adds coordinates to the World Map frame.             *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local L = _CleanLocalization.WorldMap;
local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, WorldMapButton );
_Clean.WorldMap = me;

me.Text = me:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );


me.Scale = 1;
me.OffsetX, me.OffsetY = -8, -16;




--[[****************************************************************************
  * Function: _Clean.WorldMap.DisableBlackout                                  *
  * Description: Keeps the black background behind the map hidden.             *
  ****************************************************************************]]
function me.DisableBlackout ()
	WorldMapFrame:EnableMouse( false );
	--WorldMapFrame:EnableKeyboard( false ); -- Breaks escape keybind
	BlackoutWorld:Hide();
end


--[[****************************************************************************
  * Function: _Clean.WorldMap:OnUpdate                                         *
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
	_Clean.Backdrop.Add( me ):SetAlpha( 0.5 );

	local Color = NORMAL_FONT_COLOR;
	me.Text:SetTextColor( Color.r, Color.g, Color.b, 0.7 );
	me.Text:SetAllPoints();

	WorldMapButton:HookScript( "OnUpdate", me.OnUpdate );


	hooksecurefunc( "WorldMap_ToggleSizeUp", me.DisableBlackout );
	me.DisableBlackout();
end
