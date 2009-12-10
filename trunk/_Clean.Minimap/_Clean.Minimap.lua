--[[****************************************************************************
  * _Clean.Minimap by Saiket                                                   *
  * _Clean.Minimap.lua - Square the minimap and clean it up.                   *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local _Clean = _Clean;
local me = {
	PingText = MinimapPing:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmallGray" );
};
_Clean.Minimap = me;

local IconSize = 14;
local MinimapScale = 0.9;




--[[****************************************************************************
  * Function: _Clean.Minimap.SetPing                                           *
  * Description: This is the OnUpdate function to move the minimap ping on a   *
  *   square minimap.                                                          *
  ****************************************************************************]]
function me.SetPing ( X, Y, Sound )
	if ( abs( X ) <= 0.5 and abs( Y ) <= 0.5 ) then
		MinimapPing:SetPoint( "CENTER", Minimap, "CENTER",
			X * Minimap:GetWidth(), Y * Minimap:GetHeight() );
		MinimapPing:SetAlpha( 1.0 );
		MinimapPing:Show();
		if ( Sound ) then
			PlaySound( "MapPing" );
		end
	else
		MinimapPing:Hide();
	end
end
--[[****************************************************************************
  * Function: _Clean.Minimap:OnClick                                           *
  * Description: Broadcasts a ping at the cursor's location for a square       *
  *   minimap.                                                                 *
  ****************************************************************************]]
function me:OnClick ()
	local CursorX, CursorY = GetCursorPosition();
	local CenterX, CenterY = self:GetCenter();
	local Scale = self:GetEffectiveScale();

	self:PingLocation(
		CursorX / Scale - CenterX,
		CursorY / Scale - CenterY );
end


--[[****************************************************************************
  * Function: _Clean.Minimap:DifficultyOnEvent                                 *
  * Description: Updates the instance difficulty flag.                         *
  ****************************************************************************]]
function me:DifficultyOnEvent ()
	if ( self:IsShown() ) then
		local Texture = _G[ self:GetName().."Texture" ];
		local MinX, MinY, _, MaxY, MaxX = Texture:GetTexCoord();
		Texture:SetTexCoord( MinX + 1 / 16, MaxX - 1 / 16, MinY, MaxY );

		MinimapZoneTextButton:SetPoint( "LEFT", self, "RIGHT" );
	else
		MinimapZoneTextButton:SetPoint( "LEFT" );
	end
end


--[[****************************************************************************
  * Function: _Clean.Minimap:OnMouseWheel                                      *
  * Description: Zooms the minimap when mousewheeled over.                     *
  ****************************************************************************]]
function me:OnMouseWheel ( Delta )
	self:SetZoom( min( max( self:GetZoom() + Delta, 0 ), self:GetZoomLevels() - 1 ) );
end
--[[****************************************************************************
  * Function: _Clean.Minimap:OnEvent                                           *
  * Description: Displays the name of the player who pinged.                   *
  ****************************************************************************]]
function me:OnEvent ( Event, UnitID )
	if ( Event == "MINIMAP_PING" ) then
		me.PingText:SetText( UnitName( UnitID ) );
	end
end


--[[****************************************************************************
  * Function: _Clean.Minimap.GetMinimapShape                                   *
  * Description: Lets other addons know that the minimap is square.            *
  ****************************************************************************]]
function me.GetMinimapShape ()
	return "SQUARE";
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	MinimapCluster:ClearAllPoints();
	MinimapCluster:SetPoint( "TOPRIGHT", _Clean.TopMargin, "BOTTOMRIGHT" );
	MinimapCluster:SetWidth( Minimap:GetWidth() );
	MinimapCluster:SetHeight( Minimap:GetHeight() );
	MinimapCluster:SetScale( MinimapScale );
	MinimapCluster:EnableMouse( false );
	_Clean.Backdrop.Add( MinimapCluster, _Clean.Backdrop.Padding );


	Minimap:SetAllPoints( MinimapCluster );
	Minimap:SetMaskTexture( [[Interface\Buttons\WHITE8X8]] );
	Minimap:SetBlipTexture( [[Interface\AddOns\_Clean.Minimap\Skin\ObjectIcons]] );
	GetMinimapShape = me.GetMinimapShape;

	-- Hooks to allow pings on a square minimap
	Minimap:SetScript( "OnMouseUp", me.OnClick );
	Minimap_SetPing = me.SetPing;
	-- Show name of pinger
	me.PingText:SetPoint( "TOPRIGHT", MinimapPing, "CENTER", -8, -8 );
	me.PingText:SetAlpha( 0.75 );
	MinimapPing:HookScript( "OnEvent", me.OnEvent );




	-- Replace zoom buttons
	Minimap:HookScript( "OnMouseWheel", me.OnMouseWheel );
	Minimap:EnableMouseWheel( true );

	MinimapZoomIn:Hide();
	MinimapZoomOut:Hide();


	-- Move default buttons that sit around the minimap
	local Color = _Clean.Colors.Foreground;

	MinimapBorderTop:Hide();
	MinimapBorderTop:SetTexture();
	MinimapBorder:Hide();
	MinimapBorder:SetTexture();
	MinimapNorthTag:Hide();
	MinimapNorthTag:SetTexture();

	GameTimeFrame:Hide();
	MiniMapWorldMapButton:Hide();

	MiniMapTracking:ClearAllPoints();
	MiniMapTracking:SetPoint( "BOTTOMLEFT", Minimap, -1, 0 );
	MiniMapTracking:SetWidth( IconSize );
	MiniMapTracking:SetHeight( IconSize );
	MiniMapTrackingButton:SetAllPoints( MiniMapTracking );
	MiniMapTrackingButtonBorder:Hide();
	MiniMapTrackingButtonBorder:SetTexture();
	MiniMapTrackingBackground:Hide();
	MiniMapTrackingBackground:SetTexture();
	MiniMapTrackingIcon:SetAllPoints( MiniMapTracking );
	MiniMapTrackingIcon:SetVertexColor( unpack( Color ) );
	MiniMapTrackingButtonShine:SetAllPoints();
	_Clean.RemoveIconBorder( MiniMapTrackingIcon );
	MiniMapTrackingButton:SetScript( "OnMouseUp", nil );
	MiniMapTrackingButton:SetScript( "OnMouseDown", nil );

	-- Voice chat button
	MiniMapVoiceChatFrame:ClearAllPoints();
	MiniMapVoiceChatFrame:Hide();

	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint( "BOTTOMRIGHT", Minimap, -1, 0 );
	MiniMapMailFrame:SetWidth( IconSize );
	MiniMapMailFrame:SetHeight( IconSize );
	MiniMapMailBorder:Hide();
	MiniMapMailBorder:SetTexture();
	MiniMapMailIcon:SetAllPoints( MiniMapMailFrame );
	MiniMapMailIcon:SetTexture( [[Interface\Minimap\Tracking\Mailbox]] ); -- No black background
	_Clean.RemoveIconBorder( MiniMapMailIcon );

	MiniMapBattlefieldFrame:ClearAllPoints();
	MiniMapBattlefieldFrame:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );
	MiniMapBattlefieldFrame:SetWidth( IconSize * 1.5 );
	MiniMapBattlefieldFrame:SetHeight( IconSize * 1.5 );
	MiniMapBattlefieldBorder:Hide();
	MiniMapBattlefieldBorder:SetTexture();
	MiniMapBattlefieldIcon:SetAllPoints( MiniMapBattlefieldFrame );
	MiniMapBattlefieldIcon:SetVertexColor( unpack( Color ) );
	BattlegroundShine:SetAllPoints( MiniMapBattlefieldFrame );

	MiniMapLFGFrame:ClearAllPoints();
	MiniMapLFGFrame:SetPoint( "RIGHT", MiniMapBattlefieldFrame, "LEFT" );
	MiniMapLFGFrame:SetWidth( IconSize * 1.75 );
	MiniMapLFGFrame:SetHeight( IconSize * 1.75 );
	MiniMapLFGFrameBorder:Hide();
	MiniMapLFGFrameBorder:SetTexture();
	MiniMapLFGFrameIcon:SetAllPoints( MiniMapLFGFrame );
	MiniMapLFGFrameIconTexture:SetVertexColor( unpack( Color ) );


	-- Move the zone text inside of the square
	MinimapZoneTextButton:SetFrameStrata( "LOW" );
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetPoint( "TOPRIGHT", Minimap, 0, -2 );
	MinimapZoneTextButton:SetPoint( "LEFT", Minimap );
	MinimapZoneTextButton:EnableMouse( false );
	MinimapZoneTextButton:SetAlpha( 0.5 );
	MinimapZoneText:SetAllPoints( MinimapZoneTextButton );
	MinimapZoneText:SetFontObject( NumberFontNormalSmall );

	-- Let the dungeon difficulty flag share space with the zone text
	local Frame, Texture = MiniMapInstanceDifficulty, MiniMapInstanceDifficultyTexture;
	Frame:ClearAllPoints();
	Frame:SetPoint( "TOPLEFT", -4, 8 );
	Frame:SetWidth( Texture:GetWidth() / 2 );
	Frame:SetHeight( Texture:GetHeight() );
	Frame:SetScale( 0.7 );
	Frame:SetAlpha( 0.6 );
	Texture:SetAllPoints();
	Frame:HookScript( "OnEvent", me.DifficultyOnEvent );


	-- Move and shrink the GM ticket frame
	TicketStatusFrame:ClearAllPoints();
	TicketStatusFrame:SetPoint( "TOPRIGHT", MinimapCluster, "TOPLEFT", -8, 0 );
	TicketStatusFrame:SetScale( 0.85 );
	TicketStatusFrame:SetAlpha( 0.75 );
end
