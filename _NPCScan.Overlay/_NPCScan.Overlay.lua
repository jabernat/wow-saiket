--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.lua - Adds mob patrol paths to your map.                  *
  ****************************************************************************]]


local L = _NPCScanLocalization.OVERLAY;
local me = {};
_NPCScan.Overlay = me;
me.Version = GetAddOnMetadata( "_NPCScan.Overlay", "Version" ):match( "^([%d.]+)" );

local TexturesUnused = {};
local TexturesUsed = {};




--[[****************************************************************************
  * Function: _NPCScan.Overlay:TextureDraw                                     *
  * Description: Sets a triangle texture's texcoords to a set of real coords.  *
  ****************************************************************************]]
do
	local Det, AF, BF, CD, CE;
	local function ApplyTransform( self, A, B, C, D, E, F )
		Det = A * E - B * D;
		AF, BF, CD, CE = A * F, B * F, C * D, C * E;

		self:SetTexCoord(
			( BF - CE ) / Det, ( CD - AF ) / Det,
			( BF - CE - B ) / Det, ( CD - AF + A ) / Det,
			( BF - CE + E ) / Det, ( CD - AF - D ) / Det,
			( BF - CE + E - B ) / Det, ( CD - AF - D + A ) / Det );
	end
	local ABx, ABy, BCx, BCy;
	local ScaleX, ScaleY, ShearFactor, Sin, Cos;
	function me:TextureDraw ( Ax, Ay, Bx, By, Cx, Cy )
		ABx, ABy, BCx, BCy = Ax - Bx, Ay - By, Bx - Cx, By - Cy;

		-- Translate, rotate, scale, and shear so three of the parallelogram's corners lie on the points
		ScaleX = ( BCx * BCx + BCy * BCy ) ^ 0.5;
		ScaleY = ( ABx * BCy - BCx * ABy ) / ScaleX;
		ShearFactor = -( ABx * BCx + ABy * BCy ) / ( ScaleX * ScaleX );
		Sin, Cos = BCy / ScaleX, -BCx / ScaleX;

		ApplyTransform( self,
			 Cos * ScaleX, Sin * ScaleY + Cos * ScaleX * ShearFactor, Bx,
			-Sin * ScaleX, Cos * ScaleY - Sin * ScaleX * ShearFactor, By );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:TextureAdd                                      *
  * Description: Gets an unused texture and adds it to the given frame.        *
  ****************************************************************************]]
function me:TextureAdd ( ID )
	local Texture = TexturesUnused[ #TexturesUnused ];
	if ( Texture ) then
		TexturesUnused[ #TexturesUnused ] = nil;
		Texture:SetParent( self );
		Texture:Show();
	else
		Texture = self:CreateTexture();
		Texture:SetTexture( [[Interface\AddOns\_NPCScan.Overlay\Skin\Triangle]] );
	end
	Texture:SetAllPoints();
	Texture.ID = ID;

	local UsedCache = TexturesUsed[ self ];
	if ( not UsedCache ) then
		UsedCache = {};
		TexturesUsed[ self ] = UsedCache;
	end
	UsedCache[ #UsedCache + 1 ] = Texture;
	return Texture;
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay:PolygonRemoveAll                                *
  * Description: Removes all polygon artwork from a frame.                     *
  ****************************************************************************]]
function me:PolygonRemoveAll ()
	if ( TexturesUsed[ self ] ) then
		for _, Texture in ipairs( TexturesUsed[ self ] ) do
			TexturesUnused[ #TexturesUnused + 1 ] = Texture;
			Texture:Hide();
		end
		wipe( TexturesUsed[ self ] );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:PolygonRemove                                   *
  * Description: Reclaims all textures associated with a polygon set ID.       *
  ****************************************************************************]]
function me:PolygonRemove ( ID )
	local UsedCache = TexturesUsed[ self ];
	if ( UsedCache ) then
		for Index = #UsedCache, 1, -1 do
			local Texture = UsedCache[ Index ];
			if ( Texture.ID == ID ) then
				tremove( UsedCache, Index );
				TexturesUnused[ #TexturesUnused + 1 ] = Texture;
				Texture:Hide();
			end
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:PolygonDraw                                     *
  * Description: Draws the given polygon onto a frame.                         *
  ****************************************************************************]]
do
	local byte = string.byte;
	local lshift = bit.lshift;
	local Max = 2 ^ 16 - 1;
	function me:PolygonAdd ( ID, PolyData, R, G, B, A )
		for Index = 1, #PolyData, 12 do
			local Ax, Ay, Bx, By, Cx, Cy =
				( lshift( byte( PolyData, Index ), 8 ) + byte( PolyData, Index + 1 ) ) / Max,
				( lshift( byte( PolyData, Index + 2 ), 8 ) + byte( PolyData, Index + 3 ) ) / Max,
				( lshift( byte( PolyData, Index + 4 ), 8 ) + byte( PolyData, Index + 5 ) ) / Max,
				( lshift( byte( PolyData, Index + 6 ), 8 ) + byte( PolyData, Index + 7 ) ) / Max,
				( lshift( byte( PolyData, Index + 8 ), 8 ) + byte( PolyData, Index + 9 ) ) / Max,
				( lshift( byte( PolyData, Index + 10 ), 8 ) + byte( PolyData, Index + 11 ) ) / Max;
			local Texture = me.TextureAdd( self, ID );
			me.TextureDraw( Texture, Ax, Ay, Bx, By, Cx, Cy );
			Texture:SetVertexColor( R, G, B, A );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	local LastFrame;
	function TEST ( Frame, Count )
		me.PolygonRemove( LastFrame, 3 );
		LastFrame = Frame;
		for Index = 1, Count do
			me.PolygonAdd( Frame, 3, me.PathData[ 3 ][ 1 ], 1.0, 0.1, 0.1, 0.5 );
		end
	end
end
