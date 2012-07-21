--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Overlay.lua - Module to show and manipulate map overlays.   *
  ****************************************************************************]]


local Tools = select( 2, ... );
local Overlay = _NPCScan.Overlay;
local NS = CreateFrame( "Frame", nil, WorldMapDetailFrame );
Tools.Overlay = NS;

NS.Buttons = CreateFrame( "Frame", nil, NS );
NS.Buttons.Vertex = CreateFrame( "Button", "_NPCScanToolsOverlayVertex", NS.Buttons, "UIPanelButtonTemplate" );
NS.Buttons.Polygon = CreateFrame( "Button", "_NPCScanToolsOverlayPolygon", NS.Buttons, "UIPanelButtonTemplate" );
NS.Buttons.Hole = CreateFrame( "Button", "_NPCScanToolsOverlayHole", NS.Buttons, "UIPanelButtonTemplate" );
NS.Control = CreateFrame( "Button", nil, nil, "UIPanelButtonTemplate" );

local Polygons = {};




--- @return X and Y map coordinates of the cursor, bounded to the map.
function NS:GetCursorPosition ()
	local CursorX, CursorY = GetCursorPosition();
	local Scale = self:GetEffectiveScale();
	local Left, Bottom, Width, Height = self:GetRect();
	local X, Y = ( CursorX / Scale - Left ) / Width, 1 - ( CursorY / Scale - Bottom) / Height;
	return min( max( X, 0 ), 1 ), min( max( Y, 0 ), 1 );
end
--- Shows the selected NPC's map.
function NS:SetMapToSelection ()
	local _, _, MapID, Floor = Tools:GetSelectedNPC();
	if ( MapID == 0 ) then -- Mapless NPC
		SetMapZoom( WORLDMAP_COSMIC_ID );
	else
		SetMapByID( MapID );
		SetDungeonMapLevel( Floor );
	end
end
do
	local COORD_MAX = 2 ^ 16 - 1;
	--- @return Coord string representing (X, Y).
	function NS:PackCoord ( X, Y )
		X, Y = floor( X * COORD_MAX + 0.5 ), floor( Y * COORD_MAX + 0.5 );
		return string.char( bit.rshift( X, 8 ), bit.band( X, 255 ), bit.rshift( Y, 8 ), bit.band( Y, 255 ) );
	end
	--- @return (X, Y) represented by bytes at Index in Data.
	function NS:UnpackCoord ( Data, Index )
		local X1, X2, Y1, Y2 = Data:byte( Index, Index + 3 );
		return ( X1 * 256 + X2 ) / COORD_MAX, ( Y1 * 256 + Y2 ) / COORD_MAX;
	end
end


do
	local SIGHTING_SIZE, SIGHTING_COLOR = 8, { r = 1.0; g = 0.1; b = 1.0; }; -- Purple
	--- Draws an NPC's sightings from WowHead on the worldmap.
	local function PaintSightings ( self, Sightings, R, G, B )
		local Width, Height = self:GetSize();
		for Index = 1, #Sightings, 4 do
			local X, Y = self:UnpackCoord( Sightings, Index );
			local Texture = Overlay.TextureCreate( self, "OVERLAY", R, G, B );
			Texture:SetTexture( [[Interface\OPTIONSFRAME\VoiceChat-Record]] );
			Texture:SetTexCoord( 0, 1, 0, 1 );
			Texture:SetSize( SIGHTING_SIZE, SIGHTING_SIZE );
			Texture:SetPoint( "CENTER", self, "TOPLEFT", X * Width, -Y * Height );
		end
	end
	--- Throttles repaints to once per frame.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		local NpcID, _, MapID, Floor = Tools:GetSelectedNPC();
		local MapIDCurrent, FloorCurrent = GetCurrentMapAreaID(), GetCurrentMapDungeonLevel();
		if ( self.NpcID == NpcID and self.MapID == MapIDCurrent and self.Floor == FloorCurrent ) then
			return; -- Already rendered this map
		end
		self.NpcID, self.MapID, self.Floor = NpcID, MapIDCurrent, FloorCurrent;

		Overlay.TextureRemoveAll( self );
		if ( self.MapID ~= MapID or self.Floor ~= Floor ) then
			return; -- Viewing wrong map
		end
		local Sightings = Tools.NPCData.Sightings[ MapID ][ Floor ][ NpcID ];
		if ( Sightings ) then
			PaintSightings( self, Sightings, SIGHTING_COLOR.r, SIGHTING_COLOR.g, SIGHTING_COLOR.b );
		end
	end
	--- Draws points on the map for where this NPC was spotted by WowHead.
	function NS:Paint ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end
NS.OnShow = NS.Paint;
NS.WORLD_MAP_UPDATE = NS.Paint;


do
	local PolygonMeta = { __index = {}; };
	do
		local VertexMeta = { __index = {}; };
		--- @return Index of this vertex within its parent polygon.
		function VertexMeta.__index:GetIndex ()
			for Index, Vertex in ipairs( self:GetParent() ) do
				if ( self == Vertex ) then
					return Index;
				end
			end
			error( "Vertex not found in parent polygon." );
		end
		--- Moves this vertex to (X, Y) on the map.
		function VertexMeta.__index:SetPosition ( X, Y )
			self.X, self.Y = X, Y;
			self:GetParent():Paint();
		end
		--- Removes this vertex from its parent polygon.
		function VertexMeta.__index:Remove ()
			self:GetParent():RemoveVertex( self:GetIndex() );
		end
		--- Moves this vertex along with the cursor.
		function VertexMeta.__index:OnUpdate ()
			self:SetPosition( NS:GetCursorPosition() );
		end
		--- Begins dragging this vertex.
		function VertexMeta.__index:OnMouseDown ( Button )
			if ( Button == "RightButton" ) then
				return self:Remove();
			end
			self:SetScript( "OnUpdate", self.OnUpdate );
			self:SetScript( "OnHide", self.OnMouseUp );
		end
		--- Stops dragging this vertex.
		function VertexMeta.__index:OnMouseUp ()
			self:SetScript( "OnUpdate", nil );
			self:SetScript( "OnHide", nil );
			self:OnUpdate();
		end
		local VerticesUnused = {};
		--- @return New vertex instance at Index in this polygon.
		function PolygonMeta.__index:RemoveVertex ( Index )
			local Vertex = assert( table.remove( self, Index ), "Polygon vertex index out of range." );
			Vertex:Hide();
			Vertex:SetParent( nil );
			table.insert( VerticesUnused, Vertex );
			if ( not self.Lines or #self >= 3 ) then
				self:Paint();
			elseif ( self:IsShown() ) then -- Not already being removed
				self:Remove(); -- Too few vertices
			end
		end
		local VERTEX_SIZE, VERTEX_COLOR = 16, NORMAL_FONT_COLOR;
		--- @return New vertex instance at Index in this polygon.
		function PolygonMeta.__index:AddVertex ( Index )
			local Vertex = table.remove( VerticesUnused );
			if ( not Vertex ) then
				Vertex = CreateFrame( "Frame" );
				setmetatable( VertexMeta.__index, getmetatable( Vertex ) );
				setmetatable( Vertex, VertexMeta );
				Vertex:Hide();
				Vertex:SetSize( VERTEX_SIZE, VERTEX_SIZE );
				Vertex:SetScript( "OnMouseDown", Vertex.OnMouseDown );
				Vertex:SetScript( "OnMouseUp", Vertex.OnMouseUp );
				Vertex.Texture = Vertex:CreateTexture();
				Vertex.Texture:SetAllPoints();
				Vertex.Texture:SetTexture( [[Interface\WorldMap\WorldMapPartyIcon]] );
				Vertex.Texture:SetDesaturated( true );
				Vertex.Texture:SetVertexColor( VERTEX_COLOR.r, VERTEX_COLOR.g, VERTEX_COLOR.b );
			end
			table.insert( self, Index or #self + 1, Vertex );
			Vertex:SetParent( self );
			Vertex:Show();
			self:Paint();
			return Vertex;
		end
	end
	local LINE_WIDTH, LINE_COLOR = 32, NORMAL_FONT_COLOR;
	--- Throttles re-paints to once per frame.
	function PolygonMeta.__index:OnUpdate ()
		self:SetScript( "OnUpdate", nil );
		local Width, Height = self:GetSize();
		for Index, Vertex in ipairs( self ) do
			Vertex:SetPoint( "CENTER", self, "TOPLEFT", Width * Vertex.X, Height * -Vertex.Y );
		end
		if ( self.Lines ) then
			Overlay.TextureRemoveAll( self.Lines );
			local VertexLast = self[ #self ];
			for Index, Vertex in ipairs( self ) do
				local Texture = Overlay.TextureCreate( self.Lines, "OVERLAY", LINE_COLOR.r, LINE_COLOR.g, LINE_COLOR.b );
				Texture:SetTexture( [[Interface\TaxiFrame\UI-Taxi-Line]] );
				DrawRouteLine( Texture, self.Lines,
					Width * VertexLast.X, Height * -VertexLast.Y,
					Width * Vertex.X, Height * -Vertex.Y,
					LINE_WIDTH, "TOPLEFT" );
				VertexLast = Vertex;
			end
		end
	end
	--- Re-renders this polygon and its vertices.
	function PolygonMeta.__index:Paint ()
		self:SetScript( "OnUpdate", self.OnUpdate );
	end
	do
		local Bytes = {};
		--- @return Serialized polygon data representing this instance.
		function PolygonMeta.__index:Pack ()
			for Index, Vertex in ipairs( self ) do
				Bytes[ Index ] = Vertex:Pack();
			end
			local Data = { table.concat( Bytes ) };
			wipe( Bytes );
			return Data;
		end
	end
	--- Initializes this polygon with serialized Data.
	function PolygonMeta.__index:Unpack ( Data )
		self:Clear();
		for Index = 1, #Data[ 1 ], 4 do
			self:AddVertex():SetPosition( NS:UnpackCoord( Data[ 1 ], Index ) );
		end
	end
	--- Removes all vertices and holes from this polygon.
	function PolygonMeta.__index:Clear ()
		for Index = #self, 1, -1 do
			self:RemoveVertex( Index );
		end
	end
	--- @return Index of this polygon within the map.
	function PolygonMeta.__index:GetIndex ()
		for Index, Polygon in ipairs( Polygons ) do
			if ( self == Polygon ) then
				return Index;
			end
		end
		error( "Polygon not found on map." );
	end
	--- Clears and recycles this polygon instance.
	function PolygonMeta.__index:Remove ()
		NS:RemovePolygon( self:GetIndex() );
	end
	local PolygonsUnused = {};
	--- Clears and recycles a polygon by index.
	function NS:RemovePolygon ( Index )
		local Polygon = table.remove( Polygons, Index );
		Polygon:Hide();
		Polygon:Clear();
		if ( Polygon.Lines ) then
			Overlay.TextureRemoveAll( Polygon.Lines );
		end
		table.insert( PolygonsUnused, Polygon );
	end
	local POLYGON_DEFAULT = { NS:PackCoord( 0.5, 0.25 )..NS:PackCoord( 0.75, 0.75 )..NS:PackCoord( 0.25, 0.75 ) }; -- Triangle
	--- @return An unused polygon frame in a default configuration.
	-- @param VerticesOnly  Treated as a set of vertices instead of a polygon.
	function NS:AddPolygon ( VerticesOnly )
		local Polygon = table.remove( PolygonsUnused );
		if ( not Polygon ) then
			Polygon = CreateFrame( "Frame", nil, self );
			setmetatable( PolygonMeta.__index, getmetatable( Polygon ) );
			setmetatable( Polygon, PolygonMeta );
			Polygon:SetAllPoints();
		end
		if ( not VerticesOnly ) then
			Polygon.Lines = CreateFrame( "Frame", nil, Polygon );
			Polygon.Lines:SetAllPoints();
			Polygon.Lines:SetFrameLevel( Polygon:GetFrameLevel() + 2 ); -- Above vertices
			Polygon:Unpack( POLYGON_DEFAULT );
		end
		Polygon:Show();
		return Polygon;
	end
end


--- Validates that the selected NPC's map can be shown.
function NS:OnSelectNPC ( _, NpcID, _, MapID )
	if ( MapID ) then
		self:Show();
		self.Control:Enable();
		if ( self:IsVisible() ) then
			self.Control:OnClick(); -- Jump to map
		end
		self:Paint();
	else
		self:Hide();
		self.Control:Disable();
	end
end
--- Opens the map to the selected NPC entry.
function NS.Control:OnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	ShowUIPanel( WorldMapFrame, true );
	NS:SetMapToSelection();
end
--- Registers keys when shown out of combat.
function NS.Buttons:OnShow ()
	SetOverrideBindingClick( self, false, "V", self.Vertex:GetName() );
	SetOverrideBindingClick( self, false, "P", self.Polygon:GetName() );
	SetOverrideBindingClick( self, false, "H", self.Hole:GetName() );
end
NS.Buttons.OnHide = ClearOverrideBindings;
NS.Buttons.PLAYER_REGEN_DISABLED = NS.Buttons.Hide;
NS.Buttons.PLAYER_REGEN_ENABLED = NS.Buttons.Show;
--- Creates a new vertex at the cursor.
function NS.Buttons.Vertex:OnClick ()
	if ( NS:IsMouseOver() ) then
		PlaySound( "igMainMenuOptionCheckBoxOn" );
		Polygons.Vertices:AddVertex():SetPosition( NS:GetCursorPosition() );
	end
end
--- Creates a new default polygon.
function NS.Buttons.Polygon:OnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	table.insert( Polygons, NS:AddPolygon() );
end




NS:Hide();
NS:SetAllPoints();
NS:SetFrameLevel( WorldMapButton:GetFrameLevel() + 1 );
NS:SetScript( "OnShow", NS.OnShow );
NS:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
NS:RegisterEvent( "WORLD_MAP_UPDATE" );
Polygons.Vertices = NS:AddPolygon( true );

local Buttons = NS.Buttons;
Buttons:Hide();
Buttons:SetFrameLevel( Buttons:GetFrameLevel() + 3 ); -- Raise above overlay key
Buttons:SetScript( "OnShow", Buttons.OnShow );
Buttons:SetScript( "OnHide", Buttons.OnHide );
Buttons:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
Buttons:RegisterEvent( "PLAYER_REGEN_DISABLED" );
Buttons:RegisterEvent( "PLAYER_REGEN_ENABLED" );
--- Common setup for button controls.
local function SetupButton ( Button, Label )
	Button:SetText( Label );
	Button:SetSize( Button:GetTextWidth() + 16, 21 );
	Button:SetScript( "OnClick", Button.OnClick );
	return Button;
end
SetupButton( Buttons.Polygon, Tools.L.OVERLAY_POLYGON ):SetPoint( "BOTTOMLEFT", NS );
SetupButton( Buttons.Vertex, Tools.L.OVERLAY_VERTEX ):SetPoint( "BOTTOMLEFT", Buttons.Polygon, "TOPLEFT" );
SetupButton( Buttons.Hole, Tools.L.OVERLAY_HOLE ):SetPoint( "BOTTOMLEFT", Buttons.Polygon, "BOTTOMRIGHT" );
SetupButton( NS.Control, Tools.L.OVERLAY_CONTROL );

Tools:AddControl( NS.Control );
Tools.RegisterCallback( NS, "OnSelectNPC" );
NS:OnSelectNPC( nil, Tools:GetSelectedNPC() );
if ( not InCombatLockdown() ) then
	Buttons:PLAYER_REGEN_ENABLED();
end