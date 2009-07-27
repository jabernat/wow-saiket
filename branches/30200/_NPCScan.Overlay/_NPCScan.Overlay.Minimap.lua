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
	local Radius, RadiusMax, Side;
	local X, Y, Facing;
	local FacingSin, FacingCos;
	local RepaintPathData;
	do
		local Map, PathData, Width, Height;
		local Ax, Ax2, Ay, Ay2, Bx, Bx2, By, By2, Cx, Cx2, Cy, Cy2;
		local Max = 2 ^ 16 - 1;
		function RepaintPathData ( NpcID, R, G, B )
			Map = Overlay.NPCMaps[ NpcID ];
			PathData = Overlay.PathData[ Map ][ NpcID ];
			Width, Height = Overlay.GetZoneSize( Map );
			Width, Height = Width / Max, Height / Max;

			for Index = 1, #PathData, 12 do
				Ax, Ax2, Ay, Ay2, Bx, Bx2, By, By2, Cx, Cx2, Cy, Cy2 = PathData:byte( Index, Index + 11 );
				Ax, Ay = ( Ax * 256 + Ax2 ) * Width - X, ( Ay * 256 + Ay2 ) * Height - Y;
				Bx, By = ( Bx * 256 + Bx2 ) * Width - X, ( By * 256 + By2 ) * Height - Y;
				Cx, Cy = ( Cx * 256 + Cx2 ) * Width - X, ( Cy * 256 + Cy2 ) * Height - Y;

				if ( not RotateMinimap
					or ( Ax >= -RadiusMax and Ax <= RadiusMax and Ay >= -RadiusMax and Ay <= RadiusMax )
					or ( Bx >= -RadiusMax and Bx <= RadiusMax and By >= -RadiusMax and By <= RadiusMax )
					or ( Cx >= -RadiusMax and Cx <= RadiusMax and Cy >= -RadiusMax and Cy <= RadiusMax )
				) then
					if ( RotateMinimap ) then
						Ax, Ay = Ax * FacingCos - Ay * FacingSin, Ax * FacingSin + Ay * FacingCos;
						Bx, By = Bx * FacingCos - By * FacingSin, Bx * FacingSin + By * FacingCos;
						Cx, Cy = Cx * FacingCos - Cy * FacingSin, Cx * FacingSin + Cy * FacingCos;
					end
					if ( ( Ax >= -Radius and Ax <= Radius and Ay >= -Radius and Ay <= Radius )
						or ( Bx >= -Radius and Bx <= Radius and By >= -Radius and By <= Radius )
						or ( Cx >= -Radius and Cx <= Radius and Cy >= -Radius and Cy <= Radius )
					) then
						-- Tri within square of minimap
						Overlay.TextureDraw( Overlay.TextureAdd( me, NpcID, "ARTWORK", R, G, B, 0.55 ),
							Ax / Side + 0.5, Ay / Side + 0.5,
							Bx / Side + 0.5, By / Side + 0.5,
							Cx / Side + 0.5, Cy / Side + 0.5 );
					end
				end
			end
		end
	end

	local RadiiInside = { 150, 120, 90, 60, 40, 25 };
	local RadiiOutside = { 233 + 1 / 3, 200, 166 + 2 / 3, 133 + 1 / 3, 100, 66 + 2 / 3 };
	function me:Repaint ( Map, NewX, NewY, NewFacing )
		Overlay.PathRemoveAll( self );

		X = NewX;
		Y = NewY;
		Facing = NewFacing;

		Radius = ( IsInside and RadiiInside or RadiiOutside )[ Minimap:GetZoom() + 1 ];
		Side = Radius * 2;

		if ( RotateMinimap ) then
			RadiusMax = ( Radius ^ 2 * 2 ) ^ 0.5; -- Points within this range can potentially be inside the minimap when rotated
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
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:CVAR_UPDATE                             *
  ****************************************************************************]]
function me:CVAR_UPDATE ( _, CVar, Value )
	if ( CVar == "ROTATE_MINIMAP" ) then
		RotateMinimap = Value == "1";
		me.UpdateForce = true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:PLAYER_LOGIN                            *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	RotateMinimap = GetCVarBool( "rotateMinimap" );
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
		me.UpdateForce = true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Minimap:Disable                                 *
  ****************************************************************************]]
function me:Disable ()
	self:Hide();
	Overlay.PolygonRemoveAll( self );
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

	Overlay.ModuleRegister( "Minimap", me );
end
