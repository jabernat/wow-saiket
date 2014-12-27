--[[****************************************************************************
  * _Underscore.Minimap by Saiket                                              *
  * _Underscore.Minimap.lua - Square the minimap and clean it up.              *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local NS = select( 2, ... );
_Underscore.Minimap = NS;

NS.Frame = CreateFrame( "Frame" );
NS.PingName = CreateFrame( "ScrollFrame", nil, Minimap );

local IconSize = 14;
local MinimapScale = 0.9;




--- Hook to broadcast a ping on a square minimap.
function NS:OnMouseUp ()
	local CursorX, CursorY = GetCursorPosition();
	local CenterX, CenterY = self:GetCenter();
	local Scale = self:GetEffectiveScale();

	self:PingLocation(
		CursorX / Scale - CenterX,
		CursorY / Scale - CenterY );
end


--- Displays the name of the player who pinged.
function NS.PingName:MINIMAP_PING ( _, UnitID )
	self:Show();
	self:SetAlpha( 1 );
	self.Text:SetText( UnitName( UnitID ) );
	self.Duration = MINIMAPPING_TIMER;
end
--- Timer to automatically hide ping text as the blip fades out.
function NS.PingName:OnUpdate ( Elapsed )
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
function NS:OnMouseWheel ( Delta )
	self:SetZoom( min( max( self:GetZoom() + Delta, 0 ), self:GetZoomLevels() - 1 ) );
end
--- Restore the original minimap shape in case _Underscore was disabled right before a reload UI.
-- This corrects a bug where the minimap mask stays square in the default UI.
function NS.Frame:PLAYER_LOGOUT ()
	Minimap:SetMaskTexture( [[Textures\MinimapMask]] );
end
--- Lets other addons know that the minimap is square.
function NS.GetMinimapShape ()
	return "SQUARE";
end




NS.Frame:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
NS.Frame:RegisterEvent( "PLAYER_LOGOUT" );

NS.PingName:Hide();
NS.PingName:SetAllPoints();
local Container = CreateFrame( "Frame", nil, NS.PingName );
Container:SetSize( 1, 1 );
NS.PingName:SetScrollChild( Container );
NS.PingName.Text = Container:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmallGray" );
NS.PingName:SetScript( "OnUpdate", NS.PingName.OnUpdate );
NS.PingName:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
NS.PingName:RegisterEvent( "MINIMAP_PING" );

MinimapCluster:ClearAllPoints();
MinimapCluster:SetPoint( "TOPRIGHT", _Underscore.TopMargin, "BOTTOMRIGHT" );
MinimapCluster:SetSize( Minimap:GetSize() );
MinimapCluster:SetScale( MinimapScale );
MinimapCluster:EnableMouse( false );
_Underscore.Backdrop.Create( Minimap );


Minimap:SetAllPoints( MinimapCluster );
Minimap:SetMaskTexture( [[Interface\Buttons\WHITE8X8]] );
GetMinimapShape = NS.GetMinimapShape;
-- Hide blob clipping borders, since they only work for round minimaps
Minimap:SetArchBlobRingAlpha( 0 );
Minimap:SetQuestBlobRingAlpha( 0 );

-- Hooks to allow pings on a square minimap
Minimap_OnClick = NS.OnMouseUp;
Minimap:SetScript( "OnMouseUp", NS.OnMouseUp );
-- Show name of player who pinged
NS.PingName:SetAlpha( 0.75 );




--- Hides this texture and releases resources.
local function TextureHide ( self )
	self:Hide();
	self:SetTexture();
end

-- Replace zoom buttons
Minimap:HookScript( "OnMouseWheel", NS.OnMouseWheel );
Minimap:EnableMouseWheel( true );

MinimapZoomIn:Hide();
MinimapZoomOut:Hide();


-- Move default buttons that sit around the minimap
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
	if ( Border ) then
		TextureHide( Border );
	end
	if ( Icon ) then
		Icon:SetAllPoints();
		_Underscore.SkinButtonIcon( Icon );
		if ( not NoRecolor ) then
			Icon:SetVertexColor( unpack( _Underscore.Colors.Foreground ) );
		end
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

SkinButton( QueueStatusMinimapButton, 1.5, QueueStatusMinimapButtonBorder, QueueStatusMinimapButtonIconTexture );
QueueStatusMinimapButton:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );

SkinButton( GarrisonLandingPageMinimapButton, 1 );
GarrisonLandingPageMinimapButton:SetHitRectInsets( 0, 0, 0, 0 );
GarrisonLandingPageMinimapButton:SetPoint( "LEFT", MiniMapTracking, "RIGHT" );


-- Move the zone text inside of the square
MinimapZoneTextButton:SetFrameLevel( Minimap:GetFrameLevel() + 1 );
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
if ( IsAddOnLoaded( "_Underscore.ActionBars" ) ) then
	-- Move ticket button from help micro-button to the minimap
	HelpOpenTicketButton:SetParent( Minimap );
	HelpOpenTicketButton:ClearAllPoints();
	HelpOpenTicketButton:SetPoint( "CENTER", Minimap, "BOTTOMLEFT", -2, -2 );
	HelpOpenTicketButton:SetScale( 0.8 );
end