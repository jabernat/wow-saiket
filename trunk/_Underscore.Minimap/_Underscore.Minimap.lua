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
me.PingName = CreateFrame( "ScrollFrame", nil, Minimap );

local IconSize = 14;
local MinimapScale = 0.9;




--- Hook to broadcast a ping on a square minimap.
function me:OnMouseUp ()
	local CursorX, CursorY = GetCursorPosition();
	local CenterX, CenterY = self:GetCenter();
	local Scale = self:GetEffectiveScale();

	self:PingLocation(
		CursorX / Scale - CenterX,
		CursorY / Scale - CenterY );
end


--- Displays the name of the player who pinged.
function me.PingName:MINIMAP_PING ( _, UnitID )
	self:Show();
	self:SetAlpha( 1 );
	self.Text:SetText( UnitName( UnitID ) );
	self.Duration = MINIMAPPING_TIMER;
end
--- Timer to automatically hide ping text as the blip fades out.
function me.PingName:OnUpdate ( Elapsed )
	self.Duration = self.Duration - Elapsed;
	if ( self.Duration > 0 ) then
		local X, Y = Minimap:GetPingPosition();
		local Width, Height = Minimap:GetSize();
		self.Text:SetPoint( "TOPLEFT", Minimap, "CENTER", X * Width + 8, Y * Height - 8 );
		if ( self.Duration < MINIMAPPING_FADE_TIMER ) then
			self:SetAlpha( self.Duration / MINIMAPPING_FADE_TIMER );
		end
	else
		self:Hide();
	end
end


--- Zooms the minimap using the mousewheel.
function me:OnMouseWheel ( Delta )
	self:SetZoom( min( max( self:GetZoom() + Delta, 0 ), self:GetZoomLevels() - 1 ) );
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
me.Frame:RegisterEvent( "PLAYER_LOGOUT" );

me.PingName:Hide();
me.PingName:SetAllPoints();
local Container = CreateFrame( "Frame", nil, me.PingName );
Container:SetSize( 1, 1 );
me.PingName:SetScrollChild( Container );
me.PingName.Text = Container:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmallGray" );
me.PingName:SetScript( "OnUpdate", me.PingName.OnUpdate );
me.PingName:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
me.PingName:RegisterEvent( "MINIMAP_PING" );

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
Minimap_OnClick = me.OnMouseUp;
Minimap:SetScript( "OnMouseUp", me.OnMouseUp );
-- Show name of player who pinged
me.PingName:SetAlpha( 0.75 );




--- Hides this texture and releases resources.
local function TextureHide ( self )
	self:Hide();
	self:SetTexture();
end

-- Replace zoom buttons
Minimap:HookScript( "OnMouseWheel", me.OnMouseWheel );
Minimap:EnableMouseWheel( true );

MinimapZoomIn:Hide();
MinimapZoomOut:Hide();


-- Move default buttons that sit around the minimap
local R, G, B, A = unpack( _Underscore.Colors.Foreground );

TextureHide( MinimapBorderTop );
TextureHide( MinimapBorder );
TextureHide( MinimapNorthTag );

GameTimeFrame:Hide();
MiniMapWorldMapButton:Hide();

MiniMapVoiceChatFrame:ClearAllPoints();
MiniMapVoiceChatFrame:Hide();

--- Skins this default minimap icon.
local function SkinButton ( self, Scale, Border, Icon, NoRecolor )
	self:ClearAllPoints();
	self:SetSize( Scale * IconSize, Scale * IconSize );
	TextureHide( Border );
	Icon:SetAllPoints();
	_Underscore.SkinButtonIcon( Icon );
	if ( not NoRecolor ) then
		Icon:SetVertexColor( R, G, B, A );
	end
end
SkinButton( MiniMapTracking, 1, MiniMapTrackingButtonBorder, MiniMapTrackingIcon );
MiniMapTracking:SetPoint( "BOTTOMLEFT", Minimap, -1, 0 );
MiniMapTrackingButton:SetAllPoints();
TextureHide( MiniMapTrackingBackground );
MiniMapTrackingButtonShine:SetAllPoints();
MiniMapTrackingButton:SetScript( "OnMouseUp", nil );
MiniMapTrackingButton:SetScript( "OnMouseDown", nil );

SkinButton( MiniMapMailFrame, 1, MiniMapMailBorder, MiniMapMailIcon, true );
MiniMapMailFrame:SetPoint( "BOTTOMRIGHT", Minimap, -1, 0 );
MiniMapMailIcon:SetTexture( [[Interface\Minimap\Tracking\Mailbox]] ); -- No black background

SkinButton( MiniMapBattlefieldFrame, 1.5, MiniMapBattlefieldBorder, MiniMapBattlefieldIcon );
MiniMapBattlefieldFrame:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );
BattlegroundShine:SetAllPoints();

SkinButton( MiniMapLFGFrame, 1.75, MiniMapLFGFrameBorder, MiniMapLFGFrameIconTexture );
MiniMapLFGFrame:SetPoint( "RIGHT", MiniMapBattlefieldFrame, "LEFT" );
MiniMapLFGFrameIcon:SetAllPoints();


-- Move the zone text inside of the square
MinimapZoneTextButton:SetFrameStrata( "LOW" );
MinimapZoneTextButton:ClearAllPoints();
MinimapZoneTextButton:SetPoint( "TOPRIGHT", Minimap, 0, -2 );
MinimapZoneTextButton:SetPoint( "LEFT", Minimap );
MinimapZoneTextButton:EnableMouse( false );
MinimapZoneTextButton:SetAlpha( 0.5 );
MinimapZoneText:SetAllPoints();
MinimapZoneText:SetFontObject( NumberFontNormalSmall );

--- Repositions this instance difficulty indicator to fit a square minimap.
local function SkinDifficulty ( self )
	self:ClearAllPoints();
	self:SetPoint( "TOPRIGHT", 4, 4 );
	self:SetScale( 0.7 );
	self:SetAlpha( 0.8 );
	self:EnableMouse( false );
end
SkinDifficulty( MiniMapInstanceDifficulty );
SkinDifficulty( GuildInstanceDifficulty );


-- Move and shrink the GM ticket frame
TicketStatusFrame:ClearAllPoints();
TicketStatusFrame:SetPoint( "TOPRIGHT", MinimapCluster, "TOPLEFT", -8, 0 );
TicketStatusFrame:SetScale( 0.85 );
TicketStatusFrame:SetAlpha( 0.75 );