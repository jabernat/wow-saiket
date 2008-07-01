--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Minimap.lua - Square the minimap and clean it up.                   *
  *                                                                            *
  * + Makes the minimap square and allows pinging outside of the default       *
  *   circular area.                                                           *
  * + Removes the title above the minimap and relocates the zone name to the   *
  *   top inside of the frame. The toggle button is removed.                   *
  * + Shrinks many of the small indicators that floated around the default     *
  *   minimap and lines them up along the bottom edge of the new one. The      *
  *   tracking frame appears at the bottom left, and the mail/BG/meeting stone *
  *   icons line up in the bottom right. The game time frame is removed.       *
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
  * Function: _Clean.Minimap.MinimapOnClick                                    *
  * Description: Broadcasts a ping at the cursor's location for a square       *
  *   minimap.                                                                 *
  ****************************************************************************]]
function me.MinimapOnClick ()
	if ( not SpellIsTargeting() ) then -- Ping protected when casting spells
		local CursorX, CursorY = GetCursorPosition();
		local CenterX, CenterY = this:GetCenter();
		local Scale = this:GetEffectiveScale();
	
		Minimap:PingLocation(
			CursorX / Scale - CenterX,
			CursorY / Scale - CenterY );
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
	Minimap_SetPing = me.MinimapSetPing;
	Minimap_OnClick = me.MinimapOnClick;

	GetMinimapShape = me.GetMinimapShape;


	-- Expand the minimap to a square and replace the artwork with a simple border
	Minimap:SetMaskTexture( "Interface\\Buttons\\WHITE8X8" );
	Minimap:SetBackdrop( {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";
		insets = { left = -2, right = -2, top = -2, bottom = -2 }
	} );
	Minimap:SetBackdropColor(
		DEFAULT_CHATFRAME_COLOR.r,
		DEFAULT_CHATFRAME_COLOR.g,
		DEFAULT_CHATFRAME_COLOR.b,
		DEFAULT_CHATFRAME_ALPHA );
	Minimap:SetBlipTexture( "Interface\\AddOns\\_Clean\\Skin\\ObjectIcons" );

	MinimapCluster:SetScale( 0.9 );
	MinimapCluster:ClearAllPoints();
	MinimapCluster:SetPoint( "TOPRIGHT", UIParent, 17, 23 );
	MinimapCluster:EnableMouse( false );

	MinimapToggleButton:Hide();
	MinimapBorderTop:Hide();
	MinimapBorderTop:SetTexture();
	MinimapBorder:Hide();
	MinimapBorder:SetTexture();
	MinimapNorthTag:Hide();
	MinimapNorthTag:SetTexture();


	-- Align the ping model with its frame
	MiniMapPing:SetPosition( 0.0061, 0.0061, 0 );
	MiniMapPing:SetWidth( 15 );
	MiniMapPing:SetHeight( 15 );


	-- Move default buttons that sit around the minimap
	GameTimeFrame:Hide();
	MiniMapWorldMapButton:Hide();

	MiniMapTracking:SetAlpha( 0.6 );
	MiniMapTracking:ClearAllPoints();
	MiniMapTracking:SetPoint( "BOTTOMLEFT", Minimap )
	MiniMapTracking:SetWidth( 14 );
	MiniMapTracking:SetHeight( 14 );
	MiniMapTrackingBorder:Hide();
	MiniMapTrackingBorder:SetTexture();
	MiniMapTrackingBackground:Hide();
	MiniMapTrackingBackground:SetTexture();
	MiniMapTrackingIcon:SetAllPoints( MiniMapTracking );
	_Clean.RemoveButtonIconBorder( MiniMapTrackingIcon );

	-- Voice chat button
	MiniMapVoiceChatFrame:ClearAllPoints();
	MiniMapVoiceChatFrame:Hide();

	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint( "BOTTOMRIGHT", Minimap, -1, 1 );
	MiniMapMailFrame:SetWidth( 14 );
	MiniMapMailFrame:SetHeight( 14 );
	MiniMapMailBorder:Hide();
	MiniMapMailBorder:SetTexture();
	MiniMapMailIcon:SetAllPoints( MiniMapMailFrame );
	_Clean.RemoveButtonIconBorder( MiniMapMailIcon );

	MiniMapBattlefieldFrame:ClearAllPoints();
	MiniMapBattlefieldFrame:SetPoint( "RIGHT", MiniMapMailFrame, "LEFT" );
	MiniMapBattlefieldFrame:SetWidth( 20 );
	MiniMapBattlefieldFrame:SetHeight( 20 );
	MiniMapBattlefieldBorder:Hide();
	MiniMapBattlefieldBorder:SetTexture();
	MiniMapBattlefieldIcon:SetAllPoints( MiniMapBattlefieldFrame );
	BattlegroundShine:SetAllPoints( MiniMapBattlefieldFrame );

	MiniMapMeetingStoneFrame:ClearAllPoints();
	MiniMapMeetingStoneFrame:SetPoint( "RIGHT", MiniMapBattlefieldFrame, "LEFT" );
	MiniMapMeetingStoneFrame:SetWidth( 20 );
	MiniMapMeetingStoneFrame:SetHeight( 20 );
	MiniMapMeetingStoneBorder:Hide();
	MiniMapMeetingStoneBorder:SetTexture();
	MiniMapMeetingStoneFrameIcon:SetAllPoints( MiniMapMeetingStoneFrame );


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
