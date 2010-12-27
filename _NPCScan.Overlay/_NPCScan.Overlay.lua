--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.lua - Adds mob patrol paths to your map.                  *
  ****************************************************************************]]


_NPCScan = _NPCScan or {};
local _NPCScan = _NPCScan;
local AddOnName, me = ...;
_NPCScan.Overlay = me;

me.Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );

me.Options = {
	Version = me.Version;
	Modules = {};
	ModulesAlpha = {};
	ModulesExtra = {};
};

me.OptionsDefault = {
	Version = me.Version;
	Modules = {};
	ModulesAlpha = {};
	ModulesExtra = {};
	ShowAll = false;
};


me.NPCsEnabled = {};
me.NPCCounts = {}; -- Number of enabled NPCs that use this NPC path
me.NPCMaps = {}; -- [ NpcID ] = { [ MapID1 ] = (true|{FoundX,FoundY}); ... };
me.NPCsFoundIgnored = {
	[ 32487 ] = true; -- Putridus the Ancient
	[ 50009 ] = true; -- Mobus
};
me.NPCAliases = { -- (Key) NPC shows (Value) NPC's path instead
	-- Note: Circular references will lock client!
	-- Madexx (Brown)
	[ 51401 ] = 50154; -- Madexx (Red)
	[ 51402 ] = 50154; -- Madexx (Green)
	[ 51403 ] = 50154; -- Madexx (Black)
	[ 51404 ] = 50154; -- Madexx (Blue)
};
me.Achievements = { -- Achievements whos criteria mobs are all mapped
	[ 1312 ] = true; -- Bloody Rare (Outlands)
	[ 2257 ] = true; -- Frostbitten (Northrend)
};

me.Colors = {
	RAID_CLASS_COLORS.SHAMAN,
	RAID_CLASS_COLORS.DEATHKNIGHT,
	GREEN_FONT_COLOR,
	RAID_CLASS_COLORS.DRUID,
	RAID_CLASS_COLORS.PALADIN,
};

me.DetectionRadius = 100; -- yards

local TexturesUnused = CreateFrame( "Frame" );

me.Events = LibStub( "AceEvent-3.0" ):Embed( {} );
local MESSAGE_REGISTER = "NpcOverlay_RegisterScanner";
local MESSAGE_ADD = "NpcOverlay_Add";
local MESSAGE_REMOVE = "NpcOverlay_Remove";
local MESSAGE_FOUND = "NpcOverlay_Found";




--- Prepares an unused texture on the given frame.
-- @param Layer  Draw layer for texture.
-- @param ...  Color and optional alpha to set texture to.
function me:TextureCreate ( Layer, R, G, B, A )
	local Texture = #TexturesUnused > 0 and TexturesUnused[ #TexturesUnused ];
	if ( Texture ) then
		TexturesUnused[ #TexturesUnused ] = nil;
		Texture:SetParent( self );
		Texture:SetDrawLayer( Layer );
		Texture:ClearAllPoints();
		Texture:Show();
	else
		Texture = self:CreateTexture( nil, Layer );
	end
	Texture:SetVertexColor( R, G, B, A or 1 );
	Texture:SetBlendMode( "BLEND" );

	self[ #self + 1 ] = Texture;
	return Texture;
end
do
	local ApplyTransform;
	do
		local Det, AF, BF, CD, CE;
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy;
		--- Applies an affine transformation to Texture.
		-- @param Texture  Texture to set TexCoords for.
		-- @param ...  First 6 elements of transformation matrix.
		function ApplyTransform( Texture, A, B, C, D, E, F )
			Det = A * E - B * D;
			AF, BF, CD, CE = A * F, B * F, C * D, C * E;

			ULx, ULy = ( BF - CE ) / Det, ( CD - AF ) / Det;
			LLx, LLy = ( BF - CE - B ) / Det, ( CD - AF + A ) / Det;
			URx, URy = ( BF - CE + E ) / Det, ( CD - AF - D ) / Det;
			LRx, LRy = ( BF - CE + E - B ) / Det, ( CD - AF - D + A ) / Det;

			-- Bounds to prevent "TexCoord out of range" errors
			if ( ULx < -1e4 ) then ULx = -1e4; elseif ( ULx > 1e4 ) then ULx = 1e4; end
			if ( ULy < -1e4 ) then ULy = -1e4; elseif ( ULy > 1e4 ) then ULy = 1e4; end
			if ( LLx < -1e4 ) then LLx = -1e4; elseif ( LLx > 1e4 ) then LLx = 1e4; end
			if ( LLy < -1e4 ) then LLy = -1e4; elseif ( LLy > 1e4 ) then LLy = 1e4; end
			if ( URx < -1e4 ) then URx = -1e4; elseif ( URx > 1e4 ) then URx = 1e4; end
			if ( URy < -1e4 ) then URy = -1e4; elseif ( URy > 1e4 ) then URy = 1e4; end
			if ( LRx < -1e4 ) then LRx = -1e4; elseif ( LRx > 1e4 ) then LRx = 1e4; end
			if ( LRy < -1e4 ) then LRy = -1e4; elseif ( LRy > 1e4 ) then LRy = 1e4; end

			return Texture:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
		end
	end
	local min, max = min, max;
	local MinX, MinY, WindowX, WindowY;
	local ABx, ABy, BCx, BCy;
	local ScaleX, ScaleY, ShearFactor, Sin, Cos;
	local Parent, Width, Height;
	local SinScaleX, SinScaleY, CosScaleX, CosScaleY;
	local BorderScale, BorderOffset = 512 / 510, -1 / 512; -- Removes one-pixel transparent border
	local TrianglePath = [[Interface\AddOns\]]..AddOnName..[[\Skin\Triangle]]
	--- Draw a triangle texture with vertices at relative coords.  (0,0) is top-left, (1,1) is bottom-right.
	function me:TextureAdd ( Layer, R, G, B, Ax, Ay, Bx, By, Cx, Cy )
		ABx, ABy, BCx, BCy = Ax - Bx, Ay - By, Bx - Cx, By - Cy;
		ScaleX = ( BCx * BCx + BCy * BCy ) ^ 0.5;
		if ( ScaleX == 0 ) then
			return;
		end
		ScaleY = ( ABx * BCy - BCx * ABy ) / ScaleX;
		if ( ScaleY == 0 ) then
			return;
		end
		ShearFactor = -( ABx * BCx + ABy * BCy ) / ( ScaleX * ScaleX );
		Sin, Cos = BCy / ScaleX, -BCx / ScaleX;


		-- Get a texture
		local Texture = me.TextureCreate( self, Layer, R, G, B );
		Texture:SetTexture( TrianglePath );


		-- Note: The texture region is made as small as possible to improve framerates.
		MinX, MinY = min( Ax, Bx, Cx ), min( Ay, By, Cy );
		WindowX, WindowY = max( Ax, Bx, Cx ) - MinX, max( Ay, By, Cy ) - MinY;

		Width, Height = self:GetSize();
		Texture:SetPoint( "TOPLEFT", MinX * Width, -MinY * Height );
		Texture:SetSize( WindowX * Width, WindowY * Height );


		--[[ Transform parallelogram so its corners lie on the tri's points:
		local Matrix = Identity;
		-- Remove transparent border
		Matrix = Matrix:Scale( BorderScale, BorderScale );
		Matrix = Matrix:Translate( BorderOffset, BorderOffset );

		Matrix = Matrix:Shear( ShearFactor ); -- Shear the image so its bottom left corner aligns with point A
		Matrix = Matrix:Scale( ScaleX, ScaleY ); -- Scale X by the length of line BC, and Y by the length of the perpendicular line from BC to point A
		Matrix = Matrix:Rotate( Sin, Cos ); -- Align the top of the triangle with line BC.

		Matrix = Matrix:Translate( Bx - MinX, By - MinY ); -- Move origin to overlap point B
		Matrix = Matrix:Scale( 1 / WindowX, 1 / WindowY ); -- Adjust for change in texture size

		ApplyTransform( unpack( Matrix, 1, 6 ) );
		]]

		-- Common operations
		WindowX, WindowY = BorderScale / WindowX, BorderScale / WindowY;
		SinScaleX, SinScaleY = -Sin * ScaleX, Sin * ScaleY;
		CosScaleX, CosScaleY =  Cos * ScaleX, Cos * ScaleY;

		return ApplyTransform( Texture,
			WindowX * CosScaleX,
			WindowX * ( SinScaleY + CosScaleX * ShearFactor ),
			WindowX * ( ( SinScaleY + CosScaleX * ( 1 + ShearFactor ) ) * BorderOffset + Bx - MinX ) / BorderScale,
			WindowY * SinScaleX,
			WindowY * ( CosScaleY + SinScaleX * ShearFactor ),
			WindowY * ( ( CosScaleY + SinScaleX * ( 1 + ShearFactor ) ) * BorderOffset + By - MinY ) / BorderScale );
	end
end
--- Recycles all textures added to a frame using TextureCreate.
function me:TextureRemoveAll ()
	for Index = #self, 1, -1 do
		local Texture = self[ Index ];
		self[ Index ] = nil;
		Texture:Hide();
		Texture:SetParent( TexturesUnused );
		TexturesUnused[ #TexturesUnused + 1 ] = Texture;
	end
end


do
	local Max = 2 ^ 16 - 1;
	local Ax1, Ax2, Ay1, Ay2, Bx1, Bx2, By1, By2, Cx1, Cx2, Cy1, Cy2;
	--- Draws the given NPC's path onto a frame.
	-- @param PathData  Binary path data string.
	function me:DrawPath ( PathData, Layer, R, G, B )
		for Index = 1, #PathData, 12 do
			Ax1, Ax2, Ay1, Ay2, Bx1, Bx2, By1, By2, Cx1, Cx2, Cy1, Cy2 = PathData:byte( Index, Index + 11 );
			me.TextureAdd( self, Layer, R, G, B,
				( Ax1 * 256 + Ax2 ) / Max, ( Ay1 * 256 + Ay2 ) / Max,
				( Bx1 * 256 + Bx2 ) / Max, ( By1 * 256 + By2 ) / Max,
				( Cx1 * 256 + Cx2 ) / Max, ( Cy1 * 256 + Cy2 ) / Max );
		end
	end
end
do
	local RingWidth = 1.14; -- Ratio of texture width to ring width
	local GlowWidth = 1.25;
	--- Adds a found NPC's range circle onto a frame.
	-- @param X..Y  Relative coordinate to center circle on.  (0,0) is top-left, (1,1) is bottom-right.
	-- @param RadiusX  Radius relative to the frame's width.  That is, 0.5 for a circle as wide as the frame.
	function me:DrawFound ( X, Y, RadiusX, Layer, R, G, B )
		local Width, Height = self:GetSize();

		X, Y = X * Width, -Y * Height;
		local Size = RadiusX * 2 * Width;

		local Texture = me.TextureCreate( self, Layer, R, G, B );
		Texture:SetTexture( [[Interface\Minimap\Ping\ping2]] );
		Texture:SetTexCoord( 0, 1, 0, 1 );
		Texture:SetBlendMode( "ADD" );
		Texture:SetPoint( "CENTER", self, "TOPLEFT", X, Y );
		Texture:SetSize( Size * RingWidth, Size * RingWidth );

		Texture = me.TextureCreate( self, Layer, R, G, B, 0.5 );
		Texture:SetTexture( [[Textures\SunCenter]] );
		Texture:SetTexCoord( 0, 1, 0, 1 );
		Texture:SetBlendMode( "ADD" );
		Texture:SetPoint( "CENTER", self, "TOPLEFT", X, Y );
		Texture:SetSize( Size * GlowWidth, Size * GlowWidth );
	end
end
--- Passes info for all enabled NPCs in a zone to a callback function.
-- @param Callback  Function( self, PathData, [FoundX], [FoundY], R, G, B, NpcID )
function me:ApplyZone ( Map, Callback )
	local MapData = me.PathData[ Map ];
	if ( MapData ) then
		local ColorIndex = 0;

		for NpcID, PathData in pairs( MapData ) do
			ColorIndex = ColorIndex + 1;
			if ( me.Options.ShowAll or me.NPCCounts[ NpcID ] ) then
				local Color = assert( me.Colors[ ColorIndex ], "Ran out of unique path colors." );
				local Found, FoundX, FoundY = me.NPCMaps[ NpcID ][ Map ];
				if ( type( Found ) == "table" ) then
					FoundX, FoundY = unpack( Found );
				end
				Callback( self, PathData, FoundX, FoundY, Color.r, Color.g, Color.b, NpcID );
			end
		end
	end
end




--- @return Aliased NPC ID, or original if not aliased.
local function GetRealNpcID ( NpcID )
	local AliasID = me.NPCAliases[ NpcID ];
	while ( AliasID ) do
		NpcID, AliasID = AliasID, me.NPCAliases[ AliasID ];
	end
	return NpcID;
end
--- @return First Map ID that NpcID can be found on or nil if unknown.
function me.GetNPCMapID ( NpcID )
	local Maps = me.NPCMaps[ GetRealNpcID( NpcID ) ];
	if ( Maps ) then
		return ( next( Maps ) );
	end
end

--- Enables an NPC map overlay by NpcID.
local function NPCAdd ( NpcID )
	local AliasID, NpcID = NpcID, GetRealNpcID( NpcID );
	if ( not me.NPCsEnabled[ AliasID ] and me.NPCMaps[ NpcID ] ) then
		me.NPCsEnabled[ AliasID ] = true;

		me.NPCCounts[ NpcID ] = ( me.NPCCounts[ NpcID ] or 0 ) + 1;
		if ( me.NPCCounts[ NpcID ] == 1 and not me.Options.ShowAll ) then
			for Map in pairs( me.NPCMaps[ NpcID ] ) do
				me.Modules.UpdateMap( Map );
			end
		end
	end
end
--- Disables an NPC map overlay by NpcID.
local function NPCRemove ( NpcID )
	if ( me.NPCsEnabled[ NpcID ] ) then
		me.NPCsEnabled[ NpcID ] = nil;

		NpcID = GetRealNpcID( NpcID );
		local Count = assert( me.NPCCounts[ NpcID ], "Enabled NPC wasn't active." );
		me.NPCCounts[ NpcID ] = Count > 1 and Count - 1 or nil;

		if ( not ( Count > 1 or me.Options.ShowAll ) ) then
			for Map in pairs( me.NPCMaps[ NpcID ] ) do
				me.Modules.UpdateMap( Map );
			end
		end
	end
end
--- Saves an NPC's last seen position at the player.
local function NPCFound ( NpcID )
	NpcID = GetRealNpcID( NpcID );
	if ( me.NPCMaps[ NpcID ] and not me.NPCsFoundIgnored[ NpcID ] ) then
		local MapOld, MapNew = GetCurrentMapAreaID(), nil;
		SetMapToCurrentZone();
		local MapCurrent = GetCurrentMapAreaID();
		for Map, Found in pairs( me.NPCMaps[ NpcID ] ) do
			SetMapByID( Map );
			local X, Y = GetPlayerMapPosition( "player" );
			if ( X ~= 0 or Y ~= 0 ) then -- Found on this map
				if ( MapNew ~= MapCurrent ) then -- Current map has priority if found there
					MapNew = Map; -- Force map to view found rare
				end

				if ( type( Found ) ~= "table" ) then
					Found = {};
					me.NPCMaps[ NpcID ][ Map ] = Found;
				end
				Found[ 1 ], Found[ 2 ] = X, Y;

				if ( me.NPCCounts[ NpcID ] ) then
					me.Modules.UpdateMap( Map );
				end
			end
		end
		SetMapByID( MapNew or MapOld );
	end
end


do
	-- See <http://sites.google.com/site/wowsaiket/Add-Ons/NPCScanOverlay/API>
	-- for Overlay message documentation.
	local ScannerAddOn;
	--- Grants exclusive control of mob path visibility to the first addon that registers.
	-- @param AddOn  Logically true identifier for the controller addon.  Must be
	--   used in all subsequent messages.
	me.Events[ MESSAGE_REGISTER ] = function ( self, Event, AddOn )
		self:UnregisterMessage( Event );
		self[ Event ] = nil;
		ScannerAddOn = assert( AddOn, "Registration message must provide an addon identifier." );

		-- Quit showing all by default and let the scanning addon control visibility
		for NpcID in pairs( me.NPCsEnabled ) do
			NPCRemove( NpcID );
		end

		self:RegisterMessage( MESSAGE_ADD );
		self:RegisterMessage( MESSAGE_REMOVE );
	end;
	--- Shows a mob's path, if available.
	-- @param NpcID  Numeric creature ID to add.
	-- @param AddOn  Identifier used in registration message.
	me.Events[ MESSAGE_ADD ] = function ( self, _, NpcID, AddOn )
		if ( ScannerAddOn and AddOn == ScannerAddOn ) then
			return NPCAdd( assert( tonumber( NpcID ),
				"Add message NpcID must be numeric." ) );
		end
	end;
	--- Removes a mob's path if it has already been shown.
	-- @param NpcID  Numeric creature ID to remove.
	-- @param AddOn  Identifier used in registration message.
	me.Events[ MESSAGE_REMOVE ] = function ( self, _, NpcID, AddOn )
		if ( ScannerAddOn and AddOn == ScannerAddOn ) then
			return NPCRemove( assert( tonumber( NpcID ),
				"Remove message NpcID must be numeric." ) );
		end
	end;
	--- Saves an NPC's last seen position at the player.
	-- Will fail if the current zone doesn't match saved path data.
	-- @param NpcID  Numeric creature ID that was found.
	me.Events[ MESSAGE_FOUND ] = function ( self, _, NpcID )
		return NPCFound( assert( tonumber( NpcID ),
			"Found message Npc ID must be a number." ) );
	end;
end




--- Enables always showing all paths.
-- @return True if changed.
function me.SetShowAll ( Enable )
	Enable = not not Enable;
	if ( Enable ~= me.Options.ShowAll ) then
		me.Options.ShowAll = Enable;

		me.Config.ShowAll:SetChecked( Enable );

		-- Update all affected maps
		for Map, MapData in pairs( me.PathData ) do
			-- If a map has a disabled path, it must be redrawn
			for NpcID in pairs( MapData ) do
				if ( not me.NPCCounts[ NpcID ] ) then
					me.Modules.UpdateMap( Map );
					break;
				end
			end
		end

		return true;
	end
end


--- Reloads enabled modules from saved settings.
function me.Synchronize ( Options )
	-- Load defaults if settings omitted
	if ( not Options ) then
		Options = me.OptionsDefault;
	end

	me.SetShowAll( Options.ShowAll );
	me.Modules.OnSynchronize( Options );
end
do
	local MapNames = {};
	--- @return Localized zone name for Map or nil if unknown.
	-- Note that only true continent sub-zones are supported.
	function me.GetMapName ( Map )
		return MapNames[ Map ];
	end
	local MapIDs = {}; -- [ LocalizedZoneName ] = MapID;
	--- @return Map ID for localized zone name or nil if unknown.
	-- Note that only true continent sub-zones are supported.
	function me.GetMapID ( Name )
		return MapIDs[ Name ];
	end
	local MapWidths, MapHeights = {}, {};
	--- @return Width and height of Map in yards or nil if unavailable.
	function me.GetMapSize ( Map )
		return MapWidths[ Map ], MapHeights[ Map ];
	end

	--- Saves localized map names on a given ContinentID.
	local function HandleZones ( ContinentID, ... )
		for ZoneIndex = 1, select( "#", ... ) do
			SetMapZoom( ContinentID, ZoneIndex );

			local Map = GetCurrentMapAreaID();
			if ( me.PathData[ Map ] ) then
				local Name = select( ZoneIndex, ... );
				MapNames[ Map ], MapIDs[ Name ] = Name, Map;

				local _, X1, Y1, X2, Y2 = GetCurrentMapZone();
				local Width, Height = X1 - X2, Y1 - Y2;
				if ( not Width or Width == 0 or Height == 0 ) then
					error( "Zone dimensions unavailable for map "..Map.."." );
				end
				MapWidths[ Map ], MapHeights[ Map ] = Width, Height;
			end
		end
	end
	--- Loads defaults, validates settings, and begins listening for Overlay API messages.
	function me.Events:ADDON_LOADED ( Event, AddOn )
		if ( AddOn == AddOnName ) then
			self[ Event ] = nil;
			self:UnregisterEvent( Event );

			-- Build a lookup table for localized zone names to map files
			-- Note: Doesn't support dungeon maps, as their localized names are unavailable in-game
			for ContinentID = 1, select( "#", GetMapContinents() ) do
				HandleZones( ContinentID, GetMapZones( ContinentID ) );
			end
			-- Build a reverse lookup of NpcIDs to zones, and add them all by default
			for Map, MapData in pairs( me.PathData ) do
				if ( not me.GetMapSize( Map ) ) then
					error( "Zone dimensions unavailable for map "..Map.."." );
				end
				for NpcID in pairs( MapData ) do
					if ( not me.NPCMaps[ NpcID ] ) then
						me.NPCMaps[ NpcID ] = {};
					end
					me.NPCMaps[ NpcID ][ Map ] = true;
					NPCAdd( NpcID );
				end
			end

			local Options = _NPCScanOverlayOptions;
			_NPCScanOverlayOptions = me.Options;
			if ( Options and not Options.ModulesExtra ) then -- 3.3.5.1: Moved module options to options sub-tables
				Options.ModulesExtra = {};
			end
			me.Synchronize( Options ); -- Loads defaults if nil

			self:RegisterMessage( MESSAGE_REGISTER );
			self:RegisterMessage( MESSAGE_FOUND );
		end
	end
end




me.Events:RegisterEvent( "ADDON_LOADED" );