--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Minimap.lua - Square the minimap and clean it up.                   *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.Minimap = me;




--[[****************************************************************************
  * Function: _Clean.Minimap.MinimapSetPing                                    *
  * Description: This is the OnUpdate function to move the minimap ping on a   *
  *   square minimap.                                                          *
  ****************************************************************************]]
function me.MinimapSetPing ( X, Y, Sound )
	if ( abs( X ) <= 0.5 and abs( Y ) <= 0.5 ) then
		MiniMapPing:SetPoint( "CENTER", Minimap, "CENTER",
			X * Minimap:GetWidth(), Y * Minimap:GetHeight() );
		MiniMapPing:SetAlpha( 1.0 );
		MiniMapPing:Show();
		if ( Sound ) then
			PlaySound( "MapPing" );
		end
	else
		MiniMapPing:Hide();
	end
end
--[[****************************************************************************
  * Function: _Clean.Minimap:MinimapOnClick                                    *
  * Description: Broadcasts a ping at the cursor's location for a square       *
  *   minimap.                                                                 *
  ****************************************************************************]]
function me:MinimapOnClick ()
	local CursorX, CursorY = GetCursorPosition();
	local CenterX, CenterY = self:GetCenter();
	local Scale = self:GetEffectiveScale();

	self:PingLocation(
		CursorX / Scale - CenterX,
		CursorY / Scale - CenterY );
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
	Minimap_SetPing = me.MinimapSetPing;
	Minimap:SetScript( "OnMouseUp", me.MinimapOnClick );

	local Background = _Clean.Colors.Background;
	local Foreground = _Clean.Colors.Foreground;

	-- Expand the minimap to a square and replace the artwork with a simple border
	GetMinimapShape = me.GetMinimapShape;
	Minimap:SetMaskTexture( "Interface\\Buttons\\WHITE8X8" );
	Minimap:SetBlipTexture( "Interface\\AddOns\\_Clean\\Skin\\ObjectIcons" );

	MinimapCluster:SetWidth( Minimap:GetWidth() );
	MinimapCluster:SetHeight( Minimap:GetHeight() );
	MinimapCluster:SetScale( 0.9 );
	Minimap:SetAllPoints( MinimapCluster );
	MinimapCluster:ClearAllPoints();
	MinimapCluster:SetPoint( "TOPRIGHT", UIParent, 0, -16 );
	MinimapCluster:EnableMouse( false );
	_Clean.Backdrop.Add( MinimapCluster, _Clean.Backdrop.Padding );

	MinimapToggleButton:Hide();
	MinimapBorderTop:Hide();
	MinimapBorderTop:SetTexture();
	MinimapBorder:Hide();
	MinimapBorder:SetTexture();
	MinimapNorthTag:Hide();
	MinimapNorthTag:SetTexture();


	-- Align the ping model with its frame
	MiniMapPing:SetWidth( 15 );
	MiniMapPing:SetHeight( 15 );
	local Hypotenuse = ( GetScreenWidth() ^ 2 + GetScreenHeight() ^ 2 ) ^ 0.5 * UIParent:GetEffectiveScale();
	local Center = 0.5 * MiniMapPing:GetWidth() / Hypotenuse;
	MiniMapPing:SetPosition( Center, Center, 0 );


	-- Move default buttons that sit around the minimap
	GameTimeFrame:Hide();
	MiniMapWorldMapButton:Hide();

	MiniMapTracking:ClearAllPoints();
	MiniMapTracking:SetPoint( "BOTTOMLEFT", Minimap, -1, 0 );
	MiniMapTracking:SetWidth( 14 );
	MiniMapTracking:SetHeight( 14 );
	MiniMapTrackingButton:SetAllPoints( MiniMapTracking );
	MiniMapTrackingButtonBorder:Hide();
	MiniMapTrackingButtonBorder:SetTexture();
	MiniMapTrackingBackground:Hide();
	MiniMapTrackingBackground:SetTexture();
	MiniMapTrackingIcon:SetAllPoints( MiniMapTracking );
	MiniMapTrackingIcon:SetGradientAlpha( "VERTICAL", Background.r, Background.g, Background.b, Background.a, Foreground.r, Foreground.g, Foreground.b, Foreground.a );
	MiniMapTrackingButtonShine:SetAllPoints();
	_Clean.RemoveButtonIconBorder( MiniMapTrackingIcon );
	MiniMapTrackingButton:SetScript( "OnMouseUp", nil );
	MiniMapTrackingButton:SetScript( "OnMouseDown", nil );

	-- Voice chat button
	MiniMapVoiceChatFrame:ClearAllPoints();
	MiniMapVoiceChatFrame:Hide();

	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint( "BOTTOMRIGHT", Minimap, -1, 0 );
	MiniMapMailFrame:SetWidth( 14 );
	MiniMapMailFrame:SetHeight( 14 );
	MiniMapMailBorder:Hide();
	MiniMapMailBorder:SetTexture();
	MiniMapMailIcon:SetAllPoints( MiniMapMailFrame );
	MiniMapMailIcon:SetGradientAlpha( "VERTICAL", Background.r, Background.g, Background.b, Background.a, Foreground.r, Foreground.g, Foreground.b, Foreground.a );
	MiniMapMailIcon:SetTexture( "Interface\\Minimap\\Tracking\\Mailbox" ); -- No black background
	_Clean.RemoveButtonIconBorder( MiniMapMailIcon );

	MiniMapBattlefieldFrame:ClearAllPoints();
	MiniMapBattlefieldFrame:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );
	MiniMapBattlefieldFrame:SetWidth( 20 );
	MiniMapBattlefieldFrame:SetHeight( 20 );
	MiniMapBattlefieldBorder:Hide();
	MiniMapBattlefieldBorder:SetTexture();
	MiniMapBattlefieldIcon:SetAllPoints( MiniMapBattlefieldFrame );
	MiniMapBattlefieldIcon:SetGradientAlpha( "VERTICAL", Background.r, Background.g, Background.b, Background.a, Foreground.r, Foreground.g, Foreground.b, Foreground.a );
	BattlegroundShine:SetAllPoints( MiniMapBattlefieldFrame );

	MiniMapMeetingStoneFrame:ClearAllPoints();
	MiniMapMeetingStoneFrame:SetPoint( "RIGHT", MiniMapBattlefieldFrame, "LEFT" );
	MiniMapMeetingStoneFrame:SetWidth( 20 );
	MiniMapMeetingStoneFrame:SetHeight( 20 );
	MiniMapMeetingStoneBorder:Hide();
	MiniMapMeetingStoneBorder:SetTexture();
	MiniMapMeetingStoneFrameIcon:SetAllPoints( MiniMapMeetingStoneFrame );
	MiniMapMeetingStoneFrameIconTexture:SetGradientAlpha( "VERTICAL", Background.r, Background.g, Background.b, Background.a, Foreground.r, Foreground.g, Foreground.b, Foreground.a );


	-- Move the zone text inside of the square
	MinimapZoneTextButton:SetFrameStrata( "LOW" );
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetPoint( "TOPLEFT", Minimap, 0, -2 );
	MinimapZoneTextButton:SetPoint( "RIGHT", Minimap );
	MinimapZoneTextButton:EnableMouse( false );
	MinimapZoneTextButton:SetAlpha( 0.5 );
	MinimapZoneText:SetAllPoints( MinimapZoneTextButton );
	MinimapZoneText:SetFontObject( NumberFontNormalSmall );
end
