--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Overlay.lua - _NPCScan.Overlay module to show mob map data. *
  ****************************************************************************]]


local Routes = LibStub( "AceAddon-3.0" ):GetAddon( "Routes" );
local Tools = select( 2, ... );
local Overlay = _NPCScan.Overlay;
local L = _NPCScanLocalization.TOOLS;
local me = Overlay.Modules.WorldMapTemplate.Embed( CreateFrame( "Frame", nil, WorldMapButton ) );
Tools.Overlay = me;

me.Control = CreateFrame( "Button", nil, nil, "GameMenuButtonTemplate" );

me.AlphaDefault = 1;




--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay:Paint                                     *
  ****************************************************************************]]
do
	local Max = 2 ^ 16 - 1;
	local X, X2, Y, Y2, Density;
	local Width, Height, Texture;
	local SelectionDrawn;
	local function PaintPoints ( self, _, _, _, R, G, B, NpcID )
		if ( not self.NpcIDSelected or self.NpcIDSelected == NpcID ) then
			SelectionDrawn = true;
			local Data = Tools.NPCLocations.PositionData[ NpcID ];
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
	end
	function me:Paint ( Map )
		if ( not self.NpcIDSelected or Tools.NPCLocations.MapIDs[ self.NpcIDSelected ] == Map ) then
			SelectionDrawn = false;
			Overlay.ApplyZone( self, Map, PaintPoints );
			if ( self.NpcIDSelected and not SelectionDrawn ) then
				-- _NPCScan.Overlay has no data on mob, and therefore no assigned color
				local Color = HIGHLIGHT_FONT_COLOR;
				PaintPoints( self, nil, nil, nil, Color.r, Color.g, Color.b, self.NpcIDSelected );
			end
		end
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Tools.Overlay.Select                                    *
  ****************************************************************************]]
function me.Select ( NpcID )
	if ( me.NpcIDSelected ~= NpcID ) then
		me.NpcIDSelected = NpcID;

		local MapID = Tools.NPCLocations.MapIDs[ NpcID ];
		if ( not NpcID or MapID ) then
			me:OnMapUpdate( MapID );
		end
		return true;
	end
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

	self.NpcID, self.MapID = NpcID, Tools.NPCLocations.MapIDs[ NpcID ];
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
	Overlay.Modules.Register( ..., me, L.OVERLAY_TITLE );


	me.Control:SetText( L.OVERLAY_CONTROL );
	me.Control:SetScript( "OnClick", me.Control.OnClick );

	Tools.Config.Controls:Add( me.Control );
end
