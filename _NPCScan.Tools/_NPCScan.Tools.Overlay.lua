--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Overlay.lua - _NPCScan.Overlay module to show mob map data. *
  ****************************************************************************]]


local Routes = LibStub( "AceAddon-3.0" ):GetAddon( "Routes" );
local Tools = _NPCScan.Tools;
local Overlay = _NPCScan.Overlay;
local L = _NPCScanLocalization.TOOLS;
local me = CreateFrame( "Frame", nil, WorldMapButton );
Tools.Overlay = me;

me.Control = CreateFrame( "Button", nil, nil, "GameMenuButtonTemplate" );

me.Label = L.OVERLAY_TITLE;
me.AlphaDefault = 1;




--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:Paint                                     *
  ****************************************************************************]]
do
	local Max = 2 ^ 16 - 1;
	local X, X2, Y, Y2, Density;
	local Width, Height, Texture;
	local function PaintPoints ( self, _, _, _, R, G, B, NpcID )
		local Data = Tools.LocationData.NpcData[ NpcID ];
		if ( Data ) then
			Width, Height = self:GetWidth(), self:GetHeight();
			for Index = 1, #Data, 5 do
				X, X2, Y, Y2, Density = Data:byte( Index, Index + 4 );
				X, Y = ( X * 256 + X2 ) / Max, ( Y * 256 + Y2 ) / Max;
				Density = Density / 255;

				Texture = Overlay.TextureCreate( self, "OVERLAY", R, G, B, Density );
				Texture:SetTexture( [[Interface\OPTIONSFRAME\VoiceChat-Record]] );
				Texture:SetTexCoord( 0, 1, 0, 1 );
				Texture:SetSize( 8, 8 );
				Texture:SetPoint( "CENTER", self, "TOPLEFT", X * Width, -Y * Height );
			end
		end
	end
	function me:Paint ( Map )
		if ( me.NpcIDSelected ) then
			local NpcMap = Tools.LocationData.NpcMapIDs[ me.NpcIDSelected ];
			if ( Map == NpcMap ) then
				-- Attempt to find the NPC's normal draw color
				local Color, ColorIndex = HIGHLIGHT_FONT_COLOR, 0;
				if ( Overlay.PathData[ Map ] ) then
					for NpcID in pairs( Overlay.PathData[ Map ] ) do
						ColorIndex = ColorIndex + 1;
						if ( NpcID == me.NpcIDSelected ) then
							Color = Overlay.Colors[ ( ColorIndex - 1 ) % #Overlay.Colors + 1 ];
							break;
						end
					end
				end

				PaintPoints( self, nil, nil, nil, Color.r, Color.g, Color.b, me.NpcIDSelected );
			end
		else -- No selection; show all colored
			Overlay.ApplyZone( self, Map, PaintPoints );
		end
	end
end


--[[****************************************************************************
  * Function: local MapUpdate                                                  *
  ****************************************************************************]]
local MapUpdate;
do
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );

		local Map = GetCurrentMapAreaID() - 1;
		if ( Map ~= self.MapLast ) then
			self.MapLast = Map;

			Overlay.TextureRemoveAll( self );
			self:Paint( Map );
		end
	end
	function MapUpdate ( self, Force )
		if ( Force ) then
			self.MapLast = nil;
		end
		self:SetScript( "OnUpdate", OnUpdate );
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:OnShow                                    *
  ****************************************************************************]]
function me:OnShow ()
	MapUpdate( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:OnEvent                                   *
  ****************************************************************************]]
function me:OnEvent ()
	MapUpdate( self );
end


--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay.Select                                    *
  ****************************************************************************]]
function me.Select ( NpcID )
	if ( me.NpcIDSelected ~= NpcID ) then
		me.NpcIDSelected = NpcID;

		local MapID = Tools.LocationData.NpcMapIDs[ NpcID ];
		if ( not NpcID or MapID ) then
			me:Update( MapID );
		end
		return true;
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:Update                                    *
  ****************************************************************************]]
function me:Update ( Map )
	if ( not Map or Map == self.MapLast ) then
		MapUpdate( self, true );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:Disable                                   *
  ****************************************************************************]]
function me:Disable ()
	self:UnregisterEvent( "WORLD_MAP_UPDATE" );
	self:Hide();
	Overlay.TextureRemoveAll( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:Enable                                    *
  ****************************************************************************]]
function me:Enable ()
	self:RegisterEvent( "WORLD_MAP_UPDATE" );
	self:Show();
end


--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay.Control:SetRoutesEnabled                  *
  ****************************************************************************]]
function me.Control:SetRoutesEnabled ( NpcID, Enable )
	local RoutesDB = Routes.db.global.routes[ self.MapFile ];
	if ( RoutesDB ) then
		for Name, Route in pairs( RoutesDB ) do
			local NpcID = tonumber( Name:match( "^Overlay:([^:]+)" ) );
			if ( NpcID == self.NpcID ) then -- Path of selected mob
				Route.hidden = not Enable;
				Routes:DrawWorldmapLines();
				Routes:DrawMinimapLines( true );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay.Control:OnSelect                          *
  ****************************************************************************]]
function me.Control:OnSelect ( NpcID )
	if ( self.MapFile ) then
		-- Re-hide routes for last shown mob
		self:SetRoutesEnabled( NpcID, false );
		self.MapFile = nil;
	end

	self.NpcID, self.MapID = NpcID, Tools.LocationData.NpcMapIDs[ NpcID ];
	if ( self.MapID ) then
		self:Enable();
	else
		self:Disable();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay.Control:OnClick                           *
  * Description: Shows the selected NPC's map.                                 *
  ****************************************************************************]]
function me.Control:OnClick ()
	ShowUIPanel( WorldMapFrame );
	SetMapByID( self.MapID );

	-- Show Routes for this mob
	local MapFile = GetMapInfo();
	self.MapFile = MapFile;
	self:SetRoutesEnabled( self.NpcID, true );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetAllPoints();
	me:SetScript( "OnShow", me.OnShow );
	me:SetScript( "OnEvent", me.OnEvent );

	Overlay.ModuleRegister( "_NPCScan.Tools", me );


	me.Control:SetText( L.OVERLAY_CONTROL );
	me.Control:SetScript( "OnClick", me.Control.OnClick );

	Tools.Config.Controls:Add( me.Control );
end
