--[[****************************************************************************
  * _Underscore.WorldMap by Saiket                                             *
  * _Underscore.WorldMap.lua - Adds coordinates to the World Map frame.        *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local me = select( 2, ... );
_Underscore.WorldMap = me;
local L = me.L;

me.Frame = CreateFrame( "Frame", nil, WorldMapButton );
-- Note: Parent ScrollHandler to WorldMapFrame so it gets disabled when Carbonite takes over
me.ScrollHandler = CreateFrame( "Frame", nil, WorldMapFrame ); -- Can insecurely toggle mousewheel input

local Tooltip = CreateFrame( "Frame", nil, me.Frame );
me.Tooltip = Tooltip;
Tooltip.Text = Tooltip:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );


Tooltip.Scale = 1;
Tooltip.OffsetX, Tooltip.OffsetY = -8, -16;




--- Keeps the black background behind the map hidden.
function me.DisableBlackout ()
	WorldMapFrame:EnableMouse( false );
	--WorldMapFrame:EnableKeyboard( false ); -- Breaks escape keybind
end


do
	local GetCursorPosition = GetCursorPosition;
	--- Updates the coordinate tooltip.
	function me.Frame:OnUpdate ()
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




--- Scrolls through dungeon map levels with the mousewheel when available.
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
--- Enables and disables the mousewheel when dungeon levels are available.
function me.ScrollHandler:WORLD_MAP_UPDATE ()
	self:EnableMouseWheel( GetNumDungeonMapLevels() > 1 );
end
--- Starts monitoring the map when shown.
function me.ScrollHandler:OnShow ()
	self:RegisterEvent( "WORLD_MAP_UPDATE" );
	self:WORLD_MAP_UPDATE();
end
--- Stops monitoring the map when hidden.
function me.ScrollHandler:OnHide ()
	self:UnregisterEvent( "WORLD_MAP_UPDATE" );
end




me.Frame:SetAllPoints();
me.Frame:SetScript( "OnUpdate", me.Frame.OnUpdate );

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
ScrollHandler:EnableMouseWheel( false );
ScrollHandler:SetScript( "OnShow", ScrollHandler.OnShow );
ScrollHandler:SetScript( "OnHide", ScrollHandler.OnHide );
ScrollHandler:SetScript( "OnEvent", _Underscore.Frame.OnEvent );


BlackoutWorld:SetTexture();
hooksecurefunc( "WorldMap_ToggleSizeUp", me.DisableBlackout );
me.DisableBlackout();