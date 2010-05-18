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

-- Note: Parent ScrollHandler to WorldMapFrame so it gets disabled when Carbonite takes over
me.ScrollHandler = CreateFrame( "Frame", nil, WorldMapFrame ); -- Can insecurely toggle mousewheel input

local Tooltip = CreateFrame( "Frame", nil, me );
me.Tooltip = Tooltip;
Tooltip.Text = Tooltip:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );


Tooltip.Scale = 1;
Tooltip.OffsetX, Tooltip.OffsetY = -8, -16;




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

			Tooltip.Text:SetFormattedText( L.COORD_FORMAT,
				100 * Left / Width,
				100 * ( 1 - Bottom / Height ) );

			local Scale = Tooltip.Scale * UIParent:GetEffectiveScale();
			Tooltip:SetScale( Scale / MapScale ); -- Standard scale no matter scale of parent
			Tooltip:SetPoint( "TOPRIGHT", self, "BOTTOMLEFT",
				( Left * MapScale + Tooltip.OffsetX ) / Scale,
				( Bottom * MapScale + Tooltip.OffsetY ) / Scale );

			Tooltip:SetSize( Tooltip.Text:GetStringWidth(), Tooltip.Text:GetStringHeight() );
			Tooltip:Show();
		else
			Tooltip:Hide();
		end
	end
end




--[[****************************************************************************
  * Function: _Underscore.WorldMap.ScrollHandler:OnMouseWheel                  *
  * Description: Scrolls through dungeon map levels when available.            *
  ****************************************************************************]]
function me.ScrollHandler:OnMouseWheel ( Delta )
	local Level, LevelsMax = GetCurrentMapDungeonLevel(), GetNumDungeonMapLevels();

	if ( Delta > 0 ) then -- Up
		if ( Level < LevelsMax ) then
			SetDungeonMapLevel( Level + 1 );
		end
	else -- Down
		if ( Level > 1 ) then
			SetDungeonMapLevel( Level - 1 );
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.WorldMap.ScrollHandler:WORLD_MAP_UPDATE              *
  ****************************************************************************]]
function me.ScrollHandler:WORLD_MAP_UPDATE ()
	self:EnableMouseWheel( GetNumDungeonMapLevels() > 0 );
end
--[[****************************************************************************
  * Function: _Underscore.WorldMap.ScrollHandler:OnShow                        *
  ****************************************************************************]]
function me.ScrollHandler:OnShow ()
	self:RegisterEvent( "WORLD_MAP_UPDATE" );
	self:WORLD_MAP_UPDATE();
end
--[[****************************************************************************
  * Function: _Underscore.WorldMap.ScrollHandler:OnHide                        *
  ****************************************************************************]]
function me.ScrollHandler:OnHide ()
	self:UnregisterEvent( "WORLD_MAP_UPDATE" );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetAllPoints();
	me:SetScript( "OnUpdate", me.OnUpdate );

	Tooltip:Hide();
	Tooltip:SetFrameStrata( "TOOLTIP" );
	Tooltip:SetClampedToScreen( true );
	_Underscore.Backdrop.Create( Tooltip ):SetAlpha( 0.5 );

	local Color = NORMAL_FONT_COLOR;
	Tooltip.Text:SetTextColor( Color.r, Color.g, Color.b, 0.7 );
	Tooltip.Text:SetAllPoints();


	local ScrollHandler = me.ScrollHandler;
	ScrollHandler:SetAllPoints( WorldMapButton );
	ScrollHandler:SetScript( "OnMouseWheel", ScrollHandler.OnMouseWheel );
	ScrollHandler:SetScript( "OnShow", ScrollHandler.OnShow );
	ScrollHandler:SetScript( "OnHide", ScrollHandler.OnHide );
	ScrollHandler:SetScript( "OnEvent", _Underscore.OnEvent );


	WorldMapUnit_Update = me.UpdateUnit;

	hooksecurefunc( "WorldMap_ToggleSizeUp", me.DisableBlackout );
	me.DisableBlackout();
end
