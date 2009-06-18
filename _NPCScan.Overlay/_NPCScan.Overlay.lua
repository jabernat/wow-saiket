--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.lua - Adds mob patrol paths to your map.                  *
  ****************************************************************************]]


local L = _NPCScanLocalization.OVERLAY;
local _NPCScan = _NPCScan;
local me = CreateFrame( "Frame" );
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
	local MinX, MinY, WindowX, WindowY;
	local ABx, ABy, BCx, BCy;
	local ScaleX, ScaleY, ShearFactor, Sin, Cos;
	local Parent, Width, Height;
	function me:TextureDraw ( Ax, Ay, Bx, By, Cx, Cy )
		-- Note: The texture region is made as small as possible to improve framerates.
		local MinX, MinY = min( Ax, Bx, Cx ), min( Ay, By, Cy );
		local WindowX = max( Ax, Bx, Cx ) - MinX;
		local WindowY = max( Ay, By, Cy ) - MinY;

		-- Translate, rotate, scale, and shear so three of the parallelogram's corners lie on the points
		ABx, ABy, BCx, BCy = Ax - Bx, Ay - By, Bx - Cx, By - Cy;
		ScaleX = ( BCx * BCx + BCy * BCy ) ^ 0.5;
		ScaleY = ( ABx * BCy - BCx * ABy ) / ScaleX;
		ShearFactor = -( ABx * BCx + ABy * BCy ) / ( ScaleX * ScaleX );
		Sin, Cos = BCy / ScaleX, -BCx / ScaleX;

		ApplyTransform( self,
			 Cos * ScaleX / WindowX, ( Sin * ScaleY + Cos * ScaleX * ShearFactor ) / WindowX, ( Bx - MinX ) / WindowX,
			-Sin * ScaleX / WindowY, ( Cos * ScaleY - Sin * ScaleX * ShearFactor ) / WindowY, ( By - MinY ) / WindowY );

		Parent = self:GetParent();
		Width, Height = Parent:GetWidth(), Parent:GetHeight();
		self:SetPoint( "TOPLEFT", MinX * Width, -MinY * Height );
		self:SetWidth( WindowX * Width );
		self:SetHeight( WindowY * Height );
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
  * Function: _NPCScan.Overlay:PolygonAdd                                      *
  * Description: Draws the given polygon onto a frame.                         *
  ****************************************************************************]]
do
	local byte = string.byte;
	local lshift = bit.lshift;
	local Max = 2 ^ 16 - 1;
	function me:PolygonAdd ( ID, PolyData, Layer, R, G, B, A )
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
			Texture:SetDrawLayer( Layer );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:PolygonSetZone                                  *
  * Description: Repaints a given zone's polygons on the frame.                *
  ****************************************************************************]]
do
	local Colors = {
		RED_FONT_COLOR,
		RAID_CLASS_COLORS.PALADIN,
		GREEN_FONT_COLOR,
		RAID_CLASS_COLORS.MAGE,
		RAID_CLASS_COLORS.DRUID,
	};
	function me:PolygonSetZone ( MapName, Layer )
		me.PolygonRemoveAll( self );

		local MapData = me.PathData[ MapName ];
		if ( MapData ) then
			local ColorIndex = 0;

			for NPCID, Data in pairs( MapData ) do
				ColorIndex = ColorIndex + 1;
				local Color = Colors[ ( ColorIndex - 1 ) % #Colors + 1 ];
				if ( type( Data ) == "table" ) then
					for _, PolyData in ipairs( Data ) do
						me.PolygonAdd( self, NPCID, PolyData, Layer, Color.r, Color.g, Color.b, 0.5 );
					end
				else
					me.PolygonAdd( self, NPCID, Data, Layer, Color.r, Color.g, Color.b, 0.5 );
				end
			end
		end
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMapUpdate                                  *
  ****************************************************************************]]
do
	local LastMap;
	function me.WorldMapUpdate ()
		local Map = GetMapInfo();
		if ( Map ~= LastMap ) then
			LastMap = Map;
			me.PolygonSetZone( WorldMapDetailFrame, Map, "OVERLAY" );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMapEnable                                  *
  ****************************************************************************]]
function me.WorldMapEnable ()
	hooksecurefunc( "WorldMapFrame_Update", me.WorldMapUpdate );
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimapUpdate                        *
  ****************************************************************************]]
do
	local LastMap;
	function me.BattlefieldMinimapUpdate ()
		local Map = GetMapInfo();
		if ( Map ~= LastMap ) then
			LastMap = Map;
			me.PolygonSetZone( me.BattlefieldMinimapFrame, Map, "OVERLAY" );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimapEnable                        *
  ****************************************************************************]]
function me.BattlefieldMinimapEnable ()
	hooksecurefunc( "BattlefieldMinimap_Update", me.BattlefieldMinimapUpdate );
	me.BattlefieldMinimapFrame = CreateFrame( "Frame", nil, BattlefieldMinimap );
	me.BattlefieldMinimapFrame:SetAllPoints();
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay:ADDON_LOADED                                    *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	AddOn = AddOn:lower();
	if ( AddOn == "_npcscan.overlay" ) then
		me.WorldMapEnable();
		if ( IsAddOnLoaded( "Blizzard_BattlefieldMinimap" ) ) then
			me.BattlefieldMinimapEnable();
		end

		LoadAddOn( "Routes" ); -- TODO(Remove)
	elseif ( AddOn == "blizzard_battlefieldminimap" ) then
		me.BattlefieldMinimapEnable();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:OnEvent                                         *
  ****************************************************************************]]
me.OnEvent = _NPCScan.OnEvent;




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
end
