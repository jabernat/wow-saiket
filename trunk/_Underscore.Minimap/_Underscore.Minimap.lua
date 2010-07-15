--[[****************************************************************************
  * _Underscore.Minimap by Saiket                                              *
  * _Underscore.Minimap.lua - Square the minimap and clean it up.              *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local me = select( 2, ... );
_Underscore.Minimap = me;

me.Frame = CreateFrame( "Frame" );
me.PingText = MinimapPing:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmallGray" );

local IconSize = 14;
local MinimapScale = 0.9;




--- Hook to position the minimap ping on a square minimap.
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
--- Hook to broadcast a ping on a square minimap.
function me:OnMouseUp ()
	local CursorX, CursorY = GetCursorPosition();
	local CenterX, CenterY = self:GetCenter();
	local Scale = self:GetEffectiveScale();

	self:PingLocation(
		CursorX / Scale - CenterX,
		CursorY / Scale - CenterY );
end


--- Updates the instance difficulty flag and moves zone text to fit.
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


--- Zooms the minimap using the mousewheel.
function me:OnMouseWheel ( Delta )
	self:SetZoom( min( max( self:GetZoom() + Delta, 0 ), self:GetZoomLevels() - 1 ) );
end
--- Displays the name of the player who pinged.
function me.Frame:MINIMAP_PING ( _, UnitID )
	me.PingText:SetText( UnitName( UnitID ) );
end
--- Restore the original minimap shape in case _Underscore was disabled right before a reload UI.
-- This corrects a bug where the minimap mask stays square in the default UI.
function me.Frame:PLAYER_LOGOUT ()
	Minimap:SetMaskTexture( [[Textures\MinimapMask]] );
end


--- Lets other addons know that the minimap is square.
function me.GetMinimapShape ()
	return "SQUARE";
end




me.Frame:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
me.Frame:RegisterEvent( "MINIMAP_PING" );
me.Frame:RegisterEvent( "PLAYER_LOGOUT" );

MinimapCluster:ClearAllPoints();
MinimapCluster:SetPoint( "TOPRIGHT", _Underscore.TopMargin, "BOTTOMRIGHT" );
MinimapCluster:SetSize( Minimap:GetSize() );
MinimapCluster:SetScale( MinimapScale );
MinimapCluster:EnableMouse( false );
_Underscore.Backdrop.Create( Minimap );


Minimap:SetAllPoints( MinimapCluster );
Minimap:SetMaskTexture( [[Interface\Buttons\WHITE8X8]] );
GetMinimapShape = me.GetMinimapShape;

-- Hooks to allow pings on a square minimap
Minimap:SetScript( "OnMouseUp", me.OnMouseUp );
Minimap_SetPing = me.SetPing;
-- Show name of pinger
me.PingText:SetPoint( "TOPRIGHT", MinimapPing, "CENTER", -8, -8 );
me.PingText:SetAlpha( 0.75 );




-- Replace zoom buttons
Minimap:HookScript( "OnMouseWheel", me.OnMouseWheel );
Minimap:EnableMouseWheel( true );

MinimapZoomIn:Hide();
MinimapZoomOut:Hide();


-- Move default buttons that sit around the minimap
local Color = _Underscore.Colors.Foreground;

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
MiniMapTracking:SetSize( IconSize, IconSize );
MiniMapTrackingButton:SetAllPoints( MiniMapTracking );
MiniMapTrackingButtonBorder:Hide();
MiniMapTrackingButtonBorder:SetTexture();
MiniMapTrackingBackground:Hide();
MiniMapTrackingBackground:SetTexture();
MiniMapTrackingIcon:SetAllPoints( MiniMapTracking );
MiniMapTrackingIcon:SetVertexColor( unpack( Color ) );
MiniMapTrackingButtonShine:SetAllPoints();
_Underscore.SkinButtonIcon( MiniMapTrackingIcon );
MiniMapTrackingButton:SetScript( "OnMouseUp", nil );
MiniMapTrackingButton:SetScript( "OnMouseDown", nil );

-- Voice chat button
MiniMapVoiceChatFrame:ClearAllPoints();
MiniMapVoiceChatFrame:Hide();

MiniMapMailFrame:ClearAllPoints();
MiniMapMailFrame:SetPoint( "BOTTOMRIGHT", Minimap, -1, 0 );
MiniMapMailFrame:SetSize( IconSize, IconSize );
MiniMapMailBorder:Hide();
MiniMapMailBorder:SetTexture();
MiniMapMailIcon:SetAllPoints( MiniMapMailFrame );
MiniMapMailIcon:SetTexture( [[Interface\Minimap\Tracking\Mailbox]] ); -- No black background
_Underscore.SkinButtonIcon( MiniMapMailIcon );

MiniMapBattlefieldFrame:ClearAllPoints();
MiniMapBattlefieldFrame:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );
MiniMapBattlefieldFrame:SetSize( IconSize * 1.5, IconSize * 1.5 );
MiniMapBattlefieldBorder:Hide();
MiniMapBattlefieldBorder:SetTexture();
MiniMapBattlefieldIcon:SetAllPoints( MiniMapBattlefieldFrame );
MiniMapBattlefieldIcon:SetVertexColor( unpack( Color ) );
BattlegroundShine:SetAllPoints( MiniMapBattlefieldFrame );

MiniMapLFGFrame:ClearAllPoints();
MiniMapLFGFrame:SetPoint( "RIGHT", MiniMapBattlefieldFrame, "LEFT" );
MiniMapLFGFrame:SetSize( IconSize * 1.75, IconSize * 1.75 );
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
Frame:SetSize( Texture:GetWidth() / 2, Texture:GetHeight() );
Frame:SetScale( 0.7 );
Frame:SetAlpha( 0.6 );
Texture:SetAllPoints();
Frame:HookScript( "OnEvent", me.DifficultyOnEvent );


-- Move and shrink the GM ticket frame
TicketStatusFrame:ClearAllPoints();
TicketStatusFrame:SetPoint( "TOPRIGHT", MinimapCluster, "TOPLEFT", -8, 0 );
TicketStatusFrame:SetScale( 0.85 );
TicketStatusFrame:SetAlpha( 0.75 );