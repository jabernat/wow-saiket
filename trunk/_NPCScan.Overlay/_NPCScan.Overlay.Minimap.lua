--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.Minimap.lua - Canvas for the Minimap.                     *
  ****************************************************************************]]


local L = _NPCScanLocalization.OVERLAY;
local Overlay = _NPCScan.Overlay;
local me = CreateFrame( "Frame", nil, Minimap );
Overlay.Minimap = me;

me.Label = L.MODULE_MINIMAP;

me.UpdateRate = 0.04;
me.UpdateDistance = 0.5;

local Minimap = Minimap;
local UpdateForce, IsInside, RotateMinimap;

-- Lots of thanks to Routes (http://www.wowace.com/addons/routes/)




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:Repaint                                 *
  ****************************************************************************]]
do
	local Quadrants;
	local X, Y, Facing, Width, Height;
	local FacingSin, FacingCos;
	local MaxDataValue = 2 ^ 16 - 1;

	local RepaintPathData;
	do
		local PathData;
		local Ax, Ax2, Ay, Ay2, Bx, Bx2, By, By2, Cx, Cx2, Cy, Cy2;
		local AInside, BInside, CInside;
		local function IsQuadrantRound ( X, Y )
			return Quadrants[ Y > 0
				and ( X > 0 and 1 or 2 )
				 or ( X < 0 and 3 or 4 ) ];
		end
		function RepaintPathData ( NpcID, R, G, B )
			PathData = Overlay.PathData[ Overlay.NPCMaps[ NpcID ] ][ NpcID ];

			for Index = 1, #PathData, 12 do
				Ax, Ax2, Ay, Ay2, Bx, Bx2, By, By2, Cx, Cx2, Cy, Cy2 = PathData:byte( Index, Index + 11 );
				Ax, Ay = ( Ax * 256 + Ax2 ) * Width - X, ( Ay * 256 + Ay2 ) * Height - Y;
				Bx, By = ( Bx * 256 + Bx2 ) * Width - X, ( By * 256 + By2 ) * Height - Y;
				Cx, Cy = ( Cx * 256 + Cx2 ) * Width - X, ( Cy * 256 + Cy2 ) * Height - Y;

				if ( RotateMinimap ) then
					Ax, Ay = Ax * FacingCos - Ay * FacingSin, Ax * FacingSin + Ay * FacingCos;
					Bx, By = Bx * FacingCos - By * FacingSin, Bx * FacingSin + By * FacingCos;
					Cx, Cy = Cx * FacingCos - Cy * FacingSin, Cx * FacingSin + Cy * FacingCos;
				end

				if ( -- If all points are on one side, cannot possibly intersect
					not ( ( Ax > 0.5 and Bx > 0.5 and Cx > 0.5 )
					or ( Ay > 0.5 and By > 0.5 and Cy > 0.5 )
					or ( Ax < -0.5 and Bx < -0.5 and Cx < -0.5 )
					or ( Ay < -0.5 and By < -0.5 and Cy < -0.5 ) )
				) then
					AInside = IsQuadrantRound( Ax, Ay ) and ( Ax * Ax + Ay * Ay <= 0.25 )
						or ( Ax <= 0.5 and Ay <= 0.5 and Ax >= -0.5 and Ay >= -0.5 );
					BInside = IsQuadrantRound( Bx, By ) and ( Bx * Bx + By * By <= 0.25 )
						or ( Bx <= 0.5 and By <= 0.5 and Bx >= -0.5 and By >= -0.5 );
					CInside = IsQuadrantRound( Cx, Cy ) and ( Cx * Cx + Cy * Cy <= 0.25 )
						or ( Cx <= 0.5 and Cy <= 0.5 and Cx >= -0.5 and Cy >= -0.5 );

					-- Tri within square of minimap
					Overlay.TextureDraw( Overlay.TextureAdd( me, NpcID, "ARTWORK", R, G, B, 0.55 ),
						Ax + 0.5, Ay + 0.5, Bx + 0.5, By + 0.5, Cx + 0.5, Cy + 0.5 );
				end
			end
		end
	end

	local MinimapShapes = { -- Credit to MobileMinimapButtons as seen at <http://www.wowwiki.com/GetMinimapShape>
		-- [ Shape ] = { UR, UL, LL, LR }; where true = rounded and false = squared
		[ "ROUND" ]                 = {  true,  true,  true,  true };
		[ "SQUARE" ]                = { false, false, false, false };
		[ "CORNER-TOPRIGHT" ]       = {  true, false, false, false };
		[ "CORNER-TOPLEFT" ]        = { false,  true, false, false };
		[ "CORNER-BOTTOMLEFT" ]     = { false, false,  true, false };
		[ "CORNER-BOTTOMRIGHT" ]    = { false, false, false,  true };
		[ "SIDE-TOP" ]              = {  true,  true, false, false };
		[ "SIDE-LEFT" ]             = { false,  true,  true, false };
		[ "SIDE-BOTTOM" ]           = { false, false,  true,  true };
		[ "SIDE-RIGHT" ]            = {  true, false, false,  true };
		[ "TRICORNER-BOTTOMLEFT" ]  = { false,  true,  true,  true };
		[ "TRICORNER-BOTTOMRIGHT" ] = {  true, false,  true,  true };
		[ "TRICORNER-TOPRIGHT" ]    = {  true,  true, false,  true };
		[ "TRICORNER-TOPLEFT" ]     = {  true,  true,  true, false };
	};
	local RadiiInside = { 150, 120, 90, 60, 40, 25 };
	local RadiiOutside = { 233 + 1 / 3, 200, 166 + 2 / 3, 133 + 1 / 3, 100, 66 + 2 / 3 };
	function me:Repaint ( Map, NewX, NewY, NewFacing )
		Overlay.PathRemoveAll( self );

		Quadrants = MinimapShapes[ GetMinimapShape and GetMinimapShape() ] or MinimapShapes[ "ROUND" ];

		local Side = ( IsInside and RadiiInside or RadiiOutside )[ Minimap:GetZoom() + 1 ] * 2;
		Width, Height = Overlay.GetZoneSize( Map );
		Width, Height = Width / MaxDataValue / Side, Height / MaxDataValue / Side; -- Simplifies data decompression
		X = NewX / Side;
		Y = NewY / Side;
		Facing = NewFacing;

		if ( RotateMinimap ) then
			FacingSin = math.sin( Facing );
			FacingCos = math.cos( Facing );
		end

		Overlay.ApplyZone( Map, RepaintPathData );
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:SetZoom                                 *
  ****************************************************************************]]
do
	local Backup = Minimap.SetZoom;
	function me:SetZoom ( Zoom, ... )
		if ( self:GetZoom() ~= Zoom ) then
			UpdateForce = true;
		end
		return Backup( Minimap, Zoom, ... );
	end
end

--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:MINIMAP_UPDATE_ZOOM                     *
  * Description: Fires when the minimap swaps between indoor and outdoor zoom. *
  ****************************************************************************]]
function me:MINIMAP_UPDATE_ZOOM ()
	local Zoom = Minimap:GetZoom();
	if ( GetCVar( "minimapZoom" ) == GetCVar( "minimapInsideZoom" ) ) then -- Indeterminate case
		Minimap:SetZoom( Zoom > 0 and Zoom - 1 or Zoom + 1 ); -- Any change to make the cvars unequal
	end
	IsInside = Minimap:GetZoom() == GetCVar( "minimapInsideZoom" ) + 0;
	Minimap:SetZoom( Zoom );
	UpdateForce = true;
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:ZONE_CHANGED_NEW_AREA                   *
  ****************************************************************************]]
function me:ZONE_CHANGED_NEW_AREA ()
	UpdateForce = true;
	if ( not WorldMapFrame:IsVisible() ) then
		SetMapToCurrentZone();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:CVAR_UPDATE                             *
  ****************************************************************************]]
function me:CVAR_UPDATE ( _, CVar, Value )
	if ( CVar == "ROTATE_MINIMAP" ) then
		RotateMinimap = Value == "1";
		UpdateForce = true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:PLAYER_LOGIN                            *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	RotateMinimap = GetCVarBool( "rotateMinimap" );
	SetMapToCurrentZone();
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:OnShow                                  *
  ****************************************************************************]]
function me:OnShow ()
	UpdateForce = true;
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:OnUpdate                                *
  ****************************************************************************]]
do
	local GetPlayerMapPosition = GetPlayerMapPosition;
	local GetRealZoneText = GetRealZoneText;
	local GetPlayerFacing = GetPlayerFacing;
	local GetMapInfo = GetMapInfo;
	local UpdateNext = 0;
	local LastX, LastY, LastFacing;
	function me:OnUpdate ( Elapsed )
		UpdateNext = UpdateNext - Elapsed;
		if ( UpdateForce or UpdateNext <= 0 ) then
			UpdateNext = self.UpdateRate;

			local Map = Overlay.ZoneMaps[ GetRealZoneText() ];
			local X, Y = GetPlayerMapPosition( "player" );
			if ( not Map or ( X == 0 and Y == 0 )
				or X < 0 or X > 1 or Y < 0 or Y > 1
				or Map ~= GetMapInfo() -- Coordinates will be for wrong map
			) then
				UpdateForce = nil;
				Overlay.PathRemoveAll( self );
				return;
			end

			local Facing = RotateMinimap and GetPlayerFacing() or 0;
			local Width, Height = Overlay.GetZoneSize( Map );
			X = X * Width;
			Y = Y * Height;

			if ( UpdateForce or Facing ~= LastFacing or ( X - LastX ) ^ 2 + ( Y - LastY ) ^ 2 >= self.UpdateDistance ) then
				UpdateForce = nil;
				LastX = X;
				LastY = Y;
				LastFacing = Facing;

				self:Repaint( Map, X, Y, Facing );
			end
		end
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:Update                                  *
  ****************************************************************************]]
function me:Update ( Map )
	if ( not Map or Map == Overlay.ZoneMaps[ GetRealZoneText() ] ) then
		UpdateForce = true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:Disable                                 *
  ****************************************************************************]]
function me:Disable ()
	self:Hide();
	Overlay.PathRemoveAll( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:Enable                                  *
  ****************************************************************************]]
function me:Enable ()
	self:Show();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetAllPoints();
	me:SetScript( "OnShow", me.OnShow );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", _NPCScan.OnEvent );
	me:RegisterEvent( "MINIMAP_UPDATE_ZOOM" );
	me:RegisterEvent( "ZONE_CHANGED_NEW_AREA" );
	me:RegisterEvent( "CVAR_UPDATE" );
	me:RegisterEvent( "PLAYER_LOGIN" );

	Minimap.SetZoom = me.SetZoom;
	WorldMapFrame:HookScript( "OnHide", SetMapToCurrentZone );

	Overlay.ModuleRegister( "Minimap", me );
end
